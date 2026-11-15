import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// UpdateService manages over-the-air (OTA) updates using Shorebird.
///
/// Shorebird checks for Dart code patches automatically on every app launch.
/// When a patch is found, it downloads only the changed code (very small,
/// typically a few KB), and applies it on the next app restart.
///
/// This service exposes:
///  - [checkForUpdates]  -> manual update check (user taps "Check for Updates")
///  - [currentVersion]   -> the installed app version
///  - [autoUpdateEnabled] -> whether auto-update is on
class UpdateService {
  static const String _currentVersion = '1.0.0';
  static const String _versionUrl = 'https://raw.githubusercontent.com/ABDULLAH-AMJID/small-school-managment-system/main/version.json';

  bool _autoUpdate = true;
  String? _latestVersion;
  String? _updateNotes;
  bool _checking = false;

  bool get autoUpdateEnabled => _autoUpdate;
  set autoUpdateEnabled(bool v) => _autoUpdate = v;
  String get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
  String? get updateNotes => _updateNotes;
  bool get isChecking => _checking;
  bool get updateAvailable =>
      _latestVersion != null && _isNewer(_latestVersion!, _currentVersion);

  /// Manual update check called when user taps "Check for Updates".
  /// Returns true if an update is available.
  Future<bool> checkForUpdates({bool silent = false}) async {
    _checking = true;
    bool available = false;
    try {
      // Try to fetch remote version.json from GitHub.
      // If Shorebird is active, the engine handles the actual patch silently.
      final response = await http.get(Uri.parse(_versionUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _latestVersion = data['version'] as String?;
        _updateNotes = data['notes'] as String?;
        if (_latestVersion != null && _isNewer(_latestVersion!, _currentVersion)) {
          available = true;
        }
      }
    } catch (e) {
      // No network or GitHub unreachable — rely on Shorebird's built-in OTA.
      debugPrint('Update check (remote) unavailable: $e');
    }
    _checking = false;
    return available;
  }

  /// Auto-check on app launch. Non-blocking; results stored for UI.
  Future<void> autoCheck() async {
    if (!_autoUpdate) return;
    await checkForUpdates(silent: true);
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final c = current.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final len = l.length > c.length ? l.length : c.length;
    for (int i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  /// Trigger an update download + install (Shorebird patch). In production
  /// Shorebird does this automatically; here we offer a manual restart prompt.
  Future<void> applyUpdate(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update checked. Shorebird will apply patches on next restart.')),
    );
  }
}
