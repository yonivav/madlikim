# מדליקים 🕎

אפליקציה שגורמת ליותר אנשים להדליק נרות חנוכה אמיתיים, כל ערב, עם חברים, בכיף. עם נרי, נר חנוכה קטן שמתרגש איתכם כל ערב 🕯️

- תזכורת בזמן הנכון, כולל שני ערבי השבת של תשפ"ז, ושקט מוחלט בשבת
- מסך הדלקה: איזה נרות, באיזה סדר, ברכות מנוקדות לפי נוסח, עם הסבר ותעתיק
- "אור", רצף ותגים, בלי שיפוטיות
- חנוכייה משותפת עם המשפחה והחבר'ה, "שלח אור", והזמנות "בואו להדליק אצלי"

**היעד:** בחנויות עד 25.11.2026, לפני הנר הראשון ב-4.12.2026.

## להתחיל

```bash
bash app/tool/setup.sh   # מייצר את android/ ו-ios/ ומתקן אותן
cd app
flutter test
flutter run
```

פרטים ב-[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). חיבור לשרת ב-[docs/FIREBASE.md](docs/FIREBASE.md).

## מסמכים

- [Vision](docs/VISION.md): המסמך שממנו נבנית האפליקציה. חלק א: למה ומה. חלק ב: מפרט מסך אחר מסך
- [Development](docs/DEVELOPMENT.md): הרצה, מבנה, בדיקות
- [Firebase](docs/FIREBASE.md): חיבור השכבה החברתית
- [חנויות](docs/STORE.md): שם, תיאורים, מילות מפתח, טפסי פרטיות, הערות לבודקי אפל, צ'קליסט הגשה
- [חבילת בדיקה](docs/review/): `rabbi.pdf` לרב ו-`musician.pdf` לנגן. נוצרות מקבצי התוכן: `python3 app/tool/review_packet.py && node app/tool/review_pdf.js`
- [עיצוב](docs/design/neri/): נרי, המסכים, האייקון וצילומי החנות

## מבנה הריפו

```
app/        אפליקציית Flutter (iOS + Android)
  lib/      הקוד
  assets/   תוכן לבדיקת רב (content/) וגופנים
  test/     טסטים
  tool/     סקריפט הקמה
web/        דף נחיתה לקישורי הזמנה ומדיניות פרטיות (web/privacy)
docs/       Vision ומסמכים
firestore.rules, firestore.indexes.json, firebase.json
```

## בדיקות אוטומטיות

כל push לגיטהאב מריץ את `.github/workflows/ci.yml`: הקמת הפרויקט, `flutter analyze`, `flutter test`, ובניית APK לאנדרואיד (להורדה מלשונית Actions). בניית iOS: Actions → CI → Run workflow → לסמן iOS.

## סטאק

Flutter · Riverpod · flutter_local_notifications · Firebase (אופציונלי) · חישוב לוח עברי ושקיעה בקוד שלנו
