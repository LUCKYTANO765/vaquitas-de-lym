import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  final bool isGround;

  Platform({
    required Vector2 position,
    required Vector2 size,
    this.isGround = false,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // Color diferente para suelo vs plataformas
    final color = isGround
        ? const Color(0xFF4CAF50)   // verde pasto
        : const Color(0xFF8D6E63);  // marrón ladrillo

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    ));

    // Borde superior más oscuro (estilo Mario)
    add(RectangleComponent(
      size: Vector2(size.x, 4),
      paint: Paint()..color = color.withValues(alpha: 0.6),
    ));

    add(RectangleHitbox());
  }
}
