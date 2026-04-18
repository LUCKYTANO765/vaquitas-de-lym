import 'dart:math' show min;
import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart' show TextStyle, Color, VoidCallback;
import 'platform.dart';
import 'milk_bottle.dart';
import 'traps.dart';
import '../vaquitas_game.dart';

enum PlayerState { idle, running, jumping, falling }

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<VaquitasGame> {
  final VoidCallback onReachGoal;
  final JoystickComponent joystick;

  // ── Física ───────────────────────────────────────────────────────────────
  static const double gravity      = 900.0;
  static const double jumpForce    = -560.0;
  static const double maxFallSpeed = 600.0;
  static const double walkAccel    = 1400.0;
  static const double maxWalkSpeed = 220.0;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;

  // ── Estado ───────────────────────────────────────────────────────────────
  bool _facingRight = true;
  PlayerState state = PlayerState.idle;
  late Vector2 _spawnPoint;
  int _moveInput = 0;

  // ── Invulnerabilidad ──────────────────────────────────────────────────────
  double _invulnerableTimer = 0.0;
  double _flashTimer        = 0.0;
  bool   _flashVisible      = true;

  // ── Sprites ───────────────────────────────────────────────────────────────
  late SpriteAnimationComponent _sprite;
  late SpriteAnimation _animRunRight;
  late SpriteAnimation _animRunLeft;
  late SpriteAnimation _animIdleRight;
  late SpriteAnimation _animIdleLeft;


  Player({
    required Vector2 position,
    required this.onReachGoal,
    required this.joystick,
  }) : super(
          position: position,
          size: Vector2(32, 48),
          anchor: Anchor.bottomLeft,
        );

  @override
  Future<void> onLoad() async {
    _spawnPoint = position.clone();

    // Cargar imágenes
    final imgRunR  = await game.images.load('CORRER DERECHA01.png');
    final imgRunL  = await game.images.load('CORRER IZQUIERDA01.png');
    final imgIdleR = await game.images.load('PARADO DERECHA01.png');
    final imgIdleL = await game.images.load('PARADO IZQUIERDA01.png');

    // ── CORRER DERECHA: 4 frames con posición exacta (análisis de imagen)
    // content y=98-277 (h=180), frames en x: 69,277,473,673
    _animRunRight = SpriteAnimation([
      SpriteAnimationFrame(Sprite(imgRunR, srcPosition: Vector2(69,  98), srcSize: Vector2(190, 180)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunR, srcPosition: Vector2(277, 98), srcSize: Vector2(185, 180)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunR, srcPosition: Vector2(473, 98), srcSize: Vector2(183, 180)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunR, srcPosition: Vector2(673, 98), srcSize: Vector2(189, 180)), 0.12),
    ], loop: true);

    // ── CORRER IZQUIERDA: 4 frames con posición exacta
    // content y=124-368 (h=245), frames en x: 98,346,607,858
    _animRunLeft = SpriteAnimation([
      SpriteAnimationFrame(Sprite(imgRunL, srcPosition: Vector2(98,  124), srcSize: Vector2(245, 245)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunL, srcPosition: Vector2(346, 124), srcSize: Vector2(247, 245)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunL, srcPosition: Vector2(607, 124), srcSize: Vector2(239, 245)), 0.12),
      SpriteAnimationFrame(Sprite(imgRunL, srcPosition: Vector2(858, 124), srcSize: Vector2(238, 245)), 0.12),
    ], loop: true);

    // ── PARADO DERECHA: 1 frame, content x=119-374 y=91-433
    _animIdleRight = SpriteAnimation([
      SpriteAnimationFrame(Sprite(imgIdleR, srcPosition: Vector2(119, 91), srcSize: Vector2(256, 343)), 1.0),
    ], loop: true);

    // ── PARADO IZQUIERDA: 1 frame, content x=63-311 y=60-416
    _animIdleLeft = SpriteAnimation([
      SpriteAnimationFrame(Sprite(imgIdleL, srcPosition: Vector2(63, 60), srcSize: Vector2(249, 357)), 1.0),
    ], loop: true);

    // Sprite visual: 64×80, pie alineado con el fondo del hitbox (local y=48)
    // x=-16 centra los 64px sobre los 32px del hitbox
    // y=-32 → bottom sprite = -32+80 = 48 = bottom hitbox ✓
    _sprite = SpriteAnimationComponent(
      animation: _animIdleRight,
      size: Vector2(64, 80),
      position: Vector2(-16, -32),
    );
    add(_sprite);

    // Hitbox de colisión (más pequeño que el sprite visual)
    add(RectangleHitbox(
      size: Vector2(28, 44),
      position: Vector2(2, 4),
      isSolid: true,
    ));
  }

  // ── API pública ───────────────────────────────────────────────────────────
  bool get isInvulnerable => _invulnerableTimer > 0;

  void moveLeft(double speed)  { _moveInput = -1; }
  void moveRight(double speed) { _moveInput =  1; }
  void stopHorizontal()        { _moveInput =  0; }
  void releaseJump()           {} // no-op: salto de altura fija

  void jump() {
    if (isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
      state = PlayerState.jumping;
    }
  }

  void startInvulnerability(double duration) {
    _invulnerableTimer = duration;
    _flashTimer   = 0;
    _flashVisible = true;
  }

  void respawn() {
    position   = _spawnPoint.clone();
    velocity   = Vector2.zero();
    isOnGround = false;
    state      = PlayerState.idle;
    startInvulnerability(2.0);
  }

  // ── Detección de suelo ────────────────────────────────────────────────────
  bool _checkOnGround() {
    final pLeft  = position.x + 3;
    final pRight = position.x + size.x - 3;
    final pFoot  = position.y;

    for (final c in game.world.children) {
      if (c is! Platform) continue;
      final platTop   = c.position.y;
      final platLeft  = c.position.x;
      final platRight = c.position.x + c.size.x;

      if (pRight > platLeft && pLeft < platRight &&
          pFoot >= platTop - 6.0 && pFoot <= platTop + 10) {
        position.y = platTop;
        return true;
      }
    }
    return false;
  }

  // ── Colisión lateral (eje X) ──────────────────────────────────────────────
  void _resolveXCollision() {
    final pTop    = position.y - size.y + 4;
    final pBottom = position.y - 2;
    final pLeft   = position.x + 2;
    final pRight  = position.x + size.x - 2;

    for (final c in game.world.children) {
      if (c is! Platform) continue;
      final platTop    = c.position.y;
      final platBottom = c.position.y + c.size.y;
      final platLeft   = c.position.x;
      final platRight  = c.position.x + c.size.x;

      if (pBottom <= platTop || pTop >= platBottom) continue;
      if (pRight <= platLeft || pLeft >= platRight) continue;

      if (velocity.x > 0) {
        position.x = platLeft - size.x + 2;
        velocity.x = 0;
      } else if (velocity.x < 0) {
        position.x = platRight - 2;
        velocity.x = 0;
      }
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    // 1. Invulnerabilidad
    if (_invulnerableTimer > 0) {
      _invulnerableTimer -= dt;
      _flashTimer += dt;
      if (_flashTimer >= 0.1) {
        _flashTimer = 0;
        _flashVisible = !_flashVisible;
      }
      if (_invulnerableTimer <= 0) _flashVisible = true;
    }

    // 2. Movimiento horizontal con aceleración y fricción
    if (_moveInput < 0) {
      velocity.x = (velocity.x - walkAccel * dt).clamp(-maxWalkSpeed, maxWalkSpeed);
    } else if (_moveInput > 0) {
      velocity.x = (velocity.x + walkAccel * dt).clamp(-maxWalkSpeed, maxWalkSpeed);
    } else {
      velocity.x *= (1.0 - min(1.0, 10.0 * dt));
      if (velocity.x.abs() < 2) velocity.x = 0;
    }

    // 3. Mover X + resolver colisión lateral
    position.x += velocity.x * dt;
    _resolveXCollision();

    // 4. Gravedad
    if (!isOnGround) {
      velocity.y += gravity * dt;
      if (velocity.y > maxFallSpeed) velocity.y = maxFallSpeed;
    }

    // 5. Mover Y + resolver suelo
    position.y += velocity.y * dt;
    if (velocity.y >= 0) {
      if (_checkOnGround()) {
        velocity.y = 0;
        isOnGround = true;
      } else {
        isOnGround = false;
      }
    } else {
      isOnGround = false;
    }

    // 6. Estado
    if (!isOnGround) {
      state = velocity.y < 0 ? PlayerState.jumping : PlayerState.falling;
    } else if (velocity.x.abs() > 10) {
      state = PlayerState.running;
    } else {
      state = PlayerState.idle;
    }

    // 7. Dirección
    if (velocity.x >  10) _facingRight = true;
    if (velocity.x < -10) _facingRight = false;

    // 8. Actualizar animación del sprite
    final newAnim = (state == PlayerState.running)
        ? (_facingRight ? _animRunRight : _animRunLeft)
        : (_facingRight ? _animIdleRight : _animIdleLeft);

    if (_sprite.animation != newAnim) _sprite.animation = newAnim;

    // 9. Flash de invulnerabilidad via opacidad
    _sprite.opacity = _flashVisible ? 1.0 : 0.0;

    // 10. Caída al vacío
    if (position.y > 1400) respawn();
  }

  // ── Colisiones (botellas de leche y bandera) ─────────────────────────────
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is MilkBottle) other.collect();
    if (other is TrickyGoalFlag) {
      if (!other.tryEscape(position)) onReachGoal();
    } else if (other is GoalFlag) {
      onReachGoal();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Bandera de meta al final del nivel
class GoalFlag extends PositionComponent with CollisionCallbacks {
  GoalFlag({required Vector2 position})
      : super(
          position: position,
          size: Vector2(32, 80),
          anchor: Anchor.bottomLeft,
        );

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      position: Vector2(14, 0),
      size: Vector2(4, 80),
      paint: Paint()..color = const Color(0xFF795548),
    ));
    add(RectangleComponent(
      position: Vector2(18, 4),
      size: Vector2(20, 14),
      paint: Paint()..color = const Color(0xFFFFD600),
    ));
    add(TextComponent(
      text: '★',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
      position: Vector2(20, 2),
    ));
    add(RectangleHitbox());
  }
}
