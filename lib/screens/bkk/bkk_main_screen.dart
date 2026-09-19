import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import 'bkk_applicants_screen.dart';
import 'bkk_dashboard_screen.dart';
import 'bkk_jobs_screen.dart';
import 'bkk_profile_screen.dart';

class BkkMainScreen extends StatefulWidget {
  const BkkMainScreen({super.key});

  @override
  State<BkkMainScreen> createState() => BkkMainScreenState();
}

class BkkMainScreenState extends State<BkkMainScreen> {
  int _index = 0;

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    const pages = [
      BkkDashboardScreen(),
      BkkJobsScreen(),
      BkkApplicantsScreen(),
      BkkProfileScreen(),
    ];

    return Scaffold(
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Lowongan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Pelamar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store_rounded),
              label: 'Profil BKK',
            ),
          ],
        ),
      ),
    );
  }
}

void goToBkkTab(BuildContext context, int index) {
  context.findAncestorStateOfType<BkkMainScreenState>()?.goToTab(index);
}
