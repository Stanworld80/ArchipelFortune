import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../core/environment.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield null;
    return;
  }

  final firestoreService = ref.watch(firestoreServiceProvider);
  UserModel? profile = await firestoreService.getUserProfile(user.uid);
  
  if (profile == null) {
    // Determine initial role
    String role = 'player';
    if (user.email == AppEnvironment.superAdminEmail) {
      role = 'superAdmin';
    }

    // Create a new profile if it doesn't exist
    profile = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Capitaine',
      role: role,
      piecesOr: 50, // Default starting gold for new players
      lastLoginAt: DateTime.now(),
    );
    await firestoreService.saveUserProfile(profile);
  } else {
    // Update last login
    profile = profile.copyWith(lastLoginAt: DateTime.now());
    await firestoreService.saveUserProfile(profile);
  }

  yield* firestoreService.getUserProfileStream(user.uid);
});


final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<void> signInWithGoogle() async {
    await ref.read(authServiceProvider).signInWithGoogle();
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    await ref.read(authServiceProvider).signInWithEmailAndPassword(email, password);
  }

  Future<void> registerWithEmailPassword(String email, String password) async {
    await ref.read(authServiceProvider).registerWithEmailAndPassword(email, password);
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
  }
}
