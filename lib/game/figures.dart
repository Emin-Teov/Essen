import 'dart:math' as math;

import '../engine/math3d.dart';
import '../engine/mesh.dart';
import 'props.dart';

enum Weapon { none, katana, bow }

enum Pose { stand, kneel, lying }

/// Body/outfit family, derived from a [FigureStyle].
enum FigureKind { samurai, ashigaru, shinobi, robed }

/// Level of detail for [drawFigure].
class Lod {
  static const high = 0; // close-up: articulated limbs, layered armor, faces
  static const mid = 1; // medium distance
  static const low = 2; // far away: a handful of boxes

  /// Distance thresholds (meters from the camera).
  static const highDistance = 12.0;
  static const lowDistance = 40.0;

  /// Most characters drawn in high detail at once (the player is extra).
  static const maxHigh = 4;
}

class FigureStyle {
  final int armor, under, skin;
  final int? helmet, hat, hair, crest, mask, scarf;
  final int? hood; // shinobi hood: covers the head except an eye band
  final int? lacing; // armor lacing (odoshi) color
  final bool robe;
  final Weapon weapon;
  final double scale;

  const FigureStyle({
    required this.armor,
    required this.under,
    this.skin = 0xFFD9A982,
    this.helmet,
    this.hat,
    this.hair,
    this.crest,
    this.mask,
    this.scarf,
    this.hood,
    this.lacing,
    this.robe = false,
    this.weapon = Weapon.katana,
    this.scale = 1,
  });

  FigureKind get kind => hood != null
      ? FigureKind.shinobi
      : helmet != null
          ? FigureKind.samurai
          : hat != null
              ? FigureKind.ashigaru
              : FigureKind.robed;

  static const essen = FigureStyle(
      armor: 0xFF1D2433, under: 0xFF141824, skin: 0xFFE2B794, hood: 0xFF10131C,
      scarf: 0xFFB3202C, robe: true);
  static const samurai = FigureStyle(
      armor: 0xFF8E1C1C, under: 0xFF2A2A30, helmet: 0xFF1E1E22, crest: Pal.gold,
      lacing: 0xFF26305A);
  static const archer = FigureStyle(
      armor: 0xFF6A3328, under: 0xFF3A3328, hat: 0xFF2B2B2B, weapon: Weapon.bow,
      lacing: 0xFF2A2420);
  static const rival = FigureStyle(
      armor: 0xFF1F3A66, under: 0xFF1C1F2A, helmet: 0xFF121520, crest: 0xFFC9CED6, scale: 1.08,
      lacing: 0xFFD8DCE2);
  static const boss = FigureStyle(
      armor: 0xFF17171B, under: 0xFF5A1010, helmet: 0xFF0E0E10, crest: Pal.gold,
      mask: 0xFFA01818, scale: 1.25, lacing: 0xFFB0802A);
  static const soun = FigureStyle(
      armor: 0xFF5E6266, under: 0xFF45484C, hair: 0xFFDCDCDC, robe: true, weapon: Weapon.none);
  static const tsuru = FigureStyle(
      armor: 0xFF6B4E3A, under: 0xFF4F3A2C, hair: 0xFF9A9A9A, robe: true, weapon: Weapon.none,
      scale: 0.86);
  static const hotaru = FigureStyle(
      armor: 0xFF1E2438, under: 0xFF161A28, hair: 0xFF141414, scarf: 0xFFB02030,
      robe: true, weapon: Weapon.none, scale: 0.94);
}

/// Animation inputs for a figure.
class FigureAnim {
  double walkPhase = 0;
  double walkAmount = 0; // 0..1+
  double armRaise = 0.25; // right arm angle (radians, + = forward/up)
  double leftArm = 0.2;
  double fall = 0; // 0..1 lying on the back
  double bowDraw = 0; // 0..1
  double hunch = 0; // forward lean
  double crouch = 0; // 0..1 knees bent, body lowered
  double air = 0; // 0..1 legs tucked while airborne
  double twist = 0; // torso rotation (radians) for horizontal slashes
  double scarfWave = 0; // phase for the trailing scarf
  double scarfLift = 0; // 0..1 how far the scarf streams back
  Pose pose = Pose.stand;
}

/// Picks a level of detail from the camera distance.
int lodForDistance(double d) =>
    d < Lod.highDistance ? Lod.high : (d < Lod.lowDistance ? Lod.mid : Lod.low);

