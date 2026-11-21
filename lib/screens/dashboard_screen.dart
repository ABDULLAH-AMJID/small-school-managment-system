import 'package:flutter/material.dart';
import 'package:small_school_management/models/app_models.dart';
import 'package:small_school_management/utils/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser? currentUser;
  const DashboardScreen({super.key, this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  AppUser get user =>
      widget.currentUser ??
      AppUser(
          username: '-',
          password: '-',
          name: 'User',
          phone: '',
          role: AppRole.admin);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login')),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Updates'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 48, color: Colors.white),
                const SizedBox(height: 10),
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(user.role.label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          _drawerTile('Dashboard', Icons.home, '/dashboard'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Students', Icons.people, '/students'),
          if (user.role == AppRole.admin)
            _drawerTile('Teachers', Icons.person, '/teachers'),
          _drawerTile('Classes', Icons.category, '/classes'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Attendance', Icons.check_circle, '/attendance'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Exams', Icons.assignment, '/exams'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Timetable', Icons.schedule, '/timetable'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Marks', Icons.grade, '/marks'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Fees', Icons.payments, '/fees'),
          if (user.role == AppRole.admin || user.role == AppRole.teacher)
            _drawerTile('Weekly Report', Icons.article, '/weeklyreport'),
          if (user.role == AppRole.parent)
            _drawerTile('Child Report', Icons.assignment, '/reportcard'),
          _drawerTile('Settings', Icons.settings, '/settings'),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.danger),
            title: Text('Logout', style: TextStyle(color: AppTheme.danger)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homeGrid();
      case 1:
        return _updatesTab();
      default:
        return const SettingsPlaceholder();
    }
  }

  Map<String, dynamic> _item(String title, IconData icon, String route) =>
      {'title': title, 'icon': icon, 'route': route};

  Widget _homeGrid() {
    final role = user.role;
    final List<Map<String, dynamic>> items = [];
    if (role == AppRole.admin || role == AppRole.teacher) {
      items.addAll([
        _item('Students', Icons.people, '/students'),
        _item('Attendance', Icons.check_circle, '/attendance'),
        _item('Exams', Icons.assignment, '/exams'),
        _item('Timetable', Icons.schedule, '/timetable'),
      ]);
      if (role == AppRole.admin) {
        items.add(_item('Teachers', Icons.person, '/teachers'));
        items.add(_item('Classes', Icons.category, '/classes'));
      }
      items.addAll([
        _item('Marks', Icons.grade, '/marks'),
        _item('Fees', Icons.payments, '/fees'),
        _item('Weekly Report', Icons.article, '/weeklyreport'),
      ]);
    } else {
      items.add(_item('Child Report', Icons.assignment, '/reportcard'));
      items.add(_item('Fees', Icons.payments, '/fees'));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(it['icon'] as IconData, size: 36, color: AppTheme.primary),
                const SizedBox(height: 10),
                Text(it['title'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, it['route'] as String),
          );
        },
      ),
    );
  }

  Widget _updatesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update, size: 64, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text('App Updates', style: AppTheme.heading),
          const SizedBox(height: 8),
          Text('Version 1.0.0', style: AppTheme.caption),
          const SizedBox(height: 20),
          Text('Shorebird OTA updates apply automatically on restart.',
              textAlign: TextAlign.center, style: AppTheme.body),
        ],
      ),
    );
  }
}

class SettingsPlaceholder extends StatelessWidget {
  const SettingsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Settings'));
}
