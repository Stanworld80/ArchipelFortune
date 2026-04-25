import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_painter.dart';
import 'loot_overlay.dart';
import 'bank_overlay.dart';

import '../../providers/session_provider.dart';
import '../../models/session_model.dart';
import 'collections_view.dart';
import 'journal_view.dart';
import 'minimap_view.dart';

class GameDashboardView extends ConsumerStatefulWidget {
  const GameDashboardView({super.key});

  @override
  ConsumerState<GameDashboardView> createState() => _GameDashboardViewState();
}

class _GameDashboardViewState extends ConsumerState<GameDashboardView> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late AnimationController _flashController;
  late AnimationController _blinkController;
  String? _lastStatusMessage;
  ui.Image? _mapBg;
  ui.Image? _shipIcon;
  ui.Image? _islandIcon;
  ui.Image? _reefIcon;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _loadAssets();
  }

  Future<void> _loadAssets() async {
    _mapBg = await _loadImage('assets/images/mer.png');
    _shipIcon = await _loadImage('assets/images/ship_sprite2.png');
    _islandIcon = await _loadImage('assets/images/island_sprite.png');
    _reefIcon = await _loadImage('assets/images/reef1.png');
    if (mounted) setState(() {});
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
    _flashController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _triggerFeedback(String message) {
    final msg = message.toUpperCase();
    if (msg.contains('PERDEZ') || msg.contains('ATTAQUE') || msg.contains('DÉGÂTS') || msg.contains('NAUFRAGE')) {
      _shakeController.forward(from: 0);
      _flashController.forward(from: 0).then((_) => _flashController.reverse());
    }
  }

  void _showProvisionWarning(int threshold) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.amber, width: 2)),
        title: Row(
          children: [
            Icon(threshold == 5 ? Icons.report_problem : Icons.warning, color: Colors.amber),
            const SizedBox(width: 10),
            const Text('Attention Matelot !', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          threshold == 10 
            ? 'Vos provisions sont basses (moins de 10). Pensez à accoster bientôt !'
            : 'ALERTE : Provisions critiques (moins de 5) ! La famine guette votre équipage.',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('COMPRIS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    // Trigger feedback on status message change
    if (session?.statusMessage != null && session?.statusMessage != _lastStatusMessage) {
      _lastStatusMessage = session!.statusMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerFeedback(session.statusMessage!);
      });
    }

    // Low provisions warnings
    ref.listen<int?>(sessionProvider.select((s) => s?.provisions), (previous, next) {
      if (next == null) return;
      if (previous != null) {
        if (next < 10 && previous >= 10) {
          _showProvisionWarning(10);
        } else if (next < 5 && previous >= 5) {
          _showProvisionWarning(5);
        }
      }
    });

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
          // Bouton Collection (petit bouton rond)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CollectionsView()),
              ),
              icon: const Icon(Icons.collections_bookmark, size: 20),
              tooltip: 'Collection',
              style: IconButton.styleFrom(
                backgroundColor: Colors.teal.shade900.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bouton Journal
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const JournalView(),
              ),
              icon: const Icon(Icons.history_edu, size: 20),
              tooltip: 'JOURNAL_BTN',
              style: IconButton.styleFrom(
                backgroundColor: Colors.teal.shade900.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bouton Minimap
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IconButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const MiniMapView(),
              ),
              icon: const Icon(Icons.map, size: 20),
              tooltip: 'MINIMAP_BTN',
              style: IconButton.styleFrom(
                backgroundColor: Colors.teal.shade900.withValues(alpha: 0.4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Or
          Center(
            child: Text(
              '${session.orVolatil} 🪙',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
            ),
          ),
          const SizedBox(width: 12),

          // Kits de Réparation
          Center(
            child: Text(
              '${session.boisCharpente} 🛠️',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD7CCC8)),
            ),
          ),
          const SizedBox(width: 12),

          // Provisions
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AnimatedBuilder(
                animation: _blinkController,
                builder: (context, child) {
                  final provisions = session.provisions;
                  Color color = Colors.white;
                  FontWeight weight = FontWeight.normal;
                  double opacity = 1.0;

                  if (provisions < 10) {
                    color = Colors.red;
                    weight = FontWeight.bold;
                  }
                  
                  if (provisions < 5) {
                    opacity = _blinkController.value;
                  }

                  return Opacity(
                    opacity: opacity,
                    child: Text(
                      '$provisions 🍎',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: weight,
                        color: color,
                      ),
                    ),
                  );
                },
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
              color: const Color(0xFF2D1B13), // Bois sombre
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Calcul de la secousse
                      double shake = 0;
                      if (_shakeController.isAnimating) {
                        shake = sin(_shakeController.value * pi * 10) * 8 * (1 - _shakeController.value);
                      }

                      return Transform.translate(
                        offset: Offset(shake, shake / 2),
                        child: Semantics(
                          label: 'SHIP_ICON',
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: MapPainter(
                                session: session, 
                                tileSize: MediaQuery.of(context).size.shortestSide / 5,
                                background: _mapBg,
                                shipImage: _shipIcon,
                                islandImage: _islandIcon,
                                reefImage: _reefIcon,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Flash de dégâts
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashController,
              builder: (context, child) {
                return Container(
                  color: Colors.red.withValues(alpha: _flashController.value * 0.4),
                );
              },
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
                  color: Colors.black.withOpacity(0.8),
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



          // Contrôles de Navigation (Barre de Gouvernail)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ShipControlWheel(
                session: session,
                onMove: (dir) async {
                  HapticFeedback.lightImpact();
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
                      onPressed: () async {
                        await ref.read(sessionProvider.notifier).finishExpedition(isSuccess: false);
                        
                        // Retour au port
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('RETOUR AU PORT'),
                    ),

                  ],
                ),
              ),
            ),

          // --- NOUVEAUX OVERLAYS D'ESCALE ---
          
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

class ShipControlWheel extends StatelessWidget {
  final SessionState session;
  final Function(String) onMove;

  const ShipControlWheel({super.key, required this.session, required this.onMove});

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 130;
    const int mapSize = 64;

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

    // Edge check (uniquement pour le mouvement vers l'avant)
    bool isEdge(int arrowAngle) {
      if (getMoveType(arrowAngle) != 'forward') return false;

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
              color: Colors.black.withOpacity(0.2),
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
            semanticLabel: 'MOVE_UP_BTN',
            onTap: () => onMove(getMoveType(0)),
          ),
          _DirectionArrow(
            angle: 90,
            icon: Icons.keyboard_arrow_right,
            isHidden: isReverse(90),
            isDisabled: isEdge(90),
            semanticLabel: 'MOVE_RIGHT_BTN',
            onTap: () => onMove(getMoveType(90)),
          ),
          _DirectionArrow(
            angle: 180,
            icon: Icons.keyboard_arrow_down,
            isHidden: isReverse(180),
            isDisabled: isEdge(180),
            semanticLabel: 'MOVE_DOWN_BTN',
            onTap: () => onMove(getMoveType(180)),
          ),
          _DirectionArrow(
            angle: 270,
            icon: Icons.keyboard_arrow_left,
            isHidden: isReverse(270),
            isDisabled: isEdge(270),
            semanticLabel: 'MOVE_LEFT_BTN',
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
  final String semanticLabel;
  final VoidCallback onTap;

  const _DirectionArrow({
    required this.angle,
    required this.icon,
    this.isHidden = false,
    this.isDisabled = false,
    required this.semanticLabel,
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
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: !isDisabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: isDisabled ? null : (_) => onTap(),
            onTap: isDisabled ? null : () {}, // Keep empty onTap to maintain InkWell visual effects
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDisabled ? Colors.grey.withOpacity(0.5) : Colors.teal.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Icon(icon, color: isDisabled ? Colors.white38 : Colors.white, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}
