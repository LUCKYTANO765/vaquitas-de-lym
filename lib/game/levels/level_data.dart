import 'package:flame/components.dart';

// Datos de una plataforma
class PlatformData {
  final Vector2 position;
  final Vector2 size;
  final bool isGround;

  PlatformData({
    required this.position,
    required this.size,
    this.isGround = false,
  });
}

// Datos de un enemigo
class EnemyData {
  final Vector2 position;
  final double patrolRange;

  EnemyData({required this.position, required this.patrolRange});
}

// Datos de una moneda/flor
class CoinData {
  final Vector2 position;

  CoinData({required this.position});
}

class LevelInfo {
  final List<PlatformData> platforms;
  final List<EnemyData> enemies;
  final List<CoinData> coins;
  final Vector2 playerStart;
  final Vector2 goalPosition;
  final Vector2 worldSize;
  final String name;
  final String emoji;
  // 'city_day' | 'city_night' | 'rooftop' | 'tower'
  final String bgType;

  LevelInfo({
    required this.platforms,
    required this.enemies,
    required this.coins,
    required this.playerStart,
    required this.goalPosition,
    required this.worldSize,
    required this.name,
    required this.emoji,
    required this.bgType,
  });

  // Cantidad maxima de monedas en este nivel
  int get maxCoins => coins.length;
}

class LevelData {
  static LevelInfo getLevel(int level) {
    switch (level) {
      case 1:
        return _level1();
      case 2:
        return _level2();
      case 3:
        return _level3();
      case 4:
        return _level4Tower();
      default:
        return _level1();
    }
  }

  // ─────────────────────────────────────────────
  // NIVEL 1: Barrio Tranquilo
  // Introduccion a la ciudad de noche — plataformas bajas, pocos enemigos
  // ─────────────────────────────────────────────
  static LevelInfo _level1() {
    return LevelInfo(
      name: 'Barrio Tranquilo',
      emoji: '🏘️',
      bgType: 'city_night',
      worldSize: Vector2(2400, 600),
      playerStart: Vector2(80, 500),
      goalPosition: Vector2(2300, 440),
      platforms: [
        // Aceras del barrio — suelo principal
        PlatformData(position: Vector2(0, 550), size: Vector2(800, 50), isGround: true),
        PlatformData(position: Vector2(900, 550), size: Vector2(600, 50), isGround: true),
        PlatformData(position: Vector2(1600, 550), size: Vector2(800, 50), isGround: true),
        // Escalones de casas bajas — primer paso 80px, luego 60px cada subida
        PlatformData(position: Vector2(300, 470), size: Vector2(130, 20)),  // 80px sobre suelo
        PlatformData(position: Vector2(510, 410), size: Vector2(130, 20)),  // 60px sobre anterior
        PlatformData(position: Vector2(710, 350), size: Vector2(130, 20)),  // 60px sobre anterior
        // Techo de tiendas
        PlatformData(position: Vector2(1000, 470), size: Vector2(160, 20)), // 80px sobre suelo
        PlatformData(position: Vector2(1210, 410), size: Vector2(160, 20)), // 60px sobre anterior
        PlatformData(position: Vector2(1420, 350), size: Vector2(130, 20)), // 60px sobre anterior
        // Cornisas del barrio
        PlatformData(position: Vector2(1700, 470), size: Vector2(190, 20)), // 80px sobre suelo
        PlatformData(position: Vector2(1960, 410), size: Vector2(130, 20)), // 60px sobre anterior
        PlatformData(position: Vector2(2160, 480), size: Vector2(200, 20)), // accesible desde suelo
      ],
      enemies: [
        EnemyData(position: Vector2(400, 550), patrolRange: 200),
        EnemyData(position: Vector2(1060, 470), patrolRange: 120),
        EnemyData(position: Vector2(1730, 470), patrolRange: 160),
      ],
      coins: [
        CoinData(position: Vector2(360, 445)),   // sobre plat (300,470)
        CoinData(position: Vector2(570, 385)),   // sobre plat (510,410)
        CoinData(position: Vector2(770, 325)),   // sobre plat (710,350)
        CoinData(position: Vector2(1270, 385)),  // sobre plat (1210,410)
        CoinData(position: Vector2(1480, 325)),  // sobre plat (1420,350)
        CoinData(position: Vector2(1820, 445)),  // sobre plat (1700,470)
        CoinData(position: Vector2(2010, 385)),  // sobre plat (1960,410)
      ],
    );
  }

