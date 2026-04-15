import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'dart:math';
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

  int maxHealth = 5;
  int health = 5;
  bool _isDead = false;
  double _chargeTimer = 0;
  bool _isCharging = false;
  double _startX = 0;
  double _baseY = 0;

  late RectangleComponent _healthBar;

  BossEnemy({
    required Vector2 position,
    required this.onPlayerHit,
    required this.onBossDefeated,
  }) : super(
            position: position,
            size: Vector2(100, 100),
            anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    _startX = position.x;
    _baseY = position.y;

    // Titulo 'JEFE FINAL'
    add(TextComponent(
      text: 'JEFE FINAL!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFFFF5252),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), offset: Offset(1, 1))],
        ),
      ),
      position: Vector2(0, -30),
    ));

    // Emoji de Vaca Gigante
    add(TextComponent(
      text: '🐄',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 85)),
      position: Vector2(6, 2),
    ));

    // Barra de vida
    add(RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(0, -15),
      paint: Paint()..color = const Color(0xFF333333),
    ));
    _healthBar = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(0, -15),
      paint: Paint()..color = const Color(0xFF4CAF50),
    );
    add(_healthBar);

    add(RectangleHitbox(size: Vector2(90, 80), position: Vector2(5, 20)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDead) return;

    _healthBar.size.x = (health / maxHealth) * 100;
    if (health < 3) {
      _healthBar.paint.color = const Color(0xFFE53935);
    } else {
      _healthBar.paint.color = const Color(0xFF4CAF50);
    }

    _chargeTimer += dt;
    // Empieza a cargar cada 2.5 segs
    if (_chargeTimer > 2.5 && !_isCharging) {
      _chargeTimer = 0;
      _isCharging = true;
    }

    if (_isCharging) {
      position.x -= 350 * dt;
      // Efecto de saltito usando seno
      position.y = _baseY - (sin(_chargeTimer * 15).abs() * 40);

      if (position.x < _startX - 230) {
        _isCharging = false;
        position.y = _baseY;
      }
    } else {
      position.y = _baseY;
      if (position.x < _startX) position.x += 120 * dt;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player && !_isDead && !other.isInvulnerable) {
      final playerFoot = other.position.y;
      final bossTop    = _baseY - 80;

      if (playerFoot <= bossTop + 30 && other.velocity.y > 0) {
        // Pisotón exitoso al jefe
        health--;
        other.velocity.y = -400; // Gran rebote
        
        // Efecto visual de golpe
        scale = Vector2(0.8, 1.2);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!_isDead && isMounted) scale = Vector2.all(1.0);
        });

        if (health <= 0) _defeat();
      } else {
        // El jugador es atropellado
        other.velocity.y = -200;
        other.velocity.x = -300; // Lanzado hacia atrás
        onPlayerHit();
      }
    }
  }

  void _defeat() {
    _isDead = true;
    scale = Vector2.all(1.0);
    add(TextComponent(
      text: '💥🐄💥',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 90)),
      position: Vector2(-10, -90)
    ));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isMounted) {
        removeFromParent();
        onBossDefeated();
      }
    });
  }
}
