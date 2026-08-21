import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

/// Every action JARVIS can actually perform.
/// Adding a new real capability means adding a case here AND a handler —
/// there is no "unhandled but shown as success" path.
enum IntentType {
  openApp,
  torchOn,
  torchOff,
  getBattery,
  getDeviceInfo,
  setVolume,
  setBrightness,
  screenOff,
  call,
  sendMessage,
  webSearch,
  youtubeSearch,
  navigation,
  setReminder,
  runCustomCommand,
  conversation, // fall through to AI layer
  smallTalk, // greetings/pleasantries — answered locally & warmly, no AI needed
  unknown,
}

class CommandIntent extends Equatable {
  final IntentType type;
  final Map<String, String> slots; // e.g. {"app": "youtube"} or {"contact": "mummy"}
  final String rawText;
  final RiskLevel risk;

  const CommandIntent({
    required this.type,
    required this.rawText,
    this.slots = const {},
    this.risk = RiskLevel.low,
  });

  @override
  List<Object?> get props => [type, slots, rawText, risk];
}
