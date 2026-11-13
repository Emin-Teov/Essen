import '../engine/mesh.dart';
import '../game/terrain.dart';
import '../l10n/l10n.dart';

/// Story structure: chapters, objectives, spawns and pickups.
/// All player-facing text lives in lib/l10n/story_*.dart, looked up by key.

enum EnemyKind { samurai, archer, rival, boss }

/// Speaker keys (display names come from the `spk.*` UI strings).
class Spk {
  static const essen = 'essen';
  static const soun = 'soun';
  static const tsuru = 'tsuru';
  static const hotaru = 'hotaru';
  static const rendo = 'rendo';
  static const masakage = 'masakage';
  static const hint = 'hint';
  static const unknown = 'unknown';
}

class DialogLine {
  final String speaker; // a [Spk] key
  final String text;
  final List<String>? choices;

  const DialogLine(this.speaker, this.text, {this.choices});
}

enum ObjType { reach, eliminate, collect, duel, defeat }

class SpawnDef {
  final EnemyKind kind;
  final String group;
  final double x, z;
  final double wander;
  final String? point; // overrides x/z with a named world point

  const SpawnDef(this.kind, this.group, this.x, this.z, {this.wander = 10, this.point});
}

class PickupDef {
  final String kind; // 'scroll', 'supply', 'health'
  final double x, z;
  final String? codex; // lore unlocked on pickup
  final String? dialogKey; // conversation shown on pickup
  final String? point; // overrides x/z with a named world point

  const PickupDef(this.kind, this.x, this.z, {this.codex, this.dialogKey, this.point});

  List<DialogLine> get dialog => dialogKey == null ? const [] : L10n.dialog(dialogKey!);
}

class NpcDef {
  final String id; // 'soun', 'tsuru', 'hotaru'
  final String point;
  final double yaw;

  const NpcDef(this.id, this.point, {this.yaw = 0});
}

class Objective {
  /// Text key, e.g. 'c1.o2'. Dialog keys derive from it:
  /// `<id>.before`, `<id>.after`, `<id>.mid` (boss at half health).
  final String id;
  final ObjType type;
  final String? point; // world point name (reach / duel)
  final double radius;
  final String? group; // enemy group (eliminate / duel / defeat)
  final String? pickupKind; // collect
  final int count;
  final List<SpawnDef> spawns;
  final List<PickupDef> pickups;
  final List<String> actions; // run on completion
  final List<String> unlock; // codex ids unlocked on completion

  const Objective(
    this.id,
    this.type, {
    this.point,
    this.radius = 6,
    this.group,
    this.pickupKind,
    this.count = 0,
    this.spawns = const [],
    this.pickups = const [],
    this.actions = const [],
    this.unlock = const [],
  });

  String get text => L10n.s(id);
  List<DialogLine> get before => L10n.dialog('$id.before');
  List<DialogLine> get after => L10n.dialog('$id.after');
  List<DialogLine> get midBoss => L10n.dialog('$id.mid');
}

class Chapter {
  final int number;
  final String kanji;
  final Lighting Function() lighting;
  final String startPoint;
  final double startYaw;
  final List<SpawnDef> spawns;
  final List<PickupDef> pickups;
  final List<NpcDef> npcs;
  final List<Objective> objectives;
  final bool petals;
  final bool embers;

  const Chapter({
    required this.number,
    required this.kanji,
    required this.lighting,
    required this.startPoint,
    required this.startYaw,
    required this.objectives,
    this.spawns = const [],
    this.pickups = const [],
    this.npcs = const [],
    this.petals = false,
    this.embers = false,
  });

  String get title => L10n.s('ch$number.title');
  List<String> get intro => L10n.paragraphs('ch$number.intro');
  List<String> get outro => L10n.paragraphs('ch$number.outro');
}

class CodexEntry {
  final String id;
  final String category; // Characters, Places, Lore

  const CodexEntry(this.id, this.category);

  String get title => L10n.s('codex.$id.title');
  String get text => L10n.s('codex.$id.text');
}

// --------------------------------------------------------------------------
// Coordinates

const _kx = Places.kasumiX, _kz = Places.kasumiZ;
const _cx = Places.campX, _cz = Places.campZ;
const _hx = Places.hanamuraX, _hz = Places.hanamuraZ;
const _qx = Places.castleX, _qz = Places.castleZ;

// --------------------------------------------------------------------------
// The story

class Story {
  static const String gameTitle = 'Essen';
  static String get tagline => L10n.s('tagline');

  static List<String> get endingMercy => L10n.paragraphs('ending.mercy');
  static List<String> get endingVengeance => L10n.paragraphs('ending.vengeance');

