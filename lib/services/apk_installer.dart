import 'package:flutter/services.dart';

/// Native (Kotlin) side se baat karne ka bridge — `ApkInstallerPlugin.kt`.
///
/// Dart se seedha APK install nahi ho sakta: Android 7+ pe file:// URI share
/// karna mana hai aur install intent ko content:// URI + permission grant
/// chahiye. Is liye yeh kaam Kotlin karta hai.
class ApkInstaller {
  static const MethodChannel _channel =
      MethodChannel('com.schoolapp.small_school_management/installer');

  /// Android 8+ pe "Install unknown apps" ki ijazat hai?
  /// Android 7 aur purane pe hamesha true (wahan yeh permission hai hi nahi).
  static Future<bool> canRequestInstall() async {
    try {
      final ok = await _channel.invokeMethod<bool>('canRequestInstall');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// "Install unknown apps" ka settings page kholta hai.
  static Future<bool> openInstallSettings() async {
    try {
      final ok = await _channel.invokeMethod<bool>('openInstallSettings');
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Downloaded APK ka installer kholta hai.
  /// Throws [PlatformException] agar file nahi mili ya intent fail hua.
  static Future<bool> install(String path) async {
    final ok = await _channel.invokeMethod<bool>('installApk', {'path': path});
    return ok ?? false;
  }
}
