import gleam/float
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import utils
import vector.{type Vector}

/// The size of the player character in pixels.
pub const player_size = 10.0

const max_speed = 4.0

fn acceleration() {
  2.0 /. 3.0
}

const jump_power = 0.2

const time_between_fire = 120

const invulnerability_time = 500

const base_max_health = 100

/// Represents the player character.
pub type Player {
  /// Represents the player character.
  Player(
    /// The character's current position in the dungeon.
    position: Vector,
    /// The character's current velocity.
    velocity: Vector,
    /// The character's current acceleration.
    acceleration: Vector,
    /// Last time that the player fired a bullet
    last_fire_time: Int,
    /// Last time that the player was hit
    last_hit_time: Int,
    /// Player's current remaining hit points
    current_health: Int,
    /// Player's max hit points
    max_health: Int,
  )
}

/// Makes the starting player at the given position.
pub fn new_player(initial_position: Vector) -> Player {
  Player(
    position: initial_position,
    velocity: vector.Vector(0.0, 0.0, 0.0),
    acceleration: vector.Vector(0.0, 0.0, 0.0),
    last_fire_time: 0,
    last_hit_time: 0,
    current_health: base_max_health,
    max_health: base_max_health,
  )
}

/// Advances the player forward assuming they can.
pub fn move(player: Player) -> Player {
  Player(..player, position: vector.add(player.position, player.velocity))
}

/// Accelerates the player's velocity.
pub fn update_velocity(player: Player) -> Player {
  // Base acceleration
  let vel = vector.add(player.velocity, player.acceleration)
  // Limit xy velocity
  let limited =
    vector.vector_2d(vel)
    |> vector.limit(max_speed)
  Player(..player, velocity: vector.Vector(limited.x, limited.y, vel.z))
}

/// Let's the player jump if they are on the ground.
pub fn jump(player: Player) -> Player {
  case player.position.z, player.velocity.z {
    p, v if p == 0.0 && v <=. 0.0 ->
      Player(
        ..player,
        velocity: vector.Vector(
          player.velocity.x,
          player.velocity.y,
          jump_power,
        ),
      )
    _, _ -> player
  }
}

/// Accelerates the player in the x direction.
pub fn accelerate_x(player: Player, forward: Bool) -> Player {
  let acc = case forward {
    True -> acceleration()
    False -> -1.0 *. acceleration()
  }
  Player(
    ..player,
    acceleration: vector.Vector(
      acc,
      player.acceleration.y,
      player.acceleration.z,
    ),
  )
}

/// Accelerates the player in the y direction.
pub fn accelerate_y(player: Player, forward: Bool) -> Player {
  let acc = case forward {
    True -> acceleration()
    False -> -1.0 *. acceleration()
  }
  Player(
    ..player,
    acceleration: vector.Vector(
      player.acceleration.x,
      acc,
      player.acceleration.z,
    ),
  )
}

/// Stops the player in the x direction.
pub fn stop_x(player: Player) -> Player {
  Player(
    ..player,
    velocity: vector.Vector(0.0, player.velocity.y, player.velocity.z),
    acceleration: vector.Vector(
      0.0,
      player.acceleration.y,
      player.acceleration.z,
    ),
  )
}

/// Stops the player in the y direction.
pub fn stop_y(player: Player) -> Player {
  Player(
    ..player,
    velocity: vector.Vector(player.velocity.x, 0.0, player.velocity.z),
    acceleration: vector.Vector(
      player.acceleration.x,
      0.0,
      player.acceleration.z,
    ),
  )
}

const player_gravity_strength = 0.02

/// Applies gravity to the velocity and resets z position to floor when appropriate.
pub fn apply_gravity(player: Player) -> Player {
  let position = case player.position.z {
    z if z <. 0.0 -> vector.Vector(player.position.x, player.position.y, 0.0)
    _ -> player.position
  }
  Player(
    ..player,
    position: position,
    velocity: vector.Vector(
      player.velocity.x,
      player.velocity.y,
      player.velocity.z -. player_gravity_strength,
    ),
  )
}

/// Applies damage to the player.
pub fn apply_damage(player: Player, damage: Int) -> Player {
  Player(
    ..player,
    current_health: player.current_health - damage,
    last_hit_time: utils.now_in_milliseconds(),
  )
}

/// Is the player currently dead.
pub fn is_player_dead(player: Player) -> Bool {
  player.current_health <= 0
}

/// Is the player currently invulnerable.
pub fn is_player_invulnerable(player: Player) -> Bool {
  player.last_hit_time + invulnerability_time >= utils.now_in_milliseconds()
}

/// Can the player fire a bullet at the moment.
pub fn can_player_fire(player: Player) -> Bool {
  player.last_fire_time + time_between_fire <= utils.now_in_milliseconds()
}

const dead_fill_color = "#000000"

const invulnerable_fill_color = "#4c4cff"

const player_fill_color = "#0000ff"

const player_stroke_color = "#000000"

/// Renders the player to the screen.
pub fn draw(p: P5, player: Player) {
  case is_player_dead(player), is_player_invulnerable(player) {
    True, _ -> p5.fill(p, dead_fill_color)
    _, True -> p5.fill(p, invulnerable_fill_color)
    _, _ -> p5.fill(p, player_fill_color)
  }

  p5.stroke(p, player_stroke_color)

  let assert Ok(size_to_draw) =
    float.power(player_size, 1.0 +. player.position.z /. 4.0)
  let size_to_draw = float.max(size_to_draw, player_size /. 2.0)

  p5.ellipse(
    p,
    player.position.x,
    player.position.y,
    size_to_draw,
    size_to_draw,
  )
}
