import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/environment.dart';
import 'firebase_options_dev.dart';
import 'firebase_options_prod.dart';

import 'providers/auth_provider.dart';
import 'views/auth/login_view.dart';
import 'views/home/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppEnvironment.printEnv();

  // Initialisation de Firebase
  try {
    if (AppEnvironment.isDev) {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptionsDev.currentPlatform,
        );
      } else {
        // Pour Android, cela chargera le fichier google-services.json que le script build_deploy.sh copie.
        await Firebase.initializeApp();
      }
    } else if (AppEnvironment.isProd) {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptionsProd.currentPlatform,
        );
      } else {
        // Pour Android, google-services-prod.json est copié en google-services.json par le script/CI
        await Firebase.initializeApp();
      }
    } else {
      // Staging : utilise les options par défaut (google-services.json copié par le script)
      await Firebase.initializeApp();
    }
    debugPrint("Firebase Initialized Successfully.");
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(
    const ProviderScope(
      child: ArchipelFortuneApp(),
    ),
  );
}

class ArchipelFortuneApp extends StatelessWidget {
  const ArchipelFortuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Archipel de la Fortune',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends ConsumerWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeView();
        } else {
          return const LoginView();
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('L\'Archipel de la Fortune')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Environnement : ${AppEnvironment.envName}'),
            ],
          ),
        ),
      ),
      error: (e, trace) => Scaffold(
        body: Center(child: Text("Erreur d'authentification: $e")),
      ),
    );
  }
}
