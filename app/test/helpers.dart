import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:madlikim/content/content.dart';

/// Loads the real content files from disk (tests run from app/).
ContentBook loadContent() {
  Map<String, dynamic> read(String name) =>
      jsonDecode(File('assets/content/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  return ContentBook(
    blessings: read('blessings'),
    songs: read('songs'),
    faq: read('faq'),
    messages: read('messages'),
    random: Random(1),
  );
}
