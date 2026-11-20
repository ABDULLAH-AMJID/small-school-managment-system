# Build Fixes — small-school-managment-system

Repo: https://github.com/ABDULLAH-AMJID/small-school-managment-system (private, branch `main`)
Commit jise build kiya gaya: `5899603` — "Add build instructions and version config"
Build environment: Flutter 3.50.1 · Dart 3.14.0 · JDK 21 · AGP 9.3.1 · Gradle 9.5.0 · Android SDK 36

**Natija:** repo ka code jaisa tha, woh **build hi nahi hota tha**. 15 compile errors the.
Sab theek kar ke ab teen APKs bante hain (niche section 3).

---

## 1. Compile errors (yeh build ko roke hue the)

| File | Masla | Fix |
|---|---|---|
| `lib/main.dart:19` | `runApp(const SchoolApp)` — constructor ke `()` gayab | `runApp(const SchoolApp())` |
| `lib/screens/report_card_screen.dart:32-33` | `if (s == null) {` **dobara duplicate** likha tha → ek extra `{`, poori class unclosed | duplicate line delete |
| `lib/screens/exam_screen.dart:43` | `Row(...)` ka `)` gayab: `Expanded(child: _tf(_classC, 'Class')])` | `'Class'))]` |
| `lib/screens/exam_screen.dart:45-47` | Do `Expanded` seedha `Column` ke andar the (Flutter mein `Expanded` sirf `Row`/`Column` ke flex bachon mein chalta hai) + bracket imbalance | unhein `Row(children: [ ... ])` mein wrap kiya |

**Pehle:** 15 errors · **Ab:** `flutter analyze` → **0 errors, 0 warnings** (125 `info` style lints
baqi hain — `prefer_const_constructors` waghera. Maine aap ka code style nahi chhera.)

---

## 2. Build configuration / dependency errors

Har ek ne build ko alag marhale pe roka:

| # | Error | Wajah | Fix |
|---|---|---|---|
| 1 | `Error: unable to find directory entry in pubspec.yaml: .../assets/images/` | `pubspec.yaml` mein `assets/images/`, `assets/icons/`, `assets/lottie/` declared hain magar **repo mein yeh folders maujood nahi** | teen folders `.gitkeep` ke saath banaye (code mein in assets ka kahin istemaal nahi, is liye placeholders kaafi hain) |
| 2 | `The option 'android.enableR8' is deprecated. It was removed in version 7.0 of the Android Gradle plugin.` → **fatal** | `android.enableR8=false` purane template se bacha tha; AGP 9.3.1 isay error manta hai | property delete |
| 3 | `Execution failed for JetifyTransform: ... Java heap space` | `android.enableJetifier=true` Flutter ke engine jars ko jetify karne ki koshish mein heap khatam kar deta tha | property delete (saare plugins pehle se AndroidX hain: `sqflite_android`, `path_provider_android`, `printing`, `share_plus`, `url_launcher_android`, `jni`) |
| 4 | `:printing:checkDebugAarMetadata` — *21 issues*: `androidx.fragment:1.7.1` / `androidx.window:1.2.0` require compileSdk 34+, `printing` compiled against android-30 | `printing 5.13.1` mein `compileSdkVersion 30` hai | `printing` **5.13.1 → 5.15.1** (is mein `compileSdk = 34` hai) |
| 5 | `printing >=5.13.2 depends on web ^1.0.0 and share_plus 9.0.0 depends on web ^0.5.0` → version solving failed | printing upgrade ke liye share_plus bhi barhana zaroori tha | `share_plus` **9.0.0 → 13.3.1** (`web 1.1.2`) |
| 6 | `Share.shareXFiles` ab `@Deprecated` | share_plus 10+ mein API badli | `SharePlus.instance.share(ShareParams(files: ..., text: ..., subject: ...))` |
| 7 | `:share_plus:compileDebugKotlin` → `Unresolved reference 'ShareSuccessManager'` / `'SharePlusPendingIntent'` | Stale incremental Kotlin state. **Note:** maine pehle socha tha `android.builtInKotlin=false` wajah hai — woh **ghalat** tha (niche section 5) | `flutter clean` |

### Memory tuning (is sandbox ke liye)

`android/gradle.properties` mein `MaxMetaspaceSize=128m` tha jo release build ko
`OutOfMemoryError: Metaspace` deta hai. Kiya gaya:

```properties
org.gradle.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8
org.gradle.workers.max=1
```

---

## 3. Jo APKs bane (verified)

| File | Size | Kaam |
|---|---|---|
| `apk/school-management-v1.0.0-arm64-v8a.apk` | **18 MB** | Aaj kal ke phones ke liye — **yehi install karein** |
| `apk/school-management-v1.0.0-armeabi-v7a.apk` | 16 MB | Purane 32-bit phones |
| `apk/school-management-v1.0.0-universal.apk` | 52 MB | Sab architectures, ek file |

`aapt2 dump badging` se tasdeeq:

```
package: com.schoolapp.small_school_management   versionName: 1.0.0   versionCode: 1
targetSdkVersion: 36      compileSdkVersion: 36
application-label: 'School Management'
uses-permission: android.permission.INTERNET
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'
```

Debug APK bhi bana tha (158 MB) — size ki wajah se rakha nahi; `flutter build apk --debug` se
dobara mil jayega.

