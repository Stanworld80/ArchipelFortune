import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_painter.dart';
import 'loot_overlay.dart';
import 'bank_overlay.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';

class GameDashboardView extends ConsumerWidget {
  const GameDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    // Si on arrive ici sans session (ex: refresh), on redirige ou on affiche une erreur
    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Aucune expédition en cours.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour au Port'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation en Mer'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${session.provisions} 🍎',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // La carte 2D Interactive (Vue restreinte 5x5)
          Positioned.fill(
            child: Container(
              color: Colors.blue.shade900,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: MapPainter(session: session, tileSize: MediaQuery.of(context).size.shortestSide / 5),
                  ),
                ),
              ),
            ),
          ),

          // Message d'état (Notifications)
          if (session.statusMessage != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Text(
                  session.statusMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // HUD en bas à gauche
          Positioned(
            bottom: 120,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POSITION: ${session.x}, ${session.y}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('OR EN MAIN: ${session.orVolatil} 🪙', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  Text('LUMBER: ${session.boisCharpente} 🪵', style: const TextStyle(color: Colors.brown)),
                ],
              ),
            ),
          ),

          // Contrôles de Navigation
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavButton(
                  icon: Icons.rotate_left,
                  label: 'BÂBORD',
                  onPressed: () => ref.read(sessionProvider.notifier).movePort(),
                ),
                _NavButton(
                  icon: Icons.arrow_upward,
                  label: 'AVANCER',
                  isMain: true,
                  onPressed: () => ref.read(sessionProvider.notifier).moveForward(),
                ),
                _NavButton(
                  icon: Icons.rotate_right,
                  label: 'TRIBORD',
                  onPressed: () => ref.read(sessionProvider.notifier).moveStarboard(),
                ),
              ],
            ),
          ),

          // Écran de Game Over
          if (session.isGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 80),
                    const SizedBox(height: 16),
                    const Text(
                      'EXPÉDITION TERMINÉE',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        session.statusMessage ?? "Naufrage...",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () {
                        // Retour au port
                        Navigator.of(context).pop();
                      },
                      child: const Text('RETOUR AU PORT'),
                    ),
                  ],
                ),
              ),
            ),

          // --- NOUVEAUX OVERLAYS D'ESCALE ---
          
          // Phase de Butin (Grattage)
          if (session.isAtStopover && session.lootRemaining > 0)
            const Positioned.fill(child: LootOverlay()),

          // Phase de Banque et Ravitaillement
          if (session.isAtStopover && session.lootRemaining == 0)
            const Positioned.fill(child: BankOverlay()),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isMain;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: isMain ? Colors.amber : Colors.teal.shade700,
            foregroundColor: isMain ? Colors.brown[900] : Colors.white,
            padding: EdgeInsets.all(isMain ? 20 : 12),
          ),
          icon: Icon(icon, size: isMain ? 32 : 24),
          tooltip: label,
          onPressed: onPressed,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
