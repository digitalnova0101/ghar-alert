package com.mau.siren;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;

/** Siren ko alarm stream pe loop mein bajata hai. Ek hi player poore app mein. */
final class SirenPlayer {
    private static final long MAX_MS = 10 * 60 * 1000L; // 10 min baad apne aap band
    private static MediaPlayer player;
    private static PowerManager.WakeLock wakeLock;
    private static int originalVolume = -1;
    private static Runnable onStopped;
    private static final Handler handler = new Handler(Looper.getMainLooper());
    private static final Runnable autoStop = SirenPlayer::stop;

    private SirenPlayer() {}

    static synchronized boolean isPlaying() {
        return player != null;
    }

    static synchronized void play(Context context, Runnable whenStopped) {
        Context app = context.getApplicationContext();
        onStopped = whenStopped;
        if (player != null) {
            handler.removeCallbacks(autoStop);
            handler.postDelayed(autoStop, MAX_MS);
            return;
        }

        AudioManager am = (AudioManager) app.getSystemService(Context.AUDIO_SERVICE);
        try {
            originalVolume = am.getStreamVolume(AudioManager.STREAM_ALARM);
            am.setStreamVolume(AudioManager.STREAM_ALARM,
                    am.getStreamMaxVolume(AudioManager.STREAM_ALARM), 0);
        } catch (Exception ignored) {
            originalVolume = -1;
        }

        try {
            MediaPlayer mp = new MediaPlayer();
            mp.setAudioAttributes(new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build());
            android.content.res.AssetFileDescriptor afd =
                    app.getResources().openRawResourceFd(R.raw.siren_alarm);
            mp.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            afd.close();
            mp.setLooping(true);
            mp.prepare();
            mp.start();
            player = mp;
        } catch (Exception e) {
            restoreVolume(app);
            return;
        }

        try {
            PowerManager pm = (PowerManager) app.getSystemService(Context.POWER_SERVICE);
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "gharalert:siren");
            wakeLock.acquire(MAX_MS + 5000);
        } catch (Exception ignored) {}

        handler.postDelayed(autoStop, MAX_MS);
        appContext = app;
    }

    private static Context appContext;

    static synchronized void stop() {
        handler.removeCallbacks(autoStop);
        if (player != null) {
            try {
                player.stop();
            } catch (Exception ignored) {}
            player.release();
            player = null;
        }
        if (wakeLock != null && wakeLock.isHeld()) {
            try {
                wakeLock.release();
            } catch (Exception ignored) {}
        }
        wakeLock = null;
        if (appContext != null) restoreVolume(appContext);
        Runnable cb = onStopped;
        onStopped = null;
        if (cb != null) cb.run();
    }

    private static void restoreVolume(Context app) {
        if (originalVolume < 0) return;
        try {
            AudioManager am = (AudioManager) app.getSystemService(Context.AUDIO_SERVICE);
            am.setStreamVolume(AudioManager.STREAM_ALARM, originalVolume, 0);
        } catch (Exception ignored) {}
        originalVolume = -1;
    }
}
