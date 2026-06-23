import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import 'dashboard_screen.dart';
import 'projects_screen.dart';
import 'cotisations_screen.dart';
import 'members_screen.dart';
import 'reminders_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    ProjectsScreen(),
    CotisationsScreen(),
    MembersScreen(),
    RemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().language;
    final s = AppStrings.get;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: s('nav.dashboard', lang)),
          NavigationDestination(icon: const Icon(Icons.folder_open_rounded), label: s('nav.projects', lang)),
          NavigationDestination(icon: const Icon(Icons.credit_card_rounded), label: s('nav.cotisations', lang)),
          NavigationDestination(icon: const Icon(Icons.group_rounded), label: s('nav.members', lang)),
          NavigationDestination(icon: const Icon(Icons.notifications_rounded), label: s('nav.reminders', lang)),
        ],
      ),
    );
  }
}
