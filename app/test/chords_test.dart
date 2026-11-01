import 'package:flutter_test/flutter_test.dart';
import 'package:madlikim/logic/chords.dart';

import 'helpers.dart';

void main() {
  test('parse a ChordPro line', () {
    final s = Chords.parse('[D]מָעוֹז [G]צוּר יְשׁוּעָ[A]תִי');
    expect(s.map((e) => e.chord).toList(), ['D', 'G', 'A']);
    expect(s.map((e) => e.text).join(), 'מָעוֹז צוּר יְשׁוּעָתִי');
  });

  test('text before the first chord keeps a null chord', () {
    final s = Chords.parse('אָז [G]בְּשִׁיר');
    expect(s.first.chord, isNull);
    expect(s.first.text, 'אָז ');
  });

  test('plain line', () {
    final s = Chords.parse('הַנֵּרוֹת הַלָּלוּ');
    expect(s.single.chord, isNull);
    expect(Chords.hasChords('הַנֵּרוֹת'), isFalse);
  });

  test('transpose', () {
    expect(Chords.transpose('D', 2), 'E');
    expect(Chords.transpose('D', -2), 'C');
    expect(Chords.transpose('A', 1), 'Bb');
    expect(Chords.transpose('F#m7', 1), 'Gm7');
    expect(Chords.transpose('D/F#', 5), 'G/B');
    expect(Chords.transpose('E', 12), 'E');
    expect(Chords.keyName('D', -7), 'G');
  });

  test('Maoz Tzur: 6 stanzas of 8 lines, chords in every line', () {
    final maoz =
        loadContent().songList.firstWhere((s) => s.id == 'maoz_tzur');
    expect(maoz.stanzas.length, 6);
    for (final st in maoz.stanzas) {
      expect(st.length, 8);
      for (final line in st) {
        expect(Chords.hasChords(line), isTrue, reason: line);
      }
    }
    expect(maoz.key, 'D');
  });
}