/// Builds a character. Models face local −Z, right hand at +X, feet at y = 0.
void drawFigure(MeshBuilder b, double x, double y, double z, double yaw,
    FigureStyle st, FigureAnim an, {int lod = Lod.mid}) {
  b.reset();
  b.translate(x, y, z);
  b.rotateY(-yaw);
  b.scale(st.scale, st.scale, st.scale);
  if (an.pose == Pose.lying || an.fall > 0) {
    final f = an.pose == Pose.lying ? 1.0 : an.fall;
    b.translate(0, 0.12 * f, 0);
    b.rotateX(f * math.pi / 2);
  }
  final kneel = an.pose == Pose.kneel;
  if (kneel) b.translate(0, -0.5, 0);
  if (an.crouch > 0) b.translate(0, -0.38 * an.crouch, 0);
  switch (lod) {
    case Lod.high:
      _high(b, st, an, kneel);
    case Lod.mid:
      _mid(b, st, an, kneel);
    default:
      _low(b, st, an, kneel);
  }
}

// =========================================================== low detail

void _low(MeshBuilder b, FigureStyle st, FigureAnim an, bool kneel) {
  final swing = math.sin(an.walkPhase) * 0.5 * math.min(1.0, an.walkAmount);
  for (final side in [-1.0, 1.0]) {
    b.push();
    b.translate(side * 0.13, 0.92, 0);
    b.rotateX(kneel ? 1.45 : swing * side + an.crouch * 0.85);
    b.box(0, -0.92, 0, 0.22, 0.92, 0.26, st.under, bottom: false);
    b.pop();
  }
  b.push();
  b.translate(0, 0.9, 0);
  if (an.twist != 0) b.rotateY(an.twist);
  b.box(0, -0.25, 0, 0.52, 0.72, 0.3, st.armor);
  b.box(0, 0.5, 0, 0.24, 0.27, 0.25, st.hood ?? st.skin, bottom: false);
  final top = st.helmet ?? st.hat ?? st.hair;
  if (top != null) b.box(0, 0.74, 0, 0.3, 0.1, 0.3, top);
  for (final side in [-1.0, 1.0]) {
    b.push();
    b.translate(side * 0.32, 0.42, 0);
    b.rotateX(side > 0 ? an.armRaise : an.leftArm);
    b.box(0, -0.62, 0, 0.13, 0.62, 0.14, st.robe ? st.armor : st.under, bottom: false);
    if (side > 0 && st.weapon == Weapon.katana) b.box(0, -0.64, -0.6, 0.03, 0.05, 1.1, 0xFFCDD3DA);
    b.pop();
  }
  b.pop();
}

// =========================================================== medium detail

