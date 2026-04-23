import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'google_login_stub.dart'
    if (dart.library.html) 'google_login_web.dart'
    if (dart.library.io) 'google_login_mobile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error during email sign in: $e');
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error during email registration: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await googleLogin(_auth);
    } catch (e) {
      debugPrint('Error during Google sign in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
