import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'core/di/injection.dart';
import 'core/network/api_config.dart';
import 'core/network/manga_api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/manga_detail/models/manga_detail.dart';
import 'routes/app_pages.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Open Manga Reader',
        navigatorKey: AppRoutes.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: AppRoutes.routes,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isCheckingAuth = true;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkAuthState();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    String? mangaId;
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'manga') {
      mangaId = uri.pathSegments[1];
    } else if (uri.host == 'manga' && uri.pathSegments.isNotEmpty) {
      mangaId = uri.pathSegments[0];
    }

    if (mangaId != null) {
      try {
        final apiService = getIt<MangaApiService>();
        final mangaData = await apiService.getMangaDetail(mangaId);
        final manga = MangaDetail.fromMap(mangaData);

        AppRoutes.navigatorKey.currentState?.pushNamed(
          AppRoutes.detail,
          arguments: manga,
        );
      } catch (e) {
        debugPrint('Error handling deep link: $e');
      }
    }
  }

  Future<void> _checkAuthState() async {
    try {
      _authSubscription = _authService.authStateChanges.listen(
        (User? user) async {
          if (mounted) {
            if (user != null) {
              await _checkApiConfiguration();
            } else {
              setState(() {
                _isCheckingAuth = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isCheckingAuth = false;
            });
          }
        },
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isCheckingAuth) {
          setState(() {
            _isCheckingAuth = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _checkApiConfiguration() async {
    try {
      final configs = await ApiConfigManager.loadApiConfigs();

      if (configs.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.baseApiSetting);
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.baseApiSetting);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Checking authentication...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Provider<AuthService>(
      create: (_) => _authService,
      child: const LoginScreen(),
    );
  }
}
