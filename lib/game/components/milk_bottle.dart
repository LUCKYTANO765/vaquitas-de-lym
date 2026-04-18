import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';
import '../game_state.dart';

class MilkBottle extends PositionComponent with CollisionCallbacks {
  final GameState gameState;
  bool _collected = false;

  // Animacion de pulso y flotacion
  double _pulseTimer = 0.0;
  double _floatTimer = 0.0;
  final double _baseY;

  // Referencias a los sub-componentes visuales para animarlos
  late RectangleComponent _body;
  late RectangleComponent _shine;

  MilkBottle({
    required Vector2 position,
    required this.gameState,
  })  : _baseY = position.y,
        super(position: position, size: Vector2(18, 26), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // ── Cuerpo de la botella — rectángulo blanco ──
    _body = RectangleComponent(
      position: Vector2(3, 6),
      size: Vector2(12, 18),
      paint: Paint()..color = const Color(0xFFF5F5F5), // blanco leche
    );
    add(_body);

    // Borde de la botella
    add(RectangleComponent(
      position: Vector2(3, 6),
      size: Vector2(12, 18),
      paint: Paint()
        ..color = const Color(0xFFB0BEC5) // gris claro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    ));

    // ── Cuello de la botella — más angosto arriba ──
    add(RectangleComponent(
      position: Vector2(5, 1),
      size: Vector2(8, 7),
      paint: Paint()..color = const Color(0xFFF5F5F5),
    ));

    // Borde del cuello
    add(RectangleComponent(
      position: Vector2(5, 1),
      size: Vector2(8, 7),
      paint: Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    ));

    // ── Tapa de la botella — azul celeste ──
    add(RectangleComponent(
      position: Vector2(5, 0),
      size: Vector2(8, 3),
      paint: Paint()..color = const Color(0xFF42A5F5), // azul
    ));

    // ── Etiqueta — franja azul en el centro del cuerpo ──
    add(RectangleComponent(
      position: Vector2(4, 12),
      size: Vector2(10, 6),
      paint: Paint()..color = const Color(0xFF90CAF9), // azul claro
    ));

    // ── Brillo en esquina superior izquierda del cuerpo ──
    _shine = RectangleComponent(
      position: Vector2(4, 7),
      size: Vector2(4, 5),
      paint: Paint()..color = const Color(0xFFFFFFFF).withAlpha(180),
    );
    add(_shine);

    // Hitbox de colision
    add(RectangleHitbox(
      size: Vector2(14, 22),
      position: Vector2(2, 2),
      isSolid: false,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;

    // Flotacion vertical suave
    _floatTimer += dt * 2.5;
    position.y = _baseY + math.sin(_floatTimer) * 5.0;

    // Pulso de escala — la botella "respira"
    _pulseTimer += dt * 3.0;
    final pulse = 1.0 + math.sin(_pulseTimer) * 0.08;
    scale = Vector2.all(pulse);

    // El brillo parpadea suavemente alternando opacidad
    final shineAlpha = ((math.sin(_pulseTimer * 1.5) + 1) / 2 * 120 + 60).toInt();
    _shine.paint = Paint()
      ..color = Color.fromARGB(shineAlpha, 255, 255, 255);
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    gameState.collectMilk();
    removeFromParent();
  }
}
