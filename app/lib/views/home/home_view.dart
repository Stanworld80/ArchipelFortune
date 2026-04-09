import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_view.dart';
import '../game/collections_view.dart';
import '../game/game_dashboard_view.dart';
import '../../models/user_model.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('L\'Archipel de la Fortune'),
        backgroundColor: Colors.transparent, // AppBar Transparente pour le dégradé
        elevation: 0,
        actions: [
          userProfileAsync.maybeWhen(
            data: (profile) => profile == null ? const SizedBox.shrink() : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'admin') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminView()));
                } else if (value == 'logout') {
                  ref.read(authControllerProvider).signOut();
                }
              },
              child: Semantics(
                label: 'PROFILE_BTN',
                button: true,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, color: Colors.brown),
                  ),
                ),
              ),
              itemBuilder: (context) => [
                if (profile.role == 'admin' || profile.role == 'superAdmin')
                  const PopupMenuItem<String>(
                    value: 'admin',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('Panel Admin'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Déconnexion'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.collections_bookmark, color: Colors.amber),
            tooltip: 'Mes Collections',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CollectionsView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004D40), // Dark Teal
              Color(0xFF00796B), // Medium Teal
              Color(0xFF009688), // Teal
            ],
          ),
        ),
        child: userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profil non trouvé.', style: TextStyle(color: Colors.white)));
            }
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.amberAccent, Colors.orange],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Text(
                          'Archipel de la Fortune !!',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        'Bienvenue, ${profile.displayName} !', 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.amber, width: 2)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                          child: Column(
                            children: [
                              Text('Rôle: ${profile.role}', style: const TextStyle(fontSize: 20, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${profile.piecesOr} Pièces d\'Or',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Semantics(
                        label: 'EXPLORE_MAIN_BTN',
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.explore, size: 28),
                          label: const Text('EXPLORER L\'ARCHIPEL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.brown[900],
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 10,
                          ),
                          onPressed: () {
                            _showPreparationDialog(context, ref, profile);
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Une aventure d\'exploration , de découvertes et de fortune vous attend...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.white))),
        ),
      ),
    );
  }

  void _showPreparationDialog(BuildContext context, WidgetRef ref, UserModel profile) {
    int provisionsToBuy = 20;
    int woodToBuy = 1;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int totalCost = (provisionsToBuy ~/ 10) * 5 + (woodToBuy * 10);
            bool canAfford = profile.piecesOr >= totalCost;

            return AlertDialog(
              backgroundColor: const Color(0xFF004D40),
              title: const Text('Préparation du Navire', style: TextStyle(color: Colors.amber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Combien de provisions et de bois souhaitez-vous emporter ?', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.apple, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Provisions ($provisionsToBuy)')),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: provisionsToBuy > 10 ? () => setState(() => provisionsToBuy -= 10) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => setState(() => provisionsToBuy += 10),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.handyman, color: Colors.brown),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Bois ($woodToBuy)')),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: woodToBuy > 0 ? () => setState(() => woodToBuy -= 1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => setState(() => woodToBuy += 1),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Coût Total:', style: TextStyle(color: Colors.white)),
                      Text('$totalCost 🪙', style: TextStyle(color: canAfford ? Colors.amber : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (!canAfford)
                    const Text('Or insuffisant !', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
                ),
                  onPressed: canAfford ? () async {
                    setState(() => _isLoading = true);
                    try {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.updateUserField(profile.uid, 'piecesOr', profile.piecesOr - totalCost);
                      
                      const int? testSeed = bool.hasEnvironment('TEST_SEED') ? int.fromEnvironment('TEST_SEED') : null;
                      
                      await ref.read(sessionProvider.notifier).startNewSession(
                        startingProvisions: provisionsToBuy,
                        startingBois: woodToBuy,
                        seed: testSeed,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GameDashboardView()),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    } finally {
                      if (context.mounted) setState(() => _isLoading = false);
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.brown))
                    : const Text('Prendre la Mer'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
