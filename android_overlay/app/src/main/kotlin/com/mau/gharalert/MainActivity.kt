package com.mau.gharalert

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        // v2: channel khud awaaz nahi bajata, siren plugin alarm volume pe bajata hai
        const val CHANNEL_NORMAL = "ghar_alarm_v2"
        const val CHANNEL_DND = "ghar_alarm_dnd_v2"
        val OLD_CHANNELS = listOf("ghar_alarm_v1", "ghar_alarm_dnd_v1")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Lock screen ke upar khulo aur screen on karo (alarm ke liye)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ghar_alert/native")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "setupAlarmChannel" -> result.success(setupAlarmChannel())
                        "hasDndAccess" -> result.success(nm().isNotificationPolicyAccessGranted)
                        "openDndSettings" -> {
                            open(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                            result.success(null)
                        }
                        "isIgnoringBattery" -> {
                            val pm = getSystemService(PowerManager::class.java)
                            result.success(pm.isIgnoringBatteryOptimizations(packageName))
                        }
                        "requestIgnoreBattery" -> {
                            val ok = open(Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            ))
                            if (!ok) open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                            result.success(null)
                        }
                        "canFullScreen" -> result.success(
                            if (Build.VERSION.SDK_INT >= 34) nm().canUseFullScreenIntent() else true
                        )
                        "openFullScreenSettings" -> {
                            if (Build.VERSION.SDK_INT >= 34) {
                                open(Intent(
                                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                    Uri.parse("package:$packageName")
                                ))
                            } else {
                                openAppSettings()
                            }
                            result.success(null)
                        }
                        "openAppSettings" -> {
                            openAppSettings()
                            result.success(null)
                        }
                        "openSeeEasy" -> result.success(openSeeEasy())
                        "dial" -> {
                            val number = call.argument<String>("number") ?: ""
                            open(Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + Uri.encode(number))))
                            result.success(null)
                        }
                        "appVersion" -> result.success(
                            packageManager.getPackageInfo(packageName, 0).versionName ?: ""
                        )
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", e.message, null)
                }
            }
    }

    private fun nm(): NotificationManager = getSystemService(NotificationManager::class.java)

    /**
     * Siren wala alarm channel banata hai: alarm volume pe bajta hai (silent mode
     * mein bhi), aur DND permission ho to Do Not Disturb bhi bypass karta hai.
     * Android channel ki awaaz/DND setting baad mein nahi badalne deta, isliye
     * DND ke liye alag channel id hai.
     */
    private fun setupAlarmChannel(): String {
        val dnd = nm().isNotificationPolicyAccessGranted
        val id = if (dnd) CHANNEL_DND else CHANNEL_NORMAL
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return id
        if (nm().getNotificationChannel(id) == null) {
            val channel = NotificationChannel(id, "Ghar ka alarm", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Camera mein khatra dikhne par alert"
            channel.setSound(null, null)
            channel.enableVibration(true)
            channel.vibrationPattern = longArrayOf(0, 800, 400, 800, 400, 800)
            channel.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            channel.setBypassDnd(dnd)
            nm().createNotificationChannel(channel)
        }
        if (dnd) nm().deleteNotificationChannel(CHANNEL_NORMAL)
        OLD_CHANNELS.forEach { nm().deleteNotificationChannel(it) }
        return id
    }

    private fun openSeeEasy(): Boolean {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val apps = packageManager.queryIntentActivities(launcher, 0)
        val match = apps.firstOrNull { info ->
            val label = info.loadLabel(packageManager).toString().lowercase().replace(" ", "")
            label.contains("seeeasy") || info.activityInfo.packageName.lowercase().contains("seeeasy")
        } ?: return false
        val intent = packageManager.getLaunchIntentForPackage(match.activityInfo.packageName)
            ?: return false
        return open(intent)
    }

    private fun openAppSettings() {
        open(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
    }

    private fun open(intent: Intent): Boolean = try {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }
}