void _mid(MeshBuilder b, FigureStyle st, FigureAnim an, bool kneel) {
  final swing = math.sin(an.walkPhase) * 0.55 * math.min(1.2, an.walkAmount);
  for (final side in [-1.0, 1.0]) {
    b.push();
    b.translate(side * 0.13, 0.92, 0);
    final tuck = an.air * (side > 0 ? 0.9 : 0.2);
    b.rotateX(kneel ? 1.45 : swing * side + an.crouch * 0.85 + tuck);
    b.box(0, -0.92, 0, 0.2, 0.92, 0.25, st.under);
    b.box(0, -0.92, -0.04, 0.21, 0.1, 0.32, 0xFF202020);
    b.pop();
  }

  b.push();
  b.translate(0, 0.9, 0);
  final lean = an.hunch + an.crouch * 0.35 + math.min(1.0, an.walkAmount) * 0.08;
  if (lean != 0) b.rotateX(-lean);
  if (an.twist != 0) b.rotateY(an.twist);
  if (st.robe) {
    b.frustum(0, -0.55, 0, 0.62, 0.44, 0.46, 0.3, 0.6, st.armor);
    b.box(0, 0.05, 0, 0.46, 0.55, 0.28, st.armor);
    b.box(0, 0.2, 0, 0.48, 0.09, 0.3, st.under);
  } else {
    b.frustum(0, -0.3, 0, 0.66, 0.44, 0.5, 0.32, 0.36, scaleColor(st.armor, 0.8));
    b.box(0, 0.02, 0, 0.5, 0.58, 0.3, st.armor, topColor: scaleColor(st.armor, 1.1));
    b.box(0, 0.12, -0.155, 0.4, 0.05, 0.02, Pal.gold);
    for (final side in [-1.0, 1.0]) {
      b.box(side * 0.34, 0.38, 0, 0.2, 0.26, 0.34, scaleColor(st.armor, 0.9));
    }
  }
  if (st.scarf != null) _scarf(b, st.scarf!, an, 4);
  if (st.hood != null) {
    b.box(0, 0.58, 0, 0.24, 0.28, 0.26, st.hood!);
    b.box(0, 0.7, -0.125, 0.2, 0.06, 0.02, st.skin);
    b.box(-0.05, 0.715, -0.137, 0.035, 0.02, 0.01, 0xFF1A2A3A);
    b.box(0.05, 0.715, -0.137, 0.035, 0.02, 0.01, 0xFF1A2A3A);
  } else {
    b.box(0, 0.58, 0, 0.22, 0.26, 0.24, st.skin);
  }
  if (st.mask != null) b.box(0, 0.58, -0.11, 0.2, 0.12, 0.05, st.mask!);
  if (st.helmet != null) {
    b.frustum(0, 0.78, 0, 0.36, 0.38, 0.2, 0.22, 0.16, st.helmet!);
    b.frustum(0, 0.62, 0.02, 0.46, 0.44, 0.34, 0.34, 0.16, st.helmet!);
    if (st.crest != null) _crest(b, st, 0.9);
  } else if (st.hat != null) {
    b.cylinder(0, 0.8, 0, 0.42, 0, 0.18, 7, st.hat!);
  } else if (st.hair != null) {
    b.box(0, 0.78, 0.02, 0.24, 0.08, 0.26, st.hair!);
    b.box(0, 0.62, 0.11, 0.24, 0.2, 0.06, st.hair!);
    b.box(0, 0.8, 0.12, 0.09, 0.1, 0.1, st.hair!);
  }

  b.push();
  b.translate(0.31, 0.42, 0);
  b.rotateX(an.armRaise);
  b.box(0, -0.58, 0, 0.13, 0.58, 0.14, st.robe ? st.armor : st.under);
  b.box(0, -0.62, 0, 0.11, 0.08, 0.11, st.hood != null ? st.hood! : st.skin);
  if (st.weapon == Weapon.katana) {
    b.box(0, -0.63, -0.12, 0.05, 0.05, 0.26, 0xFF201810);
    b.box(0, -0.63, -0.27, 0.12, 0.03, 0.06, Pal.gold);
    b.box(0, -0.63, -0.82, 0.025, 0.06, 1.05, 0xFFCDD3DA);
  }
  b.pop();

  b.push();
  b.translate(-0.31, 0.42, 0);
  final la = st.weapon == Weapon.bow ? 0.4 + an.bowDraw * 1.15 : an.leftArm;
  b.rotateX(la);
  b.box(0, -0.58, 0, 0.13, 0.58, 0.14, st.robe ? st.armor : st.under);
  if (st.weapon == Weapon.bow) {
    b.box(0, -1.25, 0, 0.04, 1.4, 0.04, 0xFF3A2614);
    if (an.bowDraw > 0.3) b.box(0, -0.62, 0.15, 0.02, 0.02, 0.6, 0xFFE8E0D0);
  }
  b.pop();
  if (st.weapon == Weapon.katana) {
    b.push();
    if (st.hood != null) {
      b.translate(0, 0.25, 0.17);
      b.rotateZ(0.8);
      b.box(0, -0.45, 0, 0.05, 0.9, 0.05, 0xFF141414);
    } else if (an.armRaise < 0.6) {
      b.translate(-0.28, -0.12, 0);
      b.rotateX(0.5);
      b.box(0, 0, 0, 0.05, 0.05, 0.9, 0xFF141414);
    }
    b.pop();
  }
  b.pop();
}

// =========================================================== high detail

const _dark = 0xFF16141A;
const _straw = 0xFFB59A62;
const _leather = 0xFF4A3424;
const _steel = 0xFFD6DCE2;
const _white = 0xFFE8E2D4;

