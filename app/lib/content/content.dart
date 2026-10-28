import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/user_profile.dart';

class Blessing {
  const Blessing({
    required this.id,
    required this.firstNightOnly,
    required this.text,
    required this.transliteration,
    required this.meaning,
    this.variantNote,
  });

  final String id;
  final bool firstNightOnly;
  final Map<Nusach, String> text;
  final String transliteration;
  final String meaning;
  final String? variantNote;

  String textFor(Nusach nusach) =>
      text[nusach] ?? text[Nusach.unknown] ?? text.values.first;
}

class Song {
  const Song(
      {required this.id,
      required this.title,
      required this.when,
      required this.text});
  final String id;
  final String title;
  final String when;
  final String text;
}

class FaqItem {
  const FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

/// All reviewable text, loaded from assets/content/*.json (Vision, ch. 32).
class ContentBook {
  ContentBook({
    required Map<String, dynamic> blessings,
    required Map<String, dynamic> songs,
    required Map<String, dynamic> faq,
    required Map<String, dynamic> messages,
    Random? random,
  })  : _messages = messages,
        _random = random ?? Random(),
        reviewed = (blessings['reviewed'] == true) &&
            (songs['reviewed'] == true) &&
            (faq['reviewed'] == true) &&
            (messages['reviewed'] == true),
        blessingList = [
          for (final b in (blessings['blessings'] as List))
            Blessing(
              id: b['id'] as String,
              firstNightOnly: b['nights'] == 'first',
              text: {
                for (final e in (b['text'] as Map<String, dynamic>).entries)
                  Nusach.values.byName(e.key): e.value as String,
              },
              transliteration: b['transliteration'] as String,
              meaning: b['meaning'] as String,
              variantNote: b['variantNote'] as String?,
            ),
        ],
        lightingOrder =
            Map<String, String>.from(blessings['order'] as Map<String, dynamic>),
        safety = blessings['safety'] as String,
        songList = [
          for (final s in (songs['songs'] as List))
            Song(
              id: s['id'] as String,
              title: s['title'] as String,
              when: s['when'] as String,
              text: s['text'] as String,
            ),
        ],
        faqList = [
          for (final f in (faq['faq'] as List))
            FaqItem(f['q'] as String, f['a'] as String),
        ];

  static Future<ContentBook> load() async {
    Future<Map<String, dynamic>> read(String name) async =>
        jsonDecode(await rootBundle.loadString('assets/content/$name.json'))
            as Map<String, dynamic>;
    return ContentBook(
      blessings: await read('blessings'),
      songs: await read('songs'),
      faq: await read('faq'),
      messages: await read('messages'),
    );
  }

  final Map<String, dynamic> _messages;
  final Random _random;

  /// True only when every content file is marked as reviewed.
  final bool reviewed;

  final List<Blessing> blessingList;
  final Map<String, String> lightingOrder;
  final String safety;
  final List<Song> songList;
  final List<FaqItem> faqList;

  List<Blessing> blessingsForNight(int night) =>
      blessingList.where((b) => !b.firstNightOnly || night == 1).toList();

  String get appLink => _messages['appLink'] as String? ?? '';

  /// Looks up a dotted [path] in messages.json, picks the address form and
  /// fills {variables}.
  String text(
    String path, {
    AddressForm form = AddressForm.plural,
    Map<String, Object?> vars = const {},
    int? index,
  }) {
    Object? node = _messages;
    for (final part in path.split('.')) {
      if (node is Map<String, dynamic>) {
        node = node[part];
      } else {
        node = null;
      }
    }
    return fill(_resolve(node, form, index), vars);
  }

  /// A random line from an array in messages.json, avoiding [exclude].
  String randomLine(String path, {Set<int> exclude = const {}}) {
    final list = (_messages[path] as List).cast<String>();
    final options = [
      for (var i = 0; i < list.length; i++)
        if (!exclude.contains(i)) i
    ];
    final pick = options.isEmpty
        ? _random.nextInt(list.length)
        : options[_random.nextInt(options.length)];
    return list[pick];
  }

  String _resolve(Object? node, AddressForm form, int? index) {
    if (node == null) return '';
    if (node is String) return node;
    if (node is List) {
      if (node.isEmpty) return '';
      final i = index ?? _random.nextInt(node.length);
      return _resolve(node[i.clamp(0, node.length - 1)], form, null);
    }
    if (node is Map<String, dynamic>) {
      final key = switch (form) {
        AddressForm.male => 'm',
        AddressForm.female => 'f',
        AddressForm.plural => 'p',
      };
      return _resolve(node[key] ?? node['p'] ?? node.values.first, form, index);
    }
    return node.toString();
  }

  static String fill(String template, Map<String, Object?> vars) {
    var out = template;
    vars.forEach((k, v) => out = out.replaceAll('{$k}', '${v ?? ''}'));
    return out;
  }
}
