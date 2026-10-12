#!/usr/bin/env python3
"""
Ghar Alert v3 - purane Android phone (Termux) pe chalne wala camera watcher.

Bahar ke cameras dekhta hai -> movement pe AI se poochta hai -> khatra ho to:
  1. Firebase pe alert save karta hai (photo + type ke saath)
  2. Family ke "Ghar Alert" app pe bhejta hai:
       "Bahar" mode ya raat  -> tez siren (silent phone pe bhi)
       "Ghar pe" mode        -> halka notification
  3. Telegram group pe backup alert
App se aane wali settings (mode, camera on/off, sensitivity, raat ka samay,
roz ka summary) apne aap padhta hai. App se "Abhi ki photo" maango to taaza photo bhejta hai.

Chalane ke liye:  python ghar_alert.py         (test: python ghar_alert.py test)
"""

import base64
import io
import json
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone

import requests
from PIL import Image, ImageChops

import google.auth.transport.requests
from google.oauth2 import service_account

# =====================================================================
#  SETTINGS - sirf yeh hissa badalna hai
# =====================================================================

NVR_IP = "192.168.1.108"          # NVR ka IP (TV pe NVR menu -> Network)
NVR_USER = "admin"
NVR_PASSWORD = "APNA_PASSWORD"    # wahi jo SeeEasy / TV pe daalte ho

# RTSP link ka format. Onvifer/VLC se jo link chala, uske hisaab se badlo.
# {user} {password} {ip} {channel} apne aap bhar jayenge.
RTSP_TEMPLATE = ("rtsp://{user}:{password}@{ip}:554"
                 "/cam/realmonitor?channel={channel}&subtype=1")

# Bahar wale cameras: naam -> NVR channel number (yahi naam app mein dikhenge)
CAMERAS = {
    "Gate camera": 1,
    "Aangan camera": 2,
}

# Firebase (SETUP.md dekho)
FIREBASE_KEY_FILE = "/data/data/com.termux/files/home/firebase-key.json"
FCM_TOPIC = "ghar_alerts"         # app mein bhi yahi hai, mat badlo

# Telegram backup (khaali chhod do to Telegram band)
TELEGRAM_BOT_TOKEN = ""
TELEGRAM_CHAT_ID = "-5545095713"

# Gemini AI
GEMINI_API_KEY = "APNI_GEMINI_KEY"
GEMINI_MODEL = "gemini-2.5-flash"     # error aaye to naya model naam daalo

CHECK_EVERY_SEC = 3          # kitne second mein ek baar cameras dekhna
ALERT_COOLDOWN_SEC = 60      # ek camera se 1 min mein ek hi naya alert
REPEAT_EVERY_SEC = 60        # siren wala alert kisi ne na dekha to har 1 min dobara
MAX_REPEATS = 5
HEARTBEAT_EVERY_SEC = 60     # app mein "system online" + battery dikhane ke liye
CONFIG_EVERY_SEC = 30        # app ki settings kitni der mein padhni
SNAPSHOT_CHECK_SEC = 10      # "Abhi ki photo" request kitni der mein check karni
LOW_BATTERY = 20             # isse kam (aur charger nahi) to family ko batao

# Sensitivity -> frame ka kitna hissa badle to movement maana jaye
SENSITIVITY = {"low": 0.05, "medium": 0.02, "high": 0.01}

# =====================================================================

AI_PROMPT = """Yeh ghar ke bahar lage CCTV camera ki photo hai. Ghar mein ek paltu billi bhi hai.
Batao kya is photo mein koi aisi situation hai jisme family ko TURANT pata chalna chahiye, jaise:
- koi kutta (ya kutte) ghar ke parisar mein dikh raha hai
- koi jaanwar kisi doosre jaanwar par hamla kar raha ho ya usse dauda raha ho
- koi anjaan insaan chupke se ghus raha ho, deewar/gate chadh raha ho, ya kuch le ja raha ho
- aag ya dhuaan

Normal cheezein (hawa se hilte ped, gaadi guzarna, roshni badalna, akeli billi aaram se ghoomna,
ghar ke log normal kaam karte hue) ke liye alert NAHI chahiye.

Sirf is JSON mein jawab do:
{"alert": true ya false,
 "category": "dog" | "person" | "animal" | "fire" | "other",
 "reason": "Hinglish mein ek chhoti line, jaise '2 kutte gate ke andar'"}"""

