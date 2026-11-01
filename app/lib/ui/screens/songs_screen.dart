import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/chords.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// After lighting: הנרות הללו, מעוז צור (with chords), מזמור שיר.
class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key, this.initialSongId = 'maoz_tzur'});
  final String initialSongId;

  @override
  ConsumerState<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> {
  late String _songId = widget.initialSongId;
  bool _chords = true;
  int _transpose = 0;

  static const _letters = 'אבגדהוזחטי';
  static const _short = {
    'hanerot_halalu': 'הנרות הללו',
    'maoz_tzur': 'מעוז צור',
    'mizmor_shir': 'מזמור שיר',
  };

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final songs = content.songList;
    final song = songs.firstWhere((s) => s.id == _songId,
        orElse: () => songs.first);
    final showChords = _chords && song.hasChords;

    return Scaffold(
      backgroundColor: AppColors.skyDeep,
      appBar: AppBar(
        actions: [UnreviewedMark(reviewed: content.reviewed)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in songs)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(_short[s.id] ?? s.title),
                      selected: s.id == song.id,
                      onSelected: (_) => setState(() => _songId = s.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(song.title, style: AppText.display),
          const SizedBox(height: 6),
          Text(song.when, style: AppText.small),
          if (song.hasChords) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                FilterChip(
                  label: const Text('אקורדים'),
                  selected: _chords,
                  onSelected: (v) => setState(() => _chords = v),
                ),
                const Spacer(),
                if (showChords)
                  _KeyControl(
                    keyName: Chords.keyName(song.key!, _transpose),
                    onDown: () => setState(() => _transpose--),
                    onUp: () => setState(() => _transpose++),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < song.stanzas.length; i++)
            _Stanza(
              label: song.stanzas.length > 1 ? _letters[i] : null,
              lines: song.stanzas[i],
              chords: showChords,
              transpose: _transpose,
              repeatLast: song.repeatLast,
            ),
          if (song.variantNote != null) ...[
            const SizedBox(height: 20),
            Text(song.variantNote!, style: AppText.small.copyWith(fontSize: 13)),
          ],
          if (song.hasChords) ...[
            const SizedBox(height: 8),
            Text('האקורדים בהרמוניה פשוטה, נוחה לגיטרה ולפסנתר.',
                style: AppText.small.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _KeyControl extends StatelessWidget {
  const _KeyControl({required this.keyName, required this.onDown, required this.onUp});
  final String keyName;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    // Left to right on purpose: lower on the left, higher on the right,
    // like a keyboard.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'סולם נמוך יותר',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, size: 18),
              onPressed: onDown,
            ),
            SizedBox(
              width: 34,
              child: Text(keyName,
                  textAlign: TextAlign.center,
                  semanticsLabel: 'סולם $keyName',
                  style: AppText.chord.copyWith(fontSize: 16)),
            ),
            IconButton(
              tooltip: 'סולם גבוה יותר',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 18),
              onPressed: onUp,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stanza extends StatelessWidget {
  const _Stanza({
    required this.label,
    required this.lines,
    required this.chords,
    required this.transpose,
    required this.repeatLast,
  });

  final String? label;
  final List<String> lines;
  final bool chords;
  final int transpose;
  final bool repeatLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(label!,
                  style: const TextStyle(
                      fontFamily: AppText.serif,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brass)),
            ),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: chords ? 6 : 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: chords
                        ? ChordLine(line: lines[i], transpose: transpose)
                        : Text(Chords.strip(lines[i]), style: AppText.lyric),
                  ),
                  if (repeatLast && i == lines.length - 1) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('(פעמיים)', style: AppText.small.copyWith(fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One lyric line with chords floating above the syllable they start on.
class ChordLine extends StatelessWidget {
  const ChordLine({super.key, required this.line, this.transpose = 0});
  final String line;
  final int transpose;

  @override
  Widget build(BuildContext context) {
    final segments = Chords.parse(line);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final s in segments)
          Padding(
            padding: EdgeInsetsDirectional.only(end: s.text.endsWith(' ') ? 6 : 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 18,
                  child: s.chord == null
                      ? null
                      : Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: Text(
                            Chords.transpose(s.chord!, transpose),
                            textDirection: TextDirection.ltr,
                            style: AppText.chord,
                          ),
                        ),
                ),
                Text(s.text.trimRight(), style: AppText.lyric),
              ],
            ),
          ),
      ],
    );
  }
}
