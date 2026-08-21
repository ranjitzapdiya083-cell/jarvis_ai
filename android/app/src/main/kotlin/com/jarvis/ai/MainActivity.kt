package com.jarvis.ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the "screen off" voice command to the real Android accessibility
 * global action. This is the ONLY supported way for a non-device-owner app
 * to lock the screen (spec section 16), and it only works if the user has
 * manually enabled JarvisAccessibilityService in system Settings.
 *
 * We never fake success here — if the accessibility service isn't running,
 * the channel returns false and the Dart side surfaces an honest message.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jarvis.ai/screen_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "screenOff" -> {
                    val instance = JarvisAccessibilityService.instance
                    if (instance != null) {
                        val success = instance.lockScreen()
                        result.success(success)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
