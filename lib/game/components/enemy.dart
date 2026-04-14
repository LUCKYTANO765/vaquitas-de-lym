import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'platform.dart';
import 'player.dart';

class Enemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlameGame> {
  final double patrolRange;
  final VoidCallback onPlayerHit;

  double _startX = 0;
  final double _speed = 80;
  bool _movingRight = true;
  bool _isDead = false;

  Enemy({
    required Vector2 position,
    required this.patrolRange,
    required this.onPlayerHit,
  }) : super(position: position, size: Vector2(36, 36), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    _startX = position.x;
    add(TextComponent(
      text: '😈',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 30)),
      position: Vector2(2, -36),
    ));
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) return;

    // Patrulla dentro del rango
    if (_movingRight) {
      if (position.x >= _startX + patrolRange || !_hasGroundAhead()) {
        _movingRight = false;
      } else {
        position.x += _speed * dt;
      }
    } else {
      if (position.x <= _startX || !_hasGroundAhead()) {
        _movingRight = true;
      } else {
        position.x -= _speed * dt;
      }
    }
  }

  /// Devuelve false si hay un precipicio al frente → el enemigo da la vuelta.
  bool _hasGroundAhead() {
    final frontX = _movingRight
        ? position.x + size.x + 4
        : position.x - 4;
    final feetY  = position.y;

    for (final c in game.world.children) {
      if (c is! Platform) continue;
      final withinX = frontX >= c.position.x && frontX <= c.position.x + c.size.x;
      final nearFeet = c.position.y >= feetY - 8 && c.position.y <= feetY + 40;
      if (withinX && nearFeet) return true;
    }
    return false;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !_isDead && !other.isInvulnerable) {
      final playerFoot = other.position.y;
      final enemyTop   = position.y - size.y;

      if (playerFoot <= enemyTop + 16 && other.velocity.y > 0) {
        // Pisotón → enemigo muere, jugador rebota
        _die();
        other.velocity.y = -280;
      } else {
        // Contacto lateral → jugador recibe daño
        onPlayerHit();
      }
    }
  }

  void _die() {
    _isDead = true;
    add(TextComponent(
      text: '💀',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 28)),
    ));
    Future.delayed(const Duration(milliseconds: 500), () => removeFromParent());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Jefe final: vaca gigante (nivel 4)
class BossEnemy extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlameGame> {
  final VoidCallback onPlayerHit;
  final VoidCallback onBossDefeated;

  int health = 3;
  bool _isDead = false;
  double _chargeTimer = 0;
  bool _isCharging = false;
  double _startX = 0;

  BossEnemy({
    required Vector2 position,
    required this.onPlayerHit,
    required this.onBossDefeated,
  }) : super(
            position: position,
            size: Vector2(72, 72),
            anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    _startX = position.x;
    add(TextComponent(
      text: '🐄',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 64)),
      position: Vector2(0, -72),
    ));
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) return;

    _chargeTimer += dt;
    if (_chargeTimer > 3.0) {
      _chargeTimer = 0;
      _isCharging = !_isCharging;
    }

    if (_isCharging) {
      position.x -= 200 * dt;
      if (position.x < _startX - 300) _isCharging = false;
    } else {
      if (position.x < _startX) position.x += 80 * dt;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !_isDead && !other.isInvulnerable) {
      final playerFoot = other.position.y;
      final bossTop    = position.y - size.y;

      if (playerFoot <= bossTop + 20 && other.velocity.y > 0) {
        health--;
        other.velocity.y = -320;
        if (health <= 0) _defeat();
      } else {
        onPlayerHit();
      }
    }
  }

  void _defeat() {
    _isDead = true;
    add(TextComponent(
      text: '💥🐄💥',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 36)),
    ));
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
      onBossDefeated();
    });
  }
}
