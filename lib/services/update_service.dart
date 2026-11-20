import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// App update check.
///
/// HAQEEQAT (purane code mein yeh ghalat thi):
/// Is app mein koi OTA / Shorebird patching MOJOOD NAHI hai. `shorebird init`
/// kabhi run nahi hua, na `shorebird.yaml` hai na koi shorebird dependency.
/// Purana update button sirf ek SnackBar dikhata tha ke patch restart pe lag
/// jayega — woh message jhoot tha, asal mein kuch hota hi nahi tha.
///
/// Ab yeh service:
///   1. GitHub pe rakhe version.json se latest version check karti hai
///   2. Installed version `package_info_plus` se leti hai (hardcode nahi)
///   3. Update milne par browser mein APK download page khol deti hai — user
///      APK install kare to naya version + naya data aa jata hai
class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/ABDULLAH-AMJID/small-school-managment-system/main/version.json';

  /// Fallback, agar version.json mein `apkUrl` na ho.
  static const String _defaultApkUrl =
      'https://github.com/ABDULLAH-AMJID/small-school-managment-system/blob/main/apk/school-management-v1.0.1-universal.apk?raw=true';

  String _currentVersion = '...';
  String? _latestVersion;
  String? _updateNotes;
  String? _apkUrl;
  bool autoUpdateEnabled = true;
  bool _checking = false;
  String? _lastError;

  String get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get updateNotes => _updateNotes;
  String? get lastError => _lastError;
  bool get isChecking => _checking;

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
  /// Returns true agar naya version available hai.
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

  /// Launch pe silent check (Settings khulne par bhi hota hai).
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
        .map((p) => int.tryParse(p.trim()) ?? 0)
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

  /// APK download page browser mein kholta hai.
  ///
  /// Purana code yahan sirf SnackBar dikhata tha aur kehta tha "next restart pe
  /// update ho jayega" — magar koi patching hoti hi nahi thi. Ab user ko saaf
  /// bataya jata hai ke APK download karke install karna hoga.
  Future<bool> openDownloadPage(BuildContext context) async {
    final uri = Uri.parse(_apkUrl ?? _defaultApkUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Browser nahi khul saka. Link: ${uri.toString()}')),
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
