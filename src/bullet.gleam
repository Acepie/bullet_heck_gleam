import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import utils
import vector.{type Vector}

const time_alive = 400

const bullet_size = 6.0

const bullet_speed = 5.0

pub const player_damage = 10

pub const enemy_damage = 5

/// Represents a fired bullet.
pub type Bullet {
  /// Represents a fired bullet.
  Bullet(
    /// The bullet's current position in the dungeon.
    position: Vector,
    /// The bullet's current velocity.
    velocity: Vector,
    /// Was the bullet fired by the player.
    belongs_to_player: Bool,
    /// The time the bullet was spawned.
    time_spawned: Int,
  )
}

/// Spawns a bullet at the given position going in the given direction.
pub fn spawn_bullet(
  position: Vector,
  direction: Vector,
  belongs_to_player: Bool,
) -> Bullet {
  Bullet(
    position: position,
    velocity: vector.multiply(vector.normalize(direction), bullet_speed),
    belongs_to_player: belongs_to_player,
    time_spawned: utils.now_in_milliseconds(),
  )
}

/// Advances a bullet forward.
pub fn advance_bullet(bullet: Bullet) -> Bullet {
  Bullet(..bullet, position: vector.add(bullet.position, bullet.velocity))
}

/// Should the bullet be alive.
pub fn is_still_alive(bullet: Bullet) -> Bool {
  bullet.time_spawned + time_alive > utils.now_in_milliseconds()
}

/// Checks if the object at the given position with given radius collides with the bullet.
pub fn collides_with(bullet: Bullet, position: Vector, size: Float) -> Bool {
  vector.distance(bullet.position, position)
  <. size /. 2.0 +. bullet_size /. 2.0
}

const player_bullet = "#3030ff"

const enemy_bullet = "#f4424b"

/// Renders the bullet to the screen.
pub fn draw(p: P5, bullet: Bullet) {
  p5.no_stroke(p)
  case bullet.belongs_to_player {
    True -> p5.fill(p, player_bullet)
    False -> p5.fill(p, enemy_bullet)
  }
  p5.circle(p, bullet.position.x, bullet.position.y, bullet_size)
}
