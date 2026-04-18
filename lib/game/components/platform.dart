import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';
import '../levels/level_data.dart';
import 'player.dart';
import 'traps.dart';

class Platform extends PositionComponent with CollisionCallbacks {
  final bool isGround;
  final PlatformBehavior behavior;

  bool _triggered = false;
  double _fallDelay = 0.35;
  double _fallVel = 0;
  late RectangleComponent _body;
  late RectangleComponent _topBorder;

  Platform({
    required Vector2 position,
    required Vector2 size,
    this.isGround = false,
    this.behavior = PlatformBehavior.normal,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    // Color diferente segun tipo
    Color color;
    switch (behavior) {
      case PlatformBehavior.fallAfterStep:
        color = const Color(0xFFFFA726); // naranja (aviso sutil)
        break;
      case PlatformBehavior.disappearOnTouch:
        color = const Color(0xFFBA68C8); // violeta translucido
        break;
      case PlatformBehavior.normal:
        color = isGround
            ? const Color(0xFF4CAF50)  // verde pasto
            : const Color(0xFF8D6E63); // marron ladrillo
    }

    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = color,
    );
    add(_body);

    _topBorder = RectangleComponent(
      size: Vector2(size.x, 4),
      paint: Paint()..color = color.withValues(alpha: 0.6),
    );
    add(_topBorder);

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_triggered) return;

    switch (behavior) {
      case PlatformBehavior.fallAfterStep:
        _fallDelay -= dt;
        if (_fallDelay <= 0) {
          _fallVel += 900 * dt;
          position.y += _fallVel * dt;
          // Ocultar cuando cae lejos
          if (position.y > 2000) removeFromParent();
        } else {
          // Vibracion previa
          position.x += (dt * 1000) % 2 < 1 ? 1 : -1;
        }
        break;
      case PlatformBehavior.disappearOnTouch:
        // Ya removida en onCollisionStart
        break;
      case PlatformBehavior.normal:
        break;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is! Player || _triggered) return;

    // Solo disparar si el jugador esta encima (pies cerca del top)
    final playerFoot = other.position.y;
    final platTop = position.y;
    if (playerFoot < platTop - 4 || playerFoot > platTop + 12) return;

    if (behavior == PlatformBehavior.disappearOnTouch) {
      _triggered = true;
      parent?.add(DevilTaunt(position: Vector2(position.x + size.x / 2, position.y - 10)));
      removeFromParent();
    } else if (behavior == PlatformBehavior.fallAfterStep) {
      _triggered = true;
      parent?.add(DevilTaunt(position: Vector2(position.x + size.x / 2, position.y - 10)));
    }
  }
}