SCOPES = [
    "https://www.googleapis.com/auth/firebase.messaging",
    "https://www.googleapis.com/auth/datastore",
]
CATEGORIES = {"dog", "person", "animal", "fire", "other"}


def log(msg):
    print(f"[{datetime.now():%H:%M:%S}] {msg}", flush=True)


def now_rfc3339():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")


# ---------------------------------------------------------------- Firestore values

def fs_decode(v):
    """Firestore REST value -> Python."""
    if not isinstance(v, dict):
        return None
    if "stringValue" in v:
        return v["stringValue"]
    if "booleanValue" in v:
        return v["booleanValue"]
    if "integerValue" in v:
        return int(v["integerValue"])
    if "doubleValue" in v:
        return float(v["doubleValue"])
    if "timestampValue" in v:
        return v["timestampValue"]
    if "mapValue" in v:
        return {k: fs_decode(x) for k, x in v["mapValue"].get("fields", {}).items()}
    if "arrayValue" in v:
        return [fs_decode(x) for x in v["arrayValue"].get("values", [])]
    return None


def fs_encode(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: fs_encode(x) for k, x in v.items()}}}
    return {"stringValue": str(v)}


# ---------------------------------------------------------------- Firebase

class Firebase:
    def __init__(self, key_file):
        self.creds = service_account.Credentials.from_service_account_file(
            key_file, scopes=SCOPES)
        self.project = self.creds.project_id
        self.root = (f"https://firestore.googleapis.com/v1/projects/{self.project}"
                     f"/databases/(default)/documents")

    def _headers(self):
        if not self.creds.valid:
            self.creds.refresh(google.auth.transport.requests.Request())
        return {"Authorization": f"Bearer {self.creds.token}"}

    def get(self, path):
        """Document ke fields (dict) ya None agar nahi hai."""
        r = requests.get(f"{self.root}/{path}", headers=self._headers(), timeout=20)
        if r.status_code == 404:
            return None
        r.raise_for_status()
        return {k: fs_decode(v) for k, v in r.json().get("fields", {}).items()}

    def write(self, path, fields, merge_fields=None):
        """fields: {name: firestore_value}. merge_fields diye to sirf wahi badlenge."""
        url = f"{self.root}/{path}"
        if merge_fields:
            url += "?" + "&".join(f"updateMask.fieldPaths={f}" for f in merge_fields)
        r = requests.patch(url, headers=self._headers(), json={"fields": fields}, timeout=30)
        r.raise_for_status()

    def create_alert(self, alert_id, camera, reason, category, level, jpeg_small):
        self.write(f"alerts/{alert_id}", {
            "camera": {"stringValue": camera},
            "reason": {"stringValue": reason},
            "category": {"stringValue": category},
            "level": {"stringValue": level},
            "createdAt": {"timestampValue": now_rfc3339()},
            "image": {"bytesValue": base64.b64encode(jpeg_small).decode()},
            "ackBy": {"nullValue": None},
            "ackAt": {"nullValue": None},
        })

    def save_snapshot(self, camera, jpeg_small):
        doc_id = requests.utils.quote(camera, safe="")
        self.write(f"snapshots/{doc_id}", {
            "camera": {"stringValue": camera},
            "createdAt": {"timestampValue": now_rfc3339()},
            "image": {"bytesValue": base64.b64encode(jpeg_small).decode()},
        })

    def heartbeat(self, cameras_online, phone):
        fields = {
            "lastSeen": {"timestampValue": now_rfc3339()},
            "cameras": fs_encode(cameras_online),
            "phone": fs_encode(phone),
        }
        self.write("status/system", fields, merge_fields=["lastSeen", "cameras", "phone"])

    def alerts_since(self, since_utc):
        """Aaj ke alerts (sirf ackBy + category, photo nahi)."""
        body = {"structuredQuery": {
            "from": [{"collectionId": "alerts"}],
            "select": {"fields": [{"fieldPath": "ackBy"}, {"fieldPath": "category"},
                                  {"fieldPath": "level"}]},
            "where": {"fieldFilter": {
                "field": {"fieldPath": "createdAt"},
                "op": "GREATER_THAN_OR_EQUAL",
                "value": {"timestampValue": since_utc.strftime("%Y-%m-%dT%H:%M:%SZ")},
            }},
        }}
        r = requests.post(f"{self.root}:runQuery", headers=self._headers(), json=body, timeout=30)
        r.raise_for_status()
        out = []
        for row in r.json():
            doc = row.get("document")
            if doc:
                out.append({k: fs_decode(v) for k, v in doc.get("fields", {}).items()})
        return out

    def push(self, data):
        """App pe data message (sab values string honi chahiye)."""
        body = {"message": {
            "topic": FCM_TOPIC,
            "data": {k: str(v) for k, v in data.items()},
            "android": {"priority": "HIGH", "ttl": "300s"},
        }}
        r = requests.post(
            f"https://fcm.googleapis.com/v1/projects/{self.project}/messages:send",
            headers=self._headers(), json=body, timeout=20)
        r.raise_for_status()


