import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/background/domain/background_service_manager.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/commands/presentation/commands_screen.dart';
import 'features/custom_commands/presentation/custom_commands_screen.dart';
import 'features/home/domain/assistant_controller.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/permissions/data/permission_service.dart';
import 'features/settings/presentation/ai_settings_screen.dart';
import 'features/settings/presentation/background_assistant_screen.dart';
import 'features/settings/presentation/permissions_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ask for the two permissions the app cannot function at all without,
  // right at first launch — matching spec section 12 (progressive
  // permission requests, not a wall of prompts).
  await PermissionService().requestEssentials();

  // If the user previously enabled Background Assistant, resume the real
  // foreground service now (e.g. after an app/device restart) rather than
  // just showing the toggle as "on" without anything actually running.
  final settings = ServiceLocator.instance.settingsRepository;
  if (await settings.getBackgroundAssistantEnabled()) {
    await BackgroundServiceManager().start();
  }

  final assistantController = await ServiceLocator.instance.buildAssistantController();
  await assistantController.initialize();

  final themeController = ThemeController(ServiceLocator.instance.settingsRepository);
  await themeController.load();

  runApp(JarvisApp(
    assistantController: assistantController,
    themeController: themeController,
  ));
}

class JarvisApp extends StatelessWidget {
  final AssistantController assistantController;
  final ThemeController themeController;

  const JarvisApp({super.key, required this.assistantController, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AssistantController>.value(value: assistantController),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'JARVIS AI',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            initialRoute: '/',
            routes: {
              '/': (_) => const HomeScreen(),
              '/chat': (_) => const ChatScreen(),
              '/commands': (_) => const CommandsScreen(),
              '/custom-commands': (_) => const CustomCommandsScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/settings/background-assistant': (_) => const BackgroundAssistantScreen(),
              '/settings/ai': (_) => const AiSettingsScreen(),
              '/permissions': (_) => const PermissionsScreen(),
            },
            builder: (context, child) => WithForegroundTask(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
