import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_config.dart';
import 'package:smart_cached_network_image/smart_cached_network_image.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Preload Google Fonts to prevent debug pauses
  await GoogleFonts.pendingFonts;

  // Initialize app configuration
  await AppConfig.init();

  if (!kIsWeb) {
    await SmartCachedNetworkImageProvider.initialize(
      const ImageLoadConfig(
        maxConcurrentRequests: 5,
        requestDelay: Duration(milliseconds: 50),
        retryCount: 3,
        retryDelay: Duration(seconds: 1),
      ),
    );
  }

  await setupInjection();
  runApp(const MyApp());
}
