import 'package:permission_handler/permission_handler.dart';

/// Maps the permissions shown in the design's "Permissions" screen to real
/// Android runtime permissions. Statuses are read live from the OS —
/// never assumed or cached as "granted" without asking Android.
class AppPermission {
  final String key;
  final String label;
  final Permission permission;

  const AppPermission(this.key, this.label, this.permission);
}

class PermissionService {
  static final List<AppPermission> all = [
    const AppPermission('microphone', 'Microphone', Permission.microphone),
    const AppPermission('contacts', 'Contacts', Permission.contacts),
    const AppPermission('phone', 'Phone', Permission.phone),
    const AppPermission('sms', 'SMS', Permission.sms),
    const AppPermission('location', 'Location', Permission.location),
    const AppPermission('calendar', 'Calendar', Permission.calendarFullAccess),
    const AppPermission('notification', 'Notifications', Permission.notification),
    const AppPermission('storage', 'Storage/Photos', Permission.photos),
  ];

  Future<Map<String, PermissionStatus>> checkAll() async {
    final result = <String, PermissionStatus>{};
    for (final p in all) {
      result[p.key] = await p.permission.status;
    }
    return result;
  }

  Future<PermissionStatus> request(String key) async {
    final entry = all.firstWhere((p) => p.key == key);
    return entry.permission.request();
  }

  Future<Map<Permission, PermissionStatus>> requestEssentials() {
    return [Permission.microphone, Permission.notification].request();
  }

  Future<bool> openSettings() => openAppSettings();
}
