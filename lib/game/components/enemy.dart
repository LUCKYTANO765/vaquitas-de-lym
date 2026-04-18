import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'dart:math';
import 'platform.dart';
import 'player.dart';
import '../vaquitas_game.dart';

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
    with CollisionCallbacks, HasGameReference<VaquitasGame> {
  final VoidCallback onPlayerHit;
  final VoidCallback onBossDefeated;

  int maxHealth = 5;
  int health = 5;
  bool _isDead = false;
  double _chargeTimer = 0;
  bool _isCharging = false;
  bool _isCasting = false;
  double _castTimer = 0;
  double _castCooldown = 5.0;
  double _startX = 0;
  double _baseY = 0;
  double _hitFlashTimer = 0;

  late RectangleComponent _healthBar;
  late SpriteComponent _bossSprite;
  late Sprite _spriteIdle;
  late Sprite _spriteAttack;
  late Sprite _spriteHurt;
  late Sprite _spriteFinal;
  late Sprite _spriteDefeated;

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

    // Titulo del jefe
    add(TextComponent(
      text: 'Malyn lith',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 18,
          color: Color(0xFFFF5252),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), offset: Offset(1, 1))],
        ),
      ),
      position: Vector2(0, -85),
    ));

    // Sprites del jefe (4 estados)
    _spriteIdle   = Sprite(await game.images.load('enemigo final pose inicial.png'));
    _spriteAttack = Sprite(await game.images.load('enemigo final ataque basico.png'));
    _spriteHurt   = Sprite(await game.images.load('enemigo final cuando lo golpean.png'));
    _spriteFinal  = Sprite(await game.images.load('enemigo final poder final.png'));
    _spriteDefeated = Sprite(await game.images.load('enemigo final derrotado.png'));

    _bossSprite = SpriteComponent(
      sprite: _spriteIdle,
      size: Vector2(140, 140),
      position: Vector2(-20, -30),
    );
    add(_bossSprite);

    // Barra de vida (arriba del titulo para no tapar la cara)
    add(RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(0, -65),
      paint: Paint()..color = const Color(0xFF333333),
    ));
    _healthBar = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(0, -65),
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

    // Cooldown ataque final
    _castCooldown -= dt;
    if (_castCooldown <= 0 && !_isCasting && !_isCharging) {
      _isCasting = true;
      _castTimer = 0;
      _castCooldown = 7.0;
    }

    if (_isCasting) {
      _castTimer += dt;
      // Pequeno temblor durante carga
      position.x = _startX + sin(_castTimer * 40) * 4;
      // Al final del cast, suelta bolas de fuego
      if (_castTimer >= 1.2) {
        _unleashFireballs();
        _isCasting = false;
        position.x = _startX;
      }
    } else {
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

    // Sprite swap segun estado
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      _bossSprite.sprite = _spriteHurt;
    } else if (_isCasting) {
      _bossSprite.sprite = _spriteFinal;
    } else if (_isCharging) {
      _bossSprite.sprite = _spriteAttack;
    } else {
      _bossSprite.sprite = _spriteIdle;
    }
  }

  void _unleashFireballs() {
    final origin = Vector2(position.x + size.x / 2, _baseY - size.y + 10);

    // 8 bolas radiales
    const count = 8;
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i - pi / 2;
      final dir = Vector2(cos(angle), sin(angle));
      game.world.add(Fireball(
        position: origin.clone(),
        velocity: dir * 220,
        onPlayerHit: onPlayerHit,
      ));
    }

    // Bola dirigida al jugador
    final player = game.player;
    final toPlayer = (player.position - origin)..normalize();
    game.world.add(Fireball(
      position: origin.clone(),
      velocity: toPlayer * 320,
      onPlayerHit: onPlayerHit,
      homing: true,
    ));
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
        _hitFlashTimer = 0.35;

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
    _bossSprite.sprite = _spriteDefeated;

    // Ocultar barra de vida y desactivar colisiones, queda tirada en piso
    _healthBar.removeFromParent();
    for (final c in children.whereType<RectangleHitbox>()) {
      c.removeFromParent();
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (isMounted) onBossDefeated();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Bola de fuego lanzada por el jefe final
class Fireball extends PositionComponent
    with CollisionCallbacks, HasGameReference<VaquitasGame> {
  Vector2 velocity;
  final VoidCallback onPlayerHit;
  final bool homing;
  double _life = 4.0;
  double _animTimer = 0;

  Fireball({
    required Vector2 position,
    required this.velocity,
    required this.onPlayerHit,
    this.homing = false,
  }) : super(position: position, size: Vector2(24, 24), anchor: Anchor.center);

  late CircleComponent _core;
  late CircleComponent _glow;

  @override
  Future<void> onLoad() async {
    _glow = CircleComponent(
      radius: 16,
      paint: Paint()
        ..color = const Color(0xAAFFAB40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      anchor: Anchor.center,
      position: size / 2,
    );
    _core = CircleComponent(
      radius: 10,
      paint: Paint()..color = const Color(0xFFFF5722),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_glow);
    add(_core);
    add(CircleHitbox(radius: 10, position: size / 2, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }

    if (homing && _life > 3.4) {
      // Pequena correccion inicial hacia el jugador
      final dir = (game.player.position - position)..normalize();
      velocity = dir * velocity.length;
    }

    position += velocity * dt;

    // Pulso visual
    _animTimer += dt;
    final pulse = 1.0 + sin(_animTimer * 18) * 0.15;
    _core.scale = Vector2.all(pulse);
    _glow.scale = Vector2.all(pulse * 1.1);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && !other.isInvulnerable) {
      onPlayerHit();
      removeFromParent();
    } else if (other is Platform) {
      removeFromParent();
    }
  }
}