# ---------------------------------------------------------------- App settings

class Config:
    """App se aane wali settings (Firestore config/main)."""

    def __init__(self):
        self.data = {}
        self.loaded_at = 0.0

    def refresh(self, fb):
        try:
            self.data = fb.get("config/main") or {}
            self.loaded_at = time.time()
        except Exception as e:
            log(f"Config padh nahi paaye (purani settings chalu): {e}")

    @property
    def mode(self):
        return self.data.get("mode") or "away"

    def night_active(self):
        night = self.data.get("night") or {}
        if night.get("enabled") is False:
            return False
        start = _mins(night.get("start") or "22:00")
        end = _mins(night.get("end") or "06:00")
        now = datetime.now()
        m = now.hour * 60 + now.minute
        return (start <= m < end) if start <= end else (m >= start or m < end)

    def level(self):
        """'alarm' = tez siren, 'quiet' = halka notification."""
        return "quiet" if (self.mode == "home" and not self.night_active()) else "alarm"

    def camera(self, name):
        cams = self.data.get("cameras") or {}
        c = cams.get(name) or {}
        enabled = c.get("enabled") is not False
        sens = SENSITIVITY.get(c.get("sensitivity") or "medium", SENSITIVITY["medium"])
        return enabled, sens

    def summary(self):
        s = self.data.get("summary") or {}
        return (s.get("enabled") is not False), (s.get("time") or "21:00")


def _mins(hhmm):
    try:
        h, m = hhmm.split(":")
        return int(h) * 60 + int(m)
    except Exception:
        return 0


# ---------------------------------------------------------------- Camera / AI

def rtsp_url(channel):
    return RTSP_TEMPLATE.format(user=NVR_USER, password=NVR_PASSWORD,
                                ip=NVR_IP, channel=channel)


def grab_frame(channel):
    cmd = ["ffmpeg", "-loglevel", "error", "-rtsp_transport", "tcp",
           "-i", rtsp_url(channel), "-frames:v", "1",
           "-f", "image2", "-vcodec", "mjpeg", "-q:v", "4", "pipe:1"]
    try:
        out = subprocess.run(cmd, capture_output=True, timeout=15)
        return out.stdout if out.returncode == 0 and out.stdout else None
    except subprocess.TimeoutExpired:
        return None


def small_gray(jpeg_bytes):
    return Image.open(io.BytesIO(jpeg_bytes)).convert("L").resize((160, 120))


def motion_amount(prev, curr):
    diff = ImageChops.difference(prev, curr).point(lambda p: 255 if p > 30 else 0)
    return diff.histogram()[255] / (diff.width * diff.height)


