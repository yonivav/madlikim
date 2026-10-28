# חיבור Firebase

בלי Firebase האפליקציה עובדת ב"מצב מקומי": הכל חוץ מהשכבה החברתית עובד רגיל, וחנוכייה משותפת כוללת רק את מי שבאותו מכשיר. כשמחברים Firebase, אותו קוד עובר לשרת אוטומטית.

## צעדים

1. יוצרים פרויקט ב-[Firebase Console](https://console.firebase.google.com).
2. מפעילים **Authentication → Anonymous**.
3. מפעילים **Firestore** (אזור: `europe-west1` או קרוב).
4. מתקינים את הכלים ומחברים:
   ```bash
   dart pub global activate flutterfire_cli
   cd app
   flutterfire configure
   ```
   זה מוסיף את `google-services.json` ו-`GoogleService-Info.plist` ומייצר `lib/firebase_options.dart`.
5. ב-`lib/main.dart` מעבירים את האפשרויות:
   ```dart
   import 'firebase_options.dart';
   ...
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```
6. מעלים חוקים ואינדקסים (מתיקיית השורש):
   ```bash
   firebase deploy --only firestore
   ```
7. (אופציונלי) מעלים את דף ההזמנה: `firebase deploy --only hosting`

## מבנה הנתונים

מפורט ב-`lib/social/firebase_social_repository.dart` ובחזון, פרק 34. חוקי האבטחה ב-`firestore.rules`.

## לבדוק לפני השקה

- חוקים ב-Emulator: אדם שלא בקבוצה לא קורא אותה, אי אפשר לספור הדלקה פעמיים, אורח כותב רק את ה-RSVP שלו.
- עומס: כל ההדלקות מגיעות בשעתיים סביב השקיעה. בקבוצות גדולות (100+) עדיף counters מבוזרים במקום `totalLight` אחד.
