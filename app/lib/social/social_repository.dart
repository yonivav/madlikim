import 'social_models.dart';

/// The social layer (Vision, chapter 34). Two implementations:
/// [LocalSocialRepository] (no server, single device) and
/// [FirebaseSocialRepository].
abstract class SocialRepository {
  /// True when data is shared with other people (Firebase).
  bool get isRemote;

  /// Signs in (anonymously) if needed. Returns my user id.
  Future<String> ensureUser();

  String? get currentUserId;

  Stream<List<Group>> watchMyGroups(int hebrewYear);

  Stream<GroupNight> watchGroupNight(String groupId, int night);

  Future<Group> createGroup({
    required String name,
    required String emoji,
    required int hebrewYear,
    required String myName,
  });

  /// Returns null when the code does not exist.
  Future<Group?> joinByCode(String code, {required String myName});

  Future<void> leaveGroup(String groupId);

  Future<void> renameGroup(String groupId, String name);

  /// Adds my lighting to every group I am in for [hebrewYear]. Idempotent
  /// per night.
  Future<void> recordLighting({
    required int hebrewYear,
    required int night,
    required int light,
  });

  Future<void> sendNudge({
    required String groupId,
    required String toUserId,
    required int night,
    required String myName,
  });

  Future<HostInvite> createInvite({
    required int hebrewYear,
    required int night,
    required String time,
    required String note,
    required String myName,
  });

  Stream<List<HostInvite>> watchMyInvites(int hebrewYear);

  Stream<HostInvite?> watchInvite(String inviteId);

  Future<void> rsvp({
    required String inviteId,
    required RsvpStatus status,
    required String myName,
  });

  Future<void> deleteInvite(String inviteId);

  /// Leaves all groups, deletes my invites and signs out.
  Future<void> deleteEverything();
}
