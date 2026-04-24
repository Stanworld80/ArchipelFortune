import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/environment.dart';

Future<UserCredential?> googleLogin(FirebaseAuth auth) async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: AppEnvironment.googleSignInServerClientId,
    );
    
    debugPrint('Starting Google Sign-In with serverClientId: ${AppEnvironment.googleSignInServerClientId}');
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    
    if (googleUser == null) {
      debugPrint('Google Sign-In cancelled by user.');
      return null;
    }

    debugPrint('Google Sign-In success: ${googleUser.email}');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await auth.signInWithCredential(credential);
  } catch (e) {
    debugPrint('Error during Google Sign-In: $e');
    rethrow;
  }
}
