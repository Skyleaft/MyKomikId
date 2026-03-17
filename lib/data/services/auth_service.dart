import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_manga_reader/core/di/injection.dart';
import 'package:my_manga_reader/data/services/manga_api_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      // 🌐 WEB FLOW
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(provider);

        // Fetch ID token and send to backend
        final idToken = await userCredential.user?.getIdToken();
        if (idToken != null) {
          await getIt<MangaApiService>().loginWithFirebase(idToken);
        }

        return userCredential.user;
      }

      // 🤖 ANDROID FLOW
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Fetch ID token and send to backend
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await getIt<MangaApiService>().loginWithFirebase(idToken);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase error: ${e.code}");
      rethrow;
    } catch (e) {
      print("Unknown error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    
    // Clear backend JWT token
    await getIt<MangaApiService>().logout();

    await _auth.signOut();
  }
}
