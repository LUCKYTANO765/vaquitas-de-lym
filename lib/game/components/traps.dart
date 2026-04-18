import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart';
import 'player.dart';
import '../vaquitas_game.dart';

/// Pincho trampa estilo Level Devil.
/// hidden=true: invisible hasta que el jugador esta cerca, entonces sale de golpe.
class SpikeTrap extends PositionComponent
    with CollisionCallbacks, HasGameReference<VaquitasGame> {
  final VoidCallback onPlayerHit;
  final double widthPx;
  final bool hiddenInitially;

  bool _revealed = false;
  double _offsetY = 0;

  SpikeTrap({
    required Vector2 position,
    required this.onPlayerHit,
    this.widthPx = 60,
    this.hiddenInitially = false,
  }) : super(
            position: position,
            size: Vector2(widthPx, 20),
            anchor: Anchor.bottomLeft);

  late PolygonComponent _spikes;
  late RectangleHitbox _hitbox;

  @override
  Future<void> onLoad() async {
    // Dientes triangulares
    const toothW = 12.0;
    final teeth = (widthPx / toothW).floor();
    final path = <Vector2>[];
    for (int i = 0; i < teeth; i++) {
      final x = i * toothW;
      path.add(Vector2(x, 20));
      path.add(Vector2(x + toothW / 2, 0));
    }
    path.add(Vector2(widthPx, 20));

    _spikes = PolygonComponent(
      path,
      paint: Paint()..color = const Color(0xFFBDBDBD),
    );
    add(_spikes);

    _hitbox = RectangleHitbox(size: Vector2(widthPx, 20));
    add(_hitbox);

    if (hiddenInitially) {
      _offsetY = 22;
      _spikes.position.y = _offsetY;
      _hitbox.position.y = _offsetY;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!hiddenInitially) return;

    final dx = (game.player.position.x - position.x).abs();
    if (!_revealed && dx < 80) {
      _revealed = true;
      parent?.add(DevilTaunt(position: Vector2(position.x + widthPx / 2, position.y - 30)));
    }

    if (_revealed && _offsetY > 0) {
      _offsetY = (_offsetY - 120 * dt).clamp(0, 22);
      _spikes.position.y = _offsetY;
      _hitbox.position.y = _offsetY;
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && !other.isInvulnerable && _offsetY <= 2) {
      onPlayerHit();
    }
  }
}

/// Bandera que se aleja al acercarse (Level Devil troll).
/// Tras `maxTeleports` huidas se queda fija y el jugador puede ganar.
class TrickyGoalFlag extends PositionComponent with CollisionCallbacks {
  final int maxTeleports;
  final double worldMaxX;
  int _teleports = 0;
  double _cooldown = 0;

  TrickyGoalFlag({
    required Vector2 position,
    this.maxTeleports = 2,
    required this.worldMaxX,
  }) : super(
            position: position,
            size: Vector2(32, 80),
            anchor: Anchor.bottomLeft);

  late RectangleHitbox _hitbox;

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
      textRenderer: TextPaint(
          style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
      position: Vector2(20, 2),
    ));
    _hitbox = RectangleHitbox();
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_cooldown > 0) _cooldown -= dt;
  }

  // Intenta escapar; devuelve true si escapo, false si ya puede ser tomada.
  bool tryEscape(Vector2 playerPos) {
    if (_teleports >= maxTeleports) return false;
    if (_cooldown > 0) return false;

    _teleports++;
    _cooldown = 0.8;
    // Salta hacia adelante 250-400px, clamp al mundo
    final jump = 300.0 + 80.0 * _teleports;
    position.x = (position.x + jump).clamp(100.0, worldMaxX - 100);

    // Pequeno guino visual
    add(TextComponent(
      text: '¡jaja!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFFF5252),
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF000000), offset: Offset(1, 1))],
        ),
      ),
      position: Vector2(-10, -18),
    )..add(RemoveEffect(delay: 1.2)));

    return true;
  }
}

// Helper de eliminacion temporal
class RemoveEffect extends Component {
  double delay;
  RemoveEffect({required this.delay});

  @override
  void update(double dt) {
    super.update(dt);
    delay -= dt;
    if (delay <= 0) parent?.removeFromParent();
  }
}

// Popup de diablo burlon — sale desde la trampa y se va arriba
class DevilTaunt extends PositionComponent {
  double _life = 0.9;
  double _vy = -80;

  DevilTaunt({required Vector2 position})
      : super(position: position, anchor: Anchor.center);

  late TextComponent _txt;

  @override
  Future<void> onLoad() async {
    _txt = TextComponent(
      text: '😈',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 28)),
      anchor: Anchor.center,
    );
    add(_txt);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _vy * dt;
    _vy += 40 * dt;
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }
}
