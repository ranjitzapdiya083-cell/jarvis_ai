import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/features/commands/domain/command_intent.dart';
import 'package:jarvis_ai/features/commands/domain/intent_engine.dart';

void main() {
  final engine = IntentEngine();

  test('recognizes torch on command', () {
    final intent = engine.recognize('torch on karo');
    expect(intent.type, IntentType.torchOn);
  });

  test('recognizes battery query', () {
    final intent = engine.recognize('battery kitni hai');
    expect(intent.type, IntentType.getBattery);
  });

  test('recognizes open app command', () {
    final intent = engine.recognize('youtube kholo');
    expect(intent.type, IntentType.openApp);
    expect(intent.slots['app'], 'youtube');
  });

  test('recognizes volume percent command', () {
    final intent = engine.recognize('volume 70 percent karo');
    expect(intent.type, IntentType.setVolume);
    expect(intent.slots['level'], '70');
  });

  test('recognizes phone number call', () {
    final intent = engine.recognize('9876543210 ko call karo');
    expect(intent.type, IntentType.call);
    expect(intent.slots['number'], '9876543210');
  });

  test('recognizes contact-name call command', () {
    final intent = engine.recognize('mummy ko call karo');
    expect(intent.type, IntentType.call);
    expect(intent.slots['contact'], 'mummy');
  });

  test('recognizes inline whatsapp message command', () {
    final intent = engine.recognize('whatsapp pe king ko hy message karo');
    expect(intent.type, IntentType.sendMessage);
    expect(intent.slots['contact'], 'king');
    expect(intent.slots['body'], 'hy');
    expect(intent.slots['app'], 'whatsapp');
  });

  test('recognizes colon-syntax sms message command', () {
    final intent = engine.recognize('papa ko message bhejo: ghar aa jao');
    expect(intent.type, IntentType.sendMessage);
    expect(intent.slots['contact'], 'papa');
    expect(intent.slots['body'], 'ghar aa jao');
    expect(intent.slots['app'], 'sms');
  });

  test('recognizes small talk (good morning) without needing AI', () {
    final intent = engine.recognize('good morning jarvis');
    expect(intent.type, IntentType.smallTalk);
    expect(intent.slots['topic'], 'morning');
  });

  test('falls back to conversation for unrecognized free text', () {
    final intent = engine.recognize('aaj mausam kaisa hai bhai');
    expect(intent.type, IntentType.conversation);
  });
}
