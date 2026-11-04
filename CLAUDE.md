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
- Compiles and runs now (iOS simulator and Android debug build both verified). CI is green on `main`.

## Store readiness (see `docs/STORE.md` for the full checklist)
- Done: CI green, `CONTACT_EMAIL` replaced, privacy page live at `https://yonivav.github.io/madlikim/privacy/`
  (repo is now public, deployed via `.github/workflows/pages.yml`), Android release signing wired up
  (`android/app/build.gradle.kts` reads `android/key.properties`, gitignored; the actual keystore lives at
  `~/madlikim-signing/` outside the repo — back it up, losing it means losing the ability to update the app).
- Still needs the owner directly (can't be done from here): Apple Developer Program enrollment + signing in to
  App Store Connect (Apple ID + 2FA); declaring "trader status" on the existing Google Play Console account
  ("Leshem Shamaim") and creating the app there; sending `docs/review/rabbi.pdf` /
  `docs/review/musician.pdf` for halachic/musical review (all content is `reviewed:false` until then);
  testing on a real iPhone and Android device (notifications especially — simulators are unreliable for this).
- Real screenshots: app runs on the iPhone 16 Pro Max simulator now; still need to tap through and capture the
  5 screens STORE.md lists (placeholders in `docs/store/` otherwise).
- Firebase is optional and NOT required for submission — `main.dart` falls back to local-only mode when it's
  not configured, which is the current state. Only set it up (`docs/FIREBASE.md`) if shipping shared menorahs
  in v1.
- Target: submission by 24.11.
- Animation follow-ups (Vision 14.5ב): Shabbat candles on Friday nights, a night-8 finale, a soft "poof" sound.
