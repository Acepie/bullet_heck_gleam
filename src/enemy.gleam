import behavior_tree/behavior_tree
import bullet.{type Bullet}
import dungeon.{type Dungeon}
import gleam/dict
import gleam/float
import gleam/list
import gleam_community/maths/elementary
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import player.{type Player}
import prng/random
import room
import utils
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

type BehaviorInput =
  behavior_tree.BehaviorInput(Enemy, Inputs)

type BehaviorResult =
  behavior_tree.BehaviorResult(Enemy, AdditionalOutputs)

/// Represents a function that given world information and an enemy updates the enemy.
pub type BehaviorTree =
  behavior_tree.BehaviorTree(Enemy, Inputs, AdditionalOutputs)

// Attempt to find a valid random direction from the given coordinate.
// Returns the coordinate in the valid direction.
fn random_direction(
  coordinate: dungeon.Coordinate,
  rooms: dungeon.Rooms,
) -> dungeon.Coordinate {
  let dir = random.int(0, 8) |> random.random_sample
  let dir = case dir {
    0 -> room.Left
    1 -> room.Right
    2 -> room.Top
    3 -> room.Bottom
    4 -> room.TopLeft
    5 -> room.TopRight
    6 -> room.BottomLeft
    _ -> room.BottomRight
  }

  let #(col, row) = coordinate

  let new_coordinate = dungeon.next_room_indices(col, row, dir)
  case dict.has_key(rooms, new_coordinate) {
    True -> new_coordinate
    False -> random_direction(coordinate, rooms)
  }
}

// NOTE: I'm making all the enemy behaviors that are worth testing public because testing behaviors would probably be unreasonably complex and brittle

// Behavior that just succeeds if the enemy has a non-empty path.
pub fn has_path_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs
  behavior_tree.BehaviorResult(enemy.path != [], enemy, AdditionalOutputs([]))
}

// Behavior that just succeeds if the enemy has not updated their path in a while.
pub fn path_is_stale_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs
  behavior_tree.BehaviorResult(
    enemy.last_path_updated + 1000 < utils.now_in_milliseconds(),
    enemy,
    AdditionalOutputs([]),
  )
}

// Finds a random nearby coordinate and sets the enemy's path to that location.
// Always succeeds.
pub fn random_path_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: inputs) =
    inputs

  // Create a new path by finding a random room that can be moved to.
  let path = [
    // Get the current room
    dungeon.point_to_coordinate(enemy.position)
    // Get a random adjacent room
    |> random_direction(inputs.dungeon.rooms)
    // Turn it into a point for the path
    |> dungeon.coordinate_to_point,
  ]

  let enemy =
    Enemy(..enemy, path: path, last_path_updated: utils.now_in_milliseconds())

  behavior_tree.BehaviorResult(True, enemy, AdditionalOutputs([]))
}

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
    /// The current path the enemy is on.
    path: List(Vector),
    /// The last time the path was updated.
    last_path_updated: Int,
    /// The behavior that an enemy will follow on each tick.
    btree: BehaviorTree,
  )
}

/// Makes a new enemy.
pub fn new_enemy(initial_position: Vector) -> Enemy {
  let default_output = AdditionalOutputs([])
  let output_to_input = fn(i, _) { i }
  let output_merge = fn(old: AdditionalOutputs, new: AdditionalOutputs) {
    AdditionalOutputs(list.append(old.bullets, new.bullets))
  }

  let sequence = behavior_tree.sequence(
    _,
    default_output,
    output_to_input,
    output_merge,
  )
  let selector = behavior_tree.selector(
    _,
    default_output,
    output_to_input,
    output_merge,
  )

  Enemy(
    position: initial_position,
    rotation: 0.0,
    velocity: vector.Vector(0.0, 0.0, 0.0),
    current_health: max_enemy_health,
    max_health: max_enemy_health,
    path: [],
    last_path_updated: 0,
    // TODO: actually make a behavior
    btree: behavior_tree.all(
      [
        // Update the enemy's path
        selector([
          sequence([
            selector([
              behavior_tree.not(has_path_behavior),
              path_is_stale_behavior,
            ]),
            random_path_behavior,
          ]),
        ]),
      ],
      default_output,
      output_to_input,
      output_merge,
    ),
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