  // ─────────────────────────────────────────────
  // NIVEL 2: Centro Comercial
  // Plataformas medianas, mas enemigos, tiendas nocturnas
  // ─────────────────────────────────────────────
  static LevelInfo _level2() {
    return LevelInfo(
      name: 'Centro Comercial',
      emoji: '🏬',
      bgType: 'city_night',
      worldSize: Vector2(2800, 600),
      playerStart: Vector2(80, 500),
      goalPosition: Vector2(2700, 440),
      platforms: [
        // Aceras principales del centro
        PlatformData(position: Vector2(0, 550), size: Vector2(500, 50), isGround: true),
        PlatformData(position: Vector2(600, 550), size: Vector2(400, 50), isGround: true),
        PlatformData(position: Vector2(1100, 550), size: Vector2(500, 50), isGround: true),
        PlatformData(position: Vector2(1700, 550), size: Vector2(400, 50), isGround: true),
        PlatformData(position: Vector2(2200, 550), size: Vector2(600, 50), isGround: true),
        // Marquesinas y balcones de tiendas
        PlatformData(position: Vector2(260, 410), size: Vector2(110, 20)),
        PlatformData(position: Vector2(460, 340), size: Vector2(110, 20)),
        PlatformData(position: Vector2(690, 430), size: Vector2(130, 20)),
        PlatformData(position: Vector2(910, 360), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1160, 290), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1390, 410), size: Vector2(130, 20)),
        // Planta alta del centro comercial
        PlatformData(position: Vector2(1810, 400), size: Vector2(110, 20)), // bajada 40px
        PlatformData(position: Vector2(2060, 340), size: Vector2(130, 20)), // bajada 50px
        PlatformData(position: Vector2(2310, 390), size: Vector2(190, 20)),
        PlatformData(position: Vector2(2560, 460), size: Vector2(200, 20)),
      ],
      enemies: [
        EnemyData(position: Vector2(310, 550), patrolRange: 180),
        EnemyData(position: Vector2(720, 430), patrolRange: 110),
        EnemyData(position: Vector2(1210, 290), patrolRange: 90),
        EnemyData(position: Vector2(1840, 400), patrolRange: 90),
        EnemyData(position: Vector2(2410, 390), patrolRange: 170),
      ],
      coins: [
        CoinData(position: Vector2(310, 380)),
        CoinData(position: Vector2(510, 310)),
        CoinData(position: Vector2(960, 330)),
        CoinData(position: Vector2(1210, 260)),
        CoinData(position: Vector2(1860, 375)),  // sobre plat (1810,400)
        CoinData(position: Vector2(2110, 315)),  // sobre plat (2060,340)
        CoinData(position: Vector2(2410, 360)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // NIVEL 3: Azoteas de la Ciudad
  // Plataformas altas y separadas — dificil, solo azoteas bajo las estrellas
  // ─────────────────────────────────────────────
  static LevelInfo _level3() {
    return LevelInfo(
      name: 'Azoteas de la Ciudad',
      emoji: '🌃',
      bgType: 'rooftop',
      worldSize: Vector2(3000, 700),
      playerStart: Vector2(80, 600),
      goalPosition: Vector2(2900, 500),
      platforms: [
        // Primeros edificios — base de azoteas
        PlatformData(position: Vector2(0, 650), size: Vector2(400, 50), isGround: true),
        PlatformData(position: Vector2(500, 650), size: Vector2(300, 50), isGround: true),
        PlatformData(position: Vector2(900, 650), size: Vector2(300, 50), isGround: true),
        PlatformData(position: Vector2(1300, 650), size: Vector2(400, 50), isGround: true),
        PlatformData(position: Vector2(1800, 650), size: Vector2(400, 50), isGround: true),
        PlatformData(position: Vector2(2300, 650), size: Vector2(700, 50), isGround: true),
        // Azoteas en zigzag muy separadas
        PlatformData(position: Vector2(200, 510), size: Vector2(90, 20)),
        PlatformData(position: Vector2(390, 430), size: Vector2(90, 20)),
        PlatformData(position: Vector2(570, 360), size: Vector2(90, 20)),
        PlatformData(position: Vector2(760, 440), size: Vector2(90, 20)),
        PlatformData(position: Vector2(960, 360), size: Vector2(90, 20)),
        PlatformData(position: Vector2(1160, 285), size: Vector2(90, 20)),
        // Tanques de agua y chimeneas como plataformas
        PlatformData(position: Vector2(1360, 360), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1560, 440), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1760, 360), size: Vector2(90, 20)),
        PlatformData(position: Vector2(1990, 285), size: Vector2(90, 20)),
        // Azoteas altas finales
        PlatformData(position: Vector2(2210, 390), size: Vector2(130, 20)),
        PlatformData(position: Vector2(2460, 490), size: Vector2(200, 20)),
        PlatformData(position: Vector2(2710, 530), size: Vector2(260, 20)),
      ],
      enemies: [
        EnemyData(position: Vector2(255, 510), patrolRange: 60),
        EnemyData(position: Vector2(610, 360), patrolRange: 60),
        EnemyData(position: Vector2(1010, 360), patrolRange: 60),
        EnemyData(position: Vector2(1410, 360), patrolRange: 90),
        EnemyData(position: Vector2(1810, 360), patrolRange: 60),
        EnemyData(position: Vector2(2250, 390), patrolRange: 110),
      ],
      coins: [
        CoinData(position: Vector2(245, 480)),
        CoinData(position: Vector2(430, 400)),
        CoinData(position: Vector2(610, 330)),
        CoinData(position: Vector2(1000, 330)),
        CoinData(position: Vector2(1200, 255)),
        CoinData(position: Vector2(1600, 410)),
        CoinData(position: Vector2(2030, 255)),
        CoinData(position: Vector2(2510, 460)),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // NIVEL 4: Torre Final
  // Rascacielos oscuro donde esta Lym — jefe final antes del rescate
  // ─────────────────────────────────────────────
  static LevelInfo _level4Tower() {
    return LevelInfo(
      name: 'Torre Final',
      emoji: '🏙️',
      bgType: 'tower',
      worldSize: Vector2(2400, 700),
      playerStart: Vector2(80, 580),
      goalPosition: Vector2(2300, 400), // Aqui esta Lym
      platforms: [
        // Suelo de la torre (hormigon oscuro)
        PlatformData(position: Vector2(0, 630), size: Vector2(400, 70), isGround: true),
        PlatformData(position: Vector2(500, 630), size: Vector2(300, 70), isGround: true),
        PlatformData(position: Vector2(900, 630), size: Vector2(400, 70), isGround: true),
        PlatformData(position: Vector2(1400, 630), size: Vector2(400, 70), isGround: true),
        PlatformData(position: Vector2(1900, 630), size: Vector2(500, 70), isGround: true),
        // Escalones hacia la cima del rascacielos
        PlatformData(position: Vector2(200, 530), size: Vector2(110, 20)),
        PlatformData(position: Vector2(410, 460), size: Vector2(110, 20)),
        PlatformData(position: Vector2(630, 410), size: Vector2(130, 20)),
        PlatformData(position: Vector2(860, 350), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1060, 440), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1290, 370), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1510, 290), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1730, 370), size: Vector2(110, 20)),
        PlatformData(position: Vector2(1960, 310), size: Vector2(130, 20)),
        // Plataforma del jefe final (penthouse del rascacielos)
        PlatformData(position: Vector2(2100, 440), size: Vector2(300, 20)),
        // Piso donde esta Lym — ultimo piso de la torre
        PlatformData(position: Vector2(2200, 210), size: Vector2(200, 20)),
      ],
      enemies: [
        EnemyData(position: Vector2(310, 530), patrolRange: 90),
        EnemyData(position: Vector2(660, 410), patrolRange: 110),
        EnemyData(position: Vector2(1110, 440), patrolRange: 90),
        EnemyData(position: Vector2(1540, 290), patrolRange: 90),
        EnemyData(position: Vector2(1970, 310), patrolRange: 110),
        // BossEnemy se agrega desde vaquitas_game.dart para este nivel
      ],
      coins: [
        CoinData(position: Vector2(255, 500)),
        CoinData(position: Vector2(460, 430)),
        CoinData(position: Vector2(690, 380)),
        CoinData(position: Vector2(910, 320)),
        CoinData(position: Vector2(1320, 340)),
        CoinData(position: Vector2(1570, 260)),
        CoinData(position: Vector2(1790, 340)),
        CoinData(position: Vector2(2010, 280)),
      ],
    );
  }
}
