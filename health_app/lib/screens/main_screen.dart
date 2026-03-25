import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'ai_hub_screen.dart';
import 'research_screen.dart';
import 'tracking_hub_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    AiHubScreen(),
    ResearchScreen(),
    TrackingHubScreen(),
    SettingsScreen(),
  ];

  void _tap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _IosTabBar(currentIndex: _index, onTap: _tap),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _IosTabBar({required this.currentIndex, required this.onTap});

  static const _tabs = [
    _Tab(Icons.house_outlined,           Icons.house_filled,    'Übersicht'),
    _Tab(Icons.stethoscope,              Icons.stethoscope,     'KI-Arzt'),
    _Tab(Icons.biotech_outlined,         Icons.biotech,         'Recherche'),
    _Tab(Icons.monitor_heart_outlined,   Icons.monitor_heart,   'Tracking'),
    _Tab(Icons.gear_outlined,            Icons.gear_outlined,   'Einst.'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 12, right: 12,
        bottom: bottom > 0 ? bottom - 4 : 8,
        top: 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.8),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                return _TabButton(
                  tab: _tabs[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  const _Tab(this.inactiveIcon, this.activeIcon, this.label);
}

class _TabButton extends StatelessWidget {
  final _Tab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab, required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.iosBlue : AppTheme.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isActive ? 36 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: AppTheme.iosBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isActive ? tab.activeIcon : tab.inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
