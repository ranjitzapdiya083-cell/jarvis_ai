import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/assistant_controller.dart';
import '../domain/assistant_state.dart';
import 'widgets/assistant_orb.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_commands_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _typedController = TextEditingController();

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AssistantController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                _buildHeader(context),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Column(
                    children: [
                      AssistantOrb(
                        state: controller.state,
                        onTap: () {
                          if (controller.state == AssistantState.listening) {
                            controller.stopListening();
                          } else {
                            controller.startListening();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(_statusLabel(controller.state), style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        controller.liveTranscript.isNotEmpty
                            ? '"${controller.liveTranscript}"'
                            : (controller.errorMessage ?? '"Hey JARVIS"'),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildStatusBar(context, controller),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(onPressed: () {}, child: const Text('See All')),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                QuickActionsGrid(
                  launcher: ServiceLocator.instance.appLauncherService,
                  device: ServiceLocator.instance.deviceControlService,
                  onFeedback: _showSnack,
                  onOpenSettings: () => Navigator.pushNamed(context, '/settings'),
                  onOpenCustomCommands: () => Navigator.pushNamed(context, '/custom-commands'),
                  onOpenDialer: () => _promptDial(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                RecentCommandsList(
                  entries: controller.recent,
                  onSeeAll: () {},
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _showTypedInputSheet(context, controller),
                icon: const Icon(Icons.keyboard),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (controller.state == AssistantState.listening) {
                        controller.stopListening();
                      } else {
                        controller.startListening();
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: AppColors.orbGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.state == AssistantState.listening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () => Navigator.pushNamed(context, '/settings'), icon: const Icon(Icons.menu)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.orbGradient.createShader(bounds),
                child: const Text(
                  'JARVIS AI',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Text('Your Voice. Your Phone. Your Assistant.',
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context, AssistantController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Background Assistant', style: Theme.of(context).textTheme.bodyLarge)),
          Text('Active', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _statusLabel(AssistantState state) {
    switch (state) {
      case AssistantState.listening:
        return 'Listening...';
      case AssistantState.processing:
        return 'Processing...';
      case AssistantState.speaking:
        return 'Speaking...';
      case AssistantState.error:
        return 'Error';
      case AssistantState.permissionRequired:
        return 'Permission Required';
      default:
        return 'Tap to speak';
    }
  }

  void _showTypedInputSheet(BuildContext context, AssistantController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _typedController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Type a command...'),
                onSubmitted: (text) {
                  Navigator.pop(context);
                  controller.submitTypedText(text);
                  _typedController.clear();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                Navigator.pop(context);
                controller.submitTypedText(_typedController.text);
                _typedController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptDial(BuildContext context) {
    final numberController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dial number'),
        content: TextField(
          controller: numberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'e.g. 9876543210'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final r = await ServiceLocator.instance.appLauncherService
                  .dialNumberNoPermission(numberController.text.trim());
              r.when(success: (_) {}, failure: (m, _) => _showSnack(m));
            },
            child: const Text('Dial'),
          ),
        ],
      ),
    ).then((_) => numberController.dispose());
  }
}
