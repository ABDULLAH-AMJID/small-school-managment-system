import 'package:flutter/material.dart';
import 'package:small_school_management/services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _update = UpdateService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pehle installed version maloom karo, phir silent check.
    _update.init().then((_) {
      if (mounted) setState(() {});
      return _update.autoCheck();
    }).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _manualCheck() async {
    setState(() => _busy = true);
    final available = await _update.checkForUpdates();
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.of(context);

    if (available) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            'Naya version ${_update.latestVersion} dastyab hai.\n'
            'Aap ka version: ${_update.currentVersion}\n\n'
            '${_update.updateNotes ?? ''}\n\n'
            'Update ke liye nayi APK download karke install karni hogi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Baad mein'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _update.openDownloadPage(context);
              },
              child: const Text('APK Download karein'),
            ),
          ],
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Settings'), leading: const BackButton()),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Auto Update Check'),
            subtitle: const Text(
              'App khulne par naya version check hota hai (Shorebird OTA nahi — '
              'nayi APK install karni parti hai)',
            ),
            trailing: Switch(
              value: _update.autoUpdateEnabled,
              onChanged: (v) => setState(() => _update.autoUpdateEnabled = v),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Check for Updates'),
            subtitle: Text(
              _busy
                  ? 'Check ho raha hai...'
                  : 'GitHub se latest version check karein',
            ),
            trailing: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onTap: _busy ? null : _manualCheck,
          ),
          const Divider(),
          ListTile(
            title: const Text('Current Version'),
            subtitle: Text(_update.currentVersion),
            trailing: const Icon(Icons.info_outline),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text(
              'Small School Management System\nFor schools with 100-150 students',
            ),
          ),
        ],
      ),
    );
  }
}
