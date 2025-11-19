package com.baseet.numu

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CHANNEL_ID_DEFAULT = "numu_reminders_default"
        private const val CHANNEL_ID_ALARMS = "numu_reminders_alarms"
        private const val CHANNEL_NAME_DEFAULT = "Reminders"
        private const val CHANNEL_NAME_ALARMS = "Alarms"
        private const val CHANNEL_DESCRIPTION_DEFAULT = "Notifications for habit and task reminders"
        private const val CHANNEL_DESCRIPTION_ALARMS = "Full-screen alarms for important reminders"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        // Notification channels are only needed on Android O (API 26) and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager

            // Create default notification channel for standard reminders
            val defaultChannel = NotificationChannel(
                CHANNEL_ID_DEFAULT,
                CHANNEL_NAME_DEFAULT,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION_DEFAULT
                enableVibration(true)
                enableLights(true)
            }

            // Create alarm channel for full-screen alarms
            val alarmChannel = NotificationChannel(
                CHANNEL_ID_ALARMS,
                CHANNEL_NAME_ALARMS,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION_ALARMS
                enableVibration(true)
                enableLights(true)
                setBypassDnd(true) // Allow alarms to bypass Do Not Disturb
            }

            // Register channels with the system
            notificationManager.createNotificationChannel(defaultChannel)
            notificationManager.createNotificationChannel(alarmChannel)
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        // Handle notification tap intents
        // The flutter_local_notifications plugin will handle the actual navigation
        setIntent(intent)
    }
}
