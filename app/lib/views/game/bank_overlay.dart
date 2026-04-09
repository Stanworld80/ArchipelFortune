import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';

class BankOverlay extends ConsumerWidget {
  const BankOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    if (session == null || userProfile == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black87,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            color: Colors.teal.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.amber, width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance, color: Colors.amber, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'BANQUE DU CAPITAINE',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _RowInfo(label: 'Or Sécurisé (Banque):', value: '${userProfile.piecesOr} 🪙', color: Colors.amber),
                  _RowInfo(label: 'Or en Main (Navire):', value: '${session.orVolatil} 🪙', color: Colors.amberAccent),
                  const SizedBox(height: 24),
                  
                  // Action : Sécuriser
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.brown[900],
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.security),
                    label: const Text('SÉCURISER L\'OR SUR LE PROFIL', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: session.orVolatil > 0 ? () async {
                      final newPermanentGold = userProfile.piecesOr + session.orVolatil;
                      // Update Firestore via firestoreServiceProvider
                      await ref.read(firestoreServiceProvider).updateUserField(userProfile.uid, 'piecesOr', newPermanentGold);
                      // Reset volatile gold in session
                      ref.read(sessionProvider.notifier).addLootToCargaison(-session.orVolatil, 0, 0);
                    } : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Action : Ravitaillement
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.apple),
                    label: const Text('RAVITAILLER (10 🍎 pour 5 🪙)'),
                    onPressed: userProfile.piecesOr >= 5 ? () async {
                       await ref.read(firestoreServiceProvider).updateUserField(userProfile.uid, 'piecesOr', userProfile.piecesOr - 5);
                       ref.read(sessionProvider.notifier).addLootToCargaison(0, 10, 0);
                    } : null,
                  ),
                  
                  const SizedBox(height: 40),
                  const Text('Que souhaitez-vous faire ?', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
                          onPressed: () {
                            if (session.orVolatil > 0) {
                              _showQuitConfirmation(context, ref, session.orVolatil);
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text('STOPPER ICI'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                          onPressed: () {
                            ref.read(sessionProvider.notifier).resumeExpedition();
                          },
                          child: const Text('REPRENDRE LA MER'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuitConfirmation(BuildContext context, WidgetRef ref, int volatilGold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.teal.shade900,
        title: const Text('ATTENTION', style: TextStyle(color: Colors.redAccent)),
        content: Text(
          'Il vous reste $volatilGold 🪙 non sécurisées dans votre cargaison. '
          'Si vous stoppez l\'expédition maintenant, cet or sera PERDU !',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER', style: TextStyle(color: Colors.amber)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pop(); // Exit game
            },
            child: const Text('ABANDONNER L\'OR ET QUITTER'),
          ),
        ],
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RowInfo({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