> **Signing:** release APK abhi **debug key** se signed hai (repo ki `build.gradle.kts` mein
> `signingConfig = signingConfigs.getByName("debug")` likha hai). Phone pe install/test ke liye
> theek hai, magar Play Store pe upload karne se pehle apni release keystore banani paregi.

---

## 4. Do functional bugs jo maine theek kiye (build se talluq nahi, magar features toot'te)

### a) `INTERNET` permission release mein missing thi
`AndroidManifest.xml` (main) mein `INTERNET` nahi tha — sirf `android/app/src/debug/AndroidManifest.xml`
mein tha. `lib/services/update_service.dart` GitHub se `version.json` fetch karta hai, is liye
**release build mein update check hamesha chup-chaap fail hota**. Ab main manifest mein add kar diya.

### b) WhatsApp package visibility (Android 11+)
`lib/services/whatsapp_service.dart` `canLaunchUrl(wa.me/...)` use karta hai. Android 11+ pe
package-visibility ke baghair `canLaunchUrl` **false** deta hai chahe WhatsApp install ho.
Ab `<queries>` mein `com.whatsapp`, `com.whatsapp.w4b`, aur `VIEW/https` + `SEND` intents add hain.

### c) App label
`small_school_management` → `School Management` (phone ke home screen pe yahi naam dikhta hai).

---

## 5. Jo maine ghalat kaha tha (record ke liye)

 Maine beech mein kaha tha ke `android.builtInKotlin=false` share_plus ki Kotlin compile failure
ki wajah hai. **Yeh ghalat tha.** Maine A/B test kiya:

- `android.builtInKotlin=true` + scratch build → ✓ Built (54.4 MB)
- `android.builtInKotlin=false` + scratch build → ✓ Built (54.4 MB)

Dono pass. Asal fix `flutter clean` tha (stale incremental Kotlin state). Flag ko maine uski
asli halat (`false`, jo Flutter ka tool khud likhta hai) pe wapas kar diya hai.

---

## 6. Jo cheezein abhi bhi theek nahi (aap ki decision chahiye)

### a) OTA update check kaam nahi karega — repo private hai
`update_service.dart` yeh URL hit karta hai:

```
https://raw.githubusercontent.com/ABDULLAH-AMJID/small-school-managment-system/main/version.json
```

Maine bina token ke test kiya: **HTTP 404**. `raw.githubusercontent.com` private repo ke liye
auth mangta hai, aur app ke paas koi token nahi hai. Yani "Check for Updates" hamesha
"no update" dega. Hal: ya to `version.json` kisi public jagah host karein (GitHub Pages,
ek public repo, ya koi bhi static host), ya repo public karein.

### b) Shorebird OTA asal mein configured hi nahi
`BUILD.md` mein Shorebird ke commands hain, magar project mein:
- `shorebird.yaml` **nahi** hai
- `pubspec.yaml` / `android/app/build.gradle.kts` mein shorebird ka koi zikr **nahi**

Aur `UpdateService.applyUpdate()` sirf ek SnackBar dikhata hai ("Shorebird will apply patches
on next restart") — koi asal patching nahi hoti. Yaani **OTA abhi sirf UI hai, kaam nahi karta**.
Agar chahiye to `shorebird init` + release pipeline set karni paregi.

### c) `google_fonts` runtime pe font download karta hai
`app_theme.dart` `GoogleFonts.poppins()` use karta hai. Pehli launch pe Poppins internet se
download hoti hai (INTERNET permission add hone ki wajah se ab yeh chalega), magar offline
pehli baar font fallback pe dikhega. Behtar: font ko `assets/fonts/` mein bundle kar dein.

### d) Koi test nahi hai
Repo mein `test/` directory hi nahi hai (`flutter test` → "Test directory not found").

### e) 125 style lints
`prefer_const_constructors` (82), `deprecated_member_use` (18), `use_build_context_synchronously` (7),
`unused_import` (7), waghera. Build pe koi asar nahi. Chahen to `dart fix --apply` se kaafi khud
theek ho jayenge.

---

## 7. Dobara build karne ka tareeqa

```bash
cd ~/apps/small-school-managment-system
flutter pub get
flutter build apk --release --split-per-abi    # 16-20 MB per-ABI APKs
# ya
flutter build apk --release                    # 52 MB universal
```

Agar Kotlin/Gradle ka ajeeb error aaye: `flutter clean && flutter pub get` phir dobara build.

---

## 8. Poori change list

```
 android/app/src/main/AndroidManifest.xml | 18 +++++++++++++++++-   (INTERNET, queries, label)
 android/gradle.properties                | 11 ++++++-----          (memory, R8/Jetifier remove)
 lib/main.dart                            |  2 +-                   (SchoolApp())
 lib/screens/exam_screen.dart             | 12 +++++++-----         (Row bracket + wrap)
 lib/screens/report_card_screen.dart      |  1 -                    (duplicate if)
 lib/services/whatsapp_service.dart       | 10 ++++++----           (SharePlus.instance.share)
 pubspec.yaml                             |  4 ++--                 (printing, share_plus)
 pubspec.lock                             | 32 ++++++++++++++--------
 + assets/{images,icons,lottie}/.gitkeep  (untracked)
 + apk/*.apk                              (untracked, 86 MB)
```
