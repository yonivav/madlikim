#!/usr/bin/env python3
"""Patches the folders `flutter create` generates. Safe to run twice."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent


def patch(path: pathlib.Path, fn):
    if not path.exists():
        print(f"  skip (missing): {path.relative_to(ROOT)}")
        return
    before = path.read_text(encoding="utf-8")
    after = fn(before)
    if after != before:
        path.write_text(after, encoding="utf-8")
        print(f"  patched: {path.relative_to(ROOT)}")
    else:
        print(f"  ok: {path.relative_to(ROOT)}")


# ---------------------------------------------------------------- Android

PERMISSIONS = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.VIBRATE",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.INTERNET",
]

RECEIVERS = """
        <!-- flutter_local_notifications: scheduled reminders and reboot -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""

DEEP_LINKS = """
            <!-- Invite links: https://madlikim.app/j/CODE , /i/ID , madlikim://j/CODE -->
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" android:host="madlikim.app" android:pathPrefix="/j/" />
                <data android:scheme="https" android:host="madlikim.app" android:pathPrefix="/i/" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="madlikim" />
            </intent-filter>
"""


def manifest(text: str) -> str:
    for p in PERMISSIONS:
        if p not in text:
            text = text.replace(
                "<application",
                f'<uses-permission android:name="{p}"/>\n    <application',
                1,
            )
    text = re.sub(r'android:label="[^"]*"', 'android:label="מדליקים"', text, count=1)
    if "ScheduledNotificationReceiver" not in text:
        text = text.replace("</application>", RECEIVERS + "    </application>", 1)
    if 'android:scheme="madlikim"' not in text:
        # Inside the main activity, after its first intent-filter.
        idx = text.find("</intent-filter>")
        if idx != -1:
            idx += len("</intent-filter>")
            text = text[:idx] + DEEP_LINKS + text[idx:]
    if "showWhenLocked" not in text:
        text = text.replace(
            'android:name=".MainActivity"',
            'android:name=".MainActivity"\n            android:showWhenLocked="true"\n            android:turnScreenOn="true"',
            1,
        )
    return text


def gradle_kts(text: str) -> str:
    text = re.sub(r"minSdk\s*=\s*[^\n]+", "minSdk = 23", text, count=1)
    if "isCoreLibraryDesugaringEnabled" not in text:
        text = re.sub(
            r"(compileOptions\s*\{)",
            r"\1\n        isCoreLibraryDesugaringEnabled = true",
            text,
            count=1,
        )
    if "desugar_jdk_libs" not in text:
        text += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    return text


def gradle_groovy(text: str) -> str:
    text = re.sub(r"minSdk(Version)?\s*=?\s*[^\n]+", "minSdkVersion 23", text, count=1)
    if "coreLibraryDesugaringEnabled" not in text:
        text = re.sub(
            r"(compileOptions\s*\{)",
            r"\1\n        coreLibraryDesugaringEnabled true",
            text,
            count=1,
        )
    if "desugar_jdk_libs" not in text:
        text += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    return text


# -------------------------------------------------------------------- iOS

PLIST_ADDITIONS = {
    "NSLocationWhenInUseUsageDescription":
        "<string>רק כדי לחשב מתי שקיעה אצלך. המיקום לא יוצא מהטלפון.</string>",
    "CFBundleDisplayName": "<string>מדליקים</string>",
    "CFBundleDevelopmentRegion": "<string>he</string>",
    "CFBundleLocalizations": "<array>\n\t\t<string>he</string>\n\t\t<string>en</string>\n\t</array>",
    "CFBundleURLTypes": (
        "<array>\n\t\t<dict>\n\t\t\t<key>CFBundleURLSchemes</key>\n"
        "\t\t\t<array>\n\t\t\t\t<string>madlikim</string>\n\t\t\t</array>\n"
        "\t\t</dict>\n\t</array>"
    ),
    "FlutterDeepLinkingEnabled": "<false/>",  # app_links handles links
}


def info_plist(text: str) -> str:
    for key, value in PLIST_ADDITIONS.items():
        pattern = re.compile(rf"<key>{key}</key>\s*(<string>[^<]*</string>|<array>.*?</array>|<true/>|<false/>)", re.S)
        entry = f"<key>{key}</key>\n\t{value}"
        if pattern.search(text):
            if key in ("CFBundleDisplayName", "CFBundleDevelopmentRegion"):
                text = pattern.sub(entry, text, count=1)
        else:
            text = text.replace("</dict>\n</plist>", f"\t{entry}\n</dict>\n</plist>", 1)
    return text


def app_delegate(text: str) -> str:
    """flutter_local_notifications needs the app delegate to receive
    notifications while the app is open. Works with both the older template
    and the newer implicit-engine template."""
    if "UNUserNotificationCenter" in text:
        return text
    line = (
        "UNUserNotificationCenter.current().delegate = "
        "self as UNUserNotificationCenterDelegate\n    "
    )
    hook = "return super.application(application, didFinishLaunchingWithOptions"
    if hook in text:
        text = text.replace(hook, line + hook, 1)
        if "import UserNotifications" not in text:
            text = text.replace("import UIKit", "import UIKit\nimport UserNotifications", 1)
    return text


def podfile(text: str) -> str:
    return re.sub(r"^#?\s*platform :ios, '[\d.]+'", "platform :ios, '13.0'", text, count=1, flags=re.M)


def main():
    android = ROOT / "android" / "app"
    ios = ROOT / "ios"
    if not android.exists() or not ios.exists():
        print("Run `flutter create --platforms=android,ios .` first.", file=sys.stderr)
        sys.exit(1)

    patch(android / "src" / "main" / "AndroidManifest.xml", manifest)
    if (android / "build.gradle.kts").exists():
        patch(android / "build.gradle.kts", gradle_kts)
    else:
        patch(android / "build.gradle", gradle_groovy)

    patch(ios / "Runner" / "Info.plist", info_plist)
    patch(ios / "Runner" / "AppDelegate.swift", app_delegate)
    patch(ios / "Podfile", podfile)


if __name__ == "__main__":
    main()
