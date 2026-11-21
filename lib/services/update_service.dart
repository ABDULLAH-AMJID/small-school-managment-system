import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// App update: check, download aur install.
///
/// HAQEEQAT (purane code mein yeh ghalat thi):
/// Is app mein koi Shorebird OTA patching MOJOOD NAHI hai — na `shorebird.yaml`
/// hai na koi shorebird dependency. Purana update button sirf SnackBar dikhata
/// tha ke patch restart pe lag jayega; woh message jhoot tha.
///
/// Ab yeh service:
///   1. GitHub pe rakhe version.json se latest version check karti hai
///   2. Installed version `package_info_plus` se leti hai (hardcode nahi)
///   3. Nayi APK app ke andar download karti hai (progress ke saath) aur
///      sha256 verify karti hai
///   4. Phir Android ka installer khol deti hai (user "Install" dabata hai)
///
/// Android pe app khud chup-chaap install nahi kar sakti — aakhri "Install"
/// tap user ka hota hai, yeh platform ki majboori hai.
class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/ABDULLAH-AMJID/small-school-managment-system/main/version.json';

  /// Fallback, agar version.json mein `apkUrl` na ho.
  static const String _defaultApkUrl =
      'https://github.com/ABDULLAH-AMJID/small-school-managment-system/blob/main/apk/school-management-v1.1.0-universal.apk?raw=true';

  String _currentVersion = '...';
  String? _latestVersion;
  String? _updateNotes;
  String? _apkUrl;
  String? _apkSha256;
  bool autoUpdateEnabled = true;
  bool _checking = false;
  String? _lastError;

  bool get latestVersionAvailable => _latestVersion != null;
  String? get latestVersion => _latestVersion;
  String? get updateNotes => _updateNotes;
  String? get apkUrl => _apkUrl;
  String? get lastError => _lastError;
  bool get isChecking => _checking;
  String get currentVersion => _currentVersion;

  bool get updateAvailable =>
      _latestVersion != null &&
      isNewerVersion(_latestVersion!, _currentVersion);

  /// Installed version asli package info se lo.
  ///
  /// BUG jo yahan fix hua: pehle version ek hardcoded constant tha (1.0.0).
  /// Yaani 1.0.1 release karne ke baad bhi app khud ko purana samajhti, aur har
  /// check pe "update available" kehti rehti — chahe update install ho chuka ho.
  Future<void> init() async {
    if (_currentVersion != '...') return;
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
    } catch (e) {
      _currentVersion = 'unknown';
    }
  }

  /// GitHub se version.json fetch karke compare karta hai.
  Future<bool> checkForUpdates() async {
    _checking = true;
    _lastError = null;
    bool available = false;
    try {
      await init();
      // Cache-buster: warna GitHub ka CDN purana version.json de sakta hai aur
      // app ko update dikhta hi nahi.
      final uri = Uri.parse(_versionUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString()
        },
      );
      final response = await http.get(uri, headers: {
        'Cache-Control': 'no-cache'
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = _decode(response.body);
        if (data != null) {
          _latestVersion = data['version'] as String?;
          _updateNotes = data['notes'] as String?;
          final url = data['apkUrl'] as String?;
          _apkUrl = (url == null || url.isEmpty) ? _defaultApkUrl : url;
          final hash = data['sha256'] as String?;
          _apkSha256 = (hash == null || hash.isEmpty) ? null : hash.trim();
          available = updateAvailable;
        } else {
          _lastError = 'version.json samajh nahi aaya';
        }
      } else {
        _lastError = 'Server ne ${response.statusCode} bheja';
      }
    } catch (e) {
      _lastError = 'Internet ya GitHub tak rasai nahi: $e';
    } finally {
      _checking = false;
    }
    return available;
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Launch pe silent check.
  Future<void> autoCheck() async {
    if (!autoUpdateEnabled) return;
    await checkForUpdates();
  }

  /// 1.0.1 vs 1.0.10 jaisi comparisons sahi karta hai (string compare nahi).
  /// Static + public is liye ke unit test ho sake.
  static bool isNewerVersion(String latest, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();

    final l = parse(latest);
    final c = parse(current);
    final len = l.length > c.length ? l.length : c.length;
    for (var i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  /// APK ka safe filename banata hai (version se), taake har version ki apni
  /// file ho aur purani download confuse na kare.
  static String apkFileName(String version) {
    final safe = version.replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '_');
    return 'school-management-v$safe-universal.apk';
  }

  /// Downloaded APK ka folder. `file_paths.xml` mein isi ko share kiya gaya hai.
  static Future<Directory> apkDir() async {
    final base = await getExternalStorageDirectory() ??
        await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'apk'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// APK download karta hai, progress [onProgress] pe bhejta hai (0.0 - 1.0).
  ///
  /// Pehle `.part` file mein download hota hai taake adhoori download ko mukammal
  /// APK na samjha jaye. Agar version.json mein sha256 hai to verify bhi hota
  /// hai — warna GitHub ki jagah koi beech mein file badal de to pata chale.
  ///
  /// [url], [dir] aur [expectedSha256] normally version.json se aate hain;
  /// parameters is liye hain ke test inhe inject kar sake.
  Future<File> downloadApk({
    void Function(double progress)? onProgress,
    String? url,
    String? version,
    Directory? dir,
    String? expectedSha256,
  }) async {
    final downloadUrl = url ?? _apkUrl ?? _defaultApkUrl;
    final fileVersion = version ?? _latestVersion ?? _currentVersion;
    final sha = expectedSha256 ?? _apkSha256;
    final folder = dir ?? await apkDir();
    final target = File(p.join(folder.path, apkFileName(fileVersion)));
    final part = File('${target.path}.part');

    if (await target.exists() && await verifySha256(target, sha)) {
      onProgress?.call(1.0);
      return target;
    }
    if (await part.exists()) await part.delete();

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),
      followRedirects: true,
    ));

    try {
      await dio.download(
        downloadUrl,
        part.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );
    } catch (e) {
      if (await part.exists()) await part.delete();
      throw 'Download fail hua: $e';
    }

    if (!await part.exists() || await part.length() == 0) {
      throw 'Download adhoora reh gaya (file khaali hai).';
    }

    if (!await verifySha256(part, sha)) {
      await part.delete();
      throw 'File ki sha256 verify nahi hui — download corrupt ya badla hua hai. '
          'Dobara koshish karein.';
    }

    if (await target.exists()) await target.delete();
    return part.rename(target.path);
  }

  /// File ka sha256 [expected] se milata hai. [expected] null ho to `true`
  /// (verify karne ko kuch nahi) — version.json mein sha256 optional hai.
  static Future<bool> verifySha256(File file, String? expected) async {
    final want = expected?.trim().toLowerCase();
    if (want == null || want.isEmpty) return true;
    return await sha256OfFile(file) == want;
  }

  static Future<String> sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  /// Browser mein APK download page kholta hai (fallback, agar in-app download
  /// fail ho ya user chahe).
  Future<bool> openDownloadPage(BuildContext context) async {
    final uri = Uri.parse(_apkUrl ?? _defaultApkUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Browser nahi khul saka. Link: $uri')),
        );
      }
      return ok;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download page khulne mein masla: $e')),
        );
      }
      return false;
    }
  }
}
