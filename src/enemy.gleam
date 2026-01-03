import behavior_tree/behavior_tree
import bullet.{type Bullet}
import dungeon.{type Dungeon}
import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam_community/maths
import obstacle
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import pit
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
fn random_direction(position: Vector, dungeon: dungeon.Dungeon) -> Vector {
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

  let #(col, row) = dungeon.point_to_coordinate(position)

  let new_position =
    dungeon.next_room_indices(col, row, dir) |> dungeon.coordinate_to_point
  case dungeon.can_move(dungeon, position, new_position) {
    True -> new_position
    False -> random_direction(position, dungeon)
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
    enemy.position
    // Get a random adjacent room
    |> random_direction(inputs.dungeon),
  ]

  let enemy =
    Enemy(..enemy, path: path, last_path_updated: utils.now_in_milliseconds())

  behavior_tree.BehaviorResult(True, enemy, AdditionalOutputs([]))
}

// Moves the enemy toward their next location in the path. Foils if there is nothing in the path.
// Removes location from path once the enemy has arrived.
pub fn follow_path_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: inputs) =
    inputs
  let Inputs(enemies, dungeon, _) = inputs

  case enemy.path {
    [] -> behavior_tree.BehaviorResult(False, enemy, AdditionalOutputs([]))
    [next, ..rest] -> {
      case
        vector.distance(next, enemy.position)
        <. int.to_float(dungeon.room_size) /. 10.0
      {
        True ->
          behavior_tree.BehaviorResult(
            True,
            Enemy(..enemy, path: rest),
            AdditionalOutputs([]),
          )
        False -> {
          let whiskers =
            create_whisker_points(enemy)
            |> list.filter_map(dungeon.get_reflecting_point(
              dungeon,
              enemy.position,
              _,
            ))

          let #(enemy, new_position) =
            move_enemy(
              enemy,
              next,
              dungeon.obstacles,
              dungeon.pits,
              enemies,
              whiskers,
            )
          let new_position = case
            dungeon.can_move(dungeon, enemy.position, new_position)
          {
            True -> new_position
            False ->
              // Apply downward velocity but don't move forward
              vector.Vector(
                enemy.position.x,
                enemy.position.y,
                enemy.position.z +. enemy.velocity.z,
              )
          }

          let enemy =
            Enemy(..enemy, position: new_position) |> steer_enemy(next)

          behavior_tree.BehaviorResult(True, enemy, AdditionalOutputs([]))
        }
      }
    }
  }
}

// Behavior that just succeeds if the enemy has line of sight and is in range of the player.
pub fn in_range_of_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(
    entity: enemy,
    additional_inputs: Inputs(_, dungeon, player),
  ) = inputs

  use <- bool.guard(
    vector.distance(enemy.position, player.position)
      >. int.to_float(dungeon.room_size / 2),
    behavior_tree.BehaviorResult(False, enemy, AdditionalOutputs([])),
  )

  behavior_tree.BehaviorResult(
    dungeon.can_move(dungeon, enemy.position, player.position),
    enemy,
    AdditionalOutputs([]),
  )
}

// Simple behavior that marks the player as spotted.
pub fn spot_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs

  behavior_tree.BehaviorResult(
    True,
    Enemy(..enemy, spotted_player: True),
    AdditionalOutputs([]),
  )
}

// Simple behavior that checks if the enemy spotted the player.
pub fn spotted_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs

  behavior_tree.BehaviorResult(
    enemy.spotted_player,
    enemy,
    AdditionalOutputs([]),
  )
}

// Behavior that set's the enemy's path to the player.
// Always succeeds.
pub fn path_to_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(
    entity: enemy,
    additional_inputs: Inputs(_, dungeon, player),
  ) = inputs

  let path = dungeon.path_to(dungeon, enemy.position, player.position)
  // Drop last path entry because player is in that room
  let path = path |> list.take(list.length(path) - 1)

  let enemy =
    Enemy(..enemy, path: path, last_path_updated: utils.now_in_milliseconds())

  behavior_tree.BehaviorResult(True, enemy, AdditionalOutputs([]))
}

