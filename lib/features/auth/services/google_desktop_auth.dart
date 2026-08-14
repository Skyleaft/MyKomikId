import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Result returned by the desktop Google OAuth flow.
class GoogleDesktopAuthResult {
  final String idToken;
  final String accessToken;

  const GoogleDesktopAuthResult({
    required this.idToken,
    required this.accessToken,
  });
}

class GoogleDesktopAuth {
  final String clientId;
  final String clientSecret;

  const GoogleDesktopAuth({
    required this.clientId,
    required this.clientSecret,
  });

  Future<GoogleDesktopAuthResult?> signIn() async {
    final cleanClientId = clientId.trim();
    if (cleanClientId.isEmpty) {
      throw Exception(
        'Google Desktop Client ID is missing. Please set GOOGLE_DESKTOP_CLIENT_ID in your .env file.',
      );
    }

    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    final redirectUri = 'http://127.0.0.1:$port';

    final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': cleanClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'access_type': 'offline',
      'prompt': 'select_account',
    });

    if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
      await server.close(force: true);
      throw Exception('Could not launch browser for Google Sign-In');
    }

    String? code;
    String? error;

    await for (final request in server) {
      final params = request.uri.queryParameters;
      code = params['code'];
      error = params['error'];

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_buildHtmlResponse(error == null));
      await request.response.close();
      break;
    }

    await server.close();

    if (error != null) {
      throw Exception('Google Sign-In was cancelled or failed: $error');
    }

    if (code == null) return null;

    return _exchangeCodeForTokens(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  }

  Future<GoogleDesktopAuthResult> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final response = await http.post(
      Uri.https('oauth2.googleapis.com', '/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': clientId.trim(),
        if (clientSecret.trim().isNotEmpty) 'client_secret': clientSecret.trim(),
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to exchange authorization code for tokens: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = json['id_token'] as String?;
    final accessToken = json['access_token'] as String?;

    if (idToken == null || accessToken == null) {
      throw Exception('Token response did not contain id_token or access_token');
    }

    return GoogleDesktopAuthResult(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  static String _buildHtmlResponse(bool success) {
    final title = success ? 'Sign-in Successful!' : 'Sign-in Failed';
    final message = success
        ? 'You have successfully signed in. You can close this tab and return to the app.'
        : 'Sign-in was cancelled or encountered an error. You can close this tab.';
    final color = success ? '#22c55e' : '#ef4444';
    final icon = success ? '✓' : '✕';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex; justify-content: center; align-items: center;
      min-height: 100vh; margin: 0; background: #0f172a; color: #f8fafc;
    }
    .card {
      background: #1e293b; border-radius: 16px; padding: 40px;
      text-align: center; max-width: 380px; box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    .icon {
      width: 64px; height: 64px; border-radius: 50%;
      background: $color; color: #fff; font-size: 32px;
      line-height: 64px; margin: 0 auto 20px;
    }
    h1 { font-size: 22px; margin: 0 0 10px; }
    p { font-size: 14px; color: #94a3b8; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">$icon</div>
    <h1>$title</h1>
    <p>$message</p>
  </div>
</body>
</html>
''';
  }
}
