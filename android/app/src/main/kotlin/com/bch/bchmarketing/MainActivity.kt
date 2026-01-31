package com.bch.bchmarketing

import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import com.bch.bchmarketing.location.LocationService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bch/location_control"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val serviceIntent = Intent(this, LocationService::class.java)
                    serviceIntent.action = LocationService.ACTION_START
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success("STARTED")
                }
                "stopService" -> {
                    val serviceIntent = Intent(this, LocationService::class.java)
                    serviceIntent.action = LocationService.ACTION_STOP
                    startService(serviceIntent)
                    result.success("STOPPED")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
