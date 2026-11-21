import 'dart:io';

import 'package:flutter/material.dart';
import 'package:small_school_management/services/apk_installer.dart';
import 'package:small_school_management/services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _update = UpdateService();
  bool _checking = false;
  bool _downloading = false;

  /// Download progress (0.0 - 1.0). `null` = server ne file ka size nahi
  /// bataya, is liye bar indeterminate (animated) dikhta hai — 0% pe atka hua
  /// nahi, jo user ko broken lagta.
  double? _progress;

  @override
  void initState() {
    super.initState();
    _update.init().then((_) {
      if (mounted) setState(() {});
      return _update.autoCheck();
    }).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    final available = await _update.checkForUpdates();
    if (!mounted) return;
    setState(() => _checking = false);

    final messenger = ScaffoldMessenger.of(context);
    if (available) {
      await _showUpdateDialog();
    } else if (_update.lastError != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Update check fail: ${_update.lastError}')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
            content: Text('App up to date hai (v${_update.currentVersion}).')),
      );
    }
  }

  Future<void> _showUpdateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'Naya version ${_update.latestVersion} dastyab hai.\n'
          'Aap ka version: ${_update.currentVersion}\n\n'
          '${_update.updateNotes ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Baad mein'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _update.openDownloadPage(context);
            },
            child: const Text('Browser mein'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _downloadAndInstall();
            },
            child: const Text('Yahin Download karein'),
          ),
        ],
      ),
    );
  }

  /// App ke andar APK download karke Android ka installer kholta hai.
  Future<void> _downloadAndInstall() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    File? apk;
    try {
      apk = await _update.downloadApk(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
    } catch (e) {
      if (mounted) setState(() => _downloading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$e'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Browser mein',
            onPressed: () => _update.openDownloadPage(context),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _downloading = false);

    // Android 8+ pe "Install unknown apps" ki ijazat zaroori hai.
    if (!await ApkInstaller.canRequestInstall()) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Install ki ijazat chahiye'),
          content: const Text(
            'App ko update install karne ki ijazat dein:\n\n'
            'Settings khulne par "Allow from this source" ON karein, '
            'phir wapas app mein aa jayen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Settings kholein'),
            ),
          ],
        ),
      );
      if (go == true) await ApkInstaller.openInstallSettings();
      return;
    }

    try {
      await ApkInstaller.install(apk.path);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Installer khulne mein masla: $e'),
          action: SnackBarAction(
            label: 'Browser mein',
            onPressed: () => _update.openDownloadPage(context),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Settings'), leading: const BackButton()),
      body: ListView(
        children: [
          if (_downloading) _DownloadTile(progress: _progress),
          if (_downloading) const Divider(),
          ListTile(
            title: const Text('Auto Update Check'),
            subtitle: const Text('App khulne par naya version check hota hai'),
            trailing: Switch(
              value: _update.autoUpdateEnabled,
              onChanged: (v) => setState(() => _update.autoUpdateEnabled = v),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Check for Updates'),
            subtitle: Text(
              _checking
                  ? 'Check ho raha hai...'
                  : _update.updateAvailable
                      ? 'v${_update.latestVersion} dastyab hai — tap karke update karein'
                      : 'GitHub se latest version check karein',
            ),
            trailing: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _update.updateAvailable
                        ? Icons.system_update
                        : Icons.refresh,
                    color: _update.updateAvailable
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            onTap: (_checking || _downloading) ? null : _checkForUpdates,
          ),
          const Divider(),
          ListTile(
            title: const Text('Current Version'),
            subtitle: Text(_update.currentVersion),
            trailing: const Icon(Icons.info_outline),
          ),
          const Divider(),
          const ListTile(
            title: Text('Update kaise hota hai'),
            subtitle: Text(
              'Nayi APK app ke andar download hoti hai, sha256 verify hoti hai, '
              'phir Android ka installer khulta hai. Aakhri "Install" aap dabate '
              'hain — Android app ko khud install karne ki ijazat nahi deta. '
              'Aap ka data (students, fees, attendance) mehfooz rehta hai.',
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About'),
            subtitle: Text(
              'Small School Management System\nFor schools with 100-150 students',
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.progress});

  /// `null` = total size maloom nahi, bar indeterminate dikhega.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final known = progress != null;
    final percent =
        known ? (progress! * 100).clamp(0, 100).toStringAsFixed(0) : null;
    return ListTile(
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: const Text('Update download ho raha hai'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          LinearProgressIndicator(value: known ? progress : null),
          const SizedBox(height: 4),
          Text(known ? '$percent%' : 'Download ho raha hai...'),
        ],
      ),
    );
  }
}
