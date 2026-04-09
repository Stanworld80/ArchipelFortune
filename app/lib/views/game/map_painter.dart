import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/session_model.dart';

class MapPainter extends CustomPainter {
  final SessionState session;
  final double tileSize;

  MapPainter({
    required this.session,
    this.tileSize = 64.0, // On augmente un peu la taille pour le 5x5
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintWater = Paint()..color = Colors.blue.shade800;
    final paintShallow = Paint()..color = Colors.blue.shade400;
    final paintSand = Paint()..color = Colors.amber.shade200;
    final paintGrass = Paint()..color = Colors.green.shade600;
    final paintForest = Paint()..color = Colors.green.shade900;
    final paintReef = Paint()..color = Colors.grey.shade800;
    final paintIsland = Paint()..color = Colors.deepOrange.shade300;
    final paintContinent = Paint()..color = Colors.brown.shade800;

    // Rayon de vision (Spécification: 5x5 centrée sur le navire)
    const int visionRadius = 2; // de -2 à +2 autour du centre

    for (int dx = -visionRadius; dx <= visionRadius; dx++) {
      for (int dy = -visionRadius; dy <= visionRadius; dy++) {
        int targetX = session.x + dx;
        int targetY = session.y + dy;

        // Si hors limites, on dessine du vide ou de l'eau
        if (targetX < 0 || targetX >= 36 || targetY < 0 || targetY >= 36) {
           canvas.drawRect(
            Rect.fromLTWH((dx + visionRadius) * tileSize, (dy + visionRadius) * tileSize, tileSize, tileSize),
            paintWater
          );
          continue;
        }

        TileType tile = session.map[targetX][targetY];
        Paint currentPaint;

        switch (tile) {
          case TileType.sea: currentPaint = paintWater; break;
          case TileType.shallow: currentPaint = paintShallow; break;
          case TileType.sand: currentPaint = paintSand; break;
          case TileType.grass: currentPaint = paintGrass; break;
          case TileType.forest: currentPaint = paintForest; break;
          case TileType.reef: currentPaint = paintReef; break;
          case TileType.island: currentPaint = paintIsland; break;
          case TileType.continent: currentPaint = paintContinent; break;
        }

        final rect = Rect.fromLTWH(
          (dx + visionRadius) * tileSize, 
          (dy + visionRadius) * tileSize, 
          tileSize, 
          tileSize
        );
        canvas.drawRect(rect, currentPaint);
        
        // Bordure subtile pour les cases
        canvas.drawRect(rect, Paint()..color = Colors.white10..style = PaintingStyle.stroke);
      }
    }

    // Dessin du Navire au centre (position 2,2 dans la grille 5x5)
    _drawShip(canvas, visionRadius * tileSize, visionRadius * tileSize, tileSize);
  }

  void _drawShip(Canvas canvas, double offsetX, double offsetY, double size) {
    final shipCenter = Offset(offsetX + size / 2, offsetY + size / 2);
    final shipPaint = Paint()..color = Colors.white;
    
    canvas.save();
    canvas.translate(shipCenter.dx, shipCenter.dy);
    // Rotation du navire selon l'orientation (0:Nord, 90:Est, 180:Sud, 270:Ouest)
    canvas.rotate(session.orientation * pi / 180);

    // Forme de navire simplifiée (un triangle isocèle pointant vers le haut)
    final path = Path();
    path.moveTo(0, -size / 3); // Pointe
    path.lineTo(size / 4, size / 4); // Arrière Droite
    path.lineTo(-size / 4, size / 4); // Arrière Gauche
    path.close();

    canvas.drawPath(path, shipPaint);
    
    // Voile ou mât
    canvas.drawRect(Rect.fromLTWH(-2, -5, 4, 15), Paint()..color = Colors.brown);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.session != session;
  }
}
