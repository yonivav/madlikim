# חנויות: כל מה שמדביקים בטפסים

> טיוטה מוכנה להדבקה. מה שבסוגריים מרובעים [כך] עוד צריך החלטה שלך.

## פרטים בסיסיים

| שדה | ערך |
|---|---|
| שם (App Store, עד 30 תווים) | מדליקים: נרות חנוכה |
| כותרת משנה (App Store, עד 30) | נרות חנוכה, כל ערב, ביחד |
| שם (Google Play, עד 30) | מדליקים: נרות חנוכה |
| Bundle ID / Package | `app.madlikim.madlikim` (נקבע ב-`setup.sh`) |
| קטגוריה | Lifestyle (שתי החנויות) |
| דירוג גיל | 4+ / Everyone |
| מחיר | חינם, בלי רכישות, בלי פרסומות |
| שפה ראשית | עברית |
| מדיניות פרטיות | `https://[הדומיין]/privacy/` (הקובץ ב-`web/privacy/index.html`) |
| כתובת תמיכה | [מייל או דף] |

בחיפוש לא מצאתי אפליקציה קיימת בשם "מדליקים". השם נשמר לך רק כשרושמים אותו ב-App Store Connect, אז כדאי לעשות את זה ראשון.

---

## תיאור קצר (Google Play, עד 80 תווים)

תזכורת להדלקת נרות חנוכה, ברכות מנוקדות וחנוכייה משותפת עם החברים

## טקסט קידום (App Store, עד 170 תווים)

חנוכה מתחיל ב-4 בדצמבר. מדליקים מזכירה בזמן, מראה בדיוק מה עושים, ונותנת לכם להדליק ביחד עם המשפחה והחברים, גם כשכל אחד בבית שלו.

## תיאור מלא

מדליקים עוזרת להדליק נרות חנוכה אמיתיים, כל ערב, בלי לשכוח ובלי להתבלבל.

🕯️ תזכורת בזמן הנכון
התזכורת מגיעה בשקיעה, בצאת הכוכבים או בשעה שבחרתם. בערב שבת היא מגיעה מוקדם, לפני נרות שבת. ובשבת עצמה האפליקציה שותקת.

🕎 בדיוק מה עושים
כמה נרות, איפה מניחים אותם ומאיזה מדליקים. הברכות מנוקדות ובאותיות גדולות, לפי נוסח ספרד או אשכנז, עם הסבר קצר ותעתיק למי שצריך.

✨ אור, רצף ותגים
כל לילה שמדליקים מוסיף אור לחנוכייה שלכם. שכחתם ערב? קורה. ממשיכים מחר.

👨‍👩‍👧‍👦 חנוכייה משותפת
פותחים חנוכייה למשפחה או לחבר'ה ושולחים קישור בוואטסאפ. כל מי שמדליק אצלו בבית מוסיף אור לחנוכייה של כולם. אפשר גם לשלוח אור לחבר שעוד לא הדליק.

🏠 בואו להדליק אצלי
מזמינים חברים לערב אחד של חנוכה ורואים מי מגיע.

🎶 אחרי ההדלקה
הנרות הללו, מעוז צור (כל הבתים, עם אקורדים לגיטרה) ומזמור שיר חנוכת הבית.

בלי הרשמה, בלי פרסומות, בלי מעקב. רוב המידע נשאר בטלפון.

## מילות מפתח (App Store, עד 100 תווים, מופרדות בפסיק)

חנוכה,חנוכייה,נרות,הדלקת נרות,ברכות,מעוז צור,תזכורת,שבת,יהדות,חג,מסורת,סופגניות

## מה חדש (גרסה 1.0)

הגרסה הראשונה. חנוכה שמח!

---

## צילומי מסך

