#!/usr/bin/env bash
# One-time setup: generates the android/ and ios/ folders and patches them.
# Run from anywhere:  bash app/tool/setup.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null; then
  echo "Flutter is not installed or not on PATH." >&2
  exit 1
fi

had_widget_test=0
[ -f test/widget_test.dart ] && had_widget_test=1

echo "==> Generating platform folders (existing files are kept)"
flutter create --platforms=android,ios --org app.madlikim --project-name madlikim .

# flutter create adds a counter-app test that does not compile against our app.
if [ "$had_widget_test" = 0 ] && [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

echo "==> Patching Android and iOS"
python3 tool/patch_platforms.py

echo "==> Getting packages"
flutter pub get

echo "==> App icon and splash screen"
dart run flutter_launcher_icons
dart run flutter_native_splash:create

echo
echo "Done. Next:"
echo "  flutter test        # run the tests"
echo "  flutter run         # run on a device or simulator"
echo "Optional: add Firebase (see docs/FIREBASE.md). Without it the app runs in local mode."