// Simple behavior that moves the enemy toward the spotted player.
pub fn follow_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(
    entity: enemy,
    additional_inputs: Inputs(enemies, dungeon, player),
  ) = inputs

  let target = vector.vector_2d(player.position)
  let whiskers =
    create_whisker_points(enemy)
    |> list.filter_map(dungeon.get_reflecting_point(dungeon, enemy.position, _))

  let #(enemy, new_position) =
    move_enemy(
      enemy,
      target,
      dungeon.obstacles,
      dungeon.pits,
      enemies,
      whiskers,
    )
  let new_position = case
    dungeon.can_move(dungeon, enemy.position, new_position)
  {
    True -> new_position
    False ->
      // Apply downward velocity but don't move forward
      vector.Vector(
        enemy.position.x,
        enemy.position.y,
        enemy.position.z +. enemy.velocity.z,
      )
  }

  let enemy = Enemy(..enemy, position: new_position) |> steer_enemy(target)

  behavior_tree.BehaviorResult(True, enemy, AdditionalOutputs([]))
}

// Simple behavior that checks if the enemy is in midair.
pub fn in_air_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs

  behavior_tree.BehaviorResult(
    enemy.position.z >. 0.0,
    enemy,
    AdditionalOutputs([]),
  )
}

// Behavior that moves the enemy while they are in midair.
pub fn move_in_air_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(
    entity: enemy,
    additional_inputs: Inputs(_, dungeon, _),
  ) = inputs

  let new_position = enemy.position |> vector.add(enemy.velocity)
  let new_position = case
    dungeon.can_move(dungeon, enemy.position, new_position)
  {
    True -> new_position
    False ->
      vector.Vector(
        enemy.position.x,
        enemy.position.y,
        enemy.position.z +. enemy.velocity.z,
      )
  }

  behavior_tree.BehaviorResult(
    True,
    Enemy(..enemy, position: new_position),
    AdditionalOutputs([]),
  )
}

// Simple behavior that checks if the enemy is looking at the player.
pub fn is_facing_player_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(
    entity: enemy,
    additional_inputs: Inputs(_, _, player),
  ) = inputs

  let player2d = vector.vector_2d(player.position)
  let enemy2d = vector.vector_2d(enemy.position)
  // Find vector from enemy to player
  let target = vector.subtract(player2d, enemy2d)
  // Extend vector based on the projection from the enemies facing direction
  let target =
    vector.multiply(
      target,
      vector.dot(vector.from_angle2d(enemy.rotation), target)
        /. vector.magnitude(target),
    )
  // Find point along vector from enemy to player
  let target = vector.add(target, enemy2d)

  behavior_tree.BehaviorResult(
    vector.distance(target, player2d) <. player.player_size /. 2.0,
    enemy,
    AdditionalOutputs([]),
  )
}

const bullet_wait_time = 200

