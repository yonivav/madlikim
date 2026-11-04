#!/usr/bin/env python3
"""Builds the review packets from assets/content/*.json.

    python3 app/tool/review_packet.py          # writes docs/review/*.html
    node app/tool/review_pdf.js                # optional: turns them into PDFs

Rerun after any content change so the reviewers always see what ships.
"""
import html
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONTENT = ROOT / "app" / "assets" / "content"
OUT = ROOT / "docs" / "review"
FONTS = "../../app/assets/fonts/"


def load(name):
    return json.loads((CONTENT / f"{name}.json").read_text(encoding="utf-8"))


def e(s):
    return html.escape(s or "")


CSS = f"""
@font-face {{ font-family: FRL; src: url({FONTS}FrankRuhlLibre.ttf); font-weight: 300 900; }}
@font-face {{ font-family: Heebo; src: url({FONTS}Heebo.ttf); font-weight: 100 900; }}
@page {{ size: A4; margin: 18mm 16mm; }}
body {{ font-family: Heebo, sans-serif; color: #1E1A14; line-height: 1.6; font-size: 11.5pt; }}
h1 {{ font-family: FRL; font-size: 26pt; margin: 0 0 4px; }}
h2 {{ font-family: FRL; font-size: 17pt; margin: 26px 0 6px; border-bottom: 1.5px solid #D9A441; padding-bottom: 4px; break-after: avoid; }}
h3 {{ font-size: 12pt; margin: 16px 0 4px; break-after: avoid; }}
.intro {{ color: #5A5245; }}
.item {{ break-inside: avoid; border: 1px solid #E4D9C4; border-radius: 8px; padding: 10px 12px; margin: 8px 0; }}
.prayer {{ font-family: FRL; font-size: 16pt; line-height: 1.9; }}
.note {{ color: #6B6355; font-size: 10pt; }}
.check {{ margin-top: 6px; color: #6B6355; font-size: 10pt; }}
.box {{ display: inline-block; width: 11px; height: 11px; border: 1.2px solid #8E621C; border-radius: 2px; vertical-align: -1px; margin-inline-end: 4px; }}
.lines {{ border-bottom: 1px dotted #B9AE98; height: 20px; }}
table {{ width: 100%; border-collapse: collapse; font-size: 10.5pt; }}
th, td {{ border: 1px solid #E4D9C4; padding: 5px 8px; text-align: start; vertical-align: top; }}
th {{ background: #F7F1E4; }}
.chordline {{ display: flex; flex-wrap: wrap; direction: rtl; margin: 0 0 2px; }}
.seg {{ display: inline-flex; flex-direction: column; }}
.c {{ height: 15px; font-size: 10pt; font-weight: 800; color: #8E621C; direction: ltr; text-align: right; padding-left: 3px; }}
.w {{ font-family: FRL; font-size: 15pt; line-height: 1.3; white-space: pre; }}
.stanza {{ break-inside: avoid; margin: 10px 0 14px; }}
.num {{ font-family: FRL; color: #8E621C; font-weight: 700; }}
"""


def check(label="מאושר"):
    return (f'<div class="check"><span class="box"></span>{label} '
            f'&nbsp;&nbsp;<span class="box"></span>צריך תיקון:</div><div class="lines"></div>')


def page(title, body):
    return (f'<!doctype html><html lang="he" dir="rtl"><head><meta charset="utf-8">'
            f'<title>{e(title)}</title><style>{CSS}</style></head><body>{body}</body></html>')


