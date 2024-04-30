import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import vector.{type Vector}

/// Represents a hole in the ground that things can fall into.
pub type Pit {
  /// Represents a hole in the ground that things can fall into.
  Pit(
    /// The position of the center of the pit.
    position: Vector,
    /// The radius of the pit.
    size: Float,
  )
}

/// Renders the pit to the screen
pub fn draw(p: P5, pit: Pit) {
  p5.no_stroke(p)
  |> p5.fill("#969696")
  |> p5.circle(pit.position.x -. 2.0, pit.position.y -. 2.0, pit.size +. 1.0)
  |> p5.fill("#3C3C3C")
  |> p5.circle(pit.position.x -. 1.0, pit.position.y -. 1.0, pit.size +. 1.0)
  |> p5.fill("#000000")
  |> p5.circle(pit.position.x, pit.position.y, pit.size *. 2.0)
}
