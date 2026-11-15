import 'package:flutter/material.dart';
import 'package:small_school_management/services/update_service.dart';
import 'package:small_school_management/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _update = UpdateService();
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _update.autoCheck();
  }

  Future<void> _manualCheck() async {
    setState(() => _checked = true);
    final available = await _update.checkForUpdates();
    setState(() => _checked = false);
    if (available) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text('Update Available'),
        content: Text('New version ${_update.latestVersion} is available.\n${_update.updateNotes ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Later')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _update.applyUpdate(context); }, child: Text('Update Now')),
        ],
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), leading: const BackButton()),
      body: ListView(
        children: [
          ListTile(
            title: Text('Auto Update'),
            subtitle: Text('Shorebird OTA updates apply on app restart'),
            trailing: Switch(value: _update.autoUpdateEnabled, onChanged: (v) => setState(() => _update.autoUpdateEnabled = v)),
          ),
          const Divider(),
          ListTile(
            title: Text('Check for Updates (Manual)'),
            subtitle: Text('Only downloads changed code (small, fast)'),
            trailing: _checked ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.refresh),
            onTap: _manualCheck,
          ),
          const Divider(),
          ListTile(
            title: Text('Current Version'),
            subtitle: Text(_update.currentVersion),
            trailing: Icon(Icons.info_outline),
          ),
          const Divider(),
          ListTile(
            title: Text('About'),
            subtitle: Text('Small School Management System\nFor schools with 100-150 students'),
          ),
        ],
      ),
    );
  }
}
