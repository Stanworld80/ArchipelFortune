import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/session_model.dart';

class MapPainter extends CustomPainter {
  final SessionState session;
  final double tileSize;
  final double animationValue;

  MapPainter({
    required this.session,
    required this.animationValue,
    this.tileSize = 64.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintWater = Paint()..color = const Color(0xFF003366); // Bleu profond
    final paintShallow = Paint()..color = const Color(0xFF00ACC1); // Turquoise/Cyan
    final paintSand = Paint()..color = Colors.amber.shade200;
    final paintGrass = Paint()..color = Colors.green.shade600;
    final paintForest = Paint()..color = Colors.green.shade900;
    final paintReef = Paint()..color = Colors.grey.shade800;
    final paintIsland = Paint()..color = Colors.deepOrange.shade300;
    final paintContinent = Paint()..color = Colors.brown.shade800;
    final paintPort = Paint()..color = Colors.brown.shade400;

    final paintSnow = Paint()..color = Colors.white;
    final paintIce = Paint()..color = Colors.cyan.shade100;
    final paintJungle = Paint()..color = const Color(0xFF1B5E20); // Vert très profond
    final paintSwamp = Paint()..color = const Color(0xFF3E2723); // Brun maraîcher

    final paintVolcano = Paint()..color = Colors.grey.shade900;
    final paintLava = Paint()..color = Colors.orangeAccent;
    final paintTemple = Paint()..color = Colors.amber.shade700;
    final paintShipwreck = Paint()..color = Colors.brown.shade300;
    final paintPirate = Paint()..color = Colors.black87;

    // Rayon de vision (5x5 centrée sur le navire)
    const int visionRadius = 2;

    for (int dx = -visionRadius; dx <= visionRadius; dx++) {
      for (int dy = -visionRadius; dy <= visionRadius; dy++) {
        int targetX = session.x + dx;
        int targetY = session.y + dy;

        final rect = Rect.fromLTWH(
          (dx + visionRadius) * tileSize, 
          (dy + visionRadius) * tileSize, 
          tileSize, 
          tileSize
        );

        // Si hors limites, on dessine du vide ou de l'eau
        if (targetX < 0 || targetX >= 50 || targetY < 0 || targetY >= 50) {
          canvas.drawRect(rect, paintWater);
          _drawWaves(canvas, rect, animationValue, targetX, targetY);
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
          case TileType.port: currentPaint = paintPort; break;
          case TileType.fishing: currentPaint = paintWater; break;
          case TileType.snow: currentPaint = paintSnow; break;
          case TileType.ice: currentPaint = paintIce; break;
          case TileType.jungle: currentPaint = paintJungle; break;
          case TileType.swamp: currentPaint = paintSwamp; break;
          case TileType.volcano: currentPaint = paintVolcano; break;
          case TileType.temple: currentPaint = paintTemple; break;
          case TileType.shipwreck: currentPaint = paintWater; break; // L'épave est sur l'eau
          case TileType.pirate: currentPaint = paintWater; break; // Le pirate est sur l'eau
        }

        canvas.drawRect(rect, currentPaint);
        
        // Animation des vagues sur l'eau
        if (tile == TileType.sea || tile == TileType.shallow) {
          _drawWaves(canvas, rect, animationValue, targetX, targetY);
        }

        if (tile == TileType.port) {
          _drawPortDetails(canvas, rect);
        }

        if (tile == TileType.volcano) {
          _drawVolcano(canvas, rect);
        }

        if (tile == TileType.temple) {
          _drawTemple(canvas, rect);
        }

        if (tile == TileType.shipwreck) {
          _drawShipwreck(canvas, rect);
        }

        if (tile == TileType.pirate) {
          _drawPirateShip(canvas, rect);
        }

        // Détails spécifiques pour la pêche
        if (tile == TileType.fishing) {
          _drawFishingSpot(canvas, rect, animationValue);
        }
        
        // Bordure subtile pour les cases
        canvas.drawRect(rect, Paint()..color = Colors.white10..style = PaintingStyle.stroke);
      }
    }

    // Dessin du Navire au centre
    _drawShip(canvas, visionRadius * tileSize, visionRadius * tileSize, tileSize);

    // Dessin des indices de découverte (US04)
    _drawDiscoveryIndices(canvas, visionRadius, tileSize);

    // Dessin de la météo (US10)
    _drawWeather(canvas, size, visionRadius);
  }

  void _drawWaves(Canvas canvas, Rect rect, double anim, int tx, int ty) {
    // Utilisation des coordonnées pour un décalage déterministe par case
    final randSeed = (tx * 7 + ty * 13) % 100 / 100.0;
    final paintWave = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final double phase = (anim + randSeed) % 1.0;
    final double waveX = rect.left + (phase * rect.width);
    final double waveY = rect.top + (randSeed * rect.height);

    // Dessine deux petits traits qui défilent
    canvas.drawLine(
      Offset(waveX, waveY), 
      Offset(waveX + 10, waveY), 
      paintWave
    );
    
    // Deuxième vaguelette décalée
    final double phase2 = (phase + 0.5) % 1.0;
    final double waveX2 = rect.left + (phase2 * rect.width);
    final double waveY2 = rect.top + ((1.0 - randSeed) * rect.height);
    canvas.drawLine(
      Offset(waveX2, waveY2), 
      Offset(waveX2 + 8, waveY2), 
      paintWave
    );
  }

  void _drawPortDetails(Canvas canvas, Rect rect) {
    final detailPaint = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2;
    // Quelques traits pour simuler des planches de bois
    canvas.drawLine(rect.topLeft + const Offset(5, 5), rect.bottomLeft + const Offset(5, -5), detailPaint);
    canvas.drawLine(rect.topCenter, rect.bottomCenter, detailPaint);
    canvas.drawLine(rect.topRight + const Offset(-5, 5), rect.bottomRight + const Offset(-5, -5), detailPaint);
  }

  void _drawShip(Canvas canvas, double offsetX, double offsetY, double size) {
    final shipCenter = Offset(offsetX + size / 2, offsetY + size / 2);
    final shipPaint = Paint()..color = Colors.white;
    
    canvas.save();
    canvas.translate(shipCenter.dx, shipCenter.dy);
    canvas.rotate(session.orientation * pi / 180);

    final path = Path();
    path.moveTo(0, -size / 3);
    path.lineTo(size / 4, size / 4);
    path.lineTo(-size / 4, size / 4);
    path.close();

    canvas.drawPath(path, shipPaint);
    canvas.drawRect(Rect.fromLTWH(-2, -5, 4, 15), Paint()..color = Colors.brown);

    canvas.restore();
  }

  void _drawDiscoveryIndices(Canvas canvas, int visionRadius, double tileSize) {
    if (session.discoveredIslandCoords.isEmpty) return;

    final paintIndex = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (var coord in session.discoveredIslandCoords) {
      final int tx = coord['x']!;
      final int ty = coord['y']!;

      // Distance relative au navire
      final dx = tx - session.x;
      final dy = ty - session.y;

      // Si l'île est hors du champ de vision immédiat, on affiche une flèche/index sur le bord
      if (dx.abs() > visionRadius || dy.abs() > visionRadius) {
        // Calcul du point sur le bord du carré de vision
        double edgeX = dx.toDouble();
        double edgeY = dy.toDouble();
        
        final double maxCoord = max(edgeX.abs(), edgeY.abs());
        edgeX = (edgeX / maxCoord) * (visionRadius + 0.5) * tileSize;
        edgeY = (edgeY / maxCoord) * (visionRadius + 0.5) * tileSize;

        final center = Offset((visionRadius * tileSize) + edgeX + tileSize/2, (visionRadius * tileSize) + edgeY + tileSize/2);
        
        // Dessiner un petit cercle scintillant ou une boussole
        canvas.drawCircle(center, 6, paintIndex);
        canvas.drawCircle(center, 12, Paint()..color = Colors.tealAccent.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }

  void _drawFishingSpot(Canvas canvas, Rect rect, double anim) {
    final paintFish = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Dessiner quelques points scintillants ou silhouettes de poissons
    final double phase = (anim * 2) % 1.0;
    final double offset = phase * 10;
    
    canvas.drawCircle(rect.center + Offset(-10 + offset, -5), 2.5, paintFish);
    canvas.drawCircle(rect.center + Offset(15 - offset, 10), 2.0, paintFish);
    canvas.drawCircle(rect.center + Offset(5, -15 + offset), 1.5, paintFish);
    
    // Silhouette de filet discret
    final paintNet = Paint()..color = Colors.white10..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawOval(rect.deflate(10), paintNet);
  }

  void _drawVolcano(Canvas canvas, Rect rect) {
    final center = rect.center;
    final baseWidth = rect.width * 0.8;
    final height = rect.height * 0.7;

    final path = Path();
    path.moveTo(center.dx - baseWidth / 2, center.dy + height / 2);
    path.lineTo(center.dx + baseWidth / 2, center.dy + height / 2);
    path.lineTo(center.dx, center.dy - height / 2);
    path.close();

    canvas.drawPath(path, Paint()..color = Colors.grey.shade900);
    
    // Lave
    canvas.drawCircle(Offset(center.dx, center.dy - height / 2 + 5), 4, Paint()..color = Colors.orangeAccent);
  }

  void _drawTemple(Canvas canvas, Rect rect) {
    final center = rect.center;
    final size = rect.width * 0.6;
    
    final paint = Paint()..color = Colors.amber.shade700..style = PaintingStyle.fill;
    
    // Base carrée
    canvas.drawRect(Rect.fromCenter(center: center, width: size, height: size * 0.4), paint);
    // Sommet triangulaire
    final path = Path();
    path.moveTo(center.dx - size / 2, center.dy - size * 0.1);
    path.lineTo(center.dx + size / 2, center.dy - size * 0.1);
    path.lineTo(center.dx, center.dy - size * 0.6);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawShipwreck(Canvas canvas, Rect rect) {
    final center = rect.center;
    final paint = Paint()..color = Colors.brown.shade300..strokeWidth = 3;
    
    // Quelques traits horizontaux pour simuler des débris de bois
    canvas.drawLine(center + const Offset(-10, -5), center + const Offset(5, -5), paint);
    canvas.drawLine(center + const Offset(-5, 5), center + const Offset(10, 5), paint);
    canvas.drawLine(center + const Offset(-8, 0), center + const Offset(8, 0), paint);
  }

  void _drawPirateShip(Canvas canvas, Rect rect) {
    final center = rect.center;
    final paintHull = Paint()..color = Colors.grey.shade800;
    final paintSails = Paint()..color = Colors.black;
    
    // Coque
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center + const Offset(0, 5), width: 25, height: 10), const Radius.circular(3)), paintHull);
    
    // Voiles
    final path = Path();
    path.moveTo(center.dx - 10, center.dy - 12);
    path.lineTo(center.dx + 10, center.dy - 12);
    path.lineTo(center.dx, center.dy + 2);
    path.close();
    canvas.drawPath(path, paintSails);
    
    // Pavillon (Petit point blanc sur voile noire)
    canvas.drawCircle(center + const Offset(0, -7), 1.5, Paint()..color = Colors.white);
  }

  void _drawWeather(Canvas canvas, Size size, int visionRadius) {
    if (session.x < 0 || session.x >= 50 || session.y < 0 || session.y >= 50) return;
    
    final currentTile = session.map[session.x][session.y];
    
    if (currentTile == TileType.snow || currentTile == TileType.ice) {
      _drawSnow(canvas, size);
    } else if (currentTile == TileType.jungle || currentTile == TileType.swamp) {
      _drawRain(canvas, size);
    } else {
      _drawFog(canvas, size);
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    
    final rand = Random(42);
    for (int i = 0; i < 40; i++) {
      final x = rand.nextDouble() * size.width;
      final yStart = rand.nextDouble() * size.height;
      final yEnd = yStart + 15 + (animationValue * 5); // Animation
      canvas.drawLine(Offset(x, yStart), Offset(x - 5, yEnd), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final rand = Random(123);
    for (int i = 0; i < 50; i++) {
      final x = rand.nextDouble() * size.width;
      final y = (rand.nextDouble() * size.height + (animationValue * 50)) % size.height;
      canvas.drawCircle(Offset(x, y), 1.5, paint);
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    // Brume légère et mouvante
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + (0.05 * sin(animationValue * pi * 2)))
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Bancs de brumes locaux
    final rand = Random(7);
    for (int i = 0; i < 5; i++) {
        final center = Offset(
          rand.nextDouble() * size.width + sin(animationValue * pi) * 20,
          rand.nextDouble() * size.height
        );
        canvas.drawCircle(center, 40, paint..color = Colors.white.withValues(alpha: 0.1));
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.session != session || oldDelegate.animationValue != animationValue;
  }
}
