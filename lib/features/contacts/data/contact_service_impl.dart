import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/result.dart';
import '../domain/contact_service.dart';

/// Real device-contacts lookup. Requires Permission.contacts to be granted —
/// if it isn't, we return an honest failure rather than silently returning
/// no results (spec: never fake success / never silently degrade).
class ContactServiceImpl implements ContactService {
  List<Contact>? _cache;

  Future<Result<List<Contact>>> _ensureLoaded() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      final requested = await Permission.contacts.request();
      if (!requested.isGranted) {
        return Result.failure(
          'Contacts permission nahi mili. Naam se call/message karne ke liye '
          'Settings > Permissions me Contacts allow karo.',
          code: 'PERMISSION_DENIED',
        );
      }
    }

    if (_cache != null) return Result.success(_cache!);

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      _cache = contacts;
      return Result.success(contacts);
    } catch (e) {
      return Result.failure('Contacts load nahi ho paye: ${e.toString()}');
    }
  }

  @override
  Future<Result<ResolvedContact>> findByName(String query) async {
    final loaded = await _ensureLoaded();
    return loaded.when(
      success: (contacts) {
        final matches = _rank(contacts, query);
        if (matches.isEmpty) {
          return Result.failure('"$query" naam ka koi contact nahi mila.', code: 'NOT_FOUND');
        }
        final best = matches.first;
        if (best.phones.isEmpty) {
          return Result.failure('"$query" ke contact mein koi phone number saved nahi hai.');
        }
        return Result.success(ResolvedContact(
          displayName: best.displayName,
          phoneNumber: best.phones.first.number,
        ));
      },
      failure: (msg, code) => Result.failure(msg, code: code),
    );
  }

  @override
  Future<Result<List<ResolvedContact>>> searchByName(String query) async {
    final loaded = await _ensureLoaded();
    return loaded.when(
      success: (contacts) {
        final matches = _rank(contacts, query)
            .where((c) => c.phones.isNotEmpty)
            .map((c) => ResolvedContact(displayName: c.displayName, phoneNumber: c.phones.first.number))
            .toList();
        return Result.success(matches);
      },
      failure: (msg, code) => Result.failure(msg, code: code),
    );
  }

  /// Simple, honest ranking: exact (case-insensitive) match first, then
  /// "starts with", then "contains". No fuzzy/AI matching — predictable
  /// and debuggable behavior over cleverness.
  List<Contact> _rank(List<Contact> contacts, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final exact = <Contact>[];
    final startsWith = <Contact>[];
    final contains = <Contact>[];

    for (final c in contacts) {
      final name = c.displayName.toLowerCase();
      if (name == q) {
        exact.add(c);
      } else if (name.startsWith(q)) {
        startsWith.add(c);
      } else if (name.contains(q)) {
        contains.add(c);
      }
    }

    return [...exact, ...startsWith, ...contains];
  }
}
