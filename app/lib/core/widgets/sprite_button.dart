import 'package:flutter/material.dart';

/// Sprite sheet regions (pixels) for 'assets/images/buttons_sprite.png'
/// Adjust these values if the image has slightly different dimensions.
///
/// Full image estimated at ~1078 x 440 px — 3 columns × 2 rows:
///   Row 1 (h ≈ 0–290): INVENTAIRE (sq) | DÉPART (circle, full height) | CARTE (shield)
///   Row 2 (h ≈ 290–440): RÉGLAGES (small circle) | VOYAGE (wide banner) | DÉFI (small circle)
class SpriteRegions {
  static const double imgW = 1078;
  static const double imgH = 440;

  static const Rect depart = Rect.fromLTRB(285, 0, 725, 440);
  static const Rect inventaire = Rect.fromLTRB(0, 0, 285, 290);
  static const Rect carte = Rect.fromLTRB(730, 0, 1078, 290);
  static const Rect reglages = Rect.fromLTRB(0, 285, 195, 440);
  static const Rect voyage = Rect.fromLTRB(195, 290, 820, 440);
  static const Rect defi = Rect.fromLTRB(820, 285, 1078, 440);
}

/// A pressable button that displays a cropped region of the sprite sheet
/// with a press-scale animation.
class SpriteButton extends StatefulWidget {
  const SpriteButton({
    super.key,
    required this.spriteRect,
    required this.onTap,
    this.width,
    this.height,
    this.semanticLabel,
    this.disabled = false,
  });

  final Rect spriteRect;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool disabled;

  static const String _asset = 'assets/images/buttons_sprite.png';

  @override
  State<SpriteButton> createState() => _SpriteButtonState();
}

class _SpriteButtonState extends State<SpriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) {
    _ctrl.forward();
    if (!widget.disabled) widget.onTap();
  }
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final rect = widget.spriteRect;
    final displayW = widget.width ?? (rect.width * 0.22);
    final displayH = widget.height ?? (rect.height * 0.22);

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: !widget.disabled,
      child: GestureDetector(
        onTapDown: widget.disabled ? null : _onTapDown,
        onTapUp: widget.disabled ? null : _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (ctx, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: Opacity(
            opacity: widget.disabled ? 0.4 : 1.0,
            child: SizedBox(
              width: displayW,
              height: displayH,
              child: ClipRect(
                child: Align(
                  // Convert the rect to an Alignment in [-1, 1] space
                  alignment: Alignment(
                    (rect.left + rect.width / 2) /
                            SpriteRegions.imgW *
                            2 -
                        1,
                    (rect.top + rect.height / 2) /
                            SpriteRegions.imgH *
                            2 -
                        1,
                  ),
                  widthFactor: SpriteRegions.imgW / rect.width,
                  heightFactor: SpriteRegions.imgH / rect.height,
                  child: Image.asset(
                    SpriteButton._asset,
                    width: displayW * (SpriteRegions.imgW / rect.width),
                    height: displayH * (SpriteRegions.imgH / rect.height),
                    filterQuality: FilterQuality.high,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: displayW,
                      height: displayH,
                      color: Colors.teal.shade900.withOpacity(0.5),
                      child: const Center(
                        child: Icon(Icons.help_outline, color: Colors.amber),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