def shrink_jpeg(jpeg_bytes, width=640, quality=70):
    img = Image.open(io.BytesIO(jpeg_bytes)).convert("RGB")
    if img.width > width:
        img = img.resize((width, int(img.height * width / img.width)))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=quality)
    return buf.getvalue()


def ask_ai(jpeg_bytes):
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}")
    body = {
        "contents": [{"parts": [
            {"text": AI_PROMPT},
            {"inline_data": {"mime_type": "image/jpeg",
                             "data": base64.b64encode(jpeg_bytes).decode()}},
        ]}],
        "generationConfig": {"responseMimeType": "application/json"},
    }
    r = requests.post(url, json=body, timeout=30)
    r.raise_for_status()
    text = r.json()["candidates"][0]["content"]["parts"][0]["text"]
    result = json.loads(text)
    if result.get("category") not in CATEGORIES:
        result["category"] = "other"
    return result


# ---------------------------------------------------------------- Phone health

def _termux_json(cmd):
    """Termux:API command chalao. Na ho to None."""
    try:
        out = subprocess.run([cmd], capture_output=True, timeout=10, text=True)
        return json.loads(out.stdout) if out.returncode == 0 and out.stdout.strip() else None
    except Exception:
        return None


def phone_health():
    info = {}
    b = _termux_json("termux-battery-status")
    if b:
        info["battery"] = int(b.get("percentage", 0))
        info["charging"] = b.get("status") in ("CHARGING", "FULL") or b.get("plugged") not in (None, "UNPLUGGED")
    w = _termux_json("termux-wifi-connectioninfo")
    if w:
        ssid = (w.get("ssid") or "").strip('"')
        if ssid and "unknown" not in ssid.lower():
            info["wifi"] = ssid
        if isinstance(w.get("rssi"), int) and w["rssi"] != -127:
            info["signal"] = w["rssi"]
    return info


# ---------------------------------------------------------------- Telegram

def telegram_text(text):
    if not TELEGRAM_BOT_TOKEN:
        return
    try:
        requests.post(f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage",
                      data={"chat_id": TELEGRAM_CHAT_ID, "text": text}, timeout=30)
    except requests.RequestException:
        pass


def telegram_photo(jpeg_bytes, caption):
    if not TELEGRAM_BOT_TOKEN:
        return
    try:
        requests.post(f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendPhoto",
                      data={"chat_id": TELEGRAM_CHAT_ID, "caption": caption},
                      files={"photo": ("alert.jpg", jpeg_bytes, "image/jpeg")}, timeout=30)
    except requests.RequestException:
        pass


# ---------------------------------------------------------------- Actions

def send_alert(fb, camera, reason, category, level, frame):
    alert_id = datetime.now().strftime("%Y%m%d-%H%M%S-") + uuid.uuid4().hex[:6]
    try:
        fb.create_alert(alert_id, camera, reason, category, level, shrink_jpeg(frame))
        fb.push({"type": "alert", "alertId": alert_id, "camera": camera,
                 "reason": reason, "category": category, "level": level})
        log(f"App alert bheja ({level}, {category}): {alert_id}")
    except Exception as e:
        log(f"Firebase error (Telegram se bhej rahe hain): {e}")
        alert_id = None
    icon = "🚨" if level == "alarm" else "👁️"
    telegram_photo(frame, f"{icon} {camera}: {reason}\n🕒 {datetime.now():%d %b, %I:%M %p}")
    return alert_id


