import behavior_tree/behavior_tree
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

/// The amount of damage an enemy does.
pub const damage = 5

/// The score reward for killing an enemy.
pub const value = 100

const max_enemy_health = 80

/// Represents the input data needed for an enemy to update.
pub type Inputs {
  /// Represents the input data needed for an enemy to update.
  Inputs(
    /// All enemies in the game.
    enemies: List(Enemy),
    /// The dungeon the enemy is in.
    dungeon: Dungeon,
    /// The player character.
    player: Player,
  )
}

/// Represents the additional outputs from updating an enemy..
pub type AdditionalOutputs {
  /// Represents the additional outputs from updating an enemy.
  AdditionalOutputs(
    /// Any bullets that were fired by the enemy.
    bullets: List(Bullet),
  )
}

/// Represents a function that given world information and an enemy updates the enemy.
pub type BehaviorTree =
  behavior_tree.BehaviorTree(Enemy, Inputs, AdditionalOutputs)

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
    btree: fn(i) {
      let behavior_tree.BehaviorInput(e, _) = i
      behavior_tree.BehaviorResult(True, e, AdditionalOutputs(bullets: []))
    },
  )
}

const enemy_gravity_strength = 0.02

/// Applies gravity to the velocity and resets z position to floor when appropriate.
pub fn apply_gravity(enemy: Enemy) -> Enemy {
  let position = case enemy.position.z {
    z if z <. 0.0 -> vector.Vector(enemy.position.x, enemy.position.y, 0.0)
    _ -> enemy.position
  }
  Enemy(
    ..enemy,
    position: position,
    velocity: vector.Vector(
      enemy.velocity.x,
      enemy.velocity.y,
      enemy.velocity.z -. enemy_gravity_strength,
    ),
  )
}

/// Applies damage to the enemy.
pub fn apply_damage(enemy: Enemy, damage: Int) -> Enemy {
  Enemy(..enemy, current_health: enemy.current_health - damage)
}

/// Is the enemy currently dead.
pub fn is_enemy_dead(enemy: Enemy) -> Bool {
  enemy.current_health <= 0
}

/// Checks if the object at the given position with given radius collides with the enemy.
pub fn collides_with(enemy: Enemy, position: Vector, size: Float) -> Bool {
  vector.distance(enemy.position, position) <. size /. 2.0 +. enemy_size /. 2.0
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
