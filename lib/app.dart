import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:protocol_handler/protocol_handler.dart';
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

class _AuthWrapperState extends State<AuthWrapper>
    with ProtocolListener, WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool _isCheckingAuth = true;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    protocolHandler.addListener(this);
    _initDeepLinks();
    _checkAuthState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    protocolHandler.removeListener(this);
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendHeartbeat();
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopHeartbeat();
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final apiService = getIt<MangaApiService>();
        if (apiService.jwtToken != null) {
          await apiService.patchUserHeartbeat();
        }
      } catch (e) {
        debugPrint('Failed to send heartbeat: $e');
      }
    }
  }

  @override
  void onProtocolUrlReceived(String url) {
    debugPrint('Received protocol url: $url');
    final uri = Uri.tryParse(url);
    if (uri != null) {
      _handleDeepLink(uri);
    }
  }

  Uri? _pendingDeepLink;

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    final initialProtocolUrl = await protocolHandler.getInitialUrl();
    if (initialProtocolUrl != null && initialProtocolUrl.isNotEmpty) {
      final uri = Uri.tryParse(initialProtocolUrl);
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint(
      'Received deep link: $uri (scheme: ${uri.scheme}, host: ${uri.host}, path: ${uri.path}, segments: ${uri.pathSegments})',
    );

    // If app is still checking auth or initializing navigation, queue it
    if (_isCheckingAuth) {
      _pendingDeepLink = uri;
      return;
    }

    String? mangaId;

    // Support open-manga-reader://manga/{id} or open-manga-reader://manga/detail/{id}
    if (uri.host == 'manga') {
      if (uri.pathSegments.isNotEmpty) {
        mangaId = uri.pathSegments.last;
      }
    }
    // Support open-manga-reader:///manga/{id} or http(s)://domain.com/manga/{id}
    else if (uri.pathSegments.contains('manga')) {
      final mangaIndex = uri.pathSegments.indexOf('manga');
      if (uri.pathSegments.length > mangaIndex + 1) {
        mangaId = uri.pathSegments[mangaIndex + 1];
      }
    }
    // Support query parameter fallback e.g. open-manga-reader://manga?id={id}
    if (mangaId == null || mangaId.isEmpty) {
      mangaId = uri.queryParameters['id'] ?? uri.queryParameters['mangaId'];
    }

    if (mangaId != null && mangaId.isNotEmpty) {
      try {
        final apiService = getIt<MangaApiService>();
        final mangaData = await apiService.getMangaDetail(mangaId);
        final manga = MangaDetail.fromMap(mangaData);

        AppRoutes.navigatorKey.currentState?.pushNamed(
          AppRoutes.detail,
          arguments: manga,
        );
      } catch (e) {
        debugPrint('Error handling deep link for mangaId "$mangaId": $e');
      }
    }
  }

  Future<void> _checkAuthState() async {
    try {
      _authSubscription = _authService.authStateChanges.listen(
        (User? user) async {
          if (mounted) {
            if (user != null) {
              _startHeartbeat();
              _sendHeartbeat();
              await _checkApiConfiguration();
            } else {
              _stopHeartbeat();
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
          setState(() {
            _isCheckingAuth = false;
          });
          Navigator.pushReplacementNamed(context, AppRoutes.baseApiSetting);
        }
      } else {
        if (mounted) {
          setState(() {
            _isCheckingAuth = false;
          });
          Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (_pendingDeepLink != null) {
            final link = _pendingDeepLink!;
            _pendingDeepLink = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleDeepLink(link);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
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
