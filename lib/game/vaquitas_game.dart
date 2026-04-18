import 'dart:math' show min, max;
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'components/player.dart';
import 'components/platform.dart';
import 'components/enemy.dart';
import 'components/milk_bottle.dart';
import 'components/background.dart';
import 'components/traps.dart';
import 'levels/level_data.dart';

class VaquitasGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapCallbacks {
  final GameState gameState;
  final VoidCallback onLevelComplete;
  final VoidCallback onGameOver;

  late Player player;
  late JoystickComponent joystick;
  late HudButtonComponent jumpButton;

  int _hAxisInput = 0;
  LevelInfo? _levelInfo;
  bool _playerReady = false;

  VaquitasGame({
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
  });

  // ── Input teclado ─────────────────────────────────────────────────────────
  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _hAxisInput = 0;
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _hAxisInput -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _hAxisInput += 1;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      if (_playerReady) player.jump();
    }

    // Salto variable: soltar tecla recorta la subida
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        if (_playerReady) player.releaseJump();
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }

  // ── Carga inicial ─────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    // Joystick táctil (HUD, no se mueve con el mundo)
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.8),
      ),
      background: CircleComponent(
        radius: 50,
        paint: Paint()..color = Colors.white.withValues(alpha: 0.3),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    camera.viewport.add(joystick);

    // Botón salto
    jumpButton = HudButtonComponent(
      button: CircleComponent(
        radius: 36,
        paint: Paint()..color = Colors.red.withValues(alpha: 0.7),
      ),
      buttonDown: CircleComponent(
        radius: 36,
        paint: Paint()..color = Colors.red.withValues(alpha: 0.4),
      ),
      margin: const EdgeInsets.only(right: 32, bottom: 32),
      onPressed: () { if (_playerReady) player.jump(); },
    );
    camera.viewport.add(jumpButton);

    await _loadLevel(gameState.currentLevel);
  }

  // ── Cargar nivel ──────────────────────────────────────────────────────────
  Future<void> _loadLevel(int level) async {
    _playerReady = false;

    // Limpiar world (plataformas, enemigos, botellas de leche, jugador, fondo)
    world.children
        .whereType<PositionComponent>()
        .toList()
        .forEach((c) => c.removeFromParent());

    final info = LevelData.getLevel(level);
    _levelInfo = info;

    // Fondo de ciudad nocturna
    world.add(GameBackground(level: level));

    // Plataformas (normales y tramposas)
    for (final p in info.platforms) {
      world.add(Platform(
        position: p.position,
        size: p.size,
        isGround: p.isGround,
        behavior: p.behavior,
      ));
    }

    // Pinchos trampa (Level Devil)
    for (final s in info.spikes) {
      world.add(SpikeTrap(
        position: s.position,
        widthPx: s.width,
        hiddenInitially: s.hiddenInitially,
        onPlayerHit: _onPlayerHitByEnemy,
      ));
    }

    // Enemigos normales
    for (final e in info.enemies) {
      world.add(Enemy(
        position: e.position,
        patrolRange: e.patrolRange,
        onPlayerHit: _onPlayerHitByEnemy,
      ));
    }

    // Jefe final solo en nivel 4
    if (level == 4) {
      world.add(BossEnemy(
        position: Vector2(2320, 440),
        onPlayerHit: _onPlayerHitByEnemy,
        onBossDefeated: () {
          // Cuando el jefe muere aparece la bandera de meta
          world.add(GoalFlag(position: Vector2(info.goalPosition.x, 440)));
        },
      ));
    } else if (info.trickyGoal) {
      world.add(TrickyGoalFlag(
        position: info.goalPosition,
        worldMaxX: info.worldSize.x,
      ));
    } else {
      world.add(GoalFlag(position: info.goalPosition));
    }

    // Botellas de leche
    gameState.resetCurrentLevel();
    for (final c in info.coins) {
      world.add(MilkBottle(position: c.position, gameState: gameState));
    }

    // Jugador
    player = Player(
      position: info.playerStart,
      onReachGoal: _onReachGoal,
      joystick: joystick,
    );
    world.add(player);

    // Cámara: comenzar desde el inicio del nivel
    camera.viewfinder.position = Vector2.zero();
    _playerReady = true;
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────
  void _onReachGoal() {
    _playerReady = false;
    pauseEngine();
    Future.delayed(const Duration(milliseconds: 600), () {
      resumeEngine();
      onLevelComplete();
    });
  }

  void _onPlayerHitByEnemy() {
    gameState.loseLife();
    if (gameState.lives <= 0) {
      _playerReady = false;
      pauseEngine();
      onGameOver();
    } else {
      player.respawn(); // respawn incluye startInvulnerability(2.0)
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);
    if (!_playerReady) return;

    // Input → movimiento del jugador
    const speed = 200.0;
    final joystickActive = joystick.direction != JoystickDirection.idle;

    if (joystickActive) {
      if (joystick.relativeDelta.x < -0.3) {
        player.moveLeft(speed);
      } else if (joystick.relativeDelta.x > 0.3) {
        player.moveRight(speed);
      } else {
        player.stopHorizontal();
      }
    } else if (_hAxisInput != 0) {
      if (_hAxisInput < 0) {
        player.moveLeft(speed);
      } else {
        player.moveRight(speed);
      }
    } else {
      player.stopHorizontal();
    }

    // Cámara con zona muerta
    _updateCamera(dt);
  }

  // ── Cámara con zona muerta estilo Mario ───────────────────────────────────
  void _updateCamera(double dt) {
    if (_levelInfo == null) return;

    final vpW = size.x;
    final vpH = size.y;

    // ── Eje X: zona muerta 30%–65% del ancho de pantalla ──
    final camLeft   = camera.viewfinder.position.x;
    final screenX   = player.position.x - camLeft;
    final deadLeft  = vpW * 0.30;
    final deadRight = vpW * 0.65;

    double targetLeft = camLeft;
    if (screenX > deadRight) {
      targetLeft = player.position.x - deadRight;
    } else if (screenX < deadLeft) { targetLeft = player.position.x - deadLeft; }

    final newLeft = camLeft + (targetLeft - camLeft) * min(1.0, 8.0 * dt);

    // ── Eje Y: seguir suavemente centrado en el jugador ──
    final camTop    = camera.viewfinder.position.y;
    final playerCY  = player.position.y - player.size.y / 2;
    final targetTop = playerCY - vpH * 0.55;
    final newTop    = camTop + (targetTop - camTop) * min(1.0, 5.0 * dt);

    // Clampear a los límites del nivel
    final lvlW = _levelInfo!.worldSize.x;
    final lvlH = _levelInfo!.worldSize.y;

    camera.viewfinder.position = Vector2(
      newLeft.clamp(0.0, max(0.0, lvlW - vpW)),
      newTop.clamp(0.0, max(0.0, lvlH - vpH)),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF0D0D2B); // noche
}
