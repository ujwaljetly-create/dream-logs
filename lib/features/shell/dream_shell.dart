import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../discover/discover_screen.dart';
import '../create/create_dream_screen.dart';
import '../cast/dream_cast_screen.dart';
import '../profile/profile_screen.dart';

class DreamShell extends StatefulWidget {
  const DreamShell({super.key});
  @override
  State<DreamShell> createState() => _DreamShellState();
}

class _DreamShellState extends State<DreamShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    DiscoverScreen(),
    CreateDreamScreen(),
    DreamCastScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: DreamColors.surface,
        indicatorColor: DreamColors.violet.withValues(alpha: .25),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Dream'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Cast'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
