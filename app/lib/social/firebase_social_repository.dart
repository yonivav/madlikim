import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'social_models.dart';
import 'social_repository.dart';

/// Firestore layout (Vision, chapter 34.2):
///
/// groups/{groupId}
///   name, emoji, ownerId, inviteCode, year, totalLight,
///   memberIds: [uid], memberNames: {uid: name}, createdAt
/// groups/{groupId}/lightings/{uid_night}   uid, night, light, markedAt
/// groups/{groupId}/nudges/{from_to_night}  from, fromName, to, night, sentAt
/// inviteCodes/{code}                       groupId
/// invites/{inviteId}
///   hostId, hostName, year, night, time, note, createdAt,
///   rsvps: {uid: {name, status}}
class FirebaseSocialRepository implements SocialRepository {
  FirebaseSocialRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Invite ids opened on this device (not hosted by me).
  final Set<String> _joinedInvites = {};

  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');

  @override
  bool get isRemote => true;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  @override
  Future<String> ensureUser() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
    return user!.uid;
  }

  Group _groupFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final names = Map<String, dynamic>.from(d['memberNames'] as Map? ?? {});
    final ids = List<String>.from(d['memberIds'] as List? ?? const []);
    return Group(
      id: doc.id,
      name: d['name'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '🕎',
      inviteCode: d['inviteCode'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      hebrewYear: d['year'] as int? ?? 0,
      totalLight: (d['totalLight'] as num?)?.toInt() ?? 0,
      members: [
        for (final id in ids)
          GroupMember(id: id, name: names[id] as String? ?? '?'),
      ],
    );
  }

  @override
  Stream<List<Group>> watchMyGroups(int hebrewYear) => _groups
      .where('memberIds', arrayContains: _uid)
      .where('year', isEqualTo: hebrewYear)
      .snapshots()
      .map((s) => s.docs.map(_groupFrom).toList());

  @override
  Stream<GroupNight> watchGroupNight(String groupId, int night) {
    final groupRef = _groups.doc(groupId);
    final uid = _uid;
    DocumentSnapshot<Map<String, dynamic>>? group;
    QuerySnapshot<Map<String, dynamic>>? lightings;
    QuerySnapshot<Map<String, dynamic>>? nudges;
    final subs = <StreamSubscription<dynamic>>[];
    late final StreamController<GroupNight> controller;

    void emit() {
      if (group == null || lightings == null || nudges == null) return;
      controller.add(GroupNight(
        group: _groupFrom(group!),
        night: night,
        litMemberIds: {
          for (final d in lightings!.docs) d.data()['uid'] as String,
        },
        nudgesToMe: [
          for (final d in nudges!.docs)
            if (d.data()['to'] == uid) d.data()['fromName'] as String? ?? '',
        ],
        nudgedByMe: {
          for (final d in nudges!.docs)
            if (d.data()['from'] == uid) d.data()['to'] as String,
        },
      ));
    }

    controller = StreamController<GroupNight>(
      onListen: () {
        subs
          ..add(groupRef.snapshots().listen((s) {
            group = s;
            emit();
          }, onError: controller.addError))
          ..add(groupRef
              .collection('lightings')
              .where('night', isEqualTo: night)
              .snapshots()
              .listen((s) {
            lightings = s;
            emit();
          }, onError: controller.addError))
          ..add(groupRef
              .collection('nudges')
              .where('night', isEqualTo: night)
              .snapshots()
              .listen((s) {
            nudges = s;
            emit();
          }, onError: controller.addError));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<Group> createGroup({
    required String name,
    required String emoji,
    required int hebrewYear,
    required String myName,
  }) async {
    final uid = await ensureUser();
    final ref = _groups.doc();
    String code;
    // Pick a code that is free. Collisions are very unlikely (31^6).
    do {
      code = InviteCodes.generate();
    } while ((await _db.collection('inviteCodes').doc(code).get()).exists);

    final batch = _db.batch();
    batch.set(ref, {
      'name': name,
      'emoji': emoji,
      'ownerId': uid,
      'inviteCode': code,
      'year': hebrewYear,
      'totalLight': 0,
      'memberIds': [uid],
      'memberNames': {uid: myName},
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('inviteCodes').doc(code), {'groupId': ref.id});
    await batch.commit();
    return _groupFrom(await ref.get());
  }

  @override
  Future<Group?> joinByCode(String code, {required String myName}) async {
    final uid = await ensureUser();
    final normalized = InviteCodes.normalize(code);
    if (!InviteCodes.isValid(normalized)) return null;
    final codeDoc =
        await _db.collection('inviteCodes').doc(normalized).get();
    if (!codeDoc.exists) return null;
    final groupId = codeDoc.data()!['groupId'] as String;
    final ref = _groups.doc(groupId);
    await ref.update({
      'memberIds': FieldValue.arrayUnion([uid]),
      'memberNames.$uid': myName,
    });
    return _groupFrom(await ref.get());
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    final uid = _uid;
    final ref = _groups.doc(groupId);
    final snap = await ref.get();
    if (!snap.exists) return;
    if (snap.data()!['ownerId'] == uid) {
      final code = snap.data()!['inviteCode'] as String?;
      final batch = _db.batch()..delete(ref);
      if (code != null) batch.delete(_db.collection('inviteCodes').doc(code));
      await batch.commit();
    } else {
      await ref.update({
        'memberIds': FieldValue.arrayRemove([uid]),
        'memberNames.$uid': FieldValue.delete(),
      });
    }
  }

  @override
  Future<void> renameGroup(String groupId, String name) =>
      _groups.doc(groupId).update({'name': name});

  @override
  Future<void> recordLighting({
    required int hebrewYear,
    required int night,
    required int light,
  }) async {
    final uid = await ensureUser();
    final groups = await _groups
        .where('memberIds', arrayContains: uid)
        .where('year', isEqualTo: hebrewYear)
        .get();
    for (final g in groups.docs) {
      final lightingRef = g.reference.collection('lightings').doc('${uid}_$night');
      await _db.runTransaction((tx) async {
        final existing = await tx.get(lightingRef);
        if (existing.exists) return;
        tx.set(lightingRef, {
          'uid': uid,
          'night': night,
          'light': light,
          'markedAt': FieldValue.serverTimestamp(),
        });
        tx.update(g.reference, {'totalLight': FieldValue.increment(light)});
      });
    }
  }

  @override
  Future<void> sendNudge({
    required String groupId,
    required String toUserId,
    required int night,
    required String myName,
  }) async {
    final uid = _uid;
    await _groups
        .doc(groupId)
        .collection('nudges')
        .doc('${uid}_${toUserId}_$night')
        .set({
      'from': uid,
      'fromName': myName,
      'to': toUserId,
      'night': night,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  HostInvite? _inviteFrom(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null) return null;
    final rsvps = Map<String, dynamic>.from(d['rsvps'] as Map? ?? {});
    return HostInvite(
      id: doc.id,
      hostId: d['hostId'] as String? ?? '',
      hostName: d['hostName'] as String? ?? '',
      hebrewYear: d['year'] as int? ?? 0,
      night: d['night'] as int? ?? 1,
      time: d['time'] as String? ?? '',
      note: d['note'] as String? ?? '',
      rsvps: {
        for (final e in rsvps.entries)
          e.key: (
            name: (e.value as Map)['name'] as String? ?? '',
            status: RsvpStatus.values
                .byName((e.value as Map)['status'] as String? ?? 'maybe'),
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
    final uid = await ensureUser();
    final ref = _invites.doc();
    await ref.set({
      'hostId': uid,
      'hostName': myName,
      'year': hebrewYear,
      'night': night,
      'time': time,
      'note': note,
      'rsvps': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return _inviteFrom(await ref.get())!;
  }

  @override
  Stream<List<HostInvite>> watchMyInvites(int hebrewYear) => _invites
          .where('hostId', isEqualTo: _uid)
          .where('year', isEqualTo: hebrewYear)
          .snapshots()
          .asyncMap((s) async {
        final hosted = s.docs.map(_inviteFrom).whereType<HostInvite>().toList();
        final joined = <HostInvite>[];
        for (final id in _joinedInvites) {
          final i = _inviteFrom(await _invites.doc(id).get());
          if (i != null && i.hebrewYear == hebrewYear) joined.add(i);
        }
        return [...hosted, ...joined]..sort((a, b) => a.night.compareTo(b.night));
      });

  @override
  Stream<HostInvite?> watchInvite(String inviteId) {
    _joinedInvites.add(inviteId);
    return _invites.doc(inviteId).snapshots().map(_inviteFrom);
  }

  @override
  Future<void> rsvp({
    required String inviteId,
    required RsvpStatus status,
    required String myName,
  }) async {
    final uid = await ensureUser();
    await _invites.doc(inviteId).update({
      'rsvps.$uid': {'name': myName, 'status': status.name},
    });
  }

  @override
  Future<void> deleteInvite(String inviteId) => _invites.doc(inviteId).delete();

  @override
  Future<void> deleteEverything() async {
    final uid = currentUserId;
    if (uid == null) return;
    final groups = await _groups.where('memberIds', arrayContains: uid).get();
    for (final g in groups.docs) {
      await leaveGroup(g.id);
    }
    final invites = await _invites.where('hostId', isEqualTo: uid).get();
    for (final i in invites.docs) {
      await i.reference.delete();
    }
    await _auth.currentUser?.delete();
    await _auth.signOut();
  }
}
