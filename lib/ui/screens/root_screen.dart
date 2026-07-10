import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'home_screen.dart';
import 'eq_screen.dart';
import 'settings_screen.dart';
import '../theme.dart';
import '../widgets/ambient_background.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    EqScreen(),
    SettingsScreen(),
  ];

  void _onSelect(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _index,
          children: _screens,
        ),
        bottomNavigationBar: NativeLiquidGlassUtils.supportsLiquidGlass
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LiquidGlassTabBar(
                items: const [
                  LiquidGlassTabItem(
                    label: 'Audio',
                    icon: NativeLiquidGlassIcon.sfSymbol('waveform'),
                  ),
                  LiquidGlassTabItem(
                    label: 'EQ',
                    icon: NativeLiquidGlassIcon.sfSymbol('slider.horizontal.3'),
                  ),
                  LiquidGlassTabItem(
                    label: 'Settings',
                    icon: NativeLiquidGlassIcon.sfSymbol('gearshape'),
                    selectedIcon:
                        NativeLiquidGlassIcon.sfSymbol('gearshape.fill'),
                  ),
                ],
                currentIndex: _index,
                onTabSelected: _onSelect,
                selectedItemColor: c.accent,
              ),
            )
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _onSelect,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.graphic_eq_outlined),
                  selectedIcon: Icon(Icons.graphic_eq),
                  label: 'Audio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'EQ',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
      ),
    );
  }
}
