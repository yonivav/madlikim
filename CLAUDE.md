# מדליקים — notes for Claude Code

Hebrew Hanukkah app for traditional Israelis: daily lighting reminders, points, blessings with
explanations, Maoz Tzur with chords, and a social layer. Flutter (iOS + Android). The full spec is
`docs/VISION.md` (Part A = product, Part B = technical spec); read the relevant chapter before changing
behavior.

## Working with the owner
- Talk to Yoni in Hebrew. Short, direct instructions. No em dashes, no AI-sounding phrasing, light humor is welcome.
- Commit messages in English.

## Layout
- `app/` Flutter app. `app/tool/setup.sh` generates the platform folders (`flutter create`), patches them
  (`patch_platforms.py`), and makes icons/splash. Run it once after cloning, from the repo root.
- `app/lib/core/` Hebrew calendar, sun times, zmanim, Hanukkah season, app phases (Shabbat always wins).
- `app/lib/ui/theme.dart` design tokens plus the glossy material: `Gloss` decorations and `GlossBox`
  (round shapes only, soft shadows, no ink outlines except on characters).
- `app/lib/ui/widgets/neri.dart` the candle character ("נרי"): colors, builds, patterns, moods, arms.
  `my_neri.dart` = the user's chosen character (6 options, default apricot-orange "נרי").
- `app/lib/ui/widgets/lighting_show.dart` "העברת האש": the animation after "הדלקתי". `ShowTimeline` is a
  pure function mirrored 1:1 by `docs/design/neri/show.js`; change both together.
- `app/assets/content/*.json` all texts (blessings, songs, FAQ, messages). Character lines live in
  `messages.json` under `neri` (masculine) and `neriF` (feminine), with `{buddy}`.
- `docs/design/neri/` HTML prototypes (render with Playwright), store screenshot generator `store.js`.

## Checks
- `cd app && flutter analyze --no-fatal-infos && flutter test`. CI (`.github/workflows/ci.yml`) runs the same
  plus an Android debug build.
- Nothing has been compiled yet as of the last cloud session (no Flutter SDK there). Expect some first-compile
  fixes; run analyze and test first.

## Open items
- First real compile and test run; simulator screenshots.
- Rabbi review of halachic content and a musician review of the chords (all content is `reviewed:false`).
- Replace `CONTACT_EMAIL` in `web/privacy/index.html`; reserve the name in App Store Connect; Firebase setup
  (`docs/FIREBASE.md`); domain decision; store submission target 24.11.
- Animation follow-ups (Vision 14.5ב): Shabbat candles on Friday nights, a night-8 finale, a soft "poof" sound.
