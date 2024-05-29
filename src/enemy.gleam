import bullet.{type Bullet}
import dungeon.{type Dungeon}
import gleam/float
import gleam_community/maths/elementary
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import player.{type Player}
import vector.{type Vector}

/// The size of an enemy in pixels.
pub const enemy_size = 10.0

const max_enemy_health = 80

/// Represents a function that given world information and an enemy updates the enemy.
pub type BehaviorTree =
  fn(Enemy, Dungeon, Player, List(Bullet)) -> Enemy

/// Represents an enemy to defeat.
pub type Enemy {
  /// Represents an enemy to defeat.
  Enemy(
    /// The enemies current position in the dungeon.
    position: Vector,
    /// The heading the enemy is facing.
    rotation: Float,
    /// The enemies current velocity.
    velocity: Vector,
    /// Enemy's current remaining hit points.
    current_health: Int,
    /// Enemy's max hit points.
    max_health: Int,
    /// The behavior that an enemy will follow on each tick.
    btree: BehaviorTree,
  )
}

/// Makes a new enemy.
pub fn new_enemy(initial_position: Vector) -> Enemy {
  Enemy(
    position: initial_position,
    rotation: 0.0,
    velocity: vector.Vector(0.0, 0.0, 0.0),
    current_health: max_enemy_health,
    max_health: max_enemy_health,
    // TODO: actually make a behavior
    btree: fn(e, _, _, _) { e },
  )
}

/// Is the enemy currently dead.
pub fn is_enemy_dead(enemy: Enemy) -> Bool {
  enemy.current_health <= 0
}

const dead_fill_color = "#000000"

const enemy_fill_color = "#ff7b00"

const enemy_stroke_color = "#000000"

/// Renders the player to the screen.
pub fn draw(p: P5, enemy: Enemy) {
  case is_enemy_dead(enemy) {
    True -> p5.fill(p, dead_fill_color)
    False -> p5.fill(p, enemy_fill_color)
  }

  let assert Ok(size_to_draw) =
    float.power(enemy_size, 1.0 +. enemy.position.z /. 4.0)
  let size_to_draw = float.max(size_to_draw, enemy_size /. 2.0)

  p
  |> p5.stroke(enemy_stroke_color)
  |> p5.circle(enemy.position.x, enemy.position.y, size_to_draw)
  |> p5.line(
    enemy.position.x,
    enemy.position.y,
    enemy.position.x +. elementary.cos(enemy.rotation) *. size_to_draw /. 2.0,
    enemy.position.y +. elementary.sin(enemy.rotation) *. size_to_draw /. 2.0,
  )
}
