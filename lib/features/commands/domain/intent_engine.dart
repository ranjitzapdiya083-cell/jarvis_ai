import '../../../core/constants/app_constants.dart';
import 'command_intent.dart';

/// Local-first Natural Language Understanding.
/// Matches Hindi / Hinglish / Gujarati-English mixed phrasing to a
/// [CommandIntent] WITHOUT calling any AI/network API — spec section 13 & 23.
///
/// Only phrases the app can genuinely execute map to a non-`unknown` intent.
/// Anything else falls through to [IntentType.conversation], which the AI
/// layer (if configured) or a plain "samajh nahi aaya" response handles.
class IntentEngine {
  // App name aliases -> canonical Android package-ish identifier used by AppLauncherService.
  static const Map<String, List<String>> _appAliases = {
    'youtube': ['youtube', 'यूट्यूब'],
    'whatsapp': ['whatsapp', 'व्हाट्सएप'],
    'instagram': ['instagram', 'insta'],
    'chrome': ['chrome', 'browser'],
    'camera': ['camera', 'कैमरा'],
    'maps': ['maps', 'google maps', 'नक्शा'],
    'calculator': ['calculator', 'कैलकुलेटर'],
    'settings': ['settings', 'सेटिंग्स'],
    'gallery': ['gallery', 'photos', 'फोटो'],
    'files': ['files', 'file manager'],
  };

  CommandIntent recognize(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) {
      return CommandIntent(type: IntentType.unknown, rawText: input);
    }

    // --- Torch / Flashlight ---
    if (_matchesAny(text, ['torch on', 'flashlight on', 'टॉर्च ऑन', 'ટોર્ચ ચાલુ']) ) {
      return CommandIntent(type: IntentType.torchOn, rawText: input);
    }
    if (_matchesAny(text, ['torch off', 'flashlight off', 'टॉर्च ऑफ', 'ટોર્ચ બંધ'])) {
      return CommandIntent(type: IntentType.torchOff, rawText: input);
    }

    // --- Battery ---
    if (_matchesAny(text, ['battery kitni', 'battery batao', 'battery status', 'बैटरी कितनी', 'બેટરી કેટલી'])) {
      return CommandIntent(type: IntentType.getBattery, rawText: input);
    }

    // --- Device info ---
    if (_matchesAny(text, ['android version', 'phone ka model', 'storage kitni', 'kitni ram', 'device info'])) {
      return CommandIntent(type: IntentType.getDeviceInfo, rawText: input);
    }

    // --- Screen off ---
    if (_matchesAny(text, ['screen off karo', 'screen off kar', 'स्क्रीन ऑफ', 'સ્ક્રીન બંધ'])) {
      return CommandIntent(type: IntentType.screenOff, rawText: input, risk: RiskLevel.medium);
    }

    // --- Volume: "volume 50 percent karo" / "volume kam karo" / "volume badhao" ---
    final volumeMatch = RegExp(r'volume\s*(\d{1,3})\s*(percent|%)?').firstMatch(text);
    if (volumeMatch != null) {
      final level = int.tryParse(volumeMatch.group(1) ?? '') ?? 50;
      return CommandIntent(
        type: IntentType.setVolume,
        rawText: input,
        slots: {'level': level.clamp(0, 100).toString()},
      );
    }
    if (_matchesAny(text, ['volume kam', 'volume down', 'volume badhao', 'volume up'])) {
      final isUp = text.contains('badhao') || text.contains('up');
      return CommandIntent(
        type: IntentType.setVolume,
        rawText: input,
        slots: {'relative': isUp ? 'up' : 'down'},
      );
    }

    // --- Brightness ---
    if (_matchesAny(text, ['brightness kam', 'brightness badhao', 'brightness kar'])) {
      final isUp = text.contains('badhao') || text.contains('increase');
      return CommandIntent(
        type: IntentType.setBrightness,
        rawText: input,
        slots: {'relative': isUp ? 'up' : 'down'},
      );
    }

    // --- Open app: "youtube kholo" / "instagram kholo" / "youtube open kar" ---
    for (final entry in _appAliases.entries) {
      for (final alias in entry.value) {
        if (text.contains(alias) &&
            _matchesAny(text, ['kholo', 'khol', 'open', 'चालू', 'ખોલ'])) {
          return CommandIntent(
            type: IntentType.openApp,
            rawText: input,
            slots: {'app': entry.key},
          );
        }
      }
    }

