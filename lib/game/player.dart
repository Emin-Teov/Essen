import '../engine/math3d.dart';
import 'figures.dart';

/// Essen. [yaw]/[pitch] steer the third-person camera; [facing] is where the
/// character's body points.
class Player {
  static const double maxHp = 100;
  static const int maxShuriken = 15;
  static const int maxSmoke = 4;
  static const double radius = 0.38;

  final Vec3 pos = Vec3.zero();
  final Vec3 vel = Vec3.zero();
  final FigureAnim anim = FigureAnim();
  double yaw = 0, pitch = 0;
  double facing = 0;
  double hp = maxHp;
  int shuriken = 10;
  int smoke = 2;
  bool crouch = false;
  bool onGround = true;
  bool sprinting = false;
  int jumps = 0;
  double eye = 1.65; // head height, used for enemy line of sight
  double camDist = 4.3; // smoothed camera boom length

  // Combat timers.
  double attackT = -1; // seconds since the swing began; -1 when idle
  bool attackHitDone = false;
  int combo = 0;
  double attackCooldown = 0;
  double lungeT = 0;
  double throwT = -1;
  double hurtFlash = 0;
  double sinceHurt = 10;
  double hiddenT = 0; // smoke cover
  double shake = 0;
  double dustT = 0;
  double fallSpeed = 0; // peak downward speed while airborne

  bool get dead => hp <= 0;
  bool get attacking => attackT >= 0;

  void reset(double x, double y, double z, double yaw_) {
    pos.set(x, y, z);
    vel.set(0, 0, 0);
    yaw = yaw_;
    facing = yaw_;
    pitch = -0.22;
    hp = maxHp;
    attackT = -1;
    throwT = -1;
    hurtFlash = 0;
    hiddenT = 0;
    crouch = false;
  }
}
