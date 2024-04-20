import gleam/int
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5

const room_color = "#cbe3ed"

const wall_color = "#42aad6"

const wall_shadow_color = "#3c3c3c"

const wall_shadow_color2 = "#646464"

/// A cardinal direction or combination direction.
pub type Direction {
  Left
  Right
  Top
  Bottom
  TopLeft
  TopRight
  BottomLeft
  BottomRight
}

/// Finds the opposite direction of the one passed in.
pub fn inverse_direction(direction: Direction) -> Direction {
  case direction {
    Left -> Right
    Right -> Left
    Top -> Bottom
    Bottom -> Top
    TopLeft -> BottomRight
    TopRight -> BottomLeft
    BottomLeft -> TopRight
    BottomRight -> TopLeft
  }
}

/// Represents a room and its walls.
pub type Room {
  /// Represents a room and its walls.
  /// For each direction True means that direction is navigable (no wall)
  Room(
    left: Bool,
    right: Bool,
    top: Bool,
    bottom: Bool,
    top_left: Bool,
    top_right: Bool,
    bottom_left: Bool,
    bottom_right: Bool,
  )
}

/// Creates a room with only walls.
pub fn initialize_unbounded_room() -> Room {
  Room(False, False, False, False, False, False, False, False)
}

/// Creates a room with the wall to a given direction set to the passed value.
pub fn set_wall(room: Room, direction: Direction, wall_value: Bool) -> Room {
  case direction {
    Left -> Room(..room, left: wall_value)
    Right -> Room(..room, right: wall_value)
    Top -> Room(..room, top: wall_value)
    Bottom -> Room(..room, bottom: wall_value)
    TopLeft -> Room(..room, top_left: wall_value)
    TopRight -> Room(..room, top_right: wall_value)
    BottomLeft -> Room(..room, bottom_left: wall_value)
    BottomRight -> Room(..room, bottom_right: wall_value)
  }
}

/// Draws a room onto the screen at the given row and column.
pub fn draw_room(
  p: P5,
  room: Room,
  room_column: Int,
  room_row: Int,
  room_size: Int,
) {
  let top = int.to_float(room_row * room_size)
  let bot = int.to_float({ room_row + 1 } * room_size)
  let left = int.to_float(room_column * room_size)
  let right = int.to_float({ room_column + 1 } * room_size)

  // room background
  p5.fill(p, room_color)
  p5.stroke(p, room_color)
  p5.rect(p, left, top, int.to_float(room_size), int.to_float(room_size))
  // room shadow
  p5.stroke_weight(p, 4)
  p5.stroke(p, wall_shadow_color)
  p5.line(p, right +. 2.0, top, right +. 2.0, bot)
  p5.line(p, left +. 3.0, bot +. 2.0, right +. 2.0, bot +. 2.0)
  p5.stroke_weight(p, 3)
  p5.stroke(p, wall_shadow_color2)
  p5.line(p, right +. 1.0, top, right +. 1.0, bot)
  p5.line(p, left +. 2.0, bot +. 1.0, right +. 1.0, bot +. 1.0)
  // walls
  p5.stroke(p, wall_color)
  p5.stroke_weight(p, 2)

  case room.left {
    True -> p
    False -> p5.line(p, left, top, left, bot)
  }

  case room.right {
    True -> p
    False -> p5.line(p, right, top, right, bot)
  }

  case room.top {
    True -> p
    False -> p5.line(p, left, top, right, top)
  }

  case room.bottom {
    True -> p
    False -> p5.line(p, left, bot, right, bot)
  }
}
