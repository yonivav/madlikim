import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'social_models.dart';
import 'social_repository.dart';

/// Works with no server. Everything lives on this device, so a group only
/// has the people who joined on this phone. Good for development, demos and
/// as a fallback when Firebase is not configured.
class LocalSocialRepository implements SocialRepository {
  LocalSocialRepository(this._prefs) {
    _load();
  }

  static const _key = 'social_local_v1';

  final SharedPreferences _prefs;
  final _changes = StreamController<void>.broadcast();
  final _random = Random();

  late String _userId;
  late Map<String, dynamic> _groups;
  late Map<String, dynamic> _invites;
  late List<String> _joinedInvites;

  void _load() {
    final raw = _prefs.getString(_key);
    final data = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    _userId = data['userId'] as String? ?? _newId();
    _groups = (data['groups'] as Map<String, dynamic>?) ?? {};
    _invites = (data['invites'] as Map<String, dynamic>?) ?? {};
    _joinedInvites = ((data['joinedInvites'] as List?) ?? []).cast<String>();
  }

  Future<void> _save() async {
    await _prefs.setString(
        _key,
        jsonEncode({
          'userId': _userId,
          'groups': _groups,
          'invites': _invites,
          'joinedInvites': _joinedInvites,
        }));
    _changes.add(null);
  }