def rabbi():
    b = load("blessings")
    s = load("songs")
    f = load("faq")
    out = ['<h1>מדליקים: חומר לבדיקה הלכתית</h1>',
           '<p class="intro">שלום הרב, זה כל התוכן ההלכתי שמופיע באפליקציה, בדיוק כפי שהמשתמשים יראו אותו. '
           'האפליקציה מיועדת לציבור המסורתי, ולכן הלשון פשוטה בכוונה. נשמח להערות על כל דבר, גם על ניסוח. '
           'ליד כל פריט יש מקום לסמן ולכתוב.</p>']

    out.append('<h2>א. הברכות</h2>')
    out.append('<p class="note">המשתמש בוחר נוסח: ספרד, אשכנז, או "לא יודע". שם ה׳ מוצג כ"ה׳". '
               'שאלה לרב: האם להציג כך, או בכתיב אחר על מסך?</p>')
    names = {"sefard": "נוסח ספרד", "ashkenaz": "נוסח אשכנז", "unknown": "כשהמשתמש לא בחר נוסח"}
    titles = {"lehadlik": "להדליק נר חנוכה", "sheasa_nisim": "שעשה נסים",
              "shehecheyanu": "שהחיינו"}
    for bl in b["blessings"]:
        when = "רק בלילה הראשון" if bl["nights"] == "first" else "כל לילה"
        out.append(f'<div class="item"><h3>{e(titles.get(bl["id"], bl["id"]))} ({when})</h3>')
        texts = {k: v for k, v in bl["text"].items() if v}
        if len(set(texts.values())) == 1:
            out.append(f'<div class="note">כל הנוסחים</div>'
                       f'<div class="prayer">{e(next(iter(texts.values())))}</div>')
        else:
            for k in ("sefard", "ashkenaz", "unknown"):
                if texts.get(k):
                    out.append(f'<div class="note">{names[k]}</div>'
                               f'<div class="prayer">{e(texts[k])}</div>')
        out.append(f'<div class="note">הסבר שמוצג: {e(bl["meaning"])}</div>')
        if bl.get("variantNote"):
            out.append(f'<div class="note">הערת נוסח: {e(bl["variantNote"])}</div>')
        out.append(f'<div class="note" dir="ltr" style="text-align:left">Transliteration: {e(bl["transliteration"])}</div>')
        out.append(check() + '</div>')

    out.append('<h2>ב. סדר ההדלקה כפי שמוצג</h2>')
    rows = [("שלב 1 (כל לילה)", b["steps"]["place"].replace("{count}", "4 נרות")),
            ("שלב 1 (לילה ראשון)", b["steps"]["placeFirst"]),
            ("שלב 2 (כל לילה)", b["steps"]["bless"]),
            ("שלב 2 (לילה ראשון)", b["steps"]["blessFirst"]),
            ("שלב 3 (כל לילה)", b["steps"]["light"]),
            ("שלב 3 (לילה ראשון)", b["steps"]["lightFirst"]),
            ("ערב שבת", b["order"]["erevShabbat"]),
            ("מוצאי שבת", b["order"]["motzeiShabbat"]),
            ("בטיחות (מוצג פעם אחת)", b["safety"])]
    out.append('<div class="item"><table><tr><th>מתי</th><th>הטקסט</th></tr>')
    out += [f'<tr><td>{e(a)}</td><td>{e(t)}</td></tr>' for a, t in rows]
    out.append('</table>' + check() + '</div>')
    out.append('<div class="item"><h3>איור החנוכייה</h3><p>הנרות מונחים מימין לשמאל. על כל נר מופיע מספר '
               'שמראה את סדר ההדלקה: 1 על הנר השמאלי (החדש), וכך הלאה ימינה. השמש גבוה, באמצע.</p>'
               + check() + '</div>')

    out.append('<h2>ג. זמנים</h2>')
    out.append('<div class="item"><table><tr><th>נושא</th><th>מה האפליקציה עושה</th></tr>'
               '<tr><td>שקיעה</td><td>השמש 0.833° מתחת לאופק (כולל שבירת אור)</td></tr>'
               '<tr><td>צאת הכוכבים</td><td>השמש 8.5° מתחת לאופק</td></tr>'
               '<tr><td>כניסת שבת</td><td>שקיעה פחות 20 דקות. ירושלים 40, חיפה 30</td></tr>'
               '<tr><td>צאת שבת</td><td>צאת הכוכבים (8.5°)</td></tr>'
               '<tr><td>מתי אפשר לסמן "הדלקתי" ביום חול</td><td>מהשקיעה (או מצאת הכוכבים, לפי בחירת המשתמש) עד 06:00 בבוקר</td></tr>'
               '<tr><td>ערב שבת</td><td>מ-12:00 בצהריים עד כניסת שבת. תזכורת בצהריים ושעה לפני כניסת שבת</td></tr>'
               '<tr><td>מוצאי שבת</td><td>מצאת השבת. תזכורת 5 דקות אחרי</td></tr>'
               '<tr><td>"עדיף עד"</td><td>חצי שעה אחרי צאת הכוכבים</td></tr>'
               '<tr><td>בשבת</td><td>אין התראות, ואין אפשרות לסמן. המסך מציג רק "שבת שלום"</td></tr>'
               '</table><p class="note">שאלה לרב: האם הזמנים והחלונות מקובלים? האם להציע ביום חול להתחיל '
               'בשקיעה כברירת מחדל?</p>' + check() + '</div>')

    out.append('<h2>ד. "למה ואיך": שאלות ותשובות</h2>')
    for q in f["faq"]:
        out.append(f'<div class="item"><h3>{e(q["q"])}</h3><p>{e(q["a"])}</p>{check()}</div>')

    out.append('<h2>ה. טקסטים אחרי ההדלקה</h2>')
    for song in s["songs"]:
        out.append(f'<div class="item"><h3>{e(song["title"])}</h3><p class="note">{e(song["when"])}</p>')
        for i, st in enumerate(song["stanzas"]):
            lines = "<br>".join(e(re.sub(r"\[[^\]]+\]", "", l)) for l in st)
            out.append(f'<div class="stanza"><div class="prayer">{lines}</div></div>')
        if song.get("variantNote"):
            out.append(f'<p class="note">{e(song["variantNote"])}</p>')
        out.append(check() + '</div>')

    out.append('<h2>ו. שאלות פתוחות לרב</h2><div class="item">'
               '<p>1. הצגת שם ה׳ על המסך: "ה׳" או כתיב אחר?</p><div class="lines"></div>'
               '<p>2. האם להזכיר את המנהגים השונים לגבי מי מדליק (כל אחד, או בעל הבית לכולם)?</p><div class="lines"></div>'
               '<p>3. האם הרב מסכים ששמו יופיע באפליקציה כמי שבדק את התוכן?</p><div class="lines"></div>'
               '</div>')
    return page("מדליקים: חומר לבדיקה הלכתית", "".join(out))


