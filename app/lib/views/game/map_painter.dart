import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/session_model.dart';

class MapPainter extends CustomPainter {
  final SessionState session;
  final double tileSize;
  final ui.Image? background;
  final ui.Image? shipImage;
  final ui.Image? islandImage;
  final ui.Image? reefImage;

  MapPainter({
    required this.session,
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
    final paintGrid = Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5;
    final paintImage = Paint()..filterQuality = ui.FilterQuality.low;
    final paintIslandSpecial = Paint()
      ..filterQuality = ui.FilterQuality.low
      ..colorFilter = const ColorFilter.matrix(<double>[
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        -1, -1, -1, 3, 0,
      ]);

    // Dessin du fond de mer (Scrolling UV mapping)
    if (background != null) {
      final double worldSize = session.map.length.toDouble(); 
      
      final double srcX = max(0.0, (session.x - 2) / worldSize * background!.width);
      final double srcY = max(0.0, (session.y - 2) / worldSize * background!.height);
      final double srcW = 5.0 / worldSize * background!.width;
      final double srcH = 5.0 / worldSize * background!.height;

      canvas.drawImageRect(
        background!,
        Rect.fromLTWH(srcX, srcY, srcW, srcH),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paintImage,
      );
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF1E3A8A));
    }

    // Rayon de vision (5x5 centrée sur le navire)
    const int visionRadius = 2;
    final double actualTileSize = size.width / 5;

    canvas.save();

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

        if (targetX < 0 || targetX >= session.map.length || targetY < 0 || targetY >= session.map[0].length) {
          canvas.drawRect(rect, paintWater..color = const Color(0xFF003366).withOpacity(0.5));
          continue;
        }

        TileType tile = session.map[targetX][targetY];
        
        if (tile == TileType.sea || tile == TileType.shallow) {
           if (tile == TileType.shallow) {
             canvas.drawRect(rect, paintWater..color = const Color(0xFF00ACC1).withOpacity(0.3));
           }
        } else if (tile == TileType.continent) {
           _drawLand(canvas, rect, tile);
        }

        if (tile == TileType.island && islandImage != null) {
          canvas.drawImageRect(
            islandImage!,
            Rect.fromLTWH(0, 0, islandImage!.width.toDouble(), islandImage!.height.toDouble()),
            rect,
            paintIslandSpecial,
          );
        } else if (tile == TileType.island) {
          canvas.drawRect(rect, paintIsland);
        }

        if (tile == TileType.reef && reefImage != null) {
          canvas.drawImageRect(
            reefImage!,
            Rect.fromLTWH(0, 0, reefImage!.width.toDouble(), reefImage!.height.toDouble()),
            rect,
            paintImage,
          );
        }
        
        canvas.drawRect(rect, paintGrid);
      }
    }

    // Dessin du Navire au centre
    _drawShipSprite(canvas, (visionRadius * actualTileSize), (visionRadius * actualTileSize), actualTileSize);

    canvas.restore();

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
      final Paint shipPaint = Paint()
        ..filterQuality = ui.FilterQuality.low
        ..colorFilter = const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          -1, -1, -1, 3, 0,
        ]);

      canvas.drawImageRect(
        shipImage!,
        Rect.fromLTWH(0, 0, shipImage!.width.toDouble(), shipImage!.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size * 0.6, height: size * 0.75),
        shipPaint,
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




  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.session != session || 
           oldDelegate.background != background ||
           oldDelegate.shipImage != shipImage ||
           oldDelegate.islandImage != islandImage ||
           oldDelegate.reefImage != reefImage;
  }
}
