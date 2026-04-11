import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/session_model.dart';

class MapPainter extends CustomPainter {
  final SessionState session;
  final double tileSize;
  final double animationValue;
  final ui.Image? background;
  final ui.Image? shipImage;
  final ui.Image? islandImage;
  final ui.Image? compassImage;

  MapPainter({
    required this.session,
    required this.animationValue,
    this.tileSize = 64.0,
    this.background,
    this.shipImage,
    this.islandImage,
    this.compassImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintWater = Paint()..color = const Color(0xFF003366);
    final paintIsland = Paint()..color = Colors.deepOrange.shade300;

    // Dessin du fond parchemin (optionnel si on utilise l'image)
    if (background != null) {
      canvas.drawImageRect(
        background!,
        Rect.fromLTWH(0, 0, background!.width.toDouble(), background!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFE5D3B3));
    }

    // Rayon de vision (5x5 centrée sur le navire)
    const int visionRadius = 2;
    const double gridPadding = 20.0; // Espace pour les chiffres sur les axes
    final double actualTileSize = (size.width - gridPadding) / 5;

    // Dessin des axes (1-5)
    _drawGridLabels(canvas, actualTileSize, gridPadding);

    canvas.save();
    canvas.translate(gridPadding, gridPadding);

    for (int dx = -visionRadius; dx <= visionRadius; dx++) {
      for (int dy = -visionRadius; dy <= visionRadius; dy++) {
        int targetX = session.x + dx;
        int targetY = session.y + dy;

        final rect = Rect.fromLTWH(
          (dx + visionRadius) * actualTileSize, 
          (dy + visionRadius) * actualTileSize, 
          actualTileSize, 
          actualTileSize
        );

        // Si hors limites, on dessine du vide ou de l'eau
        if (targetX < 0 || targetX >= 50 || targetY < 0 || targetY >= 50) {
          canvas.drawRect(rect, paintWater..color = const Color(0xFF003366).withOpacity(0.5));
          _drawWaves(canvas, rect, animationValue, targetX, targetY);
          continue;
        }

        TileType tile = session.map[targetX][targetY];
        
        // Dessin de l'eau stylisée
        if (tile == TileType.sea || tile == TileType.shallow || tile == TileType.fishing || tile == TileType.shipwreck || tile == TileType.pirate) {
           canvas.drawRect(rect, paintWater..color = (tile == TileType.shallow ? const Color(0xFF00ACC1) : const Color(0xFF003366)).withOpacity(0.3));
           _drawWaves(canvas, rect, animationValue, targetX, targetY);
        } else {
           // Autres types de sol (sable, herbe, etc.)
           _drawLand(canvas, rect, tile);
        }

        // Cas spécifiques pour les sprites
        if (tile == TileType.island && islandImage != null) {
          canvas.drawImageRect(
            islandImage!,
            Rect.fromLTWH(0, 0, islandImage!.width.toDouble(), islandImage!.height.toDouble()),
            rect.deflate(4),
            Paint()..filterQuality = ui.FilterQuality.medium,
          );
        } else if (tile == TileType.island) {
          canvas.drawRect(rect, paintIsland);
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

        if (tile == TileType.fishing) {
          _drawFishingSpot(canvas, rect, animationValue);
        }
        
        // Bordure de grille fine
        canvas.drawRect(rect, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5);
      }
    }

    // Dessin du Navire au centre
    _drawShipSprite(canvas, (visionRadius * actualTileSize), (visionRadius * actualTileSize), actualTileSize);

    canvas.restore();

    // Boussole dans le coin
    if (compassImage != null) {
      final double compassSize = size.width * 0.25;
      canvas.drawImageRect(
        compassImage!,
        Rect.fromLTWH(0, 0, compassImage!.width.toDouble(), compassImage!.height.toDouble()),
        Rect.fromLTWH(size.width - compassSize - 10, size.height - compassSize - 10, compassSize, compassSize),
        Paint()..filterQuality = ui.FilterQuality.medium,
      );
    }

    // Dessin des indices de découverte (US04)
    _drawDiscoveryIndices(canvas, visionRadius, actualTileSize, gridPadding);

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

  void _drawGridLabels(Canvas canvas, double tileSize, double padding) {
    const textStyle = TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold);
    for (int i = 1; i <= 5; i++) {
       // Labels colonnes (Haut)
       final textPainterX = TextPainter(
         text: TextSpan(text: '$i', style: textStyle),
         textDirection: TextDirection.ltr,
       )..layout();
       textPainterX.paint(canvas, Offset(padding + (i - 1) * tileSize + (tileSize - textPainterX.width) / 2, (padding - textPainterX.height) / 2));

       // Labels lignes (Gauche)
       final textPainterY = TextPainter(
         text: TextSpan(text: '$i', style: textStyle),
         textDirection: TextDirection.ltr,
       )..layout();
       textPainterY.paint(canvas, Offset((padding - textPainterY.width) / 2, padding + (i - 1) * tileSize + (tileSize - textPainterY.height) / 2));
    }
  }

  void _drawLand(Canvas canvas, Rect rect, TileType tile) {
    final paint = Paint();
    switch (tile) {
      case TileType.sand: paint.color = Colors.amber.shade200; break;
      case TileType.grass: paint.color = Colors.green.shade600; break;
      case TileType.forest: paint.color = Colors.green.shade900; break;
      case TileType.reef: paint.color = Colors.grey.shade800; break;
      case TileType.continent: paint.color = Colors.brown.shade800; break;
      case TileType.snow: paint.color = Colors.white; break;
      case TileType.ice: paint.color = Colors.cyan.shade100; break;
      case TileType.jungle: paint.color = const Color(0xFF1B5E20); break;
      case TileType.swamp: paint.color = const Color(0xFF3E2723); break;
      default: paint.color = Colors.transparent;
    }
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)), paint);
  }

  void _drawShipSprite(Canvas canvas, double offsetX, double offsetY, double size) {
    final shipCenter = Offset(offsetX + size / 2, offsetY + size / 2);
    
    canvas.save();
    canvas.translate(shipCenter.dx, shipCenter.dy);
    canvas.rotate(session.orientation * pi / 180);

    if (shipImage != null) {
      canvas.drawImageRect(
        shipImage!,
        Rect.fromLTWH(0, 0, shipImage!.width.toDouble(), shipImage!.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size * 0.8, height: size * 1.0),
        Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else {
      // Évolution Visuelle selon hullLevel
      if (session.hullLevel <= 2) {
        _drawSloop(canvas, size);
      } else if (session.hullLevel <= 4) {
        _drawBrig(canvas, size);
      } else {
        _drawFrigate(canvas, size);
      }
    }

    canvas.restore();
  }

  void _drawSloop(Canvas canvas, double size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(0, -size / 3);
    path.lineTo(size / 4, size / 4);
    path.lineTo(-size / 4, size / 4);
    path.close();
    canvas.drawPath(path, paint);
    
    // Mât unique
    canvas.drawRect(Rect.fromLTWH(-1, -size/4, 2, size/2), Paint()..color = Colors.brown);
  }

  void _drawBrig(Canvas canvas, double size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(0, -size / 2.2);
    path.lineTo(size / 3.5, size / 3.5);
    path.lineTo(-size / 3.5, size / 3.5);
    path.close();
    canvas.drawPath(path, paint);
    
    // Deux mâts
    canvas.drawRect(Rect.fromLTWH(-size/6, -size/5, 2, size/2.5), Paint()..color = Colors.brown);
    canvas.drawRect(Rect.fromLTWH(size/6, -size/10, 2, size/2.5), Paint()..color = Colors.brown);
  }

  void _drawFrigate(Canvas canvas, double size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(0, -size / 1.8);
    path.lineTo(size / 2.5, size / 3);
    path.lineTo(-size / 2.5, size / 3);
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1);
    
    // Trois mâts et détails de proue
    canvas.drawRect(Rect.fromLTWH(-size/4, -size/6, 2, size/2.5), Paint()..color = Colors.brown);
    canvas.drawRect(Rect.fromLTWH(0, -size/4, 2, size/2), Paint()..color = Colors.brown);
    canvas.drawRect(Rect.fromLTWH(size/4, -size/6, 2, size/2.5), Paint()..color = Colors.brown);
    
    // Drapeaux (micro-détails)
    canvas.drawRect(Rect.fromLTWH(1, -size/4, 4, 3), Paint()..color = Colors.red);
  }

  void _drawDiscoveryIndices(Canvas canvas, int visionRadius, double tileSize, double padding) {
    if (session.discoveredIslandCoords.isEmpty) return;

    final paintIndex = Paint()
      ..color = Colors.tealAccent.withOpacity(0.8)
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

        final center = Offset(padding + (visionRadius * tileSize) + edgeX + tileSize/2, padding + (visionRadius * tileSize) + edgeY + tileSize/2);
        
        // Dessiner un petit cercle scintillant ou une boussole
        canvas.drawCircle(center, 6, paintIndex);
        canvas.drawCircle(center, 12, Paint()..color = Colors.tealAccent.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2);
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
      ..color = Colors.blue.withOpacity(0.4)
      ..strokeWidth = 2.0;

    // Éclairs (Flash blanc aléatoire)
    final randLightning = Random(session.x + session.y + (animationValue * 10).toInt());
    if (randLightning.nextDouble() > 0.98) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white.withOpacity(0.3));
    }
    
    final rand = Random(42);
    for (int i = 0; i < 60; i++) {
      final x = rand.nextDouble() * size.width;
      final yStart = (rand.nextDouble() * size.height + (animationValue * 300)) % size.height;
      final yEnd = yStart + 20; 
      canvas.drawLine(Offset(x, yStart), Offset(x - 5, yEnd), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    final rand = Random(123);
    for (int i = 0; i < 80; i++) {
      final x = (rand.nextDouble() * size.width + (animationValue * 30)) % size.width; // Vent latéral
      final y = (rand.nextDouble() * size.height + (animationValue * 100)) % size.height;
      canvas.drawCircle(Offset(x, y), 2.0, paint);
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
        canvas.drawCircle(center, 40, paint..color = Colors.white.withOpacity(0.1));
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.session != session || oldDelegate.animationValue != animationValue;
  }
}
