# פיתוח

## הרצה ראשונה

צריך Flutter 3.29 ומעלה, Xcode (ל-iOS) ו-Android Studio (לאנדרואיד).

```bash
bash app/tool/setup.sh
cd app
flutter test
flutter run
```

`setup.sh` מריץ `flutter create` כדי לייצר את התיקיות `android/` ו-`ios/` (הקוד ב-`lib/` לא נדרס), ואז מתקן אותן:

- **אנדרואיד:** הרשאות התראות ומיקום, receivers של flutter_local_notifications (תזכורות מתוזמנות ואחרי הפעלה מחדש), core library desugaring, `minSdk 23`, קישורי הזמנה (`madlikim.app/j/..`, `madlikim://`), והשם "מדליקים".
- **iOS:** טקסט להרשאת מיקום, סכמת `madlikim://`, עברית כשפת פיתוח, ו-delegate להתראות ב-AppDelegate.

אפשר להריץ שוב בלי חשש. הסקריפט לא משנה מה שכבר תוקן.

## מבנה

```
app/lib/
├── core/            לוח עברי, שמש, זמנים, חנוכה, מצבי האפליקציה. בלי Flutter, נבדק בטסטים
├── content/         קורא את assets/content/*.json
├── models/          פרופיל, הדלקה
├── logic/           אור, רצף, תגים
├── notifications/   מתכנן התראות (טהור) + עטיפה לפלאגין
├── social/          ממשק + מימוש מקומי + Firebase
├── data/            אחסון מקומי
├── links/           קישורי הזמנה
├── state/           Riverpod
└── ui/              מסכים ווידג'טים
```

## לבדוק תאריך אחר

כל הזמן באפליקציה עובר דרך `clockProvider`. כדי לראות את האפליקציה בליל שישי בחנוכה, אפשר לשנות זמנית ב-`main.dart`:

```dart
clockProvider.overrideWithValue(() => DateTime.utc(2026, 12, 7, 16)), // נר רביעי, 18:00 בישראל
```

הטסט `test/app_widget_test.dart` עושה בדיוק את זה.

## תוכן

כל הטקסטים שרב או כותב צריכים לעבור עליהם נמצאים ב-`app/assets/content/`. כשהרב מאשר קובץ, משנים בו `"reviewed": true`. בגרסת debug מופיע סימן אזהרה ליד תוכן שלא נבדק.

## מה לא נבדק בסביבה שבה נכתב הקוד

הקוד נכתב בסביבה בלי Flutter SDK, אז `flutter analyze` ו-`flutter test` עוד לא רצו עליו. החישובים (לוח עברי, שקיעה, תאריכי חנוכה 2024 עד 2030) אומתו בהרצה מקבילה ב-JavaScript מול תאריכים ידועים. **הצעד הראשון אצלך: `flutter analyze` ו-`flutter test`**, ולתקן את מה שיצוץ.
