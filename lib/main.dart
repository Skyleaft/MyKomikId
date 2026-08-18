import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show PlatformDispatcher, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop protocol & window setup
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await protocolHandler.register('open-manga-reader');
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(480, 640));
    await windowManager.setTitle('Open Manga Reader');
  }

  // Load .env file
  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Preload Google Fonts
  GoogleFonts.pendingFonts;

  // Initialize app configuration
  await AppConfig.init();

  // Setup Dependency Injection
  await setupInjection();

  // Global Flutter and Platform Error Boundaries
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error\n$stack');
    return true;
  };

  // Set default transparent system overlay on mobile
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const MyApp());
}