void _high(MeshBuilder b, FigureStyle st, FigureAnim an, bool kneel) {
  final kind = st.kind;
  final lace = st.lacing ?? scaleColor(st.armor, 0.6);
  final armorDark = scaleColor(st.armor, 0.75);
  final shinobi = kind == FigureKind.shinobi;

  // ---------------------------------------------------------------- legs
  final walk = math.min(1.2, an.walkAmount);
  final swing = math.sin(an.walkPhase) * 0.55 * walk;
  for (final side in [-1.0, 1.0]) {
    final s = swing * side;
    final thigh = kneel ? 1.45 : s + an.crouch * 1.05 + an.air * (side > 0 ? 1.1 : 0.4);
    final knee = kneel
        ? -1.5
        : -(math.max(0.0, -s) * 1.3 + 0.08 * walk) - an.crouch * 1.5 - an.air * (side > 0 ? 1.4 : 0.6);
    b.push();
    b.translate(side * 0.12, 0.92, 0);
    b.rotateX(thigh);
    final baggy = kind != FigureKind.shinobi;
    b.box(0, -0.47, 0, baggy ? 0.24 : 0.17, 0.47, baggy ? 0.27 : 0.19, st.under);
    if (kind == FigureKind.samurai) {
      // Haidate: laced thigh armor.
      b.box(0, -0.42, -0.14, 0.22, 0.32, 0.03, armorDark);
      for (var k = 0; k < 3; k++) {
        _stripe(b, 0, -0.38 + k * 0.1, -0.158, 0.22, 0.022, lace);
      }
    }
    b.translate(0, -0.47, 0);
    b.rotateX(knee);
    b.box(0, -0.41, 0.01, 0.15, 0.41, 0.17, st.under);
    switch (kind) {
      case FigureKind.samurai:
        // Suneate shin guard with gilt edge.
        b.box(0, -0.37, -0.085, 0.15, 0.31, 0.03, armorDark);
        _stripe(b, 0, -0.07, -0.101, 0.15, 0.02, Pal.gold);
      case FigureKind.shinobi:
      case FigureKind.ashigaru:
        // Kyahan leg wraps.
        for (var k = 0; k < 3; k++) {
          b.box(0, -0.37 + k * 0.11, 0.01, 0.162, 0.035, 0.182, scaleColor(st.under, 1.45));
        }
      case FigureKind.robed:
        break;
    }
    // Feet: split-toe tabi for shinobi, straw sandals otherwise.
    final foot = shinobi ? scaleColor(st.under, 0.85) : _white;
    b.box(0, -0.47, -0.05, 0.14, 0.07, 0.28, foot);
    if (shinobi) {
      b.box(0.035, -0.47, -0.205, 0.06, 0.055, 0.05, foot);
      b.box(-0.025, -0.47, -0.2, 0.07, 0.05, 0.04, foot);
    } else {
      b.box(0, -0.485, -0.05, 0.16, 0.018, 0.31, _straw);
      b.box(0, -0.45, -0.17, 0.02, 0.03, 0.06, _dark); // thong
    }
    b.pop();
  }

  // ---------------------------------------------------------------- torso
  b.push();
  b.translate(0, 0.9, 0);
  final lean = an.hunch + an.crouch * 0.35 + math.min(1.0, an.walkAmount) * 0.08;
  if (lean != 0) b.rotateX(-lean);
  if (an.twist != 0) b.rotateY(an.twist);

  switch (kind) {
    case FigureKind.samurai:
      // Hakama and five hanging kusazuri plates with lacing.
      b.frustum(0, -0.42, 0, 0.6, 0.42, 0.48, 0.32, 0.4, st.under, bottom: false);
      for (final a in [0.0, 0.8, -0.8, 1.6, -1.6, math.pi]) {
        b.push();
        b.rotateY(a);
        b.translate(0, -0.02, -0.19);
        b.rotateX(-0.14);
        b.box(0, -0.32, 0, 0.2, 0.3, 0.035, st.armor);
        for (var k = 0; k < 3; k++) {
          _stripe(b, 0, -0.3 + k * 0.1, -0.019, 0.2, 0.022, lace);
        }
        b.pop();
      }
    case FigureKind.ashigaru:
      b.frustum(0, -0.42, 0, 0.58, 0.42, 0.46, 0.3, 0.4, st.under, bottom: false);
      for (final a in [0.0, 1.2, -1.2]) {
        b.push();
        b.rotateY(a);
        b.translate(0, -0.02, -0.18);
        b.rotateX(-0.12);
        b.box(0, -0.26, 0, 0.18, 0.24, 0.03, armorDark);
        b.pop();
      }
    case FigureKind.shinobi:
      // Short jacket hem.
      b.frustum(0, -0.22, 0, 0.46, 0.3, 0.42, 0.27, 0.24, st.armor, bottom: false);
    case FigureKind.robed:
      // Ankle-length kimono.
      b.frustum(0, -0.85, 0, 0.56, 0.42, 0.44, 0.29, 0.87, st.armor, bottom: false);
  }

  // Abdomen and chest.
  b.box(0, -0.06, 0, 0.4, 0.23, 0.25, kind == FigureKind.samurai ? st.under : st.armor);
  b.frustum(0, 0.15, 0, 0.42, 0.25, 0.5, 0.29, 0.3, st.armor, topColor: scaleColor(st.armor, 1.08));
  switch (kind) {
    case FigureKind.samurai:
      // Laced dō plates front and back, gilt clan crest.
      for (var k = 0; k < 4; k++) {
        final w = 0.42 + k * 0.016;
        _stripe(b, 0, k * 0.1, -0.142 - k * 0.006, w, 0.024, lace);
        _stripe(b, 0, k * 0.1, 0.142 + k * 0.006, w, 0.024, lace);
      }
      b.push();
      b.translate(0, 0.33, -0.155);
      b.rotateX(-math.pi / 2);
      b.cylinder(0, 0, 0, 0.055, 0.055, 0.012, 8, Pal.gold);
      b.pop();
      // Sode shoulder guards (three laced lames).
      for (final side in [-1.0, 1.0]) {
        b.push();
        b.translate(side * 0.33, 0.45, 0);
        b.rotateZ(side * 0.32);
        b.box(side * 0.04, -0.3, 0, 0.045, 0.3, 0.3, st.armor);
        for (var k = 0; k < 3; k++) {
          _stripeSide(b, side * 0.064, -0.27 + k * 0.09, 0, 0.3, 0.02, lace);
        }
        b.pop();
      }
    case FigureKind.ashigaru:
      // Okegawa breastplate with a painted mon.
      b.box(0, 0.02, -0.13, 0.4, 0.36, 0.02, armorDark);
      b.push();
      b.translate(0, 0.26, -0.143);
      b.rotateX(-math.pi / 2);
      b.cylinder(0, 0, 0, 0.05, 0.05, 0.01, 6, _white);
      b.pop();
      for (final side in [-1.0, 1.0]) {
        b.box(side * 0.31, 0.38, 0, 0.14, 0.1, 0.28, armorDark);
      }
    case FigureKind.shinobi:
      // Crossed jacket lapels.
      for (final side in [-1.0, 1.0]) {
        b.push();
        b.translate(side * 0.06, 0.28, -0.142);
        b.rotateZ(side * 0.5);
        b.box(0, -0.16, 0, 0.05, 0.32, 0.012, scaleColor(st.armor, 1.4));
        b.pop();
      }
    case FigureKind.robed:
      for (final side in [-1.0, 1.0]) {
        b.push();
        b.translate(side * 0.05, 0.3, -0.142);
        b.rotateZ(side * 0.45);
        b.box(0, -0.18, 0, 0.06, 0.34, 0.012, st.under);
        b.pop();
      }
  }

  // Obi sash, knot and belt gear.
  final sash = kind == FigureKind.samurai ? lace : (shinobi ? 0xFF2A2E3A : st.under);
  b.box(0, -0.1, 0, 0.44, 0.09, 0.28, sash);
  if (shinobi || kind == FigureKind.robed) {
    b.box(0, -0.12, 0.15, 0.12, 0.12, 0.06, scaleColor(sash, 1.1));
    final sway = math.sin(an.scarfWave * 4) * 0.04;
    b.quad2(-0.03, -0.1, 0.17, 0.02, -0.1, 0.17, 0.05 + sway, -0.34, 0.2, -0.01 + sway, -0.34, 0.2,
        scaleColor(sash, 0.95));
  }
  if (shinobi) {
    b.box(-0.22, -0.16, -0.04, 0.08, 0.1, 0.07, _leather); // shuriken pouch
    b.box(0.2, -0.15, 0.05, 0.06, 0.08, 0.06, _leather);
  }
  if (st.scarf != null) _scarf(b, st.scarf!, an, 6);

  // Neck and head.
  b.box(0, 0.45, 0, 0.11, 0.08, 0.11, st.hood ?? st.skin);
  _head(b, st, an, kind, lace);

  // Arms.
  _arm(b, st, kind, 1, an.armRaise, an.armRaise > 1.4 ? 0.15 : 0.32, lace, armorDark);
  final la = st.weapon == Weapon.bow ? 0.4 + an.bowDraw * 1.15 : an.leftArm;
  _arm(b, st, kind, -1, la, st.weapon == Weapon.bow ? 0.05 : 0.28, lace, armorDark,
      bowDraw: an.bowDraw);

  // Sheathed blades and back gear.
  if (st.weapon == Weapon.katana) {
    if (shinobi) {
      // Ninjatō scabbard across the back with its sageo cord.
      b.push();
      b.translate(0, 0.25, 0.17);
      b.rotateZ(0.8);
      b.box(0, -0.5, 0, 0.055, 0.95, 0.045, 0xFF141414);
      b.box(0, 0.45, 0, 0.06, 0.04, 0.05, 0xFF6A1A1A);
      b.pop();
    } else {
      // Daishō: katana and wakizashi scabbards through the obi.
      for (final (dz, len) in [(-0.02, 0.85), (0.04, 0.55)]) {
        b.push();
        b.translate(-0.24, -0.1, dz);
        b.rotateY(0.12);
        b.rotateX(0.38);
        b.box(0, -0.025, 0.05, 0.045, 0.05, len, 0xFF141414);
        b.box(0, -0.03, -len / 2 + 0.05, 0.05, 0.06, 0.03, Pal.gold);
        b.pop();
      }
    }
  }
  if (st.weapon == Weapon.bow) {
    // Quiver with fletched arrows on the back.
    b.push();
    b.translate(0.12, 0.05, 0.17);
    b.rotateZ(-0.35);
    b.cylinder(0, 0, 0, 0.065, 0.075, 0.55, 6, _leather);
    for (var k = 0; k < 3; k++) {
      final ox = (k - 1) * 0.03;
      b.box(ox, 0.55, 0, 0.012, 0.16, 0.012, 0xFF6B4A2E);
      b.quad2(ox, 0.62, -0.03, ox, 0.62, 0.03, ox, 0.72, 0.02, ox, 0.72, -0.02, _white);
    }
    b.pop();
  }
  b.pop();
}

