import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

/// Shell principal avec bottom navigation.
/// Wraps Dashboard, Animaux, RDV, Profil dans un StatefulShellRoute.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    _NavItem(Icons.pets_outlined, Icons.pets, 'Animaux'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'RDV'),
    _NavItem(Icons.person_outline, Icons.person, 'Profil'),
  ];

  void _onTap(int i) {
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final idx = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: _onTap,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.4),
        destinations: _items
            .map((i) => NavigationDestination(
                  icon: Icon(i.icon),
                  selectedIcon: Icon(i.activeIcon),
                  label: i.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
