import '../../../core/utils/result.dart';

/// Contract for real device control. Implementations MUST perform the
/// actual OS-level action and only return success when the OS confirms it.
abstract class DeviceControlService {
  Future<Result<void>> torchOn();
  Future<Result<void>> torchOff();
  Future<Result<int>> getBatteryLevel();
  Future<Result<void>> setVolume(int percent);
  Future<Result<void>> adjustVolume({required bool up});
  Future<Result<void>> setBrightness(double percent);
  Future<Result<void>> adjustBrightness({required bool up});

  /// Turns the screen off where Android permits (device admin / accessibility
  /// service must be granted). Returns failure with an explanatory message
  /// if the OS does not allow it for this app.
  Future<Result<void>> screenOff();

  Future<Result<DeviceInfo>> getDeviceInfo();
  Future<Result<bool>> hasInternetConnection();
}

class DeviceInfo {
  final String model;
  final String androidVersion;
  final int sdkInt;
  final String appVersion;
  final double? freeStorageGb;

  const DeviceInfo({
    required this.model,
    required this.androidVersion,
    required this.sdkInt,
    required this.appVersion,
    this.freeStorageGb,
  });
}