void _head(MeshBuilder b, FigureStyle st, FigureAnim an, FigureKind kind, int lace) {
  const eye = 0xFF1A2A3A;
  if (kind == FigureKind.shinobi) {
    final hood = st.hood!;
    b.box(0, 0.5, 0.005, 0.25, 0.3, 0.27, hood);
    // Eye band, eyes and the lower-face mask.
    b.box(0, 0.635, -0.13, 0.19, 0.06, 0.012, st.skin);
    for (final side in [-1.0, 1.0]) {
      _stripe(b, side * 0.048, 0.65, -0.137, 0.04, 0.02, eye);
      _stripe(b, side * 0.05, 0.676, -0.137, 0.05, 0.01, hood); // brow
    }
    b.box(0, 0.5, -0.14, 0.21, 0.13, 0.012, scaleColor(hood, 1.25));
    // Hood knot tails at the back.
    final sway = math.sin(an.scarfWave * 5) * 0.05;
    b.quad2(-0.03, 0.72, 0.13, 0.03, 0.72, 0.13, 0.04 + sway, 0.55, 0.26, -0.02 + sway, 0.55, 0.26, hood);
    return;
  }
  // Face.
  b.box(0, 0.52, 0, 0.21, 0.25, 0.23, st.skin);
  b.box(0, 0.58, -0.125, 0.035, 0.05, 0.03, scaleColor(st.skin, 0.9)); // nose
  for (final side in [-1.0, 1.0]) {
    _stripe(b, side * 0.05, 0.64, -0.117, 0.04, 0.018, eye);
    _stripe(b, side * 0.05, 0.668, -0.118, 0.05, 0.012, st.hair ?? 0xFF201814);
    b.box(side * 0.11, 0.58, 0, 0.02, 0.06, 0.05, scaleColor(st.skin, 0.92)); // ears
  }
  _stripe(b, 0, 0.55, -0.117, 0.06, 0.01, scaleColor(st.skin, 0.7)); // mouth

  if (st.mask != null) {
    // Menpō war mask with a white moustache.
    b.box(0, 0.5, -0.125, 0.2, 0.11, 0.04, st.mask!);
    _stripe(b, 0, 0.565, -0.148, 0.12, 0.015, _white);
  }
  if (st.helmet != null) {
    final h = st.helmet!;
    // Kabuto bowl, rim knob, visor.
    b.frustum(0, 0.72, 0.01, 0.3, 0.32, 0.22, 0.24, 0.09, h);
    b.frustum(0, 0.81, 0.01, 0.22, 0.24, 0.1, 0.11, 0.06, h);
    b.box(0, 0.87, 0.01, 0.04, 0.025, 0.04, Pal.gold);
    b.push();
    b.translate(0, 0.725, -0.15);
    b.rotateX(0.3);
    b.box(0, 0, 0, 0.3, 0.025, 0.08, h);
    b.pop();
    // Shikoro neck guard: laced lames at the back and sides.
    for (var k = 0; k < 3; k++) {
      final y = 0.66 - k * 0.07;
      final c = k.isEven ? h : lace;
      b.box(0, y, 0.15 + k * 0.012, 0.36 + k * 0.05, 0.065, 0.06, c);
      for (final side in [-1.0, 1.0]) {
        b.box(side * (0.17 + k * 0.025), y, 0.04, 0.05, 0.065, 0.24, c);
      }
    }
    // Fukigaeshi turnbacks with gilt edges.
    for (final side in [-1.0, 1.0]) {
      b.push();
      b.translate(side * 0.19, 0.68, -0.08);
      b.rotateY(side * 0.5);
      b.box(0, 0, 0, 0.035, 0.1, 0.11, h);
      b.box(0, 0.1, 0, 0.04, 0.012, 0.115, Pal.gold);
      b.pop();
    }
    if (st.crest != null) _crest(b, st, 0.8);
  } else if (st.hat != null) {
    // Jingasa: lacquered cone, rim and chin cords.
    b.cylinder(0, 0.75, 0, 0.45, 0.45, 0.025, 8, scaleColor(st.hat!, 0.8));
    b.cylinder(0, 0.775, 0, 0.44, 0, 0.16, 8, st.hat!);
    b.cylinder(0, 0.85, 0, 0.06, 0.06, 0.01, 6, Pal.gold);
    for (final side in [-1.0, 1.0]) {
      b.box(side * 0.1, 0.45, -0.02, 0.012, 0.3, 0.012, _white);
    }
  } else if (st.hair != null) {
    final hr = st.hair!;
    b.box(0, 0.72, 0.02, 0.23, 0.07, 0.25, hr);
    b.box(0, 0.54, 0.105, 0.23, 0.22, 0.05, hr);
    if (st.scale < 0.9) {
      b.ico(0, 0.8, 0.07, 0.07, 0.06, 0.07, hr); // bun
    } else if (st.scarf != null) {
      // High ponytail.
      final sway = math.sin(an.scarfWave * 3) * 0.04;
      b.box(0, 0.76, 0.1, 0.06, 0.06, 0.06, hr);
      b.quad2(-0.03, 0.78, 0.12, 0.03, 0.78, 0.12, 0.03 + sway, 0.45, 0.24, -0.03 + sway, 0.45, 0.24, hr);
    } else {
      b.box(0, 0.79, 0.04, 0.05, 0.06, 0.14, hr); // chonmage topknot
    }
  }
}

