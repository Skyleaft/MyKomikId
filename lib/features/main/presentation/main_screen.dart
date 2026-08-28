import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../settings/presentation/more_screen.dart';
import '../../settings/services/update_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _discoverSortBy;
  String? _discoverSearch;
  DateTime? _lastBackPressTime;

  void _navigateToDiscover({String? sortBy, String? search}) {
    setState(() {
      _discoverSortBy = sortBy;
      _discoverSearch = search;
      _currentIndex = 2;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final updateService = UpdateService();
    final updateData = await updateService.checkForUpdate();

    if (updateData != null && mounted) {
      _showUpdateDialog(updateData);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A new version (${updateData['version']}) is available.'),
            const SizedBox(height: 8),
            Text(
              updateData['body'] ?? 'Performance improvements and bug fixes.',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final url = Uri.parse(updateData['url']);
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  void _navigateTo(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      HomeScreen(
        key: const ValueKey('home'),
        onNavigateToDiscover: _navigateToDiscover,
      ),
      const LibraryScreen(key: ValueKey('library')),
      DiscoverScreen(
        key: const ValueKey('discover'),
        initialSearch: _discoverSearch,
        sortBy: _discoverSortBy,
      ),
      const MoreScreen(key: ValueKey('more')),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If not on Home tab, switch to Home first
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return;
        }

        // Double back to exit handler
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            if (isDesktop)
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _navigateTo,
                backgroundColor: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: IconThemeData(color: AppColors.primary),
                selectedLabelTextStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 12,
                ),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.auto_stories_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.collections_bookmark_outlined),
                    selectedIcon: Icon(Icons.collections_bookmark_rounded),
                    label: Text('Library'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore_rounded),
                    label: Text('Discover'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.more_horiz_rounded),
                    selectedIcon: Icon(Icons.more_horiz_rounded),
                    label: Text('More'),
                  ),
                ],
              ),
            Expanded(
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.03),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentIndex),
                      child: screens[_currentIndex],
                    ),
                  ),
                  if (!isDesktop)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AppBottomNav(
                        currentIndex: _currentIndex,
                        onTap: _navigateTo,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
