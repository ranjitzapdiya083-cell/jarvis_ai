import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../permissions/data/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _service = PermissionService();
  Map<String, PermissionStatus> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final statuses = await _service.checkAll();
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ...PermissionService.all.map((p) {
                    final status = _statuses[p.key] ?? PermissionStatus.denied;
                    final granted = status.isGranted;
                    return Card(
                      child: ListTile(
                        leading: Icon(_iconFor(p.key), color: granted ? AppColors.success : AppColors.warning),
                        title: Text(p.label),
                        trailing: Text(
                          granted ? 'Allowed' : (status.isPermanentlyDenied ? 'Not Granted' : 'Denied'),
                          style: TextStyle(
                            color: granted ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          if (status.isPermanentlyDenied) {
                            await _service.openSettings();
                          } else {
                            await _service.request(p.key);
                          }
                          _refresh();
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () async {
                      await _service.requestEssentials();
                      _refresh();
                    },
                    child: const Text('Check All Permissions'),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'microphone':
        return Icons.mic;
      case 'contacts':
        return Icons.contacts;
      case 'phone':
        return Icons.phone;
      case 'sms':
        return Icons.sms;
      case 'location':
        return Icons.location_on;
      case 'calendar':
        return Icons.calendar_today;
      case 'notification':
        return Icons.notifications;
      case 'storage':
        return Icons.folder;
      default:
        return Icons.security;
    }
  }
}