def handle_pending(fb, pending):
    """Siren wale alerts jinhe kisi ne nahi dekha: dobara bajao; dekh liya to sabko batao."""
    for alert_id in list(pending):
        p = pending[alert_id]
        try:
            who = (fb.get(f"alerts/{alert_id}") or {}).get("ackBy")
        except Exception as e:
            log(f"Ack check error: {e}")
            continue

        if who:
            try:
                fb.push({"type": "ack", "alertId": alert_id, "by": who})
            except Exception as e:
                log(f"Ack push error: {e}")
            telegram_text(f"👀 {who} dekh raha hai ({p['camera']})")
            log(f"{who} ne alert dekh liya")
            del pending[alert_id]
        elif time.time() - p["last_sent"] >= REPEAT_EVERY_SEC:
            if p["repeats"] >= MAX_REPEATS:
                log(f"{alert_id}: kisi ne nahi dekha, repeat band")
                del pending[alert_id]
                continue
            try:
                fb.push({"type": "alert", "alertId": alert_id, "camera": p["camera"],
                         "reason": p["reason"], "category": p["category"], "level": "alarm"})
                p["repeats"] += 1
                p["last_sent"] = time.time()
                log(f"{alert_id}: dobara bajaya ({p['repeats']}/{MAX_REPEATS})")
            except Exception as e:
                log(f"Repeat error: {e}")


def handle_snapshot_request(fb, state):
    """App se "Abhi ki photo" maangi gayi ho to sab cameras ki taaza photo bhejo."""
    try:
        req = fb.get("requests/snapshot")
    except Exception as e:
        log(f"Snapshot request check error: {e}")
        return
    if not req:
        return
    stamp = req.get("requestedAt")
    if not stamp or stamp == state.get("last_snapshot"):
        return
    if state.get("last_snapshot") is None:
        # pehli baar: purani request ko handled maan lo, sirf naye pe photo bhejo
        state["last_snapshot"] = stamp
        return
    state["last_snapshot"] = stamp
    log(f"{req.get('by', 'Koi')} ne abhi ki photo maangi")
    for name, channel in CAMERAS.items():
        frame = grab_frame(channel)
        if frame is None:
            log(f"{name}: snapshot nahi mila")
            continue
        try:
            fb.save_snapshot(name, shrink_jpeg(frame, width=960, quality=75))
        except Exception as e:
            log(f"Snapshot save error: {e}")


def send_summary(fb):
    start_local = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    since_utc = start_local.astimezone(timezone.utc)
    alerts = fb.alerts_since(since_utc)
    total = len(alerts)
    seen = sum(1 for a in alerts if a.get("ackBy"))
    if total == 0:
        title = "🌙 Aaj ka summary"
        body = "Aaj koi alert nahi aaya. Sab surakshit raha 🙂"
    else:
        kinds = {}
        names = {"dog": "kutta", "person": "insaan", "animal": "jaanwar", "fire": "aag", "other": "doosra"}
        for a in alerts:
            k = names.get(a.get("category") or "other", "doosra")
            kinds[k] = kinds.get(k, 0) + 1
        detail = ", ".join(f"{v} {k}" for k, v in sorted(kinds.items(), key=lambda x: -x[1]))
        title = f"🌙 Aaj {total} alert"
        body = f"{detail}. {seen} dekhe gaye" + ("" if seen == total else f", {total - seen} kisi ne nahi dekhe") + "."
    fb.push({"type": "summary", "title": title, "body": body})
    telegram_text(f"{title}\n{body}")
    log(f"Summary bheja: {title} - {body}")


# ---------------------------------------------------------------- Main loop

