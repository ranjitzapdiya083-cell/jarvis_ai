import '../../../core/utils/result.dart';

class ResolvedContact {
  final String displayName;
  final String phoneNumber;
  const ResolvedContact({required this.displayName, required this.phoneNumber});
}

/// Real contact lookup contract — used to turn "mummy ko call karo" into
/// an actual phone number instead of just failing.
abstract class ContactService {
  /// Fuzzy-matches [query] (e.g. "mummy", "papa", "rahul") against the
  /// device's contact list (requires Permission.contacts granted).
  /// Returns the single best match, or a failure listing how many
  /// candidates were found so the UI can disambiguate if needed.
  Future<Result<ResolvedContact>> findByName(String query);

  Future<Result<List<ResolvedContact>>> searchByName(String query);
}
