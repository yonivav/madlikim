/// ChordPro-style lines ("[D]מָעוֹז [G]צוּר") and transposition.
library;

class ChordSegment {
  const ChordSegment(this.chord, this.text);

  /// Null when this piece of text has no chord above it.
  final String? chord;
  final String text;

  @override
  String toString() => '[$chord]$text';
}

class Chords {
  static final _token = RegExp(r'\[([^\]]+)\]');

  /// Splits a line into segments, each with the chord that starts it.
  static List<ChordSegment> parse(String line) {
    final out = <ChordSegment>[];
    var pos = 0;
    String? pending;
    for (final m in _token.allMatches(line)) {
      final text = line.substring(pos, m.start);
      if (text.isNotEmpty || pending != null) out.add(ChordSegment(pending, text));
      pending = m.group(1);
      pos = m.end;
    }
    final rest = line.substring(pos);
    if (rest.isNotEmpty || pending != null) out.add(ChordSegment(pending, rest));
    return out;
  }

  /// The line without chord marks.
  static String strip(String line) => line.replaceAll(_token, '');

  static bool hasChords(String line) => _token.hasMatch(line);

  static const _sharps = [
    'C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B' //
  ];
  static const _index = {
    'C': 0, 'B#': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3, 'E': 4,
    'Fb': 4, 'F': 5, 'E#': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8, 'Ab': 8,
    'A': 9, 'A#': 10, 'Bb': 10, 'B': 11, 'Cb': 11,
  };
  static final _root = RegExp(r'^([A-G][#b]?)(.*)$');

  static String _note(String note, int steps) {
    final i = _index[note];
    if (i == null) return note;
    return _sharps[((i + steps) % 12 + 12) % 12];
  }

  /// Transposes one chord ("F#m7", "D/F#") by [steps] semitones.
  static String transpose(String chord, int steps) {
    if (steps % 12 == 0) return chord;
    final parts = chord.split('/');
    final out = <String>[];
    for (final p in parts) {
      final m = _root.firstMatch(p);
      out.add(m == null ? p : _note(m.group(1)!, steps) + m.group(2)!);
    }
    return out.join('/');
  }

  /// Name of the key [baseKey] moved by [steps] semitones.
  static String keyName(String baseKey, int steps) => transpose(baseKey, steps);
}