    // --- Calling: "mummy ko call karo" / "9876543210 par call karo" ---
    final phoneMatch = RegExp(r'(\d{10,13})').firstMatch(text);
    if (text.contains('call') || text.contains('कॉल')) {
      if (phoneMatch != null) {
        return CommandIntent(
          type: IntentType.call,
          rawText: input,
          slots: {'number': phoneMatch.group(1)!},
          risk: RiskLevel.medium,
        );
      }
      final contactMatch = RegExp(r'([a-z\u0900-\u097F]+)\s+ko\s+call').firstMatch(text);
      if (contactMatch != null) {
        return CommandIntent(
          type: IntentType.call,
          rawText: input,
          slots: {'contact': contactMatch.group(1)!},
          risk: RiskLevel.medium,
        );
      }
    }

    // --- Message: supports two phrasings:
    //   1) "<contact> ko message bhejo: <text>"           (explicit body)
    //   2) "whatsapp pe <contact> ko <text> message karo"  (inline body)
    if (text.contains('message bhejo') ||
        text.contains('message send') ||
        text.contains('message karo') ||
        (text.contains('whatsapp') && (text.contains('bhejo') || text.contains('karo')))) {
      final isWhatsapp = text.contains('whatsapp') || text.contains('व्हाट्सएप');

      // Try explicit colon syntax first: "...bhejo: <text>"
      String body = '';
      if (input.contains(':')) {
        final parts = input.split(':');
        body = parts.sublist(1).join(':').trim();
      }

      // Contact is always "<name> ko ..."
      final contactMatch = RegExp(r'([a-zA-Z\u0900-\u097F]+)\s+ko\b').firstMatch(text);

      // If no colon body found, try inline syntax: "ko <text> message karo/bhejo"
      if (body.isEmpty) {
        final inlineMatch =
            RegExp(r'ko\s+(.+?)\s+message\s+(karo|bhejo|send)').firstMatch(text);
        if (inlineMatch != null) {
          body = inlineMatch.group(1)!.trim();
        }
      }

      return CommandIntent(
        type: IntentType.sendMessage,
        rawText: input,
        slots: {
          if (contactMatch != null) 'contact': contactMatch.group(1)!,
          'body': body,
          'app': isWhatsapp ? 'whatsapp' : 'sms',
        },
        risk: RiskLevel.medium,
      );
    }

    // --- Web / YouTube search ---
    final youtubeSearchMatch = RegExp(r'youtube (?:par|pe)\s+(.+?)\s*search').firstMatch(text);
    if (youtubeSearchMatch != null) {
      return CommandIntent(
        type: IntentType.youtubeSearch,
        rawText: input,
        slots: {'query': youtubeSearchMatch.group(1)!.trim()},
      );
    }
    final googleSearchMatch = RegExp(r'google (?:par|pe)\s+(.+?)\s*search').firstMatch(text);
    if (googleSearchMatch != null) {
      return CommandIntent(
        type: IntentType.webSearch,
        rawText: input,
        slots: {'query': googleSearchMatch.group(1)!.trim()},
      );
    }

    // --- Navigation ---
    final navMatch = RegExp(r'(?:mujhe|)\s*(.+?)\s*(?:ka route dikhao|le chalo)').firstMatch(text);
    if (navMatch != null) {
      return CommandIntent(
        type: IntentType.navigation,
        rawText: input,
        slots: {'destination': navMatch.group(1)!.trim()},
      );
    }

    // --- Small talk / greetings — answered locally & warmly so JARVIS
    // always has *something* natural to say, even with no AI configured. ---
    if (_matchesAny(text, ['good morning', 'गुड मॉर्निंग', 'सुप्रभात'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'morning'});
    }
    if (_matchesAny(text, ['good afternoon', 'गुड आफ्टरनून'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'afternoon'});
    }
    if (_matchesAny(text, ['good evening', 'गुड ईवनिंग'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'evening'});
    }
    if (_matchesAny(text, ['good night', 'गुड नाइट', 'शुभ रात्रि'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'night'});
    }
    if (_matchesAny(text, ['kaise ho', 'kya haal', 'how are you', 'क्या हाल'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'how_are_you'});
    }
    if (_matchesAny(text, ['thank you', 'thanks', 'शुक्रिया', 'dhanyavad', 'धन्यवाद'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'thanks'});
    }
    if (_matchesAny(text, ['bye', 'good bye', 'phir milte', 'अलविदा'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'bye'});
    }
    if (_matchesAny(text, ['tumhara naam', 'your name', 'tum kaun', 'who are you'])) {
      return CommandIntent(type: IntentType.smallTalk, rawText: input, slots: {'topic': 'identity'});
    }

    // Nothing local matched -> hand off as open conversation / AI query.
    return CommandIntent(type: IntentType.conversation, rawText: input);
  }

  bool _matchesAny(String text, List<String> phrases) {
    for (final p in phrases) {
      if (text.contains(p)) return true;
    }
    return false;
  }
}
