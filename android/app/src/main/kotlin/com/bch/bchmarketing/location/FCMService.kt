package com.bch.bchmarketing.location

import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.os.Build

class FCMService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val data = remoteMessage.data
        Log.d(TAG, "FCM Message Received: $data")

        // CHECK IF IT IS A WAKE-UP CALL
        if (data.containsKey("action") && data["action"] == "START_LOCATION_SERVICE") {
            Log.d(TAG, "Wake-up command received! Starting LocationService...")
            startLocationService()
        }
    }

    private fun startLocationService() {
        val serviceIntent = Intent(this, LocationService::class.java)
        serviceIntent.action = LocationService.ACTION_START
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start LocationService from FCM: ${e.message}")
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM Token: $token")
        // We let the Flutter plugin handle token syncing via its own internal listeners
        // or we can save it to shared prefs if we really need native access.
    }

    companion object {
        const val TAG = "FCMService"
    }
}
