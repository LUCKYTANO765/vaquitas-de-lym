import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState extends ChangeNotifier {
  int currentLevel = 1;
  int totalLevels = 4; // Nivel 1, 2, 3, Torre Final
  int lives = 3;
  int score = 0;
  bool gameCompleted = false;

  // Botellas de leche
  int coinsCollected = 0; // botellas de leche totales acumuladas en toda la partida
  int levelCoins = 0;     // botellas de leche recogidas en el nivel actual

  // Mejor puntuacion y nombre del jugador
  int highScore = 0;
  String playerName = 'Hero';

  // Foto de la vaquita elegida por el jugador (path local)
  String? vaquitaPhotoPath;

  // Posicion de respawn dentro del nivel actual
  // El componente Player la actualiza; GameState la preserva entre muertes
  // (null = usar playerStart definido en LevelData)
  // ignore: prefer_final_fields

  // ─── Estrella del nivel ───────────────────────────────────────────────────
  /// Devuelve 1, 2 o 3 estrellas segun cuantas botellas de leche se recogieron
  /// frente al total disponible en el nivel.
  int getStarsForLevel(int collectedCoins, int maxCoins) {
    if (maxCoins <= 0) return 1;
    if (collectedCoins >= maxCoins) return 3;
    if (collectedCoins >= (maxCoins * 0.6).ceil()) return 2;
    return 1;
  }

  // ─── Botellas de leche ────────────────────────────────────────────────────
  void collectMilk() {
    levelCoins++;
    coinsCollected++;
    score += 100;
    notifyListeners();
  }

  // ─── Reset solo el nivel actual sin perder progreso global ────────────────
  void resetCurrentLevel() {
    levelCoins = 0;
    // No se resetea: score, coinsCollected, lives, currentLevel ni highScore
    notifyListeners();
  }

  // ─── Progresion de niveles ────────────────────────────────────────────────
  void nextLevel() {
    if (currentLevel < totalLevels) {
      currentLevel++;
    } else {
      gameCompleted = true;
    }
    score += 1000;
    levelCoins = 0; // reinicia botellas de leche del nivel al avanzar
    _updateHighScore();
    saveProgress();
    notifyListeners();
  }

  void addScore(int points) {
    score += points;
    _updateHighScore();
    notifyListeners();
  }

  void loseLife() {
    if (lives > 0) lives--;
    notifyListeners();
  }

  // ─── Reset completo ───────────────────────────────────────────────────────
  void resetGame() {
    currentLevel = 1;
    lives = 3;
    score = 0;
    coinsCollected = 0;
    levelCoins = 0;
    gameCompleted = false;
    saveProgress();
    notifyListeners();
  }

  // ─── High score ───────────────────────────────────────────────────────────
  void _updateHighScore() {
    if (score > highScore) {
      highScore = score;
    }
  }

  // ─── Persistencia ─────────────────────────────────────────────────────────
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', currentLevel);
    await prefs.setInt('score', score);
    await prefs.setInt('coinsCollected', coinsCollected);
    await prefs.setInt('highScore', highScore);
    await prefs.setString('playerName', playerName);
    await prefs.setBool('gameCompleted', gameCompleted);
    if (vaquitaPhotoPath != null) {
      await prefs.setString('vaquitaPhotoPath', vaquitaPhotoPath!);
    }
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    currentLevel = prefs.getInt('currentLevel') ?? 1;
    score = prefs.getInt('score') ?? 0;
    coinsCollected = prefs.getInt('coinsCollected') ?? 0;
    highScore = prefs.getInt('highScore') ?? 0;
    playerName = prefs.getString('playerName') ?? 'Hero';
    gameCompleted = prefs.getBool('gameCompleted') ?? false;
    vaquitaPhotoPath = prefs.getString('vaquitaPhotoPath');
    notifyListeners();
  }

  Future<void> setVaquitaPhoto(String path) async {
    vaquitaPhotoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vaquitaPhotoPath', path);
    notifyListeners();
  }
}
