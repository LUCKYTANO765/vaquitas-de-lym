import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';
import '../game_state.dart';

class Coin extends PositionComponent with CollisionCallbacks {
  final GameState gameState;
  bool _collected = false;

  // Animacion de pulso y flotacion
  double _pulseTimer = 0.0;
  double _floatTimer = 0.0;
  final double _baseY;

  // Referencias a los sub-componentes visuales para animarlos
  late RectangleComponent _body;
  late RectangleComponent _shine;

  Coin({
    required Vector2 position,
    required this.gameState,
  })  : _baseY = position.y,
        super(position: position, size: Vector2(20, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Cuerpo principal — cuadrado amarillo pixel art
    _body = RectangleComponent(
      size: Vector2(20, 20),
      paint: Paint()..color = const Color(0xFFFFD600),
    );
    add(_body);

    // Borde oscuro para dar efecto de profundidad pixel art
    add(RectangleComponent(
      size: Vector2(20, 20),
      paint: Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    // Brillo en esquina superior izquierda
    _shine = RectangleComponent(
      position: Vector2(3, 3),
      size: Vector2(6, 6),
      paint: Paint()..color = const Color(0xFFFFFDE7),
    );
    add(_shine);

    // Hitbox de colision (un poco mas pequena que el sprite)
    add(RectangleHitbox(
      size: Vector2(16, 16),
      position: Vector2(2, 2),
      isSolid: false,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    // Flotacion vertical suave — seno para arriba y abajo
    _floatTimer += dt * 2.5;
    position.y = _baseY + math.sin(_floatTimer) * 5.0;

    // Pulso de escala — la moneda "respira"
    _pulseTimer += dt * 3.0;
    final pulse = 1.0 + math.sin(_pulseTimer) * 0.08;
    scale = Vector2.all(pulse);

    // El brillo parpadea suavemente alternando opacidad
    final shineAlpha = ((math.sin(_pulseTimer * 1.5) + 1) / 2 * 200 + 55).toInt();
    _shine.paint = Paint()
      ..color = Color.fromARGB(shineAlpha, 255, 253, 231);
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    gameState.collectCoin();
    removeFromParent();
  }
}
