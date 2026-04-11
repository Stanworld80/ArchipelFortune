import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Le serverClientId correspond au "Web Client ID" du projet Firebase prod.
// À récupérer dans Firebase Console > Authentication > Sign-in method > Google > Configuration web.
// Il faut aussi que le SHA-1 du keystore soit enregistré dans Firebase Console Android app :
//   SHA-1 prod : B1:AC:12:B7:A9:DF:20:9A:71:01:63:DB:D6:E3:B1:87:73:35:74:67
const String? _serverClientIdProd = '417958901427-c88hjkvao549h2fpl5jn5bum21b735hl.apps.googleusercontent.com';

Future<UserCredential?> googleLogin(FirebaseAuth auth) async {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    serverClientId: _serverClientIdProd,
  );
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return await auth.signInWithCredential(credential);
}
