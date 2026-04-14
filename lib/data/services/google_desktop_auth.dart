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

/// Implements Google Sign-In for desktop (Windows / Linux / macOS) using the
/// Authorization Code flow with PKCE (RFC 7636 + RFC 8252).
///
/// ─────────────────────────────────────────────────────────────────────────────
/// SETUP — Google Cloud Console (console.cloud.google.com → APIs & Services →
///         Credentials, project: mykomikid)
/// ─────────────────────────────────────────────────────────────────────────────
/// 1. Click "+ Create Credentials" → "OAuth client ID".
/// 2. Choose application type: **Desktop app** (NOT Web application).
///    Desktop app clients automatically allow any loopback/127.0.0.1 port —
///    no redirect URI registration is needed.
/// 3. Download the JSON or copy the Client ID & Client Secret into your .env.
///
/// WHY Desktop app and not Web application?
///   Web app credentials require the *exact* redirect URI to be pre-registered.
///   Since we use a random free port, this is impossible for Web app type.
///   Desktop app type follows RFC 8252 and accepts any loopback port natively.
///
/// WHY 127.0.0.1 and not localhost?
///   Google's OAuth 2.0 server validates the loopback IP (127.0.0.1) per
///   RFC 8252 §8.3, not the hostname "localhost". Using the IP avoids DNS
///   resolution differences between platforms.
/// ─────────────────────────────────────────────────────────────────────────────
class GoogleDesktopAuth {
  final String clientId;
  final String clientSecret;

  const GoogleDesktopAuth({
    required this.clientId,
    required this.clientSecret,
  });

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Launches a system browser for Google Sign-In and returns tokens on
  /// success, or `null` if the user cancelled.
  Future<GoogleDesktopAuthResult?> signIn() async {
    // 1. Generate PKCE values
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    // 2. Bind loopback server on a random free port.
    //    Use 127.0.0.1 (not localhost) — required by Google's desktop OAuth.
    final server =
        await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;

    // RFC 8252: redirect URI for desktop apps must use 127.0.0.1 loopback.
    final redirectUri = 'http://127.0.0.1:$port';

    // 3. Build authorization URL and launch browser
    final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
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

    // 4. Wait for the redirect and extract the authorization code
    String? code;
    String? error;

    await for (final request in server) {
      final params = request.uri.queryParameters;
      code = params['code'];
      error = params['error'];

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(_buildCallbackHtml(error: error));
      await request.response.close();
      break;
    }

    await server.close(force: true);

    if (error != null || code == null) return null;

    // 5. Exchange code → tokens
    return _exchangeCodeForTokens(
      code: code,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<GoogleDesktopAuthResult?> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final body = <String, String>{
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': codeVerifier,
    };

    final response = await http.post(
      Uri.https('oauth2.googleapis.com', '/token'),
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Token exchange failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = json['id_token'] as String?;
    final accessToken = json['access_token'] as String?;

    if (idToken == null || accessToken == null) {
      throw Exception('Incomplete token payload: $json');
    }

    return GoogleDesktopAuthResult(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// PKCE: cryptographically random 128-char verifier (RFC 7636)
  static String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(128, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// PKCE: BASE64URL(SHA256(verifier)) without padding
  static String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String _buildCallbackHtml({String? error}) {
    final success = error == null;
    final message = success
        ? 'Sign-in successful! You can close this tab and return to the app.'
        : 'Sign-in was cancelled or failed: $error. You can close this tab.';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Sign-In ${success ? 'Successful' : 'Failed'}</title>
  <style>
    body { font-family: sans-serif; display: flex; align-items: center;
           justify-content: center; height: 100vh; margin: 0;
           background: #1a1a2e; color: #e0e0e0; }
    .card { background: #16213e; border-radius: 12px; padding: 40px;
            text-align: center; max-width: 400px;
            box-shadow: 0 8px 32px rgba(0,0,0,.4); }
    h2 { margin-top: 0; color: ${success ? '#4caf50' : '#ff6b6b'}; }
  </style>
</head>
<body>
  <div class="card">
    <h2>${success ? '✓ Sign-In Successful' : '✕ Sign-In Failed'}</h2>
    <p>$message</p>
  </div>
</body>
</html>''';
  }
}
