import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: navigationShell,
      bottomNavigationBar: _PremiumBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _PremiumBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_PremiumBottomNavBar> createState() => _PremiumBottomNavBarState();
}

class _PremiumBottomNavBarState extends State<_PremiumBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutCubic,
    );
    _indicatorController.forward();
  }

  @override
  void didUpdateWidget(covariant _PremiumBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _indicatorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        // Gradient background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1C1F2A).withAlpha(245),
            const Color(0xFF14161F),
          ],
        ),
        // Multi-layer shadow for depth
        boxShadow: [
          // Top highlight
          BoxShadow(
            color: Colors.white.withAlpha(5),
            offset: const Offset(0, -1),
            blurRadius: 0,
          ),
          // Main shadow
          BoxShadow(
            color: Colors.black.withAlpha(80),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
          // Ambient glow
          BoxShadow(
            color: const Color(0xFFEC5B13).withAlpha(10),
            offset: const Offset(0, -10),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating indicator background
          AnimatedBuilder(
            animation: _indicatorAnimation,
            builder: (context, child) {
              return _FloatingIndicator(
                index: widget.currentIndex,
                previousIndex: _previousIndex,
                animation: _indicatorAnimation.value,
                itemCount: 5,
              );
            },
          ),
          // Navigation items
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  isActive: widget.currentIndex == 0,
                  onTap: () => widget.onTap(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Quotes',
                  isActive: widget.currentIndex == 1,
                  onTap: () => widget.onTap(1),
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Clients',
                  isActive: widget.currentIndex == 2,
                  onTap: () => widget.onTap(2),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  isActive: widget.currentIndex == 3,
                  onTap: () => widget.onTap(3),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  isActive: widget.currentIndex == 4,
                  onTap: () => widget.onTap(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIndicator extends StatelessWidget {
  final int index;
  final int previousIndex;
  final double animation;
  final int itemCount;

  const _FloatingIndicator({
    required this.index,
    required this.previousIndex,
    required this.animation,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / itemCount;
    final indicatorWidth = itemWidth * 0.75;
    final indicatorX = itemWidth * index + (itemWidth - indicatorWidth) / 2;

    // Calculate position for smooth transition
    final previousX =
        itemWidth * previousIndex + (itemWidth - indicatorWidth) / 2;
    final currentX = indicatorX;

    final position = previousX + (currentX - previousX) * animation;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      left: position,
      top: 8,
      child: Container(
        width: indicatorWidth,
        height: 55,
        decoration: BoxDecoration(
          // Glass morphism effect
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEC5B13).withAlpha(40),
              const Color(0xFFEC5B13).withAlpha(15),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEC5B13).withAlpha(60),
            width: 1,
          ),
          // Glow effect
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC5B13).withAlpha(50),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFEC5B13).withAlpha(30),
              blurRadius: 30,
              offset: const Offset(0, 8),
              spreadRadius: -5,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glow effect for active item
            if (widget.isActive)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC5B13).withAlpha(80),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _IconWithGlow(
                        icon: widget.activeIcon,
                        isActive: widget.isActive,
                      ),
                    ),
                  );
                },
              )
            else
              _IconWithGlow(
                icon: widget.icon,
                isActive: widget.isActive,
              ),
            const SizedBox(height: 4),
            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                color: widget.isActive
                    ? const Color(0xFFEC5B13)
                    : Colors.grey.shade500,
                letterSpacing: widget.isActive ? 0.3 : 0,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWithGlow extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _IconWithGlow({
    required this.icon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 24,
        color: isActive ? const Color(0xFFEC5B13) : Colors.grey.shade500,
        // Add subtle shadow for depth
        shadows: isActive
            ? [
                Shadow(
                  color: const Color(0xFFEC5B13).withAlpha(150),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
    );
  }
}
