import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import 'alumni_applications_screen.dart';
import 'alumni_home_screen.dart';
import 'alumni_info_screen.dart';
import 'alumni_jobs_screen.dart';
import 'alumni_marketplace_screen.dart';
import 'alumni_profile_screen.dart';
import '../shared/settings_screen.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';

/// Kerangka utama alumni dengan bottom navigation 6 menu.
class AlumniMainScreen extends StatefulWidget {
  final int initialIndex;
  const AlumniMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AlumniMainScreen> createState() => AlumniMainScreenState();
}

class AlumniMainScreenState extends State<AlumniMainScreen> {
  late int _index = widget.initialIndex;

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    const pages = [
      AlumniHomeScreen(),
      AlumniJobsScreen(),
      AlumniInfoScreen(),
      AlumniApplicationsScreen(),
      AlumniMarketplaceScreen(),
      AlumniProfileScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primary),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text('SAPA Alumni',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Beranda'),
                onTap: () {
                  Navigator.pop(context);
                  goToTab(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Profil'),
                onTap: () {
                  Navigator.pop(context);
                  goToTab(5);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Keluar'),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: goToTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Lowongan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_outlined),
              activeIcon: Icon(Icons.campaign_rounded),
              label: 'Informasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Lamaran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Marketplace',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper berpindah tab dari layar anak.
void goToAlumniTab(BuildContext context, int index) {
  context.findAncestorStateOfType<AlumniMainScreenState>()?.goToTab(index);
}
