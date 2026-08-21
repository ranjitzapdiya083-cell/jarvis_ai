package com.jarvis.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager

/**
 * Turns the screen ON when JARVIS detects its wake word while the screen
 * is off — this is what makes "Hey JARVIS" feel like it "wakes up" the
 * phone, not just the assistant logic.
 *
 * HOW IT WORKS: acquires a short-lived full wake lock with
 * ACQUIRE_CAUSES_WAKEUP, which is the standard (if old-style) Android API
 * for turning the screen on from code. It's released again after a few
 * seconds so the phone can go back to sleep normally — JARVIS does not
 * keep the screen on indefinitely.
 *
 * HONEST LIMITATION: this only works if the JARVIS background service is
 * still alive when the wake word is spoken. On stock Android this is
 * reliable for a while, but several OEM skins (Xiaomi/MIUI, Oppo/ColorOS,
 * Vivo, etc.) aggressively kill background mic access after the screen has
 * been off for some time unless the user has manually whitelisted JARVIS
 * in that phone's battery-saver / autostart settings. There is no code fix
 * for this — it's a manufacturer-level restriction on ALL third-party
 * background apps, not specific to this app.
 */
class WakeScreenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_WAKE_SCREEN) return

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager

        @Suppress("DEPRECATION")
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
            "JarvisAI:WakeWordScreenOn"
        )
        wakeLock.acquire(10_000L) // auto-releases after 10s as a safety net
        // Released promptly so we don't hold a wake lock longer than needed;
        // the ON_AFTER_RELEASE flag keeps the screen on briefly after this.
        wakeLock.release()
    }

    companion object {
        const val ACTION_WAKE_SCREEN = "com.jarvis.ai.ACTION_WAKE_SCREEN"
    }
}