/// Maedate crest: a gilt V, or crescent horns on a large (boss) helmet.
void _crest(MeshBuilder b, FigureStyle st, double y) {
  final big = st.scale > 1.2;
  for (final side in [-1.0, 1.0]) {
    b.push();
    b.translate(side * 0.05, y, -0.14);
    b.rotateZ(-side * 0.55);
    b.box(0, 0, 0, 0.04, big ? 0.3 : 0.32, 0.03, st.crest!);
    if (big) {
      b.translate(0, 0.28, 0);
      b.rotateZ(side * 0.7);
      b.box(0, 0, 0, 0.035, 0.24, 0.03, st.crest!);
    }
    b.pop();
  }
}

/// Articulated arm (shoulder → elbow → hand) with its held weapon.
void _arm(MeshBuilder b, FigureStyle st, FigureKind kind, double side, double angle, double elbow,
    int lace, int armorDark, {double bowDraw = 0}) {
  b.push();
  b.translate(side * 0.31, 0.42, 0);
  b.rotateX(angle);
  final sleeve = kind == FigureKind.samurai ? st.under : st.armor;
  if (kind == FigureKind.robed) {
    // Wide kimono sleeve.
    b.frustum(0, -0.33, 0, 0.24, 0.24, 0.14, 0.15, 0.33, sleeve);
  } else {
    b.box(0, -0.3, 0, 0.12, 0.3, 0.13, sleeve);
  }
  if (kind == FigureKind.samurai) b.box(0, -0.28, -0.066, 0.1, 0.22, 0.015, armorDark);
  b.translate(0, -0.3, 0);
  b.rotateX(elbow);
  b.box(0, -0.27, 0, 0.105, 0.27, 0.115, kind == FigureKind.robed ? st.skin : sleeve);
  switch (kind) {
    case FigureKind.samurai:
      // Kote armored sleeve.
      b.box(0, -0.25, -0.06, 0.1, 0.2, 0.012, armorDark);
      _stripe(b, 0, -0.12, -0.069, 0.1, 0.018, lace);
    case FigureKind.shinobi:
      // Tekkō hand guard.
      b.box(0, -0.25, 0, 0.118, 0.16, 0.128, scaleColor(st.armor, 1.3));
    default:
      break;
  }
  final hand = kind == FigureKind.shinobi ? st.hood! : st.skin;
  b.box(0, -0.335, 0, 0.095, 0.07, 0.1, hand);
  b.translate(0, -0.31, 0);
  if (side > 0 && st.weapon == Weapon.katana) _blade(b, kind == FigureKind.shinobi);
  if (side < 0 && st.weapon == Weapon.bow) _bow(b, bowDraw);
  b.pop();
}

