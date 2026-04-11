import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_painter.dart';
import 'loot_overlay.dart';
import 'bank_overlay.dart';
import 'fishing_overlay.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import 'upgrade_shop_view.dart';
import 'quest_log_view.dart';

class GameDashboardView extends ConsumerStatefulWidget {
  const GameDashboardView({super.key});

  @override
  ConsumerState<GameDashboardView> createState() => _GameDashboardViewState();
}

class _GameDashboardViewState extends ConsumerState<GameDashboardView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

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
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: MapPainter(
                          session: session, 
                          tileSize: MediaQuery.of(context).size.shortestSide / 5,
                          animationValue: _animationController.value,
                        ),
                      );
                    },
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const UpgradeShopView(),
                        ),
                        icon: const Icon(Icons.build, size: 14),
                        label: const Text("AMÉLIORER"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => const QuestLogView(),
                        ),
                        icon: const Icon(Icons.history_edu, size: 14),
                        label: const Text("JOURNAL"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5D3B3),
                          foregroundColor: const Color(0xFF5D4037),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Contrôles de Navigation (Barre de Gouvernail)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ShipControlWheel(
                session: session,
                onMove: (dir) async {
                  if (dir == 'forward') await ref.read(sessionProvider.notifier).moveForward();
                  if (dir == 'port') await ref.read(sessionProvider.notifier).movePort();
                  if (dir == 'starboard') await ref.read(sessionProvider.notifier).moveStarboard();
                },
              ),
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
          
          // Phase de Butin (Grattage sur les îles)
          if (session.isAtStopover && session.lootRemaining > 0)
            Builder(builder: (context) {
              final currentTile = session.map[session.x][session.y];
              if (currentTile == TileType.fishing) {
                return const Positioned.fill(child: FishingOverlay());
              }
              return const Positioned.fill(child: LootOverlay());
            }),

          // Phase de Banque et Ravitaillement
          if (session.isAtStopover && session.lootRemaining == 0)
            const Positioned.fill(child: BankOverlay()),
        ],
      ),
    );
  }
}

class ShipControlWheel extends StatelessWidget {
  final SessionState session;
  final Function(String) onMove;

  const ShipControlWheel({super.key, required this.session, required this.onMove});

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 130;
    const int mapSize = 50;

    // Helper to check if a direction is "Reverse"
    bool isReverse(int arrowAngle) {
      return (session.orientation + 180) % 360 == arrowAngle;
    }

    // Helper to check if a direction is Forward relative to orientation
    String getMoveType(int arrowAngle) {
      if (session.orientation == arrowAngle) return 'forward';
      if ((session.orientation + 90) % 360 == arrowAngle) return 'starboard';
      if ((session.orientation - 90 + 360) % 360 == arrowAngle) return 'port';
      return 'none';
    }

    // Edge check
    bool isEdge(int arrowAngle) {
      if (arrowAngle == 0 && session.y == 0) return true;
      if (arrowAngle == 90 && session.x == mapSize - 1) return true;
      if (arrowAngle == 180 && session.y == mapSize - 1) return true;
      if (arrowAngle == 270 && session.x == 0) return true;
      return false;
    }

    return SizedBox(
      width: wheelSize + 100,
      height: wheelSize + 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ombre/Fond du contrôleur
          Container(
            width: wheelSize + 20,
            height: wheelSize + 20,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          
          // La Barre (Gouvernail)
          const Text(
            '☸️', // Emoji gouvernail pour un look thématique immédiat
            style: TextStyle(fontSize: 80),
          ),

          // Les 4 Flèches Directionnelles
          _DirectionArrow(
            angle: 0,
            icon: Icons.keyboard_arrow_up,
            isHidden: isReverse(0),
            isDisabled: isEdge(0),
            onTap: () => onMove(getMoveType(0)),
          ),
          _DirectionArrow(
            angle: 90,
            icon: Icons.keyboard_arrow_right,
            isHidden: isReverse(90),
            isDisabled: isEdge(90),
            onTap: () => onMove(getMoveType(90)),
          ),
          _DirectionArrow(
            angle: 180,
            icon: Icons.keyboard_arrow_down,
            isHidden: isReverse(180),
            isDisabled: isEdge(180),
            onTap: () => onMove(getMoveType(180)),
          ),
          _DirectionArrow(
            angle: 270,
            icon: Icons.keyboard_arrow_left,
            isHidden: isReverse(270),
            isDisabled: isEdge(270),
            onTap: () => onMove(getMoveType(270)),
          ),
        ],
      ),
    );
  }
}

class _DirectionArrow extends StatelessWidget {
  final double angle;
  final IconData icon;
  final bool isHidden;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DirectionArrow({
    required this.angle,
    required this.icon,
    this.isHidden = false,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox.shrink();

    // Positionnement polaire par rapport au centre
    double dist = 75.0;
    double rad = (angle - 90) * pi / 180;
    double dx = cos(rad) * dist;
    double dy = sin(rad) * dist;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDisabled ? Colors.grey.withValues(alpha: 0.5) : Colors.teal.shade700,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Icon(icon, color: isDisabled ? Colors.white38 : Colors.white, size: 40),
          ),
        ),
      ),
    );
  }
}
