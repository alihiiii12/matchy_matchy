import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class NavBarDestination {
  const NavBarDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class GlowingBottomNavBar extends StatelessWidget {
  const GlowingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarDestination> items;

  static const _barHeight = 64.0;
  static const _themeAnimDuration = Duration(milliseconds: 450);
  static const _themeAnimCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final _ = themeController.themeMode.value;
      final surface = AppColors.surface;
      final borderColor = AppColors.accent.withValues(alpha: 0.14);
      final shadowColor = AppColors.accent.withValues(alpha: 0.12);

      return AnimatedContainer(
        duration: _themeAnimDuration,
        curve: _themeAnimCurve,
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: _barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                final glowWidth = itemWidth * 0.62;
                final glowStart = safeIndex * itemWidth + (itemWidth - glowWidth) / 2;

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedPositionedDirectional(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      start: glowStart,
                      top: 7,
                      width: glowWidth,
                      height: 48,
                      child: const _GlowIndicator(),
                    ),
                    Row(
                      children: List.generate(items.length, (index) {
                        return Expanded(
                          child: _GlowingNavItem(
                            destination: items[index],
                            selected: index == safeIndex,
                            onTap: () => onTap(index),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

class _GlowIndicator extends StatelessWidget {
  const _GlowIndicator();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: GlowingBottomNavBar._themeAnimDuration,
      curve: GlowingBottomNavBar._themeAnimCurve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.accent.withValues(alpha: 0.24),
            AppColors.softBlue.withValues(alpha: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

class _GlowingNavItem extends StatefulWidget {
  const _GlowingNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavBarDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GlowingNavItem> createState() => _GlowingNavItemState();
}

class _GlowingNavItemState extends State<_GlowingNavItem> with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    widget.onTap();
    await _tapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        splashColor: AppColors.accent.withValues(alpha: 0.12),
        highlightColor: AppColors.accent.withValues(alpha: 0.06),
        child: AnimatedBuilder(
          animation: _tapScale,
          builder: (context, child) {
            return Transform.scale(
              scale: _tapScale.value * (widget.selected ? 1.06 : 1.0),
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: _GlowIcon(
                  key: ValueKey('${widget.destination.label}_${widget.selected}'),
                  icon: widget.selected ? widget.destination.activeIcon : widget.destination.icon,
                  selected: widget.selected,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: GlowingBottomNavBar._themeAnimDuration,
                curve: GlowingBottomNavBar._themeAnimCurve,
                style: TextStyle(
                  fontSize: widget.selected ? 11.5 : 10.5,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected ? AppColors.accent : AppColors.textSecondary,
                  height: 1.1,
                  shadows: widget.selected
                      ? [
                          Shadow(
                            color: AppColors.accent.withValues(alpha: 0.55),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({
    super.key,
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: selected ? 26 : 23,
      color: selected ? AppColors.accent : AppColors.textSecondary,
    );
  }
}
