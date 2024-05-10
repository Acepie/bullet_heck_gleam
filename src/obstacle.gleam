import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import vector.{type Vector}

pub const size = 6.0

pub const damage = 10

/// Represents an obstacle that the player must avoid.
pub type Obstacle {
  /// Represents an obstacle that the player must avoid.
  Obstacle(
    /// The position of the obstacle.
    position: Vector,
  )
}

/// Checks if the object at the given position with given radius collides with the bullet.
pub fn collides_with(
  obstacle: Obstacle,
  position: Vector,
  object_size: Float,
) -> Bool {
  vector.distance(obstacle.position, position)
  <. size /. 2.0 +. object_size /. 2.0
}

/// Renders the obstacle to the screen
pub fn draw(p: P5, obstacle: Obstacle) {
  let position = obstacle.position
  let spike1 = 4.0
  let spike2 = 5.0
  p5.stroke(p, "#f4424b")
  |> p5.fill("#f4424b")
  |> p5.circle(position.x, position.y, size)
  |> p5.line(
    position.x -. spike1,
    position.y -. spike1,
    position.x +. spike1,
    position.y +. spike1,
  )
  |> p5.line(
    position.x -. spike1,
    position.y +. spike1,
    position.x +. spike1,
    position.y -. spike1,
  )
  |> p5.line(position.x, position.y -. spike2, position.x, position.y +. spike2)
  |> p5.line(position.x -. spike2, position.y, position.x +. spike2, position.y)
}