// Fires a bullet from the enemy
pub fn fire_bullet_behavior(inputs: BehaviorInput) -> BehaviorResult {
  let behavior_tree.BehaviorInput(entity: enemy, additional_inputs: _) = inputs

  let now = utils.now_in_milliseconds()
  case enemy.last_bullet_fired + bullet_wait_time > now {
    True -> behavior_tree.BehaviorResult(False, enemy, AdditionalOutputs([]))
    False ->
      behavior_tree.BehaviorResult(
        True,
        Enemy(..enemy, last_bullet_fired: now),
        AdditionalOutputs([
          bullet.spawn_bullet(
            enemy.position,
            vector.from_angle2d(enemy.rotation),
            False,
          ),
        ]),
      )
  }
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
    /// The enemies current rotational velocity.
    rotational_velocity: Float,
    /// Enemy's current remaining hit points.
    current_health: Int,
    /// Enemy's max hit points.
    max_health: Int,
    /// The current path the enemy is on.
    path: List(Vector),
    /// The last time the path was updated.
    last_path_updated: Int,
    /// Can the enemy currently see the player.
    spotted_player: Bool,
    /// The last time the enemy fired a bullet.
    last_bullet_fired: Int,
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
    rotational_velocity: 0.0,
    current_health: max_enemy_health,
    max_health: max_enemy_health,
    path: [],
    last_path_updated: 0,
    spotted_player: False,
    last_bullet_fired: 0,
    btree: behavior_tree.all(
      [
        // Look for player
        sequence([in_range_of_player_behavior, spot_player_behavior]),
        // Update the enemy's path
        selector([
          sequence([spotted_player_behavior, path_to_player_behavior]),
          sequence([
            selector([
              behavior_tree.not(has_path_behavior),
              path_is_stale_behavior,
            ]),
            random_path_behavior,
          ]),
        ]),
        // Move the enemy
        selector([
          sequence([in_air_behavior, move_in_air_behavior]),
          sequence([has_path_behavior, follow_path_behavior]),
          sequence([spotted_player_behavior, follow_player_behavior]),
        ]),
        // Fire bullets
        sequence([
          in_range_of_player_behavior,
          is_facing_player_behavior,
          fire_bullet_behavior,
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

const whisker_length = 20.0

// Creates whisker points in front of the enemy that are used for collision detection.
fn create_whisker_points(enemy: Enemy) -> List(Vector) {
  let whisker_dist =
    enemy.velocity |> vector.normalize |> vector.multiply(whisker_length)
  let pi_div_4 = maths.pi() /. 4.0

  [
    whisker_dist |> vector.rotate2d(pi_div_4) |> vector.add(enemy.position),
    whisker_dist
      |> vector.rotate2d(pi_div_4 *. -1.0)
      |> vector.add(enemy.position),
  ]
}

const target_radius = 10.0

const slow_radius = 40.0

const max_speed = 3.0

const max_acceleration = 3.0

const wall_avoid_force = max_acceleration

// Update position and velocity based on distance from target.
// Returns an updated enemy and their new location if they moved.
fn move_enemy(
  enemy: Enemy,
  target: Vector,
  obstacles: List(obstacle.Obstacle),
  pits: List(pit.Pit),
  enemies: List(Enemy),
  whisker_points: List(room.Direction),
) -> #(Enemy, Vector) {
  let dir = vector.subtract(target, enemy.position)
  let dist = dir |> vector.magnitude

  use <- bool.guard(dist <. target_radius, #(enemy, enemy.position))

  let target_speed = case dist >. slow_radius {
    True -> max_speed
    False -> max_speed *. dist /. slow_radius
  }

  let target_velocity = dir |> vector.normalize |> vector.multiply(target_speed)
  let acceleration = vector.subtract(target_velocity, enemy.velocity)

  // Go through pits and either avoid them, ignore them if too far, or jump over them
  let #(acceleration, is_jumping) =
    list.fold(pits, #(acceleration, False), fn(acc, p) {
      let is_jumping = acc.1
      let dir = vector.subtract(enemy.position, p.position)
      let dist = vector.magnitude(dir)
      case dist <. pit_avoid_radius && !is_jumping {
        False -> acc
        True -> {
          // Check if jumping would go over the pit
          let landing_position =
            landing_position_if_jumped(enemy.position, enemy.velocity)
          case
            connection_crosses(
              enemy.position,
              landing_position,
              p.position,
              p.size /. 2.0,
            )
            // Don't have enemies jump if they already are in the pit
            && vector.distance(landing_position, p.position) >. p.size /. 2.0
          {
            True -> {
              #(
                vector.Vector(0.0, 0.0, -1.0 *. enemy.velocity.z +. jump_power),
                True,
              )
            }
            False -> {
              #(
                avoid_thing_at_position(
                  enemy,
                  p.position,
                  acc.0,
                  pit_avoid_force,
                  pit_avoid_radius,
                ),
                False,
              )
            }
          }
        }
      }
    })

  let acceleration = {
    use <- bool.guard(is_jumping, acceleration)

    acceleration
    |> list.fold(obstacles, _, fn(acc, o) {
      avoid_thing_at_position(enemy, o.position, acc, avoid_force, avoid_radius)
    })
    |> list.fold(enemies, _, fn(acc, e) {
      // Assume if position is same that they are the same enemy
      case e.position == enemy.position {
        True -> acc
        False ->
          avoid_thing_at_position(
            enemy,
            e.position,
            acc,
            cluster_force,
            cluster_radius,
          )
      }
    })
    |> vector.limit(max_acceleration)
    |> list.fold(whisker_points, _, fn(acc, w) {
      let add = case w {
        room.Left -> vector.Vector(-1.0 *. wall_avoid_force, 0.0, 0.0)
        room.Right -> vector.Vector(wall_avoid_force, 0.0, 0.0)
        room.Top -> vector.Vector(0.0, -1.0 *. wall_avoid_force, 0.0)
        room.Bottom -> vector.Vector(0.0, wall_avoid_force, 0.0)
        room.TopLeft ->
          vector.Vector(-1.0 *. wall_avoid_force, -1.0 *. wall_avoid_force, 0.0)
        room.TopRight ->
          vector.Vector(wall_avoid_force, -1.0 *. wall_avoid_force, 0.0)
        room.BottomLeft ->
          vector.Vector(-1.0 *. wall_avoid_force, wall_avoid_force, 0.0)
        room.BottomRight ->
          vector.Vector(wall_avoid_force, wall_avoid_force, 0.0)
      }
      vector.add(add, acc)
    })
    |> vector.limit(max_acceleration)
  }

  let velocity = vector.add(enemy.velocity, acceleration)
  #(Enemy(..enemy, velocity: velocity), vector.add(velocity, enemy.position))
}

const jump_power = 0.3

// Computes where an enemy would land if they jumped at the current position and velocity
fn landing_position_if_jumped(position: Vector, velocity: Vector) -> Vector {
  let time_in_air = jump_power /. enemy_gravity_strength
  vector.add(position, vector.multiply(velocity, time_in_air))
}

// Determines if the line from the start to the end crosses through a point with a given radius
fn connection_crosses(
  start: Vector,
  end: Vector,
  center: Vector,
  radius: Float,
) -> Bool {
  let diff = vector.subtract(end, start)
  // project center onto the line between start and end and get the parametric value for the point
  let t = {
    {
      -1.0
      *. diff.x
      *. { start.x -. center.x }
      -. diff.y
      *. { start.y -. center.y }
      -. diff.z
      *. { start.z -. center.z }
    }
    /. vector.dot(diff, diff)
  }

  // clip the parametric point to 0-1 and see if the point is within range of the center
  case t >. 1.0 || t <. 0.0 {
    True -> {
      let z =
        vector.distance(vector.add(start, vector.multiply(diff, 0.0)), center)
      let o =
        vector.distance(vector.add(start, vector.multiply(diff, 1.0)), center)
      z <. radius || o <. radius
    }
    False ->
      vector.distance(vector.add(start, vector.multiply(diff, t)), center)
      <. radius
  }
}

const pit_avoid_force = 1000.0

const pit_avoid_radius = 30.0

const avoid_force = 200.0

const avoid_radius = 50.0

const cluster_force = 100.0

const cluster_radius = 20.0

// If the enemy is too close to the given position then add some force to the acceleration to avoid it.
fn avoid_thing_at_position(
  enemy: Enemy,
  position: Vector,
  acceleration: Vector,
  force: Float,
  radius: Float,
) -> Vector {
  let dir = vector.subtract(enemy.position, position)
  let dist = vector.magnitude_squared(dir)

  case dist <. radius *. radius {
    True -> {
      let repulsion = float.min(force /. dist, max_acceleration)
      dir
      |> vector.normalize
      |> vector.multiply(repulsion)
      |> vector.add(acceleration)
    }
    False -> acceleration
  }
}

// converts radian amount to be between -pi and pi
fn clamp_radians(input_radians: Float) -> Float {
  let pi = maths.pi()
  let input_radians = case input_radians <. -1.0 *. pi {
    True -> clamp_radians(input_radians +. pi *. 2.0)
    False -> input_radians
  }
  case input_radians >. pi {
    True -> clamp_radians(input_radians -. pi *. 2.0)
    False -> input_radians
  }
}

fn target_rotation_range() -> Float {
  maths.pi() /. 30.0
}

fn slow_rotation_range() -> Float {
  maths.pi() /. 15.0
}

fn max_angular_speed() -> Float {
  maths.pi() /. 20.0
}

fn max_angular_acceleration() -> Float {
  maths.pi() /. 40.0
}

// Steers the enemy to face toward the target.
fn steer_enemy(enemy: Enemy, target: vector.Vector) -> Enemy {
  let dir = vector.subtract(target, enemy.position)
  let dist = dir |> vector.magnitude

  let target_rotation =
    case dist <. target_radius {
      True -> dir
      False -> enemy.velocity
    }
    |> vector.heading2d
  let rotation_diff = clamp_radians(target_rotation -. enemy.rotation)
  let rotation_mag = float.absolute_value(rotation_diff)

  use <- bool.guard(rotation_mag <. target_rotation_range(), enemy)

  let target_rotation_velocity =
    case rotation_mag >. slow_rotation_range() {
      True -> max_angular_speed()
      False -> max_angular_speed() *. rotation_mag /. slow_rotation_range()
    }
    *. rotation_diff
    /. rotation_mag
  let rotational_acceleration =
    target_rotation_velocity -. enemy.rotational_velocity
  let rotational_acc_mag = float.absolute_value(rotational_acceleration)
  let rotational_acceleration = case
    rotational_acc_mag >. max_angular_acceleration()
  {
    True ->
      rotational_acceleration
      *. max_angular_acceleration()
      /. rotational_acc_mag
    False -> rotational_acceleration
  }

  let rotational_velocity = enemy.rotational_velocity +. rotational_acceleration
  Enemy(
    ..enemy,
    rotational_velocity: rotational_velocity,
    rotation: enemy.rotation +. rotational_velocity,
  )
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
    enemy.position.x +. maths.cos(enemy.rotation) *. size_to_draw /. 2.0,
    enemy.position.y +. maths.sin(enemy.rotation) *. size_to_draw /. 2.0,
  )
}
