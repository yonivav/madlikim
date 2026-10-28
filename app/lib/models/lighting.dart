/// One night the user marked as lit.
class LightingRecord {
  const LightingRecord({
    required this.hebrewYear,
    required this.night,
    required this.markedAt,
    this.withGuests = false,
    this.late = false,
  });

  final int hebrewYear;
  final int night;
  final DateTime markedAt;
  final bool withGuests;

  /// Marked with "שכחתי לסמן" after the night's window closed.
  final bool late;

  Map<String, dynamic> toJson() => {
        'hebrewYear': hebrewYear,
        'night': night,
        'markedAt': markedAt.toUtc().toIso8601String(),
        'withGuests': withGuests,
        'late': late,
      };

  factory LightingRecord.fromJson(Map<String, dynamic> json) => LightingRecord(
        hebrewYear: json['hebrewYear'] as int,
        night: json['night'] as int,
        markedAt: DateTime.parse(json['markedAt'] as String),
        withGuests: json['withGuests'] as bool? ?? false,
        late: json['late'] as bool? ?? false,
      );
}
