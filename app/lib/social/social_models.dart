import 'dart:math';

class GroupMember {
  const GroupMember({required this.id, required this.name});
  final String id;
  final String name;
}

/// A shared menorah ("חנוכייה משותפת").
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.emoji,
    required this.inviteCode,
    required this.ownerId,
    required this.hebrewYear,
    required this.totalLight,
    required this.members,
  });

  final String id;
  final String name;
  final String emoji;
  final String inviteCode;
  final String ownerId;
  final int hebrewYear;
  final int totalLight;
  final List<GroupMember> members;
}

/// A group plus what happened on one night.
class GroupNight {
  const GroupNight({
    required this.group,
    required this.night,
    required this.litMemberIds,
    required this.nudgesToMe,
    required this.nudgedByMe,
  });

  final Group group;
  final int night;
  final Set<String> litMemberIds;

  /// Names of people who sent me light tonight.
  final List<String> nudgesToMe;

  /// Member ids I already sent light to tonight.
  final Set<String> nudgedByMe;
}

enum RsvpStatus { yes, maybe, no }

/// "בואו להדליק אצלי"
class HostInvite {
  const HostInvite({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hebrewYear,
    required this.night,
    required this.time,
    required this.note,
    required this.rsvps,
  });

  final String id;
  final String hostId;
  final String hostName;
  final int hebrewYear;
  final int night;

  /// "HH:mm", local to the host.
  final String time;
  final String note;

  /// userId → (name, status)
  final Map<String, ({String name, RsvpStatus status})> rsvps;

  int count(RsvpStatus s) => rsvps.values.where((r) => r.status == s).length;
}

/// 6-character codes without look-alike characters (Vision, 34.3).
class InviteCodes {
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String generate([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)])
        .join();
  }

  /// Uppercases and drops spaces and dashes.
  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  static bool isValid(String code) =>
      code.length == 6 && code.split('').every(alphabet.contains);
}
