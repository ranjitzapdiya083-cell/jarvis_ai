import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/result.dart';

/// Known package names for apps mentioned in the spec (section 14).
/// Extendable — add an entry here to support launching another app.
class AppLauncherService {
  static const Map<String, String> _packageMap = {
    'youtube': 'com.google.android.youtube',
    'whatsapp': 'com.whatsapp',
    'instagram': 'com.instagram.android',
    'chrome': 'com.android.chrome',
    'maps': 'com.google.android.apps.maps',
    'calculator': 'com.google.android.calculator',
    'gallery': 'com.google.android.apps.photos',
    'files': 'com.google.android.documentsui',
  };

  /// Opens an installed app by its canonical key (e.g. "youtube").
  /// Returns a clear failure if the app is not installed — never fakes
  /// success (spec section 14: "Never fake an action").
  Future<Result<void>> openApp(String appKey) async {
    final key = appKey.toLowerCase();

    // System screens use ACTION_* intents rather than package launch.
    if (key == 'settings') {
      try {
        const intent = AndroidIntent(action: 'android.settings.SETTINGS');
        await intent.launch();
        return const Result.success(null);
      } catch (e) {
        return Result.failure('Settings open nahi ho payi.');
      }
    }
    if (key == 'camera') {
      try {
        const intent = AndroidIntent(action: 'android.media.action.IMAGE_CAPTURE');
        await intent.launch();
        return const Result.success(null);
      } catch (e) {
        return Result.failure('Camera open nahi ho payi.');
      }
    }

    final package = _packageMap[key];
    if (package == null) {
      return Result.failure('"$appKey" JARVIS ke supported apps list mein nahi hai.');
    }

    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: package,
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Boss, ye app phone mein installed nahi hai.', code: 'NOT_INSTALLED');
    }
  }

  /// Opens a URL (used for Google/YouTube search deep-links) via the
  /// system browser/app — real navigation, not a fabricated "done".
  Future<Result<void>> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        return Result.failure('Link open nahi ho paya.');
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Link open nahi ho paya: internet ya browser check karo.');
    }
  }

  Future<Result<void>> dialNumber(String number) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.CALL',
        data: 'tel:$number',
      );
      await intent.launch();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        'Call start nahi ho payi. CALL_PHONE permission check karo.',
        code: 'PERMISSION_REQUIRED',
      );
    }
  }

  Future<Result<void>> dialNumberNoPermission(String number) async {
    // Fallback that just opens the dialer (ACTION_DIAL) without needing
    // the CALL_PHONE permission — used when the user hasn't granted it.
    try {
      final intent = AndroidIntent(action: 'android.intent.action.DIAL', data: 'tel:$number');
      await intent.launch();
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Dialer open nahi ho paya.');
    }
  }

  Future<Result<void>> sendSms(String number, String body) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: 'smsto:$number',
        arguments: {'sms_body': body},
      );
      await intent.launch();
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Message app open nahi ho payi.');
    }
  }

  /// Opens WhatsApp with the chat + message pre-filled using the official
  /// `wa.me` deep link (works whether or not the contact is saved, as long
  /// as the number includes country code).
  ///
  /// HONEST LIMITATION: WhatsApp does not provide any public API for a
  /// third-party app to send a message on a personal account silently.
  /// This deep link opens the chat with the text already typed in the
  /// input box — the user still has to tap the Send button themselves.
  /// This is a WhatsApp/Android anti-spam policy, not something that can
  /// be coded around from a normal app. (Fully silent sending is only
  /// possible via the separate, paid "WhatsApp Business Platform API"
  /// with a verified business account — a different product entirely.)
  Future<Result<void>> openWhatsAppMessage(String number, String message) async {
    final digitsOnly = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return Result.failure('WhatsApp ke liye valid number nahi mila.');
    }
    final url = 'https://wa.me/$digitsOnly?text=${Uri.encodeComponent(message)}';
    final r = await openUrl(url);
    return r.when(
      success: (_) => const Result.success(null),
      failure: (msg, _) => Result.failure(
        'WhatsApp open nahi ho paya. WhatsApp installed hai aur number sahi hai check karo. ($msg)',
      ),
    );
  }

  Future<Result<void>> openMapsSearch(String query) {
    return openUrl('geo:0,0?q=${Uri.encodeComponent(query)}');
  }
}
