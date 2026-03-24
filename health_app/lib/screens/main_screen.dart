import 'dart:ui';
import 'package:flutter/material.dart';
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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AiHubScreen(),
    ResearchScreen(),
    TrackingHubScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GlassBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(Icons.home_rounded,          Icons.home_outlined,      'Home',      AppTheme.neon),
    _NavItem(Icons.smart_toy_rounded,     Icons.smart_toy_outlined, 'KI-Arzt',  AppTheme.colorAI),
    _NavItem(Icons.science_rounded,       Icons.science_outlined,   'Recherche', AppTheme.colorResearch),
    _NavItem(Icons.monitor_heart_rounded, Icons.monitor_heart_outlined, 'Tracking', AppTheme.colorActivity),
    _NavItem(Icons.settings_rounded,      Icons.settings_outlined,  'Settings',  AppTheme.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final isActive = i == currentIndex;
                return _NavButton(
                  item: item,
                  isActive: isActive,
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

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final Color color;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label, this.color);
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _glow = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _scale.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow-Hintergrund
                    if (widget.isActive)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.item.color
                              .withOpacity(0.15 * _glow.value),
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.color
                                  .withOpacity(0.3 * _glow.value),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    Icon(
                      widget.isActive
                          ? widget.item.activeIcon
                          : widget.item.inactiveIcon,
                      color: widget.isActive
                          ? widget.item.color
                          : AppTheme.textMuted,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.isActive
                      ? widget.item.color
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
