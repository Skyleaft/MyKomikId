import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/main/presentation/main_screen.dart';
import '../features/manga_detail/presentation/manga_detail_screen.dart';
import '../features/manga_detail/models/manga_detail.dart';
import '../features/reader/presentation/reader_screen.dart';
import '../features/reader/models/reader_content.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/base_api_setting_screen.dart';
import '../features/discover/presentation/search_scrap_screen.dart';
import '../features/discover/presentation/advanced_recommendation_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String reader = '/reader';
  static const String history = '/history';
  static const String baseApiSetting = '/base_api_setting';
  static const String searchScrap = '/search_scrap';
  static const String advancedRecommendation = '/advanced_recommendation';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    home: (context) => const MainScreen(),
    detail: (context) {
      final manga = ModalRoute.of(context)!.settings.arguments as MangaDetail;
      return MangaDetailScreen(manga: manga);
    },
    reader: (context) {
      final content =
          ModalRoute.of(context)!.settings.arguments as ReaderContent;
      return ReaderScreen(content: content);
    },
    history: (context) => const HistoryScreen(),
    baseApiSetting: (context) => const BaseApiSettingScreen(),
    searchScrap: (context) => const SearchScrapScreen(),
    advancedRecommendation: (context) => const AdvancedRecommendationScreen(),
  };
}
