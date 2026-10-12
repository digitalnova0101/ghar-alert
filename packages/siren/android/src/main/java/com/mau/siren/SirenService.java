package com.mau.siren;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;

/** Foreground service: app band ho tab bhi siren bajta rahe. */
public class SirenService extends Service {
    static final String ACTION_STOP = "com.mau.siren.STOP";
    private static final String CHANNEL = "ghar_siren_fg";
    private static final int NOTIF_ID = 1101;

    static void start(Context context, String title, String body) {
        Intent i = new Intent(context, SirenService.class);
        i.putExtra("title", title);
        i.putExtra("body", body);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(i);
        } else {
            context.startService(i);
        }
    }

    static void stop(Context context) {
        SirenPlayer.stop();
        context.stopService(new Intent(context, SirenService.class));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            SirenPlayer.stop();
            stopSelf();
            return START_NOT_STICKY;
        }
        String title = intent != null ? intent.getStringExtra("title") : null;
        String body = intent != null ? intent.getStringExtra("body") : null;
        Notification n = buildNotification(title, body);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIF_ID, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK);
        } else {
            startForeground(NOTIF_ID, n);
        }
        SirenPlayer.play(this, this::stopSelf);
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        SirenPlayer.stop();
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private Notification buildNotification(String title, String body) {
        NotificationManager nm = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && nm.getNotificationChannel(CHANNEL) == null) {
            NotificationChannel ch = new NotificationChannel(CHANNEL, "Siren", NotificationManager.IMPORTANCE_LOW);
            ch.setSound(null, null);
            ch.enableVibration(false);
            nm.createNotificationChannel(ch);
        }

        int flags = PendingIntent.FLAG_UPDATE_CURRENT
                | (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ? PendingIntent.FLAG_IMMUTABLE : 0);
        Intent stop = new Intent(this, SirenService.class).setAction(ACTION_STOP);
        PendingIntent stopPi = PendingIntent.getService(this, 1, stop, flags);
        Intent launch = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent openPi = launch == null ? null : PendingIntent.getActivity(this, 2, launch, flags);

        int icon = getResources().getIdentifier("ic_stat_shield", "drawable", getPackageName());
        if (icon == 0) icon = android.R.drawable.ic_lock_idle_alarm;

        Notification.Builder b = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(this, CHANNEL)
                : new Notification.Builder(this);
        b.setSmallIcon(icon)
                .setContentTitle(title == null || title.isEmpty() ? "🚨 Siren" : title)
                .setContentText(body == null ? "" : body)
                .setOngoing(true)
                .addAction(new Notification.Action.Builder(null, "🔇 Siren band karo", stopPi).build());
        if (openPi != null) b.setContentIntent(openPi);
        return b.build();
    }
}