def chordline(line):
    segs = []
    pre = line.split("[")[0]
    if pre:
        segs.append(("", pre))
    for m in re.finditer(r"\[([^\]]+)\]([^\[]*)", line):
        segs.append((m.group(1), m.group(2)))
    return '<div class="chordline">' + "".join(
        f'<span class="seg" style="margin-left:{6 if w.endswith(" ") else 0}px">'
        f'<span class="c">{e(c)}</span><span class="w">{e(w.rstrip())}</span></span>'
        for c, w in segs) + "</div>"


def musician():
    s = load("songs")
    song = next(x for x in s["songs"] if x["id"] == "maoz_tzur")
    letters = "אבגדהו"
    out = ['<h1>מעוז צור: אקורדים לבדיקה</h1>',
           f'<p class="intro">אלה האקורדים שמופיעים באפליקציה, בסולם {e(song["key"])}, מעל ההברה שבה הם מתחלפים. '
           'הם נכתבו כהרמוניה פשוטה (I, IV, V) ולא הועתקו מתווים, אז חשוב שמישהו שמנגן יעבור עליהם. '
           'המשתמש יכול לשנות סולם באפליקציה. השורה האחרונה בכל בית מושרת פעמיים.</p>',
           '<p class="note">אפשר לסמן תיקונים ישר על הדף. האקורדים שמורים בקובץ טקסט פשוט '
           '(<span dir="ltr">app/assets/content/songs.json</span>), כך שתיקון לוקח דקה.</p>']
    for i, st in enumerate(song["stanzas"]):
        out.append(f'<div class="stanza"><div class="num">{letters[i]}</div>')
        out += [chordline(l) for l in st]
        out.append('</div>')
        if i == 0:
            out.append('<div class="item"><div class="check"><span class="box"></span>הבית הראשון בסדר '
                       '&nbsp;&nbsp;<span class="box"></span>צריך תיקון:</div><div class="lines"></div>'
                       '<div class="lines"></div></div>')
            out.append('<p class="note">שאר הבתים: אותה מנגינה, האקורדים הוצבו לפי אותו מבנה.</p>')
    out.append('<div class="item"><div class="check"><span class="box"></span>כל הבתים בסדר '
               '&nbsp;&nbsp;<span class="box"></span>הערות:</div><div class="lines"></div><div class="lines"></div></div>')
    return page("מעוז צור: אקורדים לבדיקה", "".join(out))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "rabbi.html").write_text(rabbi(), encoding="utf-8")
    (OUT / "musician.html").write_text(musician(), encoding="utf-8")
    print("wrote", OUT / "rabbi.html", "and", OUT / "musician.html")


if __name__ == "__main__":
    main()