/// Sword held in the current hand frame; the blade points along local −Z.
void _blade(MeshBuilder b, bool ninjato) {
  b.push();
  b.rotateX(-math.pi / 2); // local +Y now runs along the blade
  // Tsuka (grip) with diamond wrap, kashira cap.
  b.box(0, -0.12, 0, 0.045, 0.27, 0.05, 0xFF201810);
  for (var k = 0; k < 4; k++) {
    _stripe(b, 0, -0.09 + k * 0.055, -0.027, 0.03, 0.02, ninjato ? 0xFF3A3A44 : 0xFF6A1A1A);
  }
  b.box(0, -0.135, 0, 0.05, 0.02, 0.055, Pal.gold);
  // Tsuba guard and habaki collar.
  if (ninjato) {
    b.box(0, 0.15, 0, 0.11, 0.02, 0.11, _dark);
  } else {
    b.cylinder(0, 0.15, 0, 0.065, 0.065, 0.02, 8, _dark);
  }
  b.box(0, 0.17, 0, 0.03, 0.035, 0.06, Pal.gold);
  // Blade: two segments with a gentle curve (sori), then the tapered tip.
  b.box(0, 0.2, 0, 0.018, 0.55, 0.055, _steel);
  _stripe(b, 0, 0.2, -0.0285, 0.019, 0.55, 0xFFFFFFFF); // polished edge
  b.translate(0, 0.75, 0);
  b.rotateX(ninjato ? 0 : 0.07);
  b.box(0, 0, 0, 0.018, 0.3, 0.052, _steel);
  b.frustum(0, 0.3, 0, 0.018, 0.052, 0.004, 0.006, 0.1, _steel);
  b.pop();
}

