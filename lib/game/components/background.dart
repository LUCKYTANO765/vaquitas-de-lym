import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../utils/pixel_palette.dart';

class GameBackground extends PositionComponent {
  final int level;
  GameBackground({required this.level});

  @override
  Future<void> onLoad() async {
    if (level == 4) {
      add(_TowerBackground());
    } else {
      add(_CityNightBackground(level: level));
    }
  }
}

class _CityNightBackground extends PositionComponent {
  final int level;
  final Random _rng = Random(42); // seed fijo = edificios consistentes
  late List<_Building> _buildings;
  late List<_Star> _stars;

  _CityNightBackground({required this.level})
      : super(position: Vector2(-100, -200), size: Vector2(3500, 900));

  @override
  Future<void> onLoad() async {
    _buildings = _generateBuildings();
    _stars = _generateStars();
    add(_BackgroundRenderer(
      buildings: _buildings,
      stars: _stars,
      level: level,
      size: size,
    ));
  }

  List<_Building> _generateBuildings() {
    final buildings = <_Building>[];
    double x = -80;
    while (x < 3400) {
      final w = 60.0 + _rng.nextInt(80).toDouble();
      final h = 120.0 + _rng.nextInt(200).toDouble();
      buildings.add(_Building(
        x: x,
        width: w,
        height: h,
        windowRows: (h / 28).floor(),
        windowCols: (w / 22).floor().clamp(1, 5),
        hasNeon: _rng.nextBool() && _rng.nextBool(),
        neonColor: [
          PixelPalette.neonBlue,
          PixelPalette.neonPink,
          PixelPalette.neonGreen,
          PixelPalette.neonOrange,
        ][_rng.nextInt(4)],
      ));
      x += w + 4 + _rng.nextInt(20);
    }
    return buildings;
  }

  List<_Star> _generateStars() {
    return List.generate(80, (i) => _Star(
      x: _rng.nextDouble() * 3400,
      y: _rng.nextDouble() * 300,
      size: _rng.nextDouble() * 2 + 1,
      phase: _rng.nextDouble() * pi * 2,
    ));
  }
}

class _BackgroundRenderer extends PositionComponent {
  final List<_Building> buildings;
  final List<_Star> stars;
  final int level;
  double _time = 0;

  _BackgroundRenderer({
    required this.buildings,
    required this.stars,
    required this.level,
    required Vector2 size,
  }) : super(size: size);

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Cielo degradado
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [PixelPalette.skyDark, PixelPalette.skyMid, PixelPalette.skyLight],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.75));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.75), skyPaint);

    // Estrellas
    for (final star in stars) {
      final alpha = (0.5 + 0.5 * sin(_time * 1.5 + star.phase)).clamp(0.2, 1.0);
      final starPaint = Paint()
        ..color = PixelPalette.starBright.withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromLTWH(star.x, star.y, star.size, star.size),
        starPaint,
      );
    }

    // Luna
    _drawMoon(canvas, w * 0.85, 60);

    // Edificios traseros (más oscuros, más lejos)
    for (int i = 0; i < buildings.length; i += 2) {
      _drawBuilding(canvas, buildings[i], h, far: true);
    }

    // Edificios delanteros
    for (int i = 1; i < buildings.length; i += 2) {
      _drawBuilding(canvas, buildings[i], h, far: false);
    }
  }

  void _drawMoon(Canvas canvas, double x, double y) {
    final moonPaint = Paint()..color = PixelPalette.moon;
    final shadowPaint = Paint()..color = PixelPalette.moonShadow;

    // Luna en píxeles (bloques de 4px)
    const r = 24.0;
    canvas.drawCircle(Offset(x, y), r, moonPaint);
    // Cráteres
    canvas.drawCircle(Offset(x - 8, y - 6), 5, shadowPaint);
    canvas.drawCircle(Offset(x + 6, y + 8), 4, shadowPaint);
    canvas.drawCircle(Offset(x + 10, y - 10), 3, shadowPaint);
  }

  void _drawBuilding(Canvas canvas, _Building b, double h, {required bool far}) {
    final groundY = h * 0.72;
    final top = groundY - b.height * (far ? 0.6 : 1.0);
    final bw = b.width * (far ? 0.8 : 1.0);
    final bx = b.x;

    final bodyColor = far ? PixelPalette.buildingDark : PixelPalette.buildingMid;
    final bodyPaint = Paint()..color = bodyColor;

    // Cuerpo edificio (pixel art: sin antialiasing)
    canvas.drawRect(Rect.fromLTWH(bx, top, bw, groundY - top), bodyPaint);

    // Borde izquierdo más claro
    canvas.drawRect(
      Rect.fromLTWH(bx, top, 2, groundY - top),
      Paint()..color = PixelPalette.buildingLight,
    );

    // Ventanas
    if (!far) {
      final winPaint = Paint();
      for (int row = 0; row < b.windowRows; row++) {
        for (int col = 0; col < b.windowCols; col++) {
          final wx = bx + 6 + col * 18.0;
          final wy = top + 10 + row * 24.0;
          if (wx + 10 > bx + bw) continue;

          // Ventana encendida/apagada según hash
          final on = (row + col + b.windowRows) % 3 != 0;
          winPaint.color = on
              ? (col % 2 == 0 ? PixelPalette.windowOn : PixelPalette.windowBlue)
              : PixelPalette.windowOff;
          canvas.drawRect(Rect.fromLTWH(wx, wy, 10, 14), winPaint);
        }
      }
    }

    // Cartel de neón en la azotea
    if (b.hasNeon && !far) {
      final neonPaint = Paint()
        ..color = b.neonColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(
        Rect.fromLTWH(bx + bw * 0.2, top - 8, bw * 0.6, 6),
        neonPaint,
      );
    }
  }

}

class _Building {
  final double x, width, height;
  final int windowRows, windowCols;
  final bool hasNeon;
  final Color neonColor;
  _Building({
    required this.x,
    required this.width,
    required this.height,
    required this.windowRows,
    required this.windowCols,
    required this.hasNeon,
    required this.neonColor,
  });
}

class _Star {
  final double x, y, size, phase;
  _Star({required this.x, required this.y, required this.size, required this.phase});
}

// ═══════════════════════════════════════════════════════════════════════════════
// FONDO NIVEL 4 — TORRE FINAL (basado en imágenes)
// Usa las 3 imágenes de background del nivel 4 colocadas una al lado de la otra
// ═══════════════════════════════════════════════════════════════════════════════

class _TowerBackground extends PositionComponent with HasGameReference {
  _TowerBackground()
      : super(position: Vector2(0, 0), size: Vector2(2400, 700));

  @override
  Future<void> onLoad() async {
    // Nombres de archivo de las 3 capas de fondo
    final imageFiles = [
      'backgrunad 1 nivel 4.png',
      'backgroaund 2 nivel 4.png',
      'backgrund 3 nivel 4.png',
    ];

    // Ancho total del mundo: 2400px → cada imagen ocupa 800px
    const segmentWidth = 800.0;
    const worldHeight = 700.0;

    for (int i = 0; i < imageFiles.length; i++) {
      final image = await game.images.load(imageFiles[i]);
      final sprite = Sprite(image);

      add(SpriteComponent(
        sprite: sprite,
        position: Vector2(i * segmentWidth, 0),
        size: Vector2(segmentWidth, worldHeight),
        priority: -10, // detrás de todo
      ));
    }
  }
}
