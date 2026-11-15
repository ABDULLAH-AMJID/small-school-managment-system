import 'package:flutter/material.dart';
import 'package:small_school_management/db/database_helper.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/screens/dashboard_screen.dart';
import 'package:small_school_management/utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController(text: 'admin');
  final _pass = TextEditingController(text: 'admin123');
  final _db = DatabaseHelper();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final user = await _db.authenticate(_user.text.trim(), _pass.text.trim());
    setState(() => _loading = false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard', arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 70, color: AppTheme.primary),
                const SizedBox(height: 16),
                Text('School Management', style: AppTheme.heading.copyWith(fontSize: 24)),
                const SizedBox(height: 8),
                Text('Chote school ka complete system', style: AppTheme.caption),
                const SizedBox(height: 32),
                TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 16),
                TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Login')),
                ),
                const SizedBox(height: 16),
                Text('Default: admin / admin123', style: AppTheme.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
