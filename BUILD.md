# Small School Management System — Build Instructions

This is a complete Flutter school management system for small schools (100–150 students, up to 10th grade). It runs entirely on a mobile phone (no PC/laptop needed) and includes:

- Teacher & student attendance (class-wise)
- Exam schedule & timetable management
- Student report cards (mid-term + final marks, attendance, fees)
- Teacher records & parent contact details
- Complete fee management (balance, due date, paid/pending)
- Weekly report PDF sent to parents via WhatsApp
- WhatsApp integration (wa.me link / share PDF)
- Over-the-air (OTA) updates via Shorebird — small incremental patches, auto + manual update check

## Prerequisites (on your PC to build the APK)

You need a PC with:
- Flutter SDK (stable) — https://docs.flutter.dev/get-started/install
- Android Studio / Android SDK (API 34)
- Java JDK 17 or 21
- An Android phone to install the APK

## Step 1: Get the code

```bash
git clone https://github.com/ABDULLAH-AMJID/small-school-managment-system.git
cd small-school-managment-system
```

## Step 2: Install Flutter dependencies

```bash
flutter pub get
```

## Step 3: Configure Android SDK

```bash
flutter config --android-sdk $ANDROID_HOME
flutter doctor        # resolve any issues shown
flutter doctor --android-licenses   # accept Android licenses
```

## Step 4: Build the APK

Debug APK (for testing on your phone):

```bash
flutter build apk --debug
```

Release APK (smaller, optimized):

```bash
flutter build apk --release --split-per-abi
```

The APK will be at:
- `build/app/outputs/flutter-apk/app-debug.apk`
- or `build/app/outputs/apk/release/app-release.apk`

Install on your phone:
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```
Or copy the APK to your phone and open it.

## Default Login Credentials

| Role | Username | Password |
|------|----------|----------|
| Admin | admin | admin123 |
| Teacher | teacher | teacher123 |
| Parent | parent | parent123 |

## Over-the-Air (OTA) Updates — Shorebird

This app uses Shorebird for OTA code updates. Only changed Dart code is downloaded (small patches, fast), applied on next app restart.

### Initial release (one time)
```bash
# Install Shorebird CLI
dart pub global activate shorebird_cli
export PATH="$PATH":"$(dart pub global bin)"

# Configure Shorebird in the project
shorebird init

# Build & release the APK with OTA support
shorebird build android-apk --release
shorebird release android --apk build/app/outputs/apk/release/app-arm64-v8a-release.apk
```

### Pushing an update (small patch)
After you fix a bug or add a feature in Dart code:
```bash
shorebird patch
```
Users get the patch automatically on next app launch — no full APK download, no app store update.

### Manual update check
The app has a "Check for Updates" button in Settings. Auto-update is on by default; patches apply on restart.

## GitHub Auto-Deploy

All source is hosted at:
https://github.com/ABDULLAH-AMJID/small-school-managment-system

To push future updates:
```bash
git add -A
git commit -m "your update message"
git push origin main
```

## Features Summary

- **Student management**: add/view students with roll no, class, section, parent name & phone
- **Teacher management**: teacher records with subject, phone, salary
- **Attendance**: mark student attendance class-wise daily; teacher attendance
- **Exams**: create Mid Term / Final exams per class
- **Timetable**: create & manage class timetables (day, period, subject, time)
- **Marks**: enter subject-wise marks per exam per student
- **Fees**: monthly fee with amount, due date, paid amount, balance, pending alerts
- **Report Card**: per-student report with attendance, mid/final marks, fee status, teacher comments — share via WhatsApp PDF
- **Weekly Report**: weekly attendance %, homework status, teacher comment, fee balance & last date — auto PDF sent to parent's WhatsApp
- **WhatsApp**: opens wa.me chat with pre-filled message; shares report PDF via WhatsApp share sheet
- **Updates**: auto OTA (Shorebird) + manual check; small incremental patches

## Notes

- Data is stored locally on the phone (SQLite). No server/PC required to run.
- WhatsApp must be installed on the phone to send reports.
- For production, sign the release APK and consider a backend for multi-device sync.