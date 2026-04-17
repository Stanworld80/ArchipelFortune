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
  final ui.Image? reefImage;

  MapPainter({
    required this.session,
    required this.animationValue,
    this.tileSize = 64.0,
    this.background,
    this.shipImage,
    this.islandImage,
    this.reefImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintWater = Paint()..color = const Color(0xFF003366);
    final paintIsland = Paint()..color = Colors.deepOrange.shade300;

    // Dessin du fond de mer (Scrolling UV mapping)
    if (background != null) {
      final double worldSize = session.map.length.toDouble(); // Taille totale du monde
      
      // On calcule la région source dans l'image (0.0 à background.width/height)
      // Clamping pour éviter les coordonnées négatives aux bords (x=0, y=0)
      final double srcX = max(0.0, (session.x - 2) / worldSize * background!.width);
      final double srcY = max(0.0, (session.y - 2) / worldSize * background!.height);
      final double srcW = 5.0 / worldSize * background!.width;
      final double srcH = 5.0 / worldSize * background!.height;

      canvas.drawImageRect(
        background!,
        Rect.fromLTWH(srcX, srcY, srcW, srcH),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..filterQuality = ui.FilterQuality.medium,
      );
    } else {
      // Par défaut si pas d'image
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF1E3A8A));
    }

    // Rayon de vision (5x5 centrée sur le navire)
    const int visionRadius = 2;
    const double gridPadding = 0.0; // Espace supprimé pour les chiffres sur les axes
    final double actualTileSize = (size.width - gridPadding) / 5;

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
        if (targetX < 0 || targetX >= session.map.length || targetY < 0 || targetY >= session.map[0].length) {
          canvas.drawRect(rect, paintWater..color = const Color(0xFF003366).withOpacity(0.5));
          // _drawWaves(canvas, rect, animationValue, targetX, targetY);
          continue;
        }

        TileType tile = session.map[targetX][targetY];
        
        // Dessin de l'eau stylisée
        if (tile == TileType.sea || tile == TileType.shallow) {
           // On utilise des couleurs semi-transparentes pour laisser transparaître le fond mer.png
           canvas.drawRect(rect, paintWater..color = (tile == TileType.shallow ? const Color(0xFF00ACC1) : Colors.transparent).withOpacity(tile == TileType.shallow ? 0.3 : 0.0));
        } else if (tile == TileType.continent) {
           _drawLand(canvas, rect, tile);
        }

        if (tile == TileType.island && islandImage != null) {
          canvas.drawImageRect(
            islandImage!,
            Rect.fromLTWH(0, 0, islandImage!.width.toDouble(), islandImage!.height.toDouble()),
            rect, // Full tile instead of deflate(4) to make it "bigger"
            Paint()
              ..filterQuality = ui.FilterQuality.medium
              ..colorFilter = const ColorFilter.matrix(<double>[
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                -1, -1, -1, 3, 0,
              ]),
          );
        } else if (tile == TileType.island) {
          canvas.drawRect(rect, paintIsland);
        }

        if (tile == TileType.reef && reefImage != null) {
          canvas.drawImageRect(
            reefImage!,
            Rect.fromLTWH(0, 0, reefImage!.width.toDouble(), reefImage!.height.toDouble()),
            rect,
            Paint()..filterQuality = ui.FilterQuality.medium,
          );
        }
        
        // Bordure de grille fine
        canvas.drawRect(rect, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5);
      }
    }

    // Dessin du Navire au centre
    _drawShipSprite(canvas, (visionRadius * actualTileSize), (visionRadius * actualTileSize), actualTileSize);

    canvas.restore();

    // Dessin des indices de découverte (US04)
    _drawDiscoveryIndices(canvas, visionRadius, actualTileSize, gridPadding);

    // Dessin de la météo (US10)
    // _drawWeather(canvas, size, visionRadius);
  }

  void _drawLand(Canvas canvas, Rect rect, TileType tile) {
    if (tile != TileType.continent) return;
    final paint = Paint()..color = Colors.brown.shade800;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(4)), paint);
  }

  void _drawShipSprite(Canvas canvas, double offsetX, double offsetY, double size) {
    final shipCenter = Offset(offsetX + size / 2, offsetY + size / 2);
    
    canvas.save();
    canvas.translate(shipCenter.dx, shipCenter.dy);

    if (shipImage != null) {
      // Logic for ship orientation: use mirroring for West (270°) to avoid "upside down" rotation
      if (session.orientation == 270) {
        canvas.scale(-1, 1); // Horizontal mirror of the East-facing sprite
      } else {
        canvas.rotate(session.orientation * pi / 180);
        // Si l'image est orientée vers l'Est par défaut, on ajoute un décalage de -90° (ou pi/2 en radians)
        // pour que l'orientation 0 corresponde au Nord.
        canvas.rotate(-pi / 2);
      }

      // Filtre matriciel pour rendre le blanc transparent (Chroma Key sur le blanc)
      const ColorFilter whiteToTransparent = ColorFilter.matrix(<double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        -1, -1, -1, 3, 0,
      ]);

      canvas.drawImageRect(
        shipImage!,
        Rect.fromLTWH(0, 0, shipImage!.width.toDouble(), shipImage!.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size * 0.6, height: size * 0.75),
        Paint()
          ..filterQuality = ui.FilterQuality.medium
          ..colorFilter = whiteToTransparent,
      );
    } else {
      canvas.rotate(session.orientation * pi / 180);
      _drawBrig(canvas, size / 2);
    }

    canvas.restore();

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

  void _drawDiscoveryIndices(Canvas canvas, int visionRadius, double tileSize, double padding) {
    if (session.discoveredIslandCoords.isEmpty) return;

    final paintIndex = Paint()
      ..color = Colors.tealAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (var coord in session.discoveredIslandCoords) {
      final int tx = coord['x']!;
      final int ty = coord['y']!;

      final dx = tx - session.x;
      final dy = ty - session.y;

      if (dx.abs() > visionRadius || dy.abs() > visionRadius) {
        double edgeX = dx.toDouble();
        double edgeY = dy.toDouble();
        
        final double maxCoord = max(edgeX.abs(), edgeY.abs());
        edgeX = (edgeX / maxCoord) * (visionRadius + 0.5) * tileSize;
        edgeY = (edgeY / maxCoord) * (visionRadius + 0.5) * tileSize;

        final center = Offset(padding + (visionRadius * tileSize) + edgeX + tileSize/2, padding + (visionRadius * tileSize) + edgeY + tileSize/2);
        
        canvas.drawCircle(center, 6, paintIndex);
        canvas.drawCircle(center, 12, Paint()..color = Colors.tealAccent.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }


  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.session != session || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.reefImage != reefImage;
  }
}
