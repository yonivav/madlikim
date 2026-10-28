import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/core/hebrew_numerals.dart';
import 'package:madlikim/links/deep_links.dart';
import 'package:madlikim/logic/scoring.dart';
import 'package:madlikim/models/lighting.dart';
import 'package:madlikim/models/user_profile.dart';
import 'package:madlikim/social/local_social_repository.dart';
import 'package:madlikim/social/social_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

LightingRecord rec(int night, {bool guests = false, bool late = false}) =>
    LightingRecord(
      hebrewYear: 5787,
      night: night,
      markedAt: DateTime.utc(2026, 12, 3 + night, 15),
      withGuests: guests,
      late: late,
    );

void main() {
  group('scoring', () {
    test('all eight nights alone = 36 light', () {
      final s = Scoring.summarize(
        records: [for (var n = 1; n <= 8; n++) rec(n)],
        fridayNights: {1, 8},
        friendsJoined: 0,
      );
      expect(s.light, 36);
      expect(s.nightsLit, 8);
      expect(s.currentStreak, 8);
      expect(s.badges, containsAll([
        Achievement.firstLight,
        Achievement.halfMenorah,
        Achievement.fullMenorah,
        Achievement.erevShabbat,
      ]));
    });

    test('guests and friends add bonuses', () {
      final s = Scoring.summarize(
        records: [rec(1), rec(2, guests: true)],
        fridayNights: const {},
        friendsJoined: 3,
      );
      expect(s.light, 1 + 2 + Scoring.guestsBonus + 3 * Scoring.friendJoinedBonus);
      expect(s.badges, containsAll([Achievement.openHouse, Achievement.bringsFriends]));
    });

    test('streak: a missed night resets quietly; tonight not yet lit is fine', () {
      final records = [rec(1), rec(2), rec(4), rec(5)];
      expect(
          Scoring.summarize(
                  records: records,
                  fridayNights: const {},
                  friendsJoined: 0,
                  lastStartedNight: 6)
              .currentStreak,
          2);
      expect(
          Scoring.summarize(
                  records: records,
                  fridayNights: const {},
                  friendsJoined: 0,
                  lastStartedNight: 7)
              .currentStreak,
          0);
    });

    test('duplicate records for a night count once', () {
      final s = Scoring.summarize(
          records: [rec(3), rec(3)], fridayNights: const {}, friendsJoined: 0);
      expect(s.light, 3);
    });

    test('"not too late" only for real-time marks', () {
      expect(
          Scoring.summarize(
                  records: [rec(2)],
                  fridayNights: const {},
                  friendsJoined: 0,
                  localHourOf: (_) => 22)
              .badges,
          contains(Achievement.notTooLate));
      expect(
          Scoring.summarize(
                  records: [rec(2, late: true)],
                  fridayNights: const {},
                  friendsJoined: 0,
                  localHourOf: (_) => 22)
              .badges
              .contains(Achievement.notTooLate),
          isFalse);
    });
  });

  group('hebrew numerals', () {
    test('days', () {
      expect(hebrewNumeral(1), "א'");
      expect(hebrewNumeral(15), 'ט"ו');
      expect(hebrewNumeral(16), 'ט"ז');
      expect(hebrewNumeral(25), 'כ"ה');
      expect(hebrewNumeral(30), "ל'");
    });
  });

  group('deep links', () {
    test('https join link', () {
      final l = DeepLink.parse(Uri.parse('https://madlikim.app/j/k7m2qx'));
      expect(l, isA<JoinGroupLink>());
      expect((l as JoinGroupLink).code, 'K7M2QX');
    });
    test('custom scheme invite link', () {
      final l = DeepLink.parse(Uri.parse('madlikim://i/abc123'));
      expect((l as OpenInviteLink).inviteId, 'abc123');
    });
    test('unknown', () {
      expect(DeepLink.parse(Uri.parse('https://madlikim.app/about')), isNull);
    });
  });

  group('invite codes', () {
    test('generated codes are valid and avoid look-alikes', () {
      for (var i = 0; i < 200; i++) {
        final c = InviteCodes.generate();
        expect(InviteCodes.isValid(c), isTrue);
        expect(c.contains(RegExp('[01OIL]')), isFalse);
      }
    });
    test('normalize', () {
      expect(InviteCodes.normalize(' k7m-2qx '), 'K7M2QX');
    });
  });

  group('content', () {
    final content = loadContent();
    test('three blessings on night 1, two afterwards', () {
      expect(content.blessingsForNight(1).length, 3);
      expect(content.blessingsForNight(5).length, 2);
    });
    test('nusach variants', () {
      final b = content.blessingList.first;
      expect(b.textFor(Nusach.sefard), contains('שֶׁל'));
      expect(b.textFor(Nusach.ashkenaz).contains('שֶׁל'), isFalse);
    });
    test('address forms resolve', () {
      expect(content.text('notifications.eve.body', form: AddressForm.plural),
          startsWith('יש נרות'));
      expect(content.text('notifications.eve.body', form: AddressForm.male),
          startsWith('יש לך'));
    });
    test('no em dashes in user-facing text', () {
      for (final f in [
        content.text('share.group'),
        ...content.faqList.map((e) => e.answer),
      ]) {
        expect(f.contains('—'), isFalse);
      }
    });
  });

  group('local social repository', () {
    test('create, join, record lighting, nudge', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalSocialRepository(prefs);
      final me = await repo.ensureUser();

      final g = await repo.createGroup(
          name: 'משפחה', emoji: '🕎', hebrewYear: 5787, myName: 'אבי');
      expect(g.members.single.id, me);

      await repo.recordLighting(hebrewYear: 5787, night: 3, light: 3);
      await repo.recordLighting(hebrewYear: 5787, night: 3, light: 3);
      final groups = await repo.watchMyGroups(5787).first;
      expect(groups.single.totalLight, 3);

      final night = await repo.watchGroupNight(g.id, 3).first;
      expect(night.litMemberIds, {me});

      expect(await repo.joinByCode(g.inviteCode, myName: 'אבי'), isNotNull);
      expect(await repo.joinByCode('ZZZZZZ', myName: 'אבי'), isNull);

      final invite = await repo.createInvite(
          hebrewYear: 5787, night: 5, time: '17:30', note: '', myName: 'אבי');
      await repo.rsvp(
          inviteId: invite.id, status: RsvpStatus.yes, myName: 'אבי');
      final loaded = await repo.watchInvite(invite.id).first;
      expect(loaded!.count(RsvpStatus.yes), 1);

      // Survives a reload from storage.
      final again = LocalSocialRepository(prefs);
      expect(again.currentUserId, me);
      expect((await again.watchMyGroups(5787).first).single.name, 'משפחה');

      await again.deleteEverything();
      expect(await again.watchMyGroups(5787).first, isEmpty);
    });
  });
}
