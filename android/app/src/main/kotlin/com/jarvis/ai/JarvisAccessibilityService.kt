package com.jarvis.ai

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityEvent

/**
 * Minimal accessibility service whose ONLY purpose is exposing
 * GLOBAL_ACTION_LOCK_SCREEN (Android 9 / API 28+) so the "screen off /
 * lock karo" voice command can actually work. It does not read screen
 * content, does not log anything, and does nothing on accessibility
 * events — it only becomes active when the user has explicitly turned
 * it on in Settings > Accessibility > JARVIS AI.
 */
class JarvisAccessibilityService : AccessibilityService() {

    companion object {
        var instance: JarvisAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Intentionally empty — this service does not need to observe
        // accessibility events, only perform the lock-screen global action.
    }

    override fun onInterrupt() {}

    fun lockScreen(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
        } else {
            // Not supported below Android 9; caller surfaces this as a
            // clear failure rather than silently doing nothing.
            false
        }
    }
}