נדרש: אייפון 6.9" (1320×2868 או 1290×2796) ואנדרואיד (לפחות 1080×1920).
טיוטות לפי העיצוב נמצאות ב-`docs/store/`. **לפני ההגשה מחליפים אותן בצילומים מהאפליקציה האמיתית** (אפל דוחה צילומים שלא תואמים לאפליקציה). כדי לצלם ערב חנוכה לפני חנוכה, משנים זמנית את `clockProvider` (ראו `docs/DEVELOPMENT.md`).

הכיתובים (כמו בטיוטות, בסגנון "כותרת לבנה + שורה כתומה"):
1. **תזכורת עדינה / להדליק נרות.** מסך הבית
2. **בדיוק מה עושים / בכל ערב.** מסך ההדלקה
3. **הדלקתם? / נרי חוגג!** החגיגה
4. **כל לילה / חבר חדש מתעורר.** החבר'ה של נרי
5. **ובשבת? / נרי נח.** מסך שבת

כדאי להוסיף צילום של חנוכייה משותפת כשתהיה גרסה רצה (אין לו עדיין טיוטה).

---

## Apple: App Privacy

| סוג מידע | נאסף? | מקושר למשתמש? | למעקב? | מטרה |
|---|---|---|---|---|
| User ID (מזהה אנונימי של Firebase) | כן | כן | לא | App Functionality |
| Name (שם תצוגה בקבוצה) | כן | כן | לא | App Functionality |
| Other User Content (לילות שהודלקו, הערות בהזמנות) | כן | כן | לא | App Functionality |
| Location | **לא** (מחושב רק על המכשיר) | | | |
| Contacts, Photos, Health, Financial | לא | | | |

אם משיקים בלי Firebase: "Data Not Collected".

## Google Play: Data safety

- **נאסף:** Personal info → Name (אופציונלי). App activity → Other user-generated content. Device or other IDs.
- **משותף עם צד שלישי:** לא.
- **מטרה:** App functionality בלבד.
- **מוצפן בתעבורה:** כן.
- **אפשר לבקש מחיקה:** כן (כפתור בהגדרות).
- **מיקום:** לא נאסף. הוא משמש רק על המכשיר, ולכן לא נחשב "איסוף".
- **הרשאת התראות מדויקות:** האפליקציה משתמשת ב-`inexactAllowWhileIdle`, ולכן **לא** צריך `SCHEDULE_EXACT_ALARM` ולא את הטופס המיוחד שלו.

---

## הערות לבודקי אפל (App Review Notes)

העתיקו באנגלית:

> Madlikim is a reminder and companion app for lighting Hanukkah candles (Hanukkah 2026: December 4 to 12). No login is required.
>
> Before Hanukkah the home screen shows a countdown. Tap **"להתכונן: הברכות וסדר ההדלקה"** ("Get ready: blessings and lighting order") to see the main lighting screen with the blessings and the lighting order. Marking a night as lit becomes available on the evening of each night.
>
> On Shabbat (Friday evening to Saturday night) the app intentionally shows only a "Shabbat Shalom" screen and sends no notifications, as many users observe Shabbat.
>
> Shared menorahs: Settings are not required. Tap "חנוכייה משותפת" → "חנוכייה חדשה" to create a group and get a 6-character join code.
>
> Location is optional and used only on-device to compute sunset times. All religious texts are traditional and in the public domain.

---

## צ'קליסט לפני הגשה

- [ ] שם נשמר ב-App Store Connect וב-Play Console
- [ ] `CONTACT_EMAIL` בדף הפרטיות הוחלף, והדף עלה לאוויר
- [ ] רב אישר את התוכן (`"reviewed": true` בקבצי `content/`)
- [ ] נגן אישר את האקורדים
- [ ] CI ירוק (analyze, test, build)
- [ ] נבדק על אייפון אמיתי ועל אנדרואיד אמיתי (התראות!)
- [ ] צילומי מסך אמיתיים
- [ ] גרסה 1.0.0+1, חתימה (Android keystore, iOS signing)
- [ ] TestFlight ו-Internal testing לבטא
- [ ] **הגשה עד 24.11**
