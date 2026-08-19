import 'package:get_it/get_it.dart';
import '../config/app_config.dart';
import '../network/manga_api_service.dart';
import '../network/sync_service.dart';
import '../services/heartbeat_service.dart';
import '../services/notification_service.dart';
import '../../features/history/services/progression_service.dart';
import '../../features/library/services/library_service.dart';
import '../../features/manga_detail/services/manga_detail_service.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  await AppConfig.init();
  final mangaApiService = MangaApiService();
  await mangaApiService.init();
  getIt.registerSingleton<MangaApiService>(mangaApiService);

  final heartbeatService = HeartbeatService();
  heartbeatService.init();
  getIt.registerSingleton<HeartbeatService>(heartbeatService);

  final notificationService = NotificationService();
  getIt.registerSingleton<NotificationService>(notificationService);

  getIt.registerLazySingleton<SyncService>(() => SyncService());
  getIt.registerLazySingleton<ProgressionService>(() => ProgressionService());
  getIt.registerLazySingleton<LibraryService>(() => LibraryService());
  getIt.registerLazySingleton<MangaDetailService>(() => MangaDetailService());
}

