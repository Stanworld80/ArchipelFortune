import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;
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

  @override
  void initState() {
    super.initState();
  }

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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/landing_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // Static Compass Rose in background
          Positioned(
            top: -100,
            right: -100,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/compass_rose.png',
                width: 400,
                height: 400,
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Treasure Chest (Static)
                  Image.asset(
                    'assets/images/treasure_chest.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  
                  // Branding Title
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.amber.shade200, Colors.amber.shade700, Colors.amber.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      "L'Archipel de la Fortune",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          const Shadow(color: Colors.black87, offset: Offset(4, 4), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "QUÊTE DE GLOIRE ET DE TRÉSORS",
                    style: GoogleFonts.cinzel(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Card with Glassmorphism
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isLogin ? 'AUTHENTIFICATION' : 'REJOINDRE L\'ÉQUIPAGE',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade100,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email de l\'Explorateur',
                                  icon: Icons.alternate_email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Mot de Passe Secret',
                                  icon: Icons.vpn_key_outlined,
                                  obscureText: true,
                                ),
                                const SizedBox(height: 32),
                                if (_isLoading)
                                  const CircularProgressIndicator(color: Colors.amber)
                                else ...[
                                  _buildActionButton(
                                    onPressed: _submit,
                                    label: _isLogin ? 'LANCER L\'AVENTURE' : 'SIGNER LE CONTRAT',
                                    isPrimary: true,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                      });
                                    },
                                    child: Text(
                                      _isLogin ? 'NOUVEAU RECRUT ? CRÉER UN PROFIL' : 'DÉJÀ MEMBRE ? SE CONNECTER',
                                      style: GoogleFonts.outfit(
                                        color: Colors.amber.shade100,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text("OU", style: GoogleFonts.cinzel(color: Colors.white54, fontSize: 12)),
                                      ),
                                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildActionButton(
                                    onPressed: _loginWithGoogle,
                                    label: 'CONTINUER AVEC GOOGLE',
                                    icon: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 30),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Footer
                  Text(
                    "Version 0.1.2 • © 2026 Stanislas Selle Informatique",
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.amber.shade300, size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.amber, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    bool isPrimary = false,
    Widget? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isPrimary
            ? LinearGradient(
                colors: [Colors.amber.shade700, Colors.amber.shade900],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                )
              ]
            : null,
        border: !isPrimary ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: GoogleFonts.cinzel(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