/// Yumi longbow held in the left hand; the string pulls toward the shoulder.
void _bow(MeshBuilder b, double draw) {
  const wood = 0xFF3A2614;
  // Asymmetric limbs: the upper limb is longer, as on a real yumi.
  // Local −Z is up along the bow, +Y points back toward the archer.
  for (final (dir, len) in [(1.0, 0.95), (-1.0, 0.6)]) {
    final seg = len / 3;
    for (var k = 0; k < 3; k++) {
      // Each segment bends a little further forward (−Y) toward the tip.
      b.box(0, -0.02 - 0.02 * k * k, -dir * (seg * k + seg / 2), 0.035, 0.04, seg, wood);
    }
  }
  b.box(0, -0.025, 0, 0.045, 0.05, 0.12, 0xFFE8DCC0); // grip wrap
  // String from tip to tip, pulled back toward the shoulder by [draw].
  final pull = 0.05 + draw * 0.55;
  const t = 0.004;
  b.quad2(-t, -0.1, -0.95, t, -0.1, -0.95, t, pull, 0, -t, pull, 0, _white);
  b.quad2(-t, pull, 0, t, pull, 0, t, -0.1, 0.6, -t, -0.1, 0.6, _white);
  if (draw > 0.3) {
    b.box(0, pull - 0.85, 0, 0.015, 0.85, 0.015, 0xFF6B4A2E); // nocked arrow, pointing forward
  }
}

/// Scarf tails streaming back from the neck.
void _scarf(MeshBuilder b, int sc, FigureAnim an, int segments) {
  b.box(0, 0.5, 0, 0.36, 0.12, 0.32, sc);
  final lift = 0.15 + an.scarfLift * 0.85;
  var px = 0.06, py = 0.55, pz = 0.16;
  final step = 4 / segments;
  for (var i = 0; i < segments; i++) {
    final w = math.sin(an.scarfWave * 6 - i * 1.1 * step) * 0.08 * (i + 1) * step;
    final nx = px + w;
    final ny = py - (0.16 * (1 - lift) + 0.03) * step;
    final nz = pz + (0.18 * lift + 0.04) * step;
    final c = scaleColor(sc, 1 - i * 0.07 * step);
    b.quad2(px - 0.07, py, pz, px + 0.07, py, pz, nx + 0.07, ny, nz, nx - 0.07, ny, nz, c);
    px = nx;
    py = ny;
    pz = nz;
  }
}

/// Flat detail strip (lacing, eyes, trim) in the XY plane at depth [z]:
/// two triangles instead of a 12-triangle box.
void _stripe(MeshBuilder b, double x, double y, double z, double w, double h, int c) =>
    b.quad2(x - w / 2, y, z, x + w / 2, y, z, x + w / 2, y + h, z, x - w / 2, y + h, z, c);

/// Flat detail strip in the YZ plane at [x] (side-facing trim).
void _stripeSide(MeshBuilder b, double x, double y, double z, double d, double h, int c) =>
    b.quad2(x, y, z - d / 2, x, y, z + d / 2, x, y + h, z + d / 2, x, y + h, z - d / 2, c);
