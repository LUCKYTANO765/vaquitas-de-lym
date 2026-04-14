import 'dart:ui' show Rect;
import 'package:flame/components.dart';
import 'level_data.dart';

/// Define los limites fisicos de cada nivel.
/// La camara y los sistemas de colision usan esta clase para
/// mantener al jugador y a la vista dentro del mundo del nivel.
class LevelBounds {
  // Tamano del mundo para cada nivel
  static Vector2 getSize(int level) {
    final info = LevelData.getLevel(level);
    return info.worldSize.clone();
  }

  // Punto de aparicion del jugador al inicio del nivel
  static Vector2 getPlayerStart(int level) {
    final info = LevelData.getLevel(level);
    return info.playerStart.clone();
  }

  // Posicion de la meta / bandera / Lym en el nivel
  static Vector2 getGoalPosition(int level) {
    final info = LevelData.getLevel(level);
    return info.goalPosition.clone();
  }

  // Limite izquierdo del mundo (siempre 0 en estos niveles de scroll lateral)
  static double leftBound(int level) => 0.0;

  // Limite derecho del mundo
  static double rightBound(int level) => getSize(level).x;

  // Limite superior del mundo
  static double topBound(int level) => 0.0;

  // Limite inferior: si el jugador cae mas alla de este valor → respawn
  static double deathFloor(int level) => getSize(level).y + 200;

  /// Clampea una posicion X para que el jugador no salga por los lados.
  /// Recibe el ancho del jugador para calcular el margen derecho correctamente.
  static double clampX(int level, double x, double entityWidth) {
    final right = rightBound(level) - entityWidth;
    return x.clamp(leftBound(level), right);
  }

  /// Devuelve true si la posicion Y supera el limite de caida al vacio.
  static bool isBelowDeathFloor(int level, double y) {
    return y > deathFloor(level);
  }

  /// Rectangulo que engloba todo el mundo del nivel.
  /// Util para configurar los limites de la camara de Flame:
  ///   camera.setBounds(LevelBounds.getWorldRect(level));
  static Rect getWorldRect(int level) {
    final size = getSize(level);
    return Rect.fromLTWH(0, 0, size.x, size.y);
  }
}
