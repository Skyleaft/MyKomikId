import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_icon/animated_icon.dart';
import '../constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1024;

    // Responsive padding and height
    final EdgeInsetsGeometry margin = isDesktop
        ? const EdgeInsets.only(left: 48, right: 48, bottom: 32)
        : isTablet
        ? const EdgeInsets.only(left: 36, right: 36, bottom: 28)
        : const EdgeInsets.only(left: 24, right: 24, bottom: 24);

    final double height = isDesktop
        ? 72
        : isTablet
        ? 68
        : 64;

    // Responsive border radius
    final double borderRadius = isDesktop
        ? 36
        : isTablet
        ? 34
        : 32;

    return Container(
      margin: margin,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight)
                      .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  AnimateIcons.home,
                  'Home',
                  isTablet || isDesktop,
                ),
                _buildNavItem(
                  context,
                  1,
                  AnimateIcons.bookmark,
                  'Library',
                  isTablet || isDesktop,
                ),
                _buildNavItem(
                  context,
                  2,
                  AnimateIcons.compass,
                  'Discover',
                  isTablet || isDesktop,
                ),
                _buildNavItem(
                  context,
                  3,
                  AnimateIcons.circlesMenu3,
                  'More',
                  isTablet || isDesktop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    AnimateIcons animateIcon,
    String label,
    bool showLabel,
  ) {
    final isActive = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: isActive ? 40 : 36,
                  height: isActive ? 40 : 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: AnimateIcon(
                      key: ValueKey('nav_item_$index'),
                      onTap: () => onTap(index),
                      iconType: IconType.animatedOnTap,
                      height: isActive ? 26 : 24,
                      width: isActive ? 26 : 24,
                      color: isActive
                          ? AppColors.primary
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppColors.secondary,
                      animateIcon: animateIcon,
                    ),
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : Colors.grey,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    child: Text(label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