def main():
    fb = Firebase(FIREBASE_KEY_FILE)
    cfg = Config()
    cfg.refresh(fb)

    prev = {n: None for n in CAMERAS}
    last_alert = {n: 0.0 for n in CAMERAS}
    fail_count = {n: 0 for n in CAMERAS}
    online = {n: False for n in CAMERAS}
    pending = {}
    state = {"last_snapshot": None, "summary_day": None, "low_batt_warned": False}
    last_beat = last_snap_check = 0.0

    telegram_text("✅ Ghar Alert chalu ho gaya.")
    log(f"Shuru ho gaya (Firebase project: {fb.project}, mode: {cfg.mode})")

    while True:
        if time.time() - cfg.loaded_at >= CONFIG_EVERY_SEC:
            old_mode = cfg.mode
            cfg.refresh(fb)
            if cfg.mode != old_mode:
                log(f"Mode badla: {old_mode} -> {cfg.mode}")

        for name, channel in CAMERAS.items():
            enabled, threshold = cfg.camera(name)
            if not enabled:
                prev[name] = None
                continue

            frame = grab_frame(channel)
            if frame is None:
                fail_count[name] += 1
                if fail_count[name] == 20:
                    online[name] = False
                    telegram_text(f"⚠️ {name} se video nahi mil rahi. NVR/Wi-Fi check karo.")
                    log(f"{name} offline")
                continue

            if not online[name] and fail_count[name] >= 20:
                telegram_text(f"✅ {name} wapas chalu.")
            fail_count[name] = 0
            online[name] = True

            curr = small_gray(frame)
            if prev[name] is None:
                prev[name] = curr
                continue
            amount = motion_amount(prev[name], curr)
            prev[name] = curr

            if amount < threshold:
                continue
            if time.time() - last_alert[name] < ALERT_COOLDOWN_SEC:
                continue

            log(f"{name}: movement {amount:.0%}, AI check")
            try:
                result = ask_ai(frame)
            except Exception as e:
                log(f"AI error: {e}")
                continue

            if result.get("alert"):
                reason = result.get("reason") or "Kuch gadbad dikh rahi hai"
                category = result["category"]
                level = cfg.level()
                last_alert[name] = time.time()
                alert_id = send_alert(fb, name, reason, category, level, frame)
                if alert_id and level == "alarm":
                    pending[alert_id] = {"camera": name, "reason": reason, "category": category,
                                         "last_sent": time.time(), "repeats": 0}
            else:
                log(f"{name}: sab theek ({result.get('reason', '')})")

        if pending:
            handle_pending(fb, pending)

        if time.time() - last_snap_check >= SNAPSHOT_CHECK_SEC:
            last_snap_check = time.time()
            handle_snapshot_request(fb, state)

        if time.time() - last_beat >= HEARTBEAT_EVERY_SEC:
            health = phone_health()
            try:
                fb.heartbeat(online, health)
                last_beat = time.time()
            except Exception as e:
                log(f"Heartbeat error: {e}")
            batt, charging = health.get("battery"), health.get("charging")
            if batt is not None:
                if batt <= LOW_BATTERY and not charging and not state["low_batt_warned"]:
                    state["low_batt_warned"] = True
                    msg = f"Purane phone ki battery {batt}% hai aur charger nahi laga. Jaldi charge karo, warna nazar band ho jayegi."
                    try:
                        fb.push({"type": "info", "title": "🔋 Battery kam", "body": msg})
                    except Exception as e:
                        log(f"Battery push error: {e}")
                    telegram_text(f"🔋 {msg}")
                elif charging or batt > LOW_BATTERY + 10:
                    state["low_batt_warned"] = False

        enabled, at = cfg.summary()
        today = datetime.now().date()
        if enabled and state["summary_day"] != today:
            now_m = datetime.now().hour * 60 + datetime.now().minute
            if now_m >= _mins(at):
                if state["summary_day"] is None and now_m > _mins(at) + 5:
                    state["summary_day"] = today  # script der se chala: aaj ka skip
                else:
                    state["summary_day"] = today
                    try:
                        send_summary(fb)
                    except Exception as e:
                        log(f"Summary error: {e}")

        time.sleep(CHECK_EVERY_SEC)


def send_test_alert():
    """`python ghar_alert.py test` - bina camera ke app ka alarm test karo."""
    fb = Firebase(FIREBASE_KEY_FILE)
    img = Image.new("RGB", (640, 360), (30, 30, 60))
    buf = io.BytesIO()
    img.save(buf, "JPEG")
    alert_id = send_alert(fb, "Test camera", "Yeh sirf test hai, sab theek hai", "other", "alarm",
                          buf.getvalue())
    print("Test alert bheja:", alert_id)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        send_test_alert()
        sys.exit(0)
    while True:
        try:
            main()
        except KeyboardInterrupt:
            break
        except Exception as e:
            log(f"Error, 10 sec mein dobara shuru: {e}")
            time.sleep(10)