  static final List<Chapter> chapters = [
    Chapter(
      number: 1,
      kanji: '霞の灰',
      lighting: () => Lighting.moonlit,
      startPoint: 'start',
      startYaw: 2.4,
      embers: true,
      npcs: const [NpcDef('soun', 'soun', yaw: 0.6)],
      spawns: const [
        SpawnDef(EnemyKind.samurai, 'road', -150, 122, wander: 14),
        SpawnDef(EnemyKind.samurai, 'road', -118, 76, wander: 14),
      ],
      pickups: const [
        PickupDef('health', _kx + 6, _kz + 10),
        PickupDef('supply', _kx - 18, _kz - 4),
      ],
      objectives: const [
        Objective('c1.o1', ObjType.reach, point: 'kasumi', radius: 22),
        Objective(
          'c1.o2',
          ObjType.eliminate,
          group: 'looters',
          spawns: [
            SpawnDef(EnemyKind.samurai, 'looters', _kx + 10, _kz + 8, wander: 8),
            SpawnDef(EnemyKind.samurai, 'looters', _kx - 12, _kz + 6, wander: 8),
            SpawnDef(EnemyKind.samurai, 'looters', _kx + 4, _kz - 6, wander: 10),
            SpawnDef(EnemyKind.samurai, 'looters', _kx + 16, _kz - 4, wander: 6),
            SpawnDef(EnemyKind.archer, 'looters', _kx + 22, _kz - 16, wander: 3),
          ],
        ),
        Objective(
          'c1.o3',
          ObjType.reach,
          point: 'soun',
          radius: 4,
          unlock: ['soun', 'masakage', 'kasumi'],
          actions: ['npcPose:soun:dead'],
        ),
      ],
    ),
    Chapter(
      number: 2,
      kanji: '竹の囁き',
      lighting: () => Lighting.dawn,
      startPoint: 'kasumi',
      startYaw: 2.3,
      spawns: const [
        SpawnDef(EnemyKind.samurai, 'bamboo', _cx - 40, _cz + 30, wander: 20),
        SpawnDef(EnemyKind.samurai, 'bamboo', _cx + 45, _cz - 10, wander: 20),
        SpawnDef(EnemyKind.archer, 'bamboo', _cx + 10, _cz + 50, wander: 12),
        SpawnDef(EnemyKind.samurai, 'road', -118, 76, wander: 14),
      ],
      pickups: const [
        PickupDef('supply', _cx - 10.4, _cz + 9),
        PickupDef('health', _cx - 30, _cz + 50),
      ],
      objectives: const [
        Objective('c2.o1', ObjType.reach, point: 'camp', radius: 42),
        Objective(
          'c2.o2',
          ObjType.eliminate,
          group: 'camp',
          spawns: [
            SpawnDef(EnemyKind.samurai, 'camp', _cx - 4, _cz + 14, wander: 3),
            SpawnDef(EnemyKind.samurai, 'camp', _cx + 4, _cz + 14, wander: 3),
            SpawnDef(EnemyKind.samurai, 'camp', _cx - 6, _cz - 1, wander: 6),
            SpawnDef(EnemyKind.samurai, 'camp', _cx + 6, _cz + 4, wander: 5),
            SpawnDef(EnemyKind.archer, 'camp', _cx - 12, _cz - 8, wander: 2),
            SpawnDef(EnemyKind.archer, 'camp', _cx + 12, _cz - 8, wander: 2),
          ],
        ),
        Objective('c2.o3', ObjType.reach, point: 'orders', radius: 2.8, unlock: ['irondragon', 'rendo']),
      ],
    ),
    Chapter(
      number: 3,
      kanji: '鋼の花びら',
      lighting: () => Lighting.day,
      startPoint: 'bridgeNorth',
      startYaw: 1.6,
      petals: true,
      spawns: const [
        SpawnDef(EnemyKind.samurai, 'road', 118, 112, wander: 12),
        SpawnDef(EnemyKind.archer, 'road', 148, 80, wander: 8),
        SpawnDef(EnemyKind.samurai, 'road', 140, 92, wander: 12),
      ],
      npcs: const [NpcDef('tsuru', 'tsuru', yaw: 0)],
      pickups: const [
        PickupDef('health', _hx + 6, _hz + 4),
        PickupDef('supply', _hx + 24, _hz + 24),
      ],
      objectives: const [
        Objective(
          'c3.o1',
          ObjType.eliminate,
          group: 'tax',
          spawns: [
            SpawnDef(EnemyKind.samurai, 'tax', _hx + 14, _hz + 4, wander: 8),
            SpawnDef(EnemyKind.samurai, 'tax', _hx + 24, _hz - 4, wander: 8),
            SpawnDef(EnemyKind.samurai, 'tax', _hx + 20, _hz + 16, wander: 6),
            SpawnDef(EnemyKind.archer, 'tax', _hx + 40, _hz - 8, wander: 4),
          ],
        ),
        Objective('c3.o2', ObjType.reach, point: 'tsuru', radius: 4, unlock: ['tsuru', 'wreck']),
        Objective(
          'c3.o3',
          ObjType.collect,
          pickupKind: 'scroll',
          count: 3,
          pickups: [
            PickupDef('scroll', 112, 118, codex: 'note1', dialogKey: 'note1'),
            PickupDef('scroll', 152, 70, codex: 'note2', dialogKey: 'note2'),
            PickupDef('scroll', 0, 0, point: 'shrinePath', codex: 'note3', dialogKey: 'note3'),
          ],
        ),
        Objective(
          'c3.o4',
          ObjType.duel,
          point: 'duel',
          radius: 16,
          group: 'rival',
          spawns: [SpawnDef(EnemyKind.rival, 'rival', 0, 0, wander: 0, point: 'shrine')],
          unlock: ['rendo2'],
        ),
      ],
    ),
    Chapter(
      number: 4,
      kanji: '鉄竜の城',
      lighting: () => Lighting.sunset,
      startPoint: 'bridgeSouth',
      startYaw: 2.2,
      embers: true,
      spawns: const [
        SpawnDef(EnemyKind.samurai, 'road', 70, -124, wander: 14),
        SpawnDef(EnemyKind.archer, 'road', 100, -140, wander: 6),
        SpawnDef(EnemyKind.samurai, 'road', 130, -118, wander: 14),
      ],
      npcs: const [NpcDef('hotaru', 'cage', yaw: 3.14)],
      pickups: const [
        PickupDef('supply', _qx - 6, _qz + 60),
        PickupDef('health', _qx + 14, _qz + 58),
        PickupDef('health', _qx + 30, _qz + 22),
      ],
      objectives: const [
        Objective('c4.o1', ObjType.reach, point: 'castleGate', radius: 16),
        Objective(
          'c4.o2',
          ObjType.eliminate,
          group: 'gate',
          spawns: [
            SpawnDef(EnemyKind.samurai, 'gate', _qx - 5, _qz + 46, wander: 4),
            SpawnDef(EnemyKind.samurai, 'gate', _qx + 5, _qz + 46, wander: 4),
            SpawnDef(EnemyKind.samurai, 'gate', _qx - 8, _qz + 26, wander: 10),
            SpawnDef(EnemyKind.samurai, 'gate', _qx + 10, _qz + 20, wander: 10),
            SpawnDef(EnemyKind.archer, 'gate', _qx - 22, _qz + 30, wander: 3),
            SpawnDef(EnemyKind.archer, 'gate', _qx + 22, _qz + 30, wander: 3),
          ],
        ),
        Objective(
          'c4.o3',
          ObjType.reach,
          point: 'cage',
          radius: 3.5,
          unlock: ['hotaru'],
          actions: ['removeNpc:hotaru', 'heal'],
        ),
        Objective(
          'c4.o4',
          ObjType.defeat,
          group: 'boss',
          spawns: [
            SpawnDef(EnemyKind.boss, 'boss', _qx, _qz + 4, wander: 0),
            SpawnDef(EnemyKind.samurai, 'boss', _qx - 6, _qz + 6, wander: 4),
            SpawnDef(EnemyKind.samurai, 'boss', _qx + 6, _qz + 6, wander: 4),
          ],
          unlock: ['letter'],
        ),
      ],
    ),
  ];

  static const List<CodexEntry> codex = [
    CodexEntry('essen', 'Characters'),
    CodexEntry('kasumi', 'Places'),
    CodexEntry('soun', 'Characters'),
    CodexEntry('masakage', 'Characters'),
    CodexEntry('irondragon', 'Lore'),
    CodexEntry('rendo', 'Characters'),
    CodexEntry('rendo2', 'Lore'),
    CodexEntry('tsuru', 'Characters'),
    CodexEntry('wreck', 'Lore'),
    CodexEntry('note1', 'Lore'),
    CodexEntry('note2', 'Lore'),
    CodexEntry('note3', 'Lore'),
    CodexEntry('hotaru', 'Characters'),
    CodexEntry('letter', 'Lore'),
  ];

  static CodexEntry? codexById(String id) {
    for (final c in codex) {
      if (c.id == id) return c;
    }
    return null;
  }
}
