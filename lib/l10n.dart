import 'app_state.dart';

/// Teen bhashayein: Hinglish (hx), English (en), हिंदी (hi).
const supportedLangs = ['hx', 'en', 'hi'];

String langName(String code) => switch (code) {
      'en' => 'English',
      'hi' => 'हिंदी',
      _ => 'Hinglish',
    };

bool get isHindi => AppState.lang.value == 'hi';

String tr(String key, [Map<String, String>? args]) {
  final entry = _s[key];
  var text = entry?[AppState.lang.value] ?? entry?['hx'] ?? key;
  args?.forEach((k, v) => text = text.replaceAll('{$k}', v));
  return text;
}

const Map<String, Map<String, String>> _s = {
  // ---- general
  'tagline': {'hx': 'AI se ghar ki hifazat', 'en': 'AI-powered home protection', 'hi': 'AI से घर की हिफ़ाज़त'},
  'today': {'hx': 'Aaj', 'en': 'Today', 'hi': 'आज'},
  'yesterday': {'hx': 'Kal', 'en': 'Yesterday', 'hi': 'कल'},
  'never': {'hx': 'kabhi nahi', 'en': 'never', 'hi': 'कभी नहीं'},
  'just_now': {'hx': 'abhi', 'en': 'just now', 'hi': 'अभी'},
  'mins_ago': {'hx': '{n} min pehle', 'en': '{n} min ago', 'hi': '{n} मिनट पहले'},
  'hours_ago': {'hx': '{n} ghante pehle', 'en': '{n} h ago', 'hi': '{n} घंटे पहले'},
  'days_ago': {'hx': '{n} din pehle', 'en': '{n} d ago', 'hi': '{n} दिन पहले'},
  'good_morning': {'hx': 'Good morning 🌤️', 'en': 'Good morning 🌤️', 'hi': 'सुप्रभात 🌤️'},
  'good_afternoon': {'hx': 'Namaste 👋', 'en': 'Good afternoon 👋', 'hi': 'नमस्ते 👋'},
  'good_evening': {'hx': 'Good evening 🌙', 'en': 'Good evening 🌙', 'hi': 'शुभ संध्या 🌙'},
  'save': {'hx': 'Save', 'en': 'Save', 'hi': 'सेव करें'},
  'cancel': {'hx': 'Cancel', 'en': 'Cancel', 'hi': 'रद्द करें'},
  'next': {'hx': 'Aage', 'en': 'Next', 'hi': 'आगे'},
  'get_started': {'hx': 'Shuru karein', 'en': 'Get started', 'hi': 'शुरू करें'},
  'allow': {'hx': 'Allow', 'en': 'Allow', 'hi': 'अनुमति दें'},
  'manage': {'hx': 'Badlo', 'en': 'Manage', 'hi': 'बदलें'},
  'see_all': {'hx': 'Sab dekho', 'en': 'See all', 'hi': 'सब देखें'},
  'you': {'hx': 'aap', 'en': 'you', 'hi': 'आप'},
  'save_failed': {'hx': 'Save nahi hua, internet check karo', 'en': 'Could not save. Check internet.', 'hi': 'सेव नहीं हुआ, इंटरनेट जाँचें'},

  // ---- tabs
  'tab_home': {'hx': 'Home', 'en': 'Home', 'hi': 'होम'},
  'tab_alerts': {'hx': 'Alerts', 'en': 'Alerts', 'hi': 'अलर्ट'},
  'tab_stats': {'hx': 'Stats', 'en': 'Stats', 'hi': 'आँकड़े'},
  'tab_family': {'hx': 'Family', 'en': 'Family', 'hi': 'परिवार'},
  'tab_settings': {'hx': 'Settings', 'en': 'Settings', 'hi': 'सेटिंग्स'},

  // ---- home
  'status_watching': {'hx': 'Nazar rakhi ja rahi hai', 'en': 'Watching your home', 'hi': 'निगरानी चालू है'},
  'status_offline': {'hx': 'System band hai', 'en': 'System offline', 'hi': 'सिस्टम बंद है'},
  'last_check': {'hx': 'Last check: {t}', 'en': 'Last check: {t}', 'hi': 'आख़िरी जाँच: {t}'},
  'offline_hint': {'hx': 'Purana phone, Wi-Fi ya bijli check karo (last: {t})', 'en': 'Check the watcher phone, Wi-Fi or power (last: {t})', 'hi': 'पुराना फ़ोन, Wi-Fi या बिजली जाँचें (आख़िरी: {t})'},
  'siren_on': {'hx': 'Siren chalu', 'en': 'Siren on', 'hi': 'सायरन चालू'},
  'siren_off': {'hx': 'Sirf notification', 'en': 'Notification only', 'hi': 'सिर्फ़ नोटिफ़िकेशन'},
  'mode': {'hx': 'Mode', 'en': 'Mode', 'hi': 'मोड'},
  'mode_home': {'hx': 'Ghar pe hain', 'en': 'At home', 'hi': 'घर पर हैं'},
  'mode_home_sub': {'hx': 'Halka notification', 'en': 'Gentle notification', 'hi': 'हल्का नोटिफ़िकेशन'},
  'mode_away': {'hx': 'Bahar hain', 'en': 'Away', 'hi': 'बाहर हैं'},
  'mode_away_sub': {'hx': 'Tez siren, silent mein bhi', 'en': 'Loud siren, even on silent', 'hi': 'तेज़ सायरन, साइलेंट में भी'},
  'night_active': {'hx': 'Raat mode chalu: {e} tak siren bajega', 'en': 'Night mode on: siren until {e}', 'hi': 'रात मोड चालू: {e} तक सायरन बजेगा'},
  'night_scheduled': {'hx': 'Raat mode: {s} se {e} tak hamesha siren', 'en': 'Night mode: siren {s} to {e}', 'hi': 'रात मोड: {s} से {e} तक हमेशा सायरन'},
  'quick_actions': {'hx': 'Jaldi karo', 'en': 'Quick actions', 'hi': 'तुरंत करें'},
  'snapshot_now': {'hx': 'Abhi ki photo', 'en': 'Photo now', 'hi': 'अभी की फ़ोटो'},
  'live_view': {'hx': 'Live dekho', 'en': 'Live view', 'hi': 'लाइव देखें'},
  'live': {'hx': 'Live', 'en': 'Live', 'hi': 'लाइव'},
  'emergency': {'hx': 'Emergency', 'en': 'Emergency', 'hi': 'आपातकाल'},
  'cameras': {'hx': 'Cameras', 'en': 'Cameras', 'hi': 'कैमरे'},
  'paused': {'hx': 'Band', 'en': 'Paused', 'hi': 'बंद'},
  'no_cameras_yet': {'hx': 'Purana phone chalu hone pe cameras yahan dikhenge', 'en': 'Cameras appear once the watcher phone is running', 'hi': 'पुराना फ़ोन चालू होने पर कैमरे यहाँ दिखेंगे'},
  'no_cameras_sub': {'hx': 'Purane phone pe ghar_alert.py chalao', 'en': 'Run ghar_alert.py on the watcher phone', 'hi': 'पुराने फ़ोन पर ghar_alert.py चलाएँ'},
  'watcher_phone': {'hx': 'Purana phone', 'en': 'Watcher phone', 'hi': 'पुराना फ़ोन'},
  'health_missing': {'hx': 'Battery aur Wi-Fi dekhne ke liye purane phone pe Termux:API lagao', 'en': 'Install Termux:API on the watcher phone to see battery and Wi-Fi', 'hi': 'बैटरी और Wi-Fi देखने के लिए पुराने फ़ोन पर Termux:API लगाएँ'},
  'charging': {'hx': 'Charge ho raha', 'en': 'Charging', 'hi': 'चार्ज हो रहा'},
  'on_battery': {'hx': 'Battery pe', 'en': 'On battery', 'hi': 'बैटरी पर'},
  'signal_good': {'hx': 'Signal achha', 'en': 'Strong signal', 'hi': 'सिग्नल अच्छा'},
  'signal_ok': {'hx': 'Signal theek', 'en': 'Fair signal', 'hi': 'सिग्नल ठीक'},
  'signal_weak': {'hx': 'Signal kamzor', 'en': 'Weak signal', 'hi': 'सिग्नल कमज़ोर'},
  'signal_unknown': {'hx': 'Connected', 'en': 'Connected', 'hi': 'कनेक्टेड'},
  'latest_alert': {'hx': 'Aakhri alert', 'en': 'Latest alert', 'hi': 'आख़िरी अलर्ट'},
  'no_alerts_yet': {'hx': 'Sab surakshit hai, koi alert nahi 🙂', 'en': 'All safe. No alerts yet 🙂', 'hi': 'सब सुरक्षित है, कोई अलर्ट नहीं 🙂'},
  'setup_incomplete': {'hx': 'Setup adhoora hai', 'en': 'Setup incomplete', 'hi': 'सेटअप अधूरा है'},
  'setup_progress': {'hx': '{n}/{t} permissions di gayi. Silent pe siren ke liye poora karo', 'en': '{n}/{t} permissions granted. Finish for silent-mode siren', 'hi': '{n}/{t} अनुमतियाँ मिलीं। साइलेंट पर सायरन के लिए पूरा करें'},
  'seeeasy_missing': {'hx': 'SeeEasy app nahi mila', 'en': 'SeeEasy app not found', 'hi': 'SeeEasy ऐप नहीं मिला'},

  // ---- alerts
  'filter_all': {'hx': 'Sab', 'en': 'All', 'hi': 'सब'},
  'filter_unseen': {'hx': 'Nahi dekhe', 'en': 'Unseen', 'hi': 'नहीं देखे'},
  'n_unseen': {'hx': '{n} nahi dekhe', 'en': '{n} unseen', 'hi': '{n} नहीं देखे'},
  'no_match': {'hx': 'Is filter mein kuch nahi', 'en': 'Nothing matches this filter', 'hi': 'इस फ़िल्टर में कुछ नहीं'},
  'seen_by': {'hx': '{name} ne dekha', 'en': 'Seen by {name}', 'hi': '{name} ने देखा'},
  'not_seen': {'hx': 'Kisi ne nahi dekha', 'en': 'Not seen yet', 'hi': 'किसी ने नहीं देखा'},
  'cat_dog': {'hx': 'Kutta', 'en': 'Dog', 'hi': 'कुत्ता'},
  'cat_person': {'hx': 'Insaan', 'en': 'Person', 'hi': 'इंसान'},
  'cat_animal': {'hx': 'Jaanwar', 'en': 'Animal', 'hi': 'जानवर'},
  'cat_fire': {'hx': 'Aag / dhuaan', 'en': 'Fire / smoke', 'hi': 'आग / धुआँ'},
  'cat_other': {'hx': 'Doosra', 'en': 'Other', 'hi': 'अन्य'},

  // ---- alert screen
  'alert_default_reason': {'hx': 'Kuch gadbad dikh rahi hai', 'en': 'Something looks wrong', 'hi': 'कुछ गड़बड़ दिख रही है'},
  'swipe_ack': {'hx': 'Swipe karo: Main dekh raha hoon', 'en': "Swipe: I'm on it", 'hi': 'स्वाइप करें: मैं देख रहा हूँ'},
  'btn_ack': {'hx': 'Main dekh raha hoon', 'en': "I'm on it", 'hi': 'मैं देख रहा हूँ'},
  'is_watching': {'hx': '{name} dekh raha hai', 'en': '{name} is on it', 'hi': '{name} देख रहा है'},
  'responded_in': {'hx': '{t} mein jawab diya', 'en': 'Responded in {t}', 'hi': '{t} में जवाब दिया'},
  'silence': {'hx': 'Chup karo', 'en': 'Silence', 'hi': 'चुप करें'},
  'silenced': {'hx': 'Is phone ka alarm chup', 'en': 'Alarm silenced on this phone', 'hi': 'इस फ़ोन का अलार्म चुप'},
  'alert_missing': {'hx': 'Yeh alert ab maujood nahi hai', 'en': 'This alert no longer exists', 'hi': 'यह अलर्ट अब मौजूद नहीं है'},
  'emergency_sub': {'hx': 'Tap karte hi dialer khulega', 'en': 'Tap to open the dialer', 'hi': 'टैप करते ही डायलर खुलेगा'},
  'police_112': {'hx': 'Police / Emergency 112', 'en': 'Police / Emergency 112', 'hi': 'पुलिस / आपातकाल 112'},
  'add_contacts': {'hx': 'Family / padosi ka number jodo', 'en': 'Add family / neighbour numbers', 'hi': 'परिवार / पड़ोसी का नंबर जोड़ें'},
  'edit_contacts': {'hx': 'Contacts badlo', 'en': 'Edit contacts', 'hi': 'संपर्क बदलें'},

  // ---- notifications
  'channel_alarm': {'hx': 'Ghar ka alarm', 'en': 'Home alarm', 'hi': 'घर का अलार्म'},
  'channel_alarm_desc': {'hx': 'Khatra dikhne par tez siren', 'en': 'Loud siren when danger is detected', 'hi': 'ख़तरा दिखने पर तेज़ सायरन'},
  'channel_info': {'hx': 'Ghar alert updates', 'en': 'Home alert updates', 'hi': 'घर अलर्ट अपडेट'},
  'channel_info_desc': {'hx': 'Kisne dekha, roz ka summary, system ki khabar', 'en': 'Who responded, daily summary, system news', 'hi': 'किसने देखा, रोज़ का सारांश, सिस्टम की ख़बर'},
  'notif_ack_title': {'hx': '👀 {name} dekh raha hai', 'en': '👀 {name} is on it', 'hi': '👀 {name} देख रहा है'},
  'notif_ack_body': {'hx': 'Alarm band kar diya gaya hai.', 'en': 'The alarm has been stopped.', 'hi': 'अलार्म बंद कर दिया गया है।'},
  'test_alarm_title': {'hx': 'Test alarm', 'en': 'Test alarm', 'hi': 'टेस्ट अलार्म'},
  'test_alarm_body': {'hx': 'Sab theek hai. Band karne ke liye "Main dekh raha hoon" dabao.', 'en': 'All good. Tap "I\'m on it" to stop.', 'hi': 'सब ठीक है। बंद करने के लिए "मैं देख रहा हूँ" दबाएँ।'},

  // ---- stats
  'last_7_days': {'hx': 'Pichhle 7 din', 'en': 'Last 7 days', 'hi': 'पिछले 7 दिन'},
  'total_alerts': {'hx': 'Kul alerts', 'en': 'Total alerts', 'hi': 'कुल अलर्ट'},
  'seen_rate': {'hx': 'Dekhe gaye', 'en': 'Seen', 'hi': 'देखे गए'},
  'avg_response': {'hx': 'Avg jawab', 'en': 'Avg response', 'hi': 'औसत जवाब'},
  'alerts_per_day': {'hx': 'Roz ke alerts', 'en': 'Alerts per day', 'hi': 'रोज़ के अलर्ट'},
  'by_type': {'hx': 'Kis cheez ke alerts', 'en': 'By type', 'hi': 'किस चीज़ के अलर्ट'},
  'by_camera': {'hx': 'Camera ke hisaab se', 'en': 'By camera', 'hi': 'कैमरे के हिसाब से'},
  'n_alerts': {'hx': '{n} alerts', 'en': '{n} alerts', 'hi': '{n} अलर्ट'},
  'no_data_yet': {'hx': 'Abhi data nahi hai', 'en': 'No data yet', 'hi': 'अभी डेटा नहीं है'},

  // ---- family
  'family_sub': {'hx': '{n} log app pe hain', 'en': '{n} people on the app', 'hi': '{n} लोग ऐप पर हैं'},
  'members': {'hx': 'Sadasya', 'en': 'Members', 'hi': 'सदस्य'},
  'no_members': {'hx': 'Abhi koi nahi juda', 'en': 'Nobody has joined yet', 'hi': 'अभी कोई नहीं जुड़ा'},
  'active_now': {'hx': 'Abhi active', 'en': 'Active now', 'hi': 'अभी सक्रिय'},
  'last_active': {'hx': 'Last active: {t}', 'en': 'Last active: {t}', 'hi': 'आख़िरी बार: {t}'},
  'last_ack': {'hx': 'Aakhri alert dekha: {t}', 'en': 'Last responded: {t}', 'hi': 'आख़िरी अलर्ट देखा: {t}'},
  'alerts_seen': {'hx': 'dekhe', 'en': 'seen', 'hi': 'देखे'},
  'invite': {'hx': 'Family jodo', 'en': 'Invite family', 'hi': 'परिवार जोड़ें'},
  'invite_text': {'hx': 'GharAlert.apk family ko WhatsApp pe bhejo. Install karke naam daalte hi woh yahan dikhenge aur alerts paayenge.', 'en': 'Send GharAlert.apk to family on WhatsApp. Once they install it and enter a name, they appear here and get alerts.', 'hi': 'GharAlert.apk परिवार को WhatsApp पर भेजें। इंस्टॉल करके नाम डालते ही वे यहाँ दिखेंगे और अलर्ट पाएँगे।'},

  // ---- settings
  'profile': {'hx': 'Profile', 'en': 'Profile', 'hi': 'प्रोफ़ाइल'},
  'your_name': {'hx': 'Aapka naam', 'en': 'Your name', 'hi': 'आपका नाम'},
  'name_hint': {'hx': 'Jaise: Javed, Ammi, Bhai', 'en': 'e.g. Javed, Mom, Brother', 'hi': 'जैसे: जावेद, अम्मी, भाई'},
  'language': {'hx': 'Bhasha', 'en': 'Language', 'hi': 'भाषा'},
  'security': {'hx': 'Suraksha', 'en': 'Security', 'hi': 'सुरक्षा'},
  'app_lock': {'hx': 'App lock', 'en': 'App lock', 'hi': 'ऐप लॉक'},
  'app_lock_sub': {'hx': 'Fingerprint ya PIN se kholo. Alarm screen bina lock khulegi', 'en': 'Open with fingerprint or PIN. Alarm screen skips the lock', 'hi': 'फ़िंगरप्रिंट या PIN से खोलें। अलार्म स्क्रीन बिना लॉक खुलेगी'},
  'lock_unsupported': {'hx': 'Is phone pe screen lock set nahi hai', 'en': 'No screen lock set on this phone', 'hi': 'इस फ़ोन पर स्क्रीन लॉक सेट नहीं है'},
  'lock_reason': {'hx': 'Ghar Alert kholne ke liye', 'en': 'Unlock Ghar Alert', 'hi': 'Ghar Alert खोलने के लिए'},
  'locked_title': {'hx': 'App locked hai', 'en': 'App is locked', 'hi': 'ऐप लॉक है'},
  'locked_sub': {'hx': 'Fingerprint ya PIN se kholo', 'en': 'Use fingerprint or PIN to open', 'hi': 'फ़िंगरप्रिंट या PIN से खोलें'},
  'unlock': {'hx': 'Kholo', 'en': 'Unlock', 'hi': 'खोलें'},
  'alarm_rules': {'hx': 'Alarm ke niyam', 'en': 'Alarm rules', 'hi': 'अलार्म के नियम'},
  'night_mode': {'hx': 'Raat ka auto mode', 'en': 'Night auto mode', 'hi': 'रात का ऑटो मोड'},
  'night_mode_sub': {'hx': 'Raat mein hamesha siren, chahe "Ghar pe" mode ho', 'en': 'Always siren at night, even in At-home mode', 'hi': 'रात में हमेशा सायरन, चाहे "घर पर" मोड हो'},
  'night_hours': {'hx': 'Raat ka samay', 'en': 'Night hours', 'hi': 'रात का समय'},
  'daily_summary': {'hx': 'Roz ka summary', 'en': 'Daily summary', 'hi': 'रोज़ का सारांश'},
  'daily_summary_sub': {'hx': 'Raat ko ek notification: aaj kya hua', 'en': 'One evening notification: what happened today', 'hi': 'रात को एक नोटिफ़िकेशन: आज क्या हुआ'},
  'daily_summary_at': {'hx': 'Roz {t} baje (time badalne ke liye tap)', 'en': 'Every day at {t} (tap to change)', 'hi': 'रोज़ {t} बजे (समय बदलने के लिए टैप)'},
  'system': {'hx': 'System', 'en': 'System', 'hi': 'सिस्टम'},
  'cameras_sub': {'hx': 'On/off aur sensitivity', 'en': 'On/off and sensitivity', 'hi': 'चालू/बंद और संवेदनशीलता'},
  'emergency_contacts': {'hx': 'Emergency contacts', 'en': 'Emergency contacts', 'hi': 'आपातकालीन संपर्क'},
  'n_contacts': {'hx': '{n} contacts + 112', 'en': '{n} contacts + 112', 'hi': '{n} संपर्क + 112'},
  'permissions': {'hx': 'Permissions', 'en': 'Permissions', 'hi': 'अनुमतियाँ'},
  'permissions_sub': {'hx': 'Silent pe siren ke liye zaroori', 'en': 'Needed for the silent-mode siren', 'hi': 'साइलेंट पर सायरन के लिए ज़रूरी'},
  'test_alarm': {'hx': 'Alarm test karo', 'en': 'Test alarm', 'hi': 'अलार्म टेस्ट करें'},
  'test_alarm_sub': {'hx': 'Is phone pe siren bajao', 'en': 'Play the siren on this phone', 'hi': 'इस फ़ोन पर सायरन बजाएँ'},
  'test_alarm_hint': {'hx': 'Phone silent karke bhi test karo', 'en': 'Try it with the phone on silent too', 'hi': 'फ़ोन साइलेंट करके भी टेस्ट करें'},

  // ---- cameras screen
  'cameras_explain': {'hx': 'Kisi camera ko band karo to uske alerts nahi aayenge. Sensitivity zyada = chhoti movement pe bhi check.', 'en': 'Paused cameras send no alerts. Higher sensitivity reacts to smaller movement.', 'hi': 'किसी कैमरे को बंद करें तो उसके अलर्ट नहीं आएँगे। संवेदनशीलता ज़्यादा = छोटी हलचल पर भी जाँच।'},
  'cam_live': {'hx': 'Video aa raha hai', 'en': 'Video OK', 'hi': 'वीडियो आ रहा है'},
  'cam_no_video': {'hx': 'Video nahi mil raha', 'en': 'No video', 'hi': 'वीडियो नहीं मिल रहा'},
  'sensitivity': {'hx': 'Sensitivity', 'en': 'Sensitivity', 'hi': 'संवेदनशीलता'},
  'sens_low': {'hx': 'Kam', 'en': 'Low', 'hi': 'कम'},
  'sens_medium': {'hx': 'Normal', 'en': 'Medium', 'hi': 'सामान्य'},
  'sens_high': {'hx': 'Zyada', 'en': 'High', 'hi': 'ज़्यादा'},
  'sens_low_hint': {'hx': 'Sirf badi movement. Ped/hawa wali jagah ke liye', 'en': 'Only big movement. Good for windy spots', 'hi': 'सिर्फ़ बड़ी हलचल। पेड़/हवा वाली जगह के लिए'},
  'sens_medium_hint': {'hx': 'Zyada tar jagah ke liye sahi', 'en': 'Right for most places', 'hi': 'ज़्यादातर जगह के लिए सही'},
  'sens_high_hint': {'hx': 'Chhoti movement bhi check hogi (zyada AI check)', 'en': 'Even small movement is checked (more AI checks)', 'hi': 'छोटी हलचल भी जाँची जाएगी (ज़्यादा AI जाँच)'},

  // ---- contacts
  'add_contact': {'hx': 'Contact jodo', 'en': 'Add contact', 'hi': 'संपर्क जोड़ें'},
  'contact_name_hint': {'hx': 'Naam (jaise: Padosi Rahul)', 'en': 'Name (e.g. Neighbour Rahul)', 'hi': 'नाम (जैसे: पड़ोसी राहुल)'},
  'contact_phone_hint': {'hx': 'Phone number', 'en': 'Phone number', 'hi': 'फ़ोन नंबर'},
  'contacts_explain': {'hx': 'Yeh numbers alert screen ke Emergency button mein dikhenge. Sab family ke liye same.', 'en': 'These show under Emergency on the alert screen, for the whole family.', 'hi': 'ये नंबर अलर्ट स्क्रीन के आपातकाल बटन में दिखेंगे। पूरे परिवार के लिए एक जैसे।'},
  'always_shown': {'hx': 'Hamesha dikhega', 'en': 'Always shown', 'hi': 'हमेशा दिखेगा'},
  'no_contacts': {'hx': 'Abhi koi contact nahi', 'en': 'No contacts yet', 'hi': 'अभी कोई संपर्क नहीं'},

  // ---- snapshot
  'snapshot_waiting': {'hx': 'Purane phone se taaza photo aa rahi hai…', 'en': 'Fetching fresh photos from the watcher phone…', 'hi': 'पुराने फ़ोन से ताज़ा फ़ोटो आ रही है…'},
  'snapshot_timeout': {'hx': 'Photo nahi aayi. Purana phone chalu hai?', 'en': 'No photo yet. Is the watcher phone running?', 'hi': 'फ़ोटो नहीं आई। पुराना फ़ोन चालू है?'},
  'snapshot_ready': {'hx': 'Taaza photo aa gayi', 'en': 'Fresh photos ready', 'hi': 'ताज़ा फ़ोटो आ गई'},
  'old_photo': {'hx': 'Purani', 'en': 'Old', 'hi': 'पुरानी'},

  // ---- permissions
  'perm_explain': {'hx': 'Yeh sab ✅ hone pe hi silent phone pe bhi siren bajega aur band app bhi jaagega.', 'en': 'With all of these ✅ the siren plays even on silent, and the app wakes even when closed.', 'hi': 'ये सब ✅ होने पर ही साइलेंट फ़ोन पर भी सायरन बजेगा और बंद ऐप भी जागेगा।'},
  'perm_notif': {'hx': 'Notifications', 'en': 'Notifications', 'hi': 'नोटिफ़िकेशन'},
  'perm_notif_sub': {'hx': 'Alert dikhane ke liye', 'en': 'To show alerts', 'hi': 'अलर्ट दिखाने के लिए'},
  'perm_full': {'hx': 'Full-screen alert', 'en': 'Full-screen alert', 'hi': 'फ़ुल-स्क्रीन अलर्ट'},
  'perm_full_sub': {'hx': 'Lock screen pe call jaisi screen', 'en': 'Call-style screen on the lock screen', 'hi': 'लॉक स्क्रीन पर कॉल जैसी स्क्रीन'},
  'perm_dnd': {'hx': 'Do Not Disturb mein bhi', 'en': 'Bypass Do Not Disturb', 'hi': 'डू नॉट डिस्टर्ब में भी'},
  'perm_dnd_sub': {'hx': 'List mein Ghar Alert ko allow karo', 'en': 'Allow Ghar Alert in the list', 'hi': 'सूची में Ghar Alert को अनुमति दें'},
  'perm_battery': {'hx': 'Battery restriction hatao', 'en': 'Remove battery restriction', 'hi': 'बैटरी पाबंदी हटाएँ'},
  'perm_battery_sub': {'hx': 'Warna phone app ko sula deta hai', 'en': 'Otherwise the phone puts the app to sleep', 'hi': 'वरना फ़ोन ऐप को सुला देता है'},
  'perm_autostart': {'hx': 'Auto-start (Realme/Oppo/Vivo/Mi)', 'en': 'Auto-start (Realme/Oppo/Vivo/Mi)', 'hi': 'ऑटो-स्टार्ट (Realme/Oppo/Vivo/Mi)'},
  'perm_autostart_sub': {'hx': 'App info → Battery/Auto launch mein Allow karo', 'en': 'App info → Battery/Auto launch → Allow', 'hi': 'App info → Battery/Auto launch में Allow करें'},

  // ---- onboarding
  'ob1_title': {'hx': 'Ghar ki hifazat, AI ke saath', 'en': 'Your home, guarded by AI', 'hi': 'घर की हिफ़ाज़त, AI के साथ'},
  'ob1_body': {'hx': 'Bahar ke cameras pe 24 ghante nazar. Kutta, anjaan insaan ya aag dikhte hi AI pehchaan leta hai.', 'en': 'Your outdoor cameras, watched 24/7. AI spots dogs, strangers or fire the moment they appear.', 'hi': 'बाहर के कैमरों पर 24 घंटे नज़र। कुत्ता, अनजान इंसान या आग दिखते ही AI पहचान लेता है।'},
  'ob2_title': {'hx': 'Silent phone pe bhi siren', 'en': 'A siren, even on silent', 'hi': 'साइलेंट फ़ोन पर भी सायरन'},
  'ob2_body': {'hx': 'Khatra dikhte hi photo ke saath tez alarm. Jab tak koi na dekhe, bajta rahega.', 'en': 'A loud alarm with a photo the moment danger appears. It keeps ringing until someone responds.', 'hi': 'ख़तरा दिखते ही फ़ोटो के साथ तेज़ अलार्म। जब तक कोई न देखे, बजता रहेगा।'},
  'ob3_title': {'hx': 'Poori family saath', 'en': 'The whole family, together', 'hi': 'पूरा परिवार साथ'},
  'ob3_body': {'hx': 'Sabke phone pe alert. Koi "Main dekh raha hoon" dabaye to baaki sabka alarm band.', 'en': 'Everyone gets the alert. When one person taps "I\'m on it", everyone else\'s alarm stops.', 'hi': 'सबके फ़ोन पर अलर्ट। कोई "मैं देख रहा हूँ" दबाए तो बाकी सबका अलार्म बंद।'},
  'ob_name_title': {'hx': 'Aapka naam?', 'en': "What's your name?", 'hi': 'आपका नाम?'},
  'ob_name_body': {'hx': 'Alert dekhne pe family ko yahi naam dikhega.', 'en': 'Your family sees this name when you respond to an alert.', 'hi': 'अलर्ट देखने पर परिवार को यही नाम दिखेगा।'},
  'ob_perm_title': {'hx': 'Bas 4 permissions', 'en': 'Just 4 permissions', 'hi': 'बस 4 अनुमतियाँ'},
  'ob_perm_body': {'hx': 'Ek-ek karke allow karo. Baad mein Settings se bhi kar sakte ho.', 'en': 'Allow them one by one. You can also do this later in Settings.', 'hi': 'एक-एक करके अनुमति दें। बाद में सेटिंग्स से भी कर सकते हैं।'},
};
