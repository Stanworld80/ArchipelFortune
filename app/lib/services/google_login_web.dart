import 'package:firebase_auth/firebase_auth.dart';

Future<UserCredential?> googleLogin(FirebaseAuth auth) async {
  final GoogleAuthProvider googleProvider = GoogleAuthProvider();
  return await auth.signInWithPopup(googleProvider);
}
