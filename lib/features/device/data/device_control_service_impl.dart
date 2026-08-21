import 'dart:io';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:torch_light/torch_light.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../core/utils/result.dart';
import '../domain/device_control_service.dart';

/// Real implementation. Every method talks to an actual Android API through
/// its plugin — nothing here fabricates a value or a success state.
class DeviceControlServiceImpl implements DeviceControlService {
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  /// Matches the channel name registered in
  /// android/app/src/main/kotlin/com/jarvis/ai/MainActivity.kt
  static const MethodChannel _screenControlChannel =
      MethodChannel('com.jarvis.ai/screen_control');

  @override
  Future<Result<void>> torchOn() async {
    try {
      final available = await TorchLight.isTorchAvailable();
      if (!available) {
        return Result.failure('Is device mein flashlight/torch available nahi hai.');
      }
      await TorchLight.enableTorch();
      return const Result.success(null);
    } on Exception catch (e) {
      return Result.failure('Torch on nahi ho paya: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> torchOff() async {
    try {
      await TorchLight.disableTorch();
      return const Result.success(null);
    } on Exception catch (e) {
      return Result.failure('Torch off nahi ho paya: ${e.toString()}');
    }
  }

  @override
  Future<Result<int>> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return Result.success(level);
    } catch (e) {
      return Result.failure('Battery level nahi mil paya.');
    }
  }

  @override
  Future<Result<void>> setVolume(int percent) async {
    try {
      final clamped = percent.clamp(0, 100) / 100.0;
      VolumeController.instance.setVolume(clamped);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Volume set nahi ho paya.');
    }
  }

  @override
  Future<Result<void>> adjustVolume({required bool up}) async {
    try {
      final current = await VolumeController.instance.getVolume();
      final next = (current + (up ? 0.1 : -0.1)).clamp(0.0, 1.0);
      VolumeController.instance.setVolume(next);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Volume change nahi ho paya.');
    }
  }

  /// HONEST NOTE: `screen_brightness` changes brightness for JARVIS's own
  /// app window only (via the Activity's WindowManager attributes) — this
  /// does NOT need WRITE_SETTINGS and does NOT change the phone's global
  /// system brightness. The effect is only visible while JARVIS itself is
  /// the foreground app. True system-wide brightness control requires the
  /// WRITE_SETTINGS special permission + `Settings.System.canWrite()`,
  /// which is not implemented here.
  @override
  Future<Result<void>> setBrightness(double percent) async {
    try {
      await ScreenBrightness().setScreenBrightness(percent.clamp(0.0, 1.0));
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Brightness set nahi ho payi: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> adjustBrightness({required bool up}) async {
    try {
      final current = await ScreenBrightness().current;
      final next = (current + (up ? 0.1 : -0.1)).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(next);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Brightness change nahi ho payi.');
    }
  }

  @override
  Future<Result<void>> screenOff() async {
    // Android does NOT allow a normal (non-device-owner) app to turn the
    // screen off programmatically without either:
    //  1. Device Admin API (deprecated for this use, requires explicit user
    //     grant + shows a scary system dialog), or
    //  2. An Accessibility Service performing GLOBAL_ACTION_LOCK_SCREEN
    //     (Android 9+ only, requires user to enable Accessibility manually).
    // We never bypass the lock screen or fake this action (spec section 16 & 57).
    // The native side (MainActivity.kt) exposes a platform-channel method
    // that attempts GLOBAL_ACTION_LOCK_SCREEN via the JarvisAccessibilityService
    // IF the user has granted it; otherwise this returns a clear failure so
    // the UI can direct the user to Settings > Accessibility.
    try {
      final ok = await _screenControlChannel.invokeMethod<bool>('screenOff');
      if (ok == true) {
        return const Result.success(null);
      }
      return Result.failure(
        'Screen off ke liye Accessibility permission required hai. Settings me se JARVIS Accessibility Service enable karo.',
        code: 'ACCESSIBILITY_REQUIRED',
      );
    } catch (e) {
      return Result.failure(
        'Is Android version/device par screen off directly support nahi karta.',
        code: 'UNSUPPORTED',
      );
    }
  }

  @override
  Future<Result<DeviceInfo>> getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return Result.success(DeviceInfo(
          model: '${androidInfo.manufacturer} ${androidInfo.model}',
          androidVersion: androidInfo.version.release,
          sdkInt: androidInfo.version.sdkInt,
          appVersion: packageInfo.version,
        ));
      }
      return Result.failure('Device info sirf Android par supported hai.');
    } catch (e) {
      return Result.failure('Device info fetch nahi ho paya.');
    }
  }

  @override
  Future<Result<bool>> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return Result.success(!result.contains(ConnectivityResult.none));
    } catch (e) {
      return Result.failure('Connectivity check fail hui.');
    }
  }
}
