import 'dart:math' show min;
import 'dart:ui' hide TextStyle;
import 'package:flutter/material.dart' show TextStyle, Color;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'platform.dart';
import 'coin.dart';
import '../vaquitas_game.dart';

enum PlayerState { idle, running, jumping, falling }

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<VaquitasGame> {
  final VoidCallback onReachGoal;
  final JoystickComponent joystick;

  // ── Física ───────────────────────────────────────────────────────────────
  static const double gravity      = 900.0;
  static const double jumpForce    = -560.0;  // altura max ≈174px
  static const double maxFallSpeed = 600.0;
  static const double walkAccel    = 1400.0;
  static const double maxWalkSpeed = 220.0;

  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;

  // ── Estado ───────────────────────────────────────────────────────────────
  bool _facingRight = true;
  PlayerState state = PlayerState.idle;
  late Vector2 _spawnPoint;
  int _moveInput = 0; // -1 izq | 0 stop | 1 der

  // salto variable desactivado — altura fija y predecible

  // ── Invulnerabilidad ──────────────────────────────────────────────────────
  double _invulnerableTimer = 0.0;
  double _flashTimer        = 0.0;
  bool   _flashVisible      = true;

  // ── Animación ─────────────────────────────────────────────────────────────
  double _animTimer = 0;
  int    _animFrame = 0;

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

  void jump() {
    if (isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
      state = PlayerState.jumping;
    }
  }

  void releaseJump() {} // no-op: salto de altura fija

  /// Inicia parpadeo de invulnerabilidad tras recibir daño.
  void startInvulnerability(double duration) {
    _invulnerableTimer = duration;
    _flashTimer  = 0;
    _flashVisible = true;
  }

  void respawn() {
    position = _spawnPoint.clone();
    velocity  = Vector2.zero();
    isOnGround = false;
    state = PlayerState.idle;
    startInvulnerability(2.0);
  }

  // ── Colisiones contra plataforma (suelo) ─────────────────────────────────
  /// Raycast manual hacia abajo. Snappea el pie a la plataforma si encuentra suelo.
  bool _checkOnGround() {
    final pLeft  = position.x + 3;
    final pRight = position.x + size.x - 3;
    final pFoot  = position.y; // anchor bottomLeft → position.y == pie

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

  /// Empuja al jugador fuera de paredes en el eje X.
  void _resolveXCollision() {
    // Cuerpo efectivo (excluye 2 px de tolerancia arriba y abajo)
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

      // Sin solapamiento en Y → no hay choque lateral
      if (pBottom <= platTop || pTop >= platBottom) continue;
      // Sin solapamiento en X → no hay choque
      if (pRight <= platLeft || pLeft >= platRight) continue;

      // Empujar según dirección de movimiento
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

    // 1. Invulnerabilidad / parpadeo
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
      // Fricción: desaceleración exponencial suave
      velocity.x *= (1.0 - min(1.0, 10.0 * dt));
      if (velocity.x.abs() < 2) velocity.x = 0;
    }

    // 3. Mover en X y resolver colisiones laterales
    position.x += velocity.x * dt;
    _resolveXCollision();

    // 4. Gravedad
    if (!isOnGround) {
      velocity.y += gravity * dt;
      if (velocity.y > maxFallSpeed) velocity.y = maxFallSpeed;
    }

    // 5. Mover en Y y resolver suelo
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

    // 6. Estado de animación
    if (!isOnGround) {
      state = velocity.y < 0 ? PlayerState.jumping : PlayerState.falling;
    } else if (velocity.x.abs() > 10) {
      state = PlayerState.running;
    } else {
      state = PlayerState.idle;
    }

    // 7. Temporizador de animación
    _animTimer += dt;
    if (_animTimer >= 0.15) {
      _animTimer = 0;
      _animFrame = (_animFrame + 1) % 2;
    }

    // 8. Orientación
    if (velocity.x >  10) _facingRight = true;
    if (velocity.x < -10) _facingRight = false;

    // 9. Caída al vacío
    if (position.y > 1400) respawn();
  }

  // ── Render ────────────────────────────────────────────────────────────────
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_flashVisible) return; // parpadea durante invulnerabilidad

    if (!_facingRight) {
      canvas.save();
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    _drawPixelArt(canvas);
    if (!_facingRight) canvas.restore();
  }

  void _drawPixelArt(Canvas canvas) {
    const px = 4.0;

    final bodyPaint    = Paint()..color = const Color(0xFF1565C0);
    final hatPaint     = Paint()..color = const Color(0xFFD32F2F);
    final skinPaint    = Paint()..color = const Color(0xFFFFCC80);
    final whitePaint   = Paint()..color = const Color(0xFFFFFFFF);
    final darkPaint    = Paint()..color = const Color(0xFF0D3F7F);
    final pantsPaint   = Paint()..color = const Color(0xFF0A3D91);
    final shoePaint    = Paint()..color = const Color(0xFF4E342E);
    final outlinePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Gorro
    canvas.drawRect(const Rect.fromLTWH(2 * px, 0, 5 * px, px), hatPaint);
    canvas.drawRect(const Rect.fromLTWH(3 * px, px, 3 * px, 2 * px), hatPaint);

    // Cara
    canvas.drawRect(const Rect.fromLTWH(2 * px, 3 * px, 4 * px, 3 * px), skinPaint);
    canvas.drawRect(const Rect.fromLTWH(3 * px, 4 * px, px, px), whitePaint);
    canvas.drawRect(const Rect.fromLTWH(5 * px, 4 * px, px, px), whitePaint);
    final eyePaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(const Rect.fromLTWH(3.4 * px, 4.3 * px, px * 0.6, px * 0.6), eyePaint);
    canvas.drawRect(const Rect.fromLTWH(5.4 * px, 4.3 * px, px * 0.6, px * 0.6), eyePaint);

    // Cuerpo
    canvas.drawRect(const Rect.fromLTWH(px, 6 * px, 6 * px, 4 * px), bodyPaint);
    canvas.drawRect(const Rect.fromLTWH(3.5 * px, 7 * px, px * 0.6, px * 0.6), whitePaint);
    canvas.drawRect(const Rect.fromLTWH(3.5 * px, 8.5 * px, px * 0.6, px * 0.6), whitePaint);

    // Brazos
    if (state == PlayerState.jumping || state == PlayerState.falling) {
      canvas.drawRect(const Rect.fromLTWH(0, 5 * px, px, 2 * px), bodyPaint);
      canvas.drawRect(const Rect.fromLTWH(7 * px, 5 * px, px, 2 * px), bodyPaint);
      canvas.drawRect(const Rect.fromLTWH(0, 3 * px, px, 2 * px), skinPaint);
      canvas.drawRect(const Rect.fromLTWH(7 * px, 3 * px, px, 2 * px), skinPaint);
    } else {
      canvas.drawRect(const Rect.fromLTWH(0, 6 * px, px, 3 * px), bodyPaint);
      canvas.drawRect(const Rect.fromLTWH(7 * px, 6 * px, px, 3 * px), bodyPaint);
      canvas.drawRect(const Rect.fromLTWH(0, 9 * px, px, px), skinPaint);
      canvas.drawRect(const Rect.fromLTWH(7 * px, 9 * px, px, px), skinPaint);
    }

    // Pantalón
    canvas.drawRect(const Rect.fromLTWH(px, 10 * px, 6 * px, 2 * px), pantsPaint);

    // Piernas y zapatos
    if (state == PlayerState.running) {
      final legAOffset = _animFrame == 0 ? 0.0 : px;
      final legBOffset = _animFrame == 0 ? px : 0.0;
      canvas.drawRect(Rect.fromLTWH(px + legAOffset, 12 * px, px, 2 * px), darkPaint);
      canvas.drawRect(Rect.fromLTWH(px + legAOffset, 10 * px, px, 2 * px), pantsPaint);
      canvas.drawRect(Rect.fromLTWH(4 * px + legBOffset, 12 * px, px, 2 * px), darkPaint);
      canvas.drawRect(Rect.fromLTWH(4 * px + legBOffset, 10 * px, px, 2 * px), pantsPaint);
    } else {
      canvas.drawRect(const Rect.fromLTWH(1.5 * px, 12 * px, px, 2 * px), darkPaint);
      canvas.drawRect(const Rect.fromLTWH(4.5 * px, 12 * px, px, 2 * px), darkPaint);
    }

    canvas.drawRect(const Rect.fromLTWH(px, 11 * px, 2 * px, px), shoePaint);
    canvas.drawRect(const Rect.fromLTWH(4 * px, 11 * px, 2 * px, px), shoePaint);

    canvas.drawRect(
      const Rect.fromLTWH(px, 6 * px, 6 * px, 4 * px),
      outlinePaint,
    );
  }

  // ── Colisiones (monedas y bandera de meta) ────────────────────────────────
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Coin) other.collect();
    if (other is GoalFlag) onReachGoal();
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
