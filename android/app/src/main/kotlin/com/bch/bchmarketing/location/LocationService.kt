package com.bch.bchmarketing.location

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.bch.bchmarketing.MainActivity
import com.bch.bchmarketing.R
import com.google.android.gms.location.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.view.FlutterCallbackInformation
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class LocationService : Service() {

    private var fusedLocationClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var flutterEngine: FlutterEngine? = null
    private val isServiceRunning = AtomicBoolean(false)

    companion object {
        const val CHANNEL_ID = "location_tracking_channel"
        const val NOTIFICATION_ID = 888
        const val WAKELOCK_TAG = "LocationService::WakeLock"
        
        // Actions
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        
        // 1. Acquire Partial WakeLock implementation
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKELOCK_TAG)
        wakeLock?.setReferenceCounted(false)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_STICKY // System restarted service

        when (intent.action) {
            ACTION_START -> startTracking()
            ACTION_STOP -> stopTracking()
        }

        // START_STICKY: If OS kills us, recreate us with Intent=null
        return START_STICKY
    }

    private fun startTracking() {
        if (isServiceRunning.get()) return
        isServiceRunning.set(true)

        // 2. PROMOTE TO FOREGROUND (Mandatory < 5 seconds)
        val notification = createNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                // For Android 14+ (UPSIDE_DOWN_CAKE) we need the type
                // But ServiceCompat handles the version check for passing the type if we provide bitmask
                // 8 = FOREGROUND_SERVICE_TYPE_LOCATION
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                   startForeground(NOTIFICATION_ID, notification, 
                       if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) 
                           android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                       else 
                           android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION // For Q it is allowed but not mandatory to be specific location type, but using it is better if defined. Actually Q introduced types.
                   )
                } else {
                   startForeground(NOTIFICATION_ID, notification)
                }
            } catch (e: Exception) {
                // Fallback
                startForeground(NOTIFICATION_ID, notification)
            }
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        
        wakeLock?.acquire(10 * 60 * 1000L /* 10 mins safety timeout, re-acquired on updates */)

        // 3. Configure Location Request
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 5000) // 5s interval
            .setMinUpdateDistanceMeters(10f) // 10 meters
            .setWaitForAccurateLocation(false)
            .build()


        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                // 🔄 Re-acquire WakeLock logic every time we get a location
                // Just to be absolutely sure we don't time out if user moves
                if (wakeLock?.isHeld == true) {
                    wakeLock?.release()
                }
                wakeLock?.acquire(24 * 60 * 60 * 1000L) // Refresh for 24 hours
                
                for (location in locationResult.locations) {
                    // 4. Send to Flutter (Headless or Main)
                    sendLocationToDart(location.latitude, location.longitude, location.speed)
                }
            }
        }

        try {
            fusedLocationClient?.requestLocationUpdates(locationRequest, locationCallback!!, Looper.getMainLooper())
        } catch (e: SecurityException) {
            // Log/Handle permission loss
        }
    }

    private fun stopTracking() {
        try {
            isServiceRunning.set(false)
            
            // 🔴 Notify Dart that service is stopping (Best Effort)
            sendStopEventToDart()
            
            if (locationCallback != null) {
                fusedLocationClient?.removeLocationUpdates(locationCallback!!)
            }
            stopForeground(true)
            stopSelf()
            wakeLock?.release()
            
            // Give Dart a moment to process the message before destroying engine
            flutterEngine = null
        } catch (e: Exception) { 
            e.printStackTrace()
        }
    }

    private fun sendStopEventToDart() {
        // Ensure engine is ready to send the final goodbye
        if (flutterEngine == null) {
            val loader = FlutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            flutterEngine = FlutterEngine(applicationContext)
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val callbackHandleId = prefs.getLong("flutter.location_callback_id", 0L)
            
            if (callbackHandleId != 0L) {
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandleId)
                if (callbackInfo != null) {
                    val callback = DartExecutor.DartCallback(assets, loader.findAppBundlePath(), callbackInfo)
                    flutterEngine?.dartExecutor?.executeDartCallback(callback)
                }
            }
        }

        if (flutterEngine != null) {
             MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.bch/location_updates")
            .invokeMethod("onServiceStopped", null)
        }
    }

    // ==========================================
    // 💀 HEADLESS BRIDGE
    // ==========================================
    private fun sendLocationToDart(lat: Double, lng: Double, speed: Float) {
        // Option B: If App is KILLED/BACKGROUND, use Headless Engine
        
        if (flutterEngine == null) {
            val loader = FlutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            flutterEngine = FlutterEngine(applicationContext)
            
            val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
            val callbackHandleId = prefs.getLong("flutter.location_callback_id", 0L)
            
            if (callbackHandleId != 0L) {
                val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandleId)
                if (callbackInfo != null) {
                    val callback = DartExecutor.DartCallback(assets, loader.findAppBundlePath(), callbackInfo)
                    flutterEngine?.dartExecutor?.executeDartCallback(callback)
                }
            }
        }

        if (flutterEngine != null) {
             MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.bch/location_updates")
            .invokeMethod("onLocation", mapOf("lat" to lat, "lng" to lng, "speed" to speed))
        }
    }

    // ==========================================
    // 🛡️ SYSTEM REQUIREMENTS
    // ==========================================
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Live Location Tracking",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Running in background"
                setSound(null, null) 
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sharing Live Location")
            .setContentText("Your location is being updated in real-time")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true) 
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
    
    // ==========================================
    // 🧟 RECOVERY (SWIPE KILL)
    // ==========================================
    override fun onTaskRemoved(rootIntent: Intent?) {
        val restartServiceIntent = Intent(applicationContext, LocationService::class.java).also {
            it.action = ACTION_START
            it.setPackage(packageName)
        }
        val restartServicePendingIntent = PendingIntent.getService(
            applicationContext, 1, restartServiceIntent, PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmService = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmService.set(
            AlarmManager.ELAPSED_REALTIME,
            System.currentTimeMillis() + 1000,
            restartServicePendingIntent
        )
        
        super.onTaskRemoved(rootIntent)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