  String _newId() => List.generate(
          16, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_random.nextInt(36)])
      .join();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  bool get isRemote => false;

  @override
  String? get currentUserId => _userId;

  @override
  Future<String> ensureUser() async {
    if (_prefs.getString(_key) == null) await _save();
    return _userId;
  }

  Group _group(String id) {
    final g = _groups[id] as Map<String, dynamic>;
    final lightings = (g['lightings'] as Map<String, dynamic>? ?? {});
    return Group(
      id: id,
      name: g['name'] as String,
      emoji: g['emoji'] as String,
      inviteCode: g['code'] as String,
      ownerId: g['ownerId'] as String,
      hebrewYear: g['year'] as int,
      totalLight: lightings.values.fold<int>(0, (s, v) => s + (v as int)),
      members: [
        for (final m in (g['members'] as List))
          GroupMember(id: m['id'] as String, name: m['name'] as String),
      ],
    );
  }

  bool _isMember(Map<String, dynamic> g) =>
      (g['members'] as List).any((m) => m['id'] == _userId);

  @override
  Stream<List<Group>> watchMyGroups(int hebrewYear) => _watch(() => [
        for (final e in _groups.entries)
          if (_isMember(e.value as Map<String, dynamic>) &&
              (e.value as Map<String, dynamic>)['year'] == hebrewYear)
            _group(e.key),
      ]);

  @override
  Stream<GroupNight> watchGroupNight(String groupId, int night) =>
      _watch(() {
        final g = _groups[groupId] as Map<String, dynamic>;
        final lightings = (g['lightings'] as Map<String, dynamic>? ?? {});
        final nudges = (g['nudges'] as List? ?? []).cast<Map<String, dynamic>>();
        return GroupNight(
          group: _group(groupId),
          night: night,
          litMemberIds: {
            for (final k in lightings.keys)
              if (k.endsWith('_$night')) k.substring(0, k.lastIndexOf('_')),
          },
          nudgesToMe: [
            for (final n in nudges)
              if (n['to'] == _userId && n['night'] == night)
                n['fromName'] as String,
          ],
          nudgedByMe: {
            for (final n in nudges)
              if (n['from'] == _userId && n['night'] == night) n['to'] as String,
          },
        );
      });

  @override
  Future<Group> createGroup({
    required String name,
    required String emoji,
    required int hebrewYear,
    required String myName,
  }) async {
    final id = _newId();
    _groups[id] = <String, dynamic>{
      'name': name,
      'emoji': emoji,
      'code': InviteCodes.generate(_random),
      'ownerId': _userId,
      'year': hebrewYear,
      'members': <dynamic>[
        <String, dynamic>{'id': _userId, 'name': myName}
      ],
      'lightings': <String, dynamic>{},
      'nudges': <dynamic>[],
    };
    await _save();
    return _group(id);
  }

  @override
  Future<Group?> joinByCode(String code, {required String myName}) async {
    final normalized = InviteCodes.normalize(code);
    for (final e in _groups.entries) {
      final g = e.value as Map<String, dynamic>;
      if (g['code'] == normalized) {
        if (!_isMember(g)) {
          (g['members'] as List).add({'id': _userId, 'name': myName});
          await _save();
        }
        return _group(e.key);
      }
    }
    return null;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final g = _groups[groupId] as Map<String, dynamic>?;
    if (g == null) return;
    (g['members'] as List).removeWhere((m) => m['id'] == _userId);
    if ((g['members'] as List).isEmpty || g['ownerId'] == _userId) {
      _groups.remove(groupId);
    }
    await _save();
  }

  @override
  Future<void> renameGroup(String groupId, String name) async {
    final g = _groups[groupId] as Map<String, dynamic>?;
    if (g == null) return;
    g['name'] = name;
    await _save();
  }

  @override
  Future<void> recordLighting({
    required int hebrewYear,
    required int night,
    required int light,
  }) async {
    var changed = false;
    for (final g in _groups.values.cast<Map<String, dynamic>>()) {
      if (g['year'] != hebrewYear || !_isMember(g)) continue;
      final lightings =
          (g['lightings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      g['lightings'] = lightings;
      lightings.putIfAbsent('${_userId}_$night', () {
        changed = true;
        return light;
      });
    }
    if (changed) await _save();
  }

  @override
  Future<void> sendNudge({
    required String groupId,
    required String toUserId,
    required int night,
    required String myName,
  }) async {
    final g = _groups[groupId] as Map<String, dynamic>?;
    if (g == null) return;
    final nudges = (g['nudges'] as List?) ?? <dynamic>[];
    g['nudges'] = nudges;
    final exists = nudges.any((n) =>
        n['from'] == _userId && n['to'] == toUserId && n['night'] == night);
    if (exists) return;
    nudges.add({
      'from': _userId,
      'fromName': myName,
      'to': toUserId,
      'night': night,
    });
    await _save();
  }

  HostInvite _invite(String id) {
    final i = _invites[id] as Map<String, dynamic>;
    final rsvps = (i['rsvps'] as Map<String, dynamic>? ?? {});
    return HostInvite(
      id: id,
      hostId: i['hostId'] as String,
      hostName: i['hostName'] as String,
      hebrewYear: i['year'] as int,
      night: i['night'] as int,
      time: i['time'] as String,
      note: i['note'] as String,
      rsvps: {
        for (final e in rsvps.entries)
          e.key: (
            name: (e.value as Map)['name'] as String,
            status: RsvpStatus.values.byName((e.value as Map)['status'] as String),
          ),
      },
    );
  }

  @override
  Future<HostInvite> createInvite({
    required int hebrewYear,
    required int night,
    required String time,
    required String note,
    required String myName,
  }) async {
    final id = _newId();
    _invites[id] = <String, dynamic>{
      'hostId': _userId,
      'hostName': myName,
      'year': hebrewYear,
      'night': night,
      'time': time,
      'note': note,
      'rsvps': <String, dynamic>{},
    };
    await _save();
    return _invite(id);
  }

  @override
  Stream<List<HostInvite>> watchMyInvites(int hebrewYear) => _watch(() => [
        for (final e in _invites.entries)
          if ((e.value as Map)['year'] == hebrewYear &&
              ((e.value as Map)['hostId'] == _userId ||
                  _joinedInvites.contains(e.key)))
            _invite(e.key),
      ]..sort((a, b) => a.night.compareTo(b.night)));

  @override
  Stream<HostInvite?> watchInvite(String inviteId) {
    if (_invites.containsKey(inviteId) && !_joinedInvites.contains(inviteId)) {
      final host = (_invites[inviteId] as Map)['hostId'];
      if (host != _userId) {
        _joinedInvites.add(inviteId);
        unawaited(_save());
      }
    }
    return _watch(() =>
        _invites.containsKey(inviteId) ? _invite(inviteId) : null);
  }

  @override
  Future<void> rsvp({
    required String inviteId,
    required RsvpStatus status,
    required String myName,
  }) async {
    final i = _invites[inviteId] as Map<String, dynamic>?;
    if (i == null) return;
    final rsvps = (i['rsvps'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    i['rsvps'] = rsvps;
    rsvps[_userId] = {'name': myName, 'status': status.name};
    if (!_joinedInvites.contains(inviteId) && i['hostId'] != _userId) {
      _joinedInvites.add(inviteId);
    }
    await _save();
  }

  @override
  Future<void> deleteInvite(String inviteId) async {
    _invites.remove(inviteId);
    _joinedInvites.remove(inviteId);
    await _save();
  }

  @override
  Future<void> deleteEverything() async {
    await _prefs.remove(_key);
    _load();
    _changes.add(null);
  }
}
