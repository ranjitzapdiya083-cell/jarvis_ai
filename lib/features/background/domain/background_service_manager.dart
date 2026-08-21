import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../../core/utils/result.dart';
import '../data/jarvis_task_handler.dart';

/// Single control point for the real Android foreground service that
/// keeps wake-word listening alive in the background. Wraps
/// flutter_foreground_task so the rest of the app never touches the
/// plugin API directly.
class BackgroundServiceManager {
  static bool _optionsInitialized = false;

  static void _ensureOptionsInitialized() {
    if (_optionsInitialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'jarvis_ai_background_channel',
        channelName: 'JARVIS AI Background Assistant',
        channelDescription: 'Keeps JARVIS listening for the wake word in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _optionsInitialized = true;
  }

  Future<Result<void>> start() async {
    _ensureOptionsInitialized();

    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      final requested = await FlutterForegroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        return Result.failure(
          'Notification permission ke bina background service Android par nahi chal sakti.',
          code: 'NOTIFICATION_PERMISSION_DENIED',
        );
      }
    }

    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations == false) {
      // Not fatal — just means Android may kill the service more
      // aggressively on some OEM skins. We ask, but proceed either way.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    try {
      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'JARVIS AI',
        notificationText: 'Starting background assistant...',
        callback: startBackgroundTaskHandler,
      );
      if (result is ServiceRequestFailure) {
        return Result.failure('Background service start nahi ho payi: ${result.error}');
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Background service start nahi ho payi: ${e.toString()}');
    }
  }

  Future<Result<void>> stop() async {
    try {
      final result = await FlutterForegroundTask.stopService();
      if (result is ServiceRequestFailure) {
        return Result.failure('Background service stop nahi ho payi: ${result.error}');
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Background service stop nahi ho payi: ${e.toString()}');
    }
  }

  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;
}
