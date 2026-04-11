import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    _setLoading(true);
    try {
      if (_isLogin) {
        await ref.read(authControllerProvider).signInWithEmailPassword(email, password);
      } else {
        await ref.read(authControllerProvider).registerWithEmailPassword(email, password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
    _setLoading(false);
  }

  Future<void> _loginWithGoogle() async {
    _setLoading(true);
    try {
      await ref.read(authControllerProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
    _setLoading(false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004D40), // Teal dark
              Color(0xFF00251A), // Near black/teal
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding Titre en Grand (AU-DESSUS)
                Text(
                  "L'Archipel de la Fortune",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade400,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Une aventure de fortune et d'exploration",
                  style: GoogleFonts.sourceSans3(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Formulaire (Carte)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 12,
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin ? 'Authentification' : 'Rejoindre l\'aventure',
                            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 32),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else ...[
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                backgroundColor: Colors.teal.shade800,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _submit,
                              child: Text(_isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin ? 'Pas encore de compte ? Créer un profil' : 'Déjà inscrit ? Se connecter',
                                style: TextStyle(color: Colors.teal.shade700),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text("OU", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: const Icon(Icons.g_mobiledata, size: 36, color: Colors.blue),
                              label: const Text('Continuer avec Google', style: TextStyle(color: Colors.black87)),
                              onPressed: _loginWithGoogle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Footer (AU-DESSOUS)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Text(
                        "Version 0.1.1",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FooterLink(label: "Mentions Légales", onPressed: () {}),
                          const Text(" • ", style: TextStyle(color: Colors.white24)),
                          _FooterLink(label: "À propos", onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "(C) 2026 Stanislas Selle Informatique",
                        style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FooterLink({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, decoration: TextDecoration.underline, fontSize: 14),
        ),
      ),
    );
  }
}
