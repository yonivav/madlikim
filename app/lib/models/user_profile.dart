import '../core/hanukkah.dart';
import '../core/place.dart';

enum AddressForm { male, female, plural }

enum Nusach { sefard, ashkenaz, unknown }

enum HouseholdMode { everyone, oneForAll }

enum ReminderMode { sunset, tzeit, fixed }

class ReminderSettings {
  const ReminderSettings({
    this.mode = ReminderMode.sunset,
    this.fixedHour = 18,
    this.fixedMinute = 0,
    this.secondReminder = true,
  });

  final ReminderMode mode;
  final int fixedHour;
  final int fixedMinute;
  final bool secondReminder;

  LightingStart get lightingStart =>
      mode == ReminderMode.tzeit ? LightingStart.tzeit : LightingStart.sunset;

  ReminderSettings copyWith({
    ReminderMode? mode,
    int? fixedHour,
    int? fixedMinute,
    bool? secondReminder,
  }) =>
      ReminderSettings(
        mode: mode ?? this.mode,
        fixedHour: fixedHour ?? this.fixedHour,
        fixedMinute: fixedMinute ?? this.fixedMinute,
        secondReminder: secondReminder ?? this.secondReminder,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'fixedHour': fixedHour,
        'fixedMinute': fixedMinute,
        'secondReminder': secondReminder,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      ReminderSettings(
        mode: ReminderMode.values.byName(json['mode'] as String? ?? 'sunset'),
        fixedHour: json['fixedHour'] as int? ?? 18,
        fixedMinute: json['fixedMinute'] as int? ?? 0,
        secondReminder: json['secondReminder'] as bool? ?? true,
      );
}

class UserProfile {
  const UserProfile({
    required this.displayName,
    this.addressForm = AddressForm.plural,
    this.nusach = Nusach.unknown,
    this.householdMode = HouseholdMode.everyone,
    this.place = Cities.telAviv,
    this.reminders = const ReminderSettings(),
    this.showTransliteration = false,
    this.neriId = 'neri',
  });

  final String displayName;

  /// Which candle character the user picked (see NeriCharacter.all).
  final String neriId;
  final AddressForm addressForm;
  final Nusach nusach;
  final HouseholdMode householdMode;
  final Place place;
  final ReminderSettings reminders;
  final bool showTransliteration;

  UserProfile copyWith({
    String? displayName,
    AddressForm? addressForm,
    Nusach? nusach,
    HouseholdMode? householdMode,
    Place? place,
    ReminderSettings? reminders,
    bool? showTransliteration,
    String? neriId,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        addressForm: addressForm ?? this.addressForm,
        nusach: nusach ?? this.nusach,
        householdMode: householdMode ?? this.householdMode,
        place: place ?? this.place,
        reminders: reminders ?? this.reminders,
        showTransliteration: showTransliteration ?? this.showTransliteration,
        neriId: neriId ?? this.neriId,
      );

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'addressForm': addressForm.name,
        'nusach': nusach.name,
        'householdMode': householdMode.name,
        'place': place.toJson(),
        'reminders': reminders.toJson(),
        'showTransliteration': showTransliteration,
        'neriId': neriId,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        displayName: json['displayName'] as String? ?? '',
        addressForm: AddressForm.values
            .byName(json['addressForm'] as String? ?? 'plural'),
        nusach: Nusach.values.byName(json['nusach'] as String? ?? 'unknown'),
        householdMode: HouseholdMode.values
            .byName(json['householdMode'] as String? ?? 'everyone'),
        place: json['place'] is Map<String, dynamic>
            ? Place.fromJson(json['place'] as Map<String, dynamic>)
            : Cities.telAviv,
        reminders: json['reminders'] is Map<String, dynamic>
            ? ReminderSettings.fromJson(
                json['reminders'] as Map<String, dynamic>)
            : const ReminderSettings(),
        showTransliteration: json['showTransliteration'] as bool? ?? false,
        neriId: json['neriId'] as String? ?? 'neri',
      );
}
