/// A place we compute times for.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.timeZone = 'Asia/Jerusalem',
    this.candleLightingOffsetMinutes = 20,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  /// IANA time zone name, e.g. "Asia/Jerusalem".
  final String timeZone;

  /// Minutes before sunset for Shabbat candle lighting (local custom).
  final int candleLightingOffsetMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'timeZone': timeZone,
        'candleOffset': candleLightingOffsetMinutes,
      };

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timeZone: json['timeZone'] as String? ?? 'Asia/Jerusalem',
        candleLightingOffsetMinutes: json['candleOffset'] as int? ?? 20,
      );

  Place copyWith({String? name}) => Place(
        id: id,
        name: name ?? this.name,
        lat: lat,
        lng: lng,
        timeZone: timeZone,
        candleLightingOffsetMinutes: candleLightingOffsetMinutes,
      );
}

/// Common Israeli cities. Candle-lighting offsets follow the widespread local
/// custom (Jerusalem 40, Haifa 30, most other places 20). To be confirmed by
/// the reviewing rabbi.
class Cities {
  static const jerusalem = Place(
      id: 'jerusalem',
      name: 'ירושלים',
      lat: 31.7683,
      lng: 35.2137,
      candleLightingOffsetMinutes: 40);
  static const telAviv =
      Place(id: 'tel_aviv', name: 'תל אביב', lat: 32.0853, lng: 34.7818);

  static const all = <Place>[
    jerusalem,
    telAviv,
    Place(
        id: 'haifa',
        name: 'חיפה',
        lat: 32.7940,
        lng: 34.9896,
        candleLightingOffsetMinutes: 30),
    Place(id: 'ramat_gan', name: 'רמת גן', lat: 32.0684, lng: 34.8248),
    Place(id: 'petah_tikva', name: 'פתח תקווה', lat: 32.0840, lng: 34.8878),
    Place(id: 'bnei_brak', name: 'בני ברק', lat: 32.0807, lng: 34.8338),
    Place(id: 'rishon', name: 'ראשון לציון', lat: 31.9730, lng: 34.7925),
    Place(id: 'holon', name: 'חולון', lat: 32.0158, lng: 34.7874),
    Place(id: 'netanya', name: 'נתניה', lat: 32.3215, lng: 34.8532),
    Place(id: 'ashdod', name: 'אשדוד', lat: 31.8044, lng: 34.6553),
    Place(id: 'beer_sheva', name: 'באר שבע', lat: 31.2518, lng: 34.7913),
    Place(id: 'modiin', name: 'מודיעין', lat: 31.8980, lng: 35.0104),
    Place(id: 'kfar_saba', name: 'כפר סבא', lat: 32.1750, lng: 34.9070),
    Place(id: 'herzliya', name: 'הרצליה', lat: 32.1663, lng: 34.8433),
    Place(id: 'rehovot', name: 'רחובות', lat: 31.8928, lng: 34.8113),
    Place(id: 'beit_shemesh', name: 'בית שמש', lat: 31.7470, lng: 34.9881),
    Place(id: 'tiberias', name: 'טבריה', lat: 32.7922, lng: 35.5312),
    Place(id: 'safed', name: 'צפת', lat: 32.9646, lng: 35.4960),
    Place(id: 'eilat', name: 'אילת', lat: 29.5577, lng: 34.9519),
  ];

  static Place byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => telAviv);
}
