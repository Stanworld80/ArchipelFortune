import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../models/session_model.dart';

class MiniMapView extends ConsumerWidget {
  const MiniMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: const Color(0xFF2D1B13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              label: 'Carte du Monde',
              container: true,
              child: const Text(
                'Carte du Monde',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                ),
                child: CustomPaint(
                  painter: MiniMapPainter(session: session),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Semantics(
                button: true,
                label: 'Fermer',
                child: const Text('Fermer', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniMapPainter extends CustomPainter {
  final SessionState session;
  static const int mapSize = 64;

  MiniMapPainter({required this.session});

  @override
  void paint(Canvas canvas, Size size) {
    final double tileSize = size.width / mapSize;
    final paintSea = Paint()..color = const Color(0xFF003366);
    final paintShallow = Paint()..color = const Color(0xFF00ACC1);
    final paintReef = Paint()..color = Colors.lightBlueAccent;
    final paintIsland = Paint()..color = Colors.deepOrange.shade300;
    final paintContinent = Paint()..color = Colors.brown.shade800;
    final paintFog = Paint()..color = const Color(0xFF1A1A1A);
    final paintShip = Paint()..color = Colors.red;

    // Remplir le fond avec le brouillard
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintFog);

    for (int x = 0; x < mapSize; x++) {
      for (int y = 0; y < mapSize; y++) {
        if (session.discoveredTiles.contains(x * mapSize + y)) {
          final rect = Rect.fromLTWH(x * tileSize, y * tileSize, tileSize, tileSize);
          final tile = session.map[x][y];
          
          Paint tilePaint = paintSea;
          switch (tile) {
            case TileType.sea: tilePaint = paintSea; break;
            case TileType.shallow: tilePaint = paintShallow; break;
            case TileType.reef: tilePaint = paintReef; break;
            case TileType.island: tilePaint = paintIsland; break;
            case TileType.continent: tilePaint = paintContinent; break;
          }
          
          // Afin d'éviter de trop petits carrés avec de petites marges, on utilise drawRect ou un inflate léger
          canvas.drawRect(rect.inflate(0.2), tilePaint);
        }
      }
    }

    // Dessin du bateau
    final shipCenter = Offset(
      session.x * tileSize + tileSize / 2,
      session.y * tileSize + tileSize / 2
    );
    canvas.drawCircle(shipCenter, tileSize * 1.5, paintShip);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return oldDelegate.session != session;
  }
}
