import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../device/data/app_launcher_service.dart';
import '../../../device/domain/device_control_service.dart';

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});
}

class QuickActionsGrid extends StatelessWidget {
  final AppLauncherService launcher;
  final DeviceControlService device;
  final void Function(String message) onFeedback;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCustomCommands;
  final VoidCallback onOpenDialer;

  const QuickActionsGrid({
    super.key,
    required this.launcher,
    required this.device,
    required this.onFeedback,
    required this.onOpenSettings,
    required this.onOpenCustomCommands,
    required this.onOpenDialer,
  });

  Future<void> _run<T>(Future<Result<T>> Function() action) async {
    final result = await action();
    result.when(success: (_) {}, failure: (msg, _) => onFeedback(msg));
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(icon: Icons.call, label: 'Call', color: AppColors.success, onTap: onOpenDialer),
      _QuickAction(
        icon: Icons.chat,
        label: 'WhatsApp',
        color: const Color(0xFF25D366),
        onTap: () => _run(() => launcher.openApp('whatsapp')),
      ),
      _QuickAction(
        icon: Icons.smart_display,
        label: 'YouTube',
        color: const Color(0xFFFF0000),
        onTap: () => _run(() => launcher.openApp('youtube')),
      ),
      _QuickAction(
        icon: Icons.map,
        label: 'Maps',
        color: const Color(0xFF34A853),
        onTap: () => _run(() => launcher.openApp('maps')),
      ),
      _QuickAction(
        icon: Icons.flashlight_on,
        label: 'Torch',
        color: AppColors.warning,
        onTap: () => _run(() => device.torchOn()),
      ),
      _QuickAction(
        icon: Icons.camera_alt,
        label: 'Camera',
        color: AppColors.electricBlue,
        onTap: () => _run(() => launcher.openApp('camera')),
      ),
      _QuickAction(icon: Icons.settings, label: 'Settings', color: AppColors.darkTextSecondary, onTap: onOpenSettings),
      _QuickAction(icon: Icons.add, label: 'Add', color: AppColors.purple, onTap: onOpenCustomCommands),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) => _QuickActionTile(action: actions[index]),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: action.color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(action.icon, color: action.color, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
