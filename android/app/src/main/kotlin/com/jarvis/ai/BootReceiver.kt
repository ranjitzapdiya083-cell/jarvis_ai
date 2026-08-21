package com.jarvis.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Only re-arms the background assistant if the user explicitly turned on
 * "Auto Start on Boot" in Settings > Background Assistant (spec section 7).
 * The actual SharedPreferences check + foreground service start is done
 * from Dart via flutter_foreground_task's own boot-completed handling,
 * configured in the app's bootstrap; this receiver is a safe no-op stub
 * that developers can extend if they add native-only foreground service
 * logic instead of the Flutter-side one.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // No-op by default: flutter_foreground_task handles restart via
            // its own registered receiver when "Auto Start on Boot" is on.
            // Kept here so the manifest-declared receiver has a concrete,
            // compilable implementation rather than a dangling reference.
        }
    }
}
