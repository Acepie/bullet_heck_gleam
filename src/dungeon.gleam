import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/iterator
import gleam/result
import p5js_gleam.{type P5}
import prng/random
import room
import vector

const dungeon_size = 7

const max_depth = dungeon_size

const room_rate = 0.8

const break_rate = 0.3

fn center() -> Int {
  dungeon_size / 2
}

/// The size of each room in pixels.
pub const room_size = 100

/// The total size of the dungeon in pixels.
pub fn total_size() -> Float {
  int.to_float(dungeon_size * room_size)
}

type Coordinate =
  #(Int, Int)

type Rooms =
  Dict(Coordinate, room.Room)

/// Represents the dungeon and all its hazards.
pub type Dungeon {
  Dungeon(rooms: Rooms)
}

/// Creates the initial game dungeon.
pub fn generate_dungeon() -> Dungeon {
  let center = center()
  let rooms =
    dict.new()
    |> generate_rooms(center, center, 0, room.Left)
    |> break_walls
    |> compute_corner_walls
  Dungeon(rooms)
}

// Recursively generate rooms by randomly deciding to traverse each direction.
// For the current room, look at each of the cardinal direction and
// randomly decide to traverse or create wall.
// Never goes backwards and auto stops at a maximum depth.
fn generate_rooms(
  rooms: Rooms,
  column: Int,
  row: Int,
  recursion_depth: Int,
  previous_direction: room.Direction,
) -> Rooms {
  // Initialize the current room
  let r = room.initialize_unbounded_room()
  let r = case recursion_depth {
    0 -> r
    _ -> room.set_navigable(r, previous_direction, True)
  }
  let rooms = dict.insert(rooms, #(column, row), r)

  // Exit if we've recursed too far
  use <- bool.guard(recursion_depth > max_depth, rooms)

  let advance_direction = fn(rooms: Rooms, direction: room.Direction) -> Rooms {
    // Do not try to go back where you came from
    use <- bool.guard(
      direction == previous_direction && recursion_depth != 0,
      rooms,
    )

    let #(next_column, next_row) = next_room_indices(column, row, direction)
    // Do not try to go out of bounds
    use <- bool.guard(coordinate_out_of_bounds(next_column, next_row), rooms)
    // Do not go some place that already has a room
    use <- bool.guard(dict.has_key(rooms, #(next_column, next_row)), rooms)
    // Decide if we should advance
    let room_roll: Float =
      random.float(0.0, 1.0)
      |> random.random_sample

    use <- bool.guard(room_roll >. room_rate, rooms)

    // Update current room to remove wall to next room
    let assert Ok(r) = dict.get(rooms, #(column, row))
    let r = room.set_navigable(r, direction, True)
    let rooms = dict.insert(rooms, #(column, row), r)
    // Advance to next room and recur
    generate_rooms(
      rooms,
      next_column,
      next_row,
      recursion_depth + 1,
      room.inverse_direction(direction),
    )
  }

  rooms
  |> advance_direction(room.Left)
  |> advance_direction(room.Right)
  |> advance_direction(room.Top)
  |> advance_direction(room.Bottom)
}

/// Gets the indices of the room that would be in the given direction from the given indices.
pub fn next_room_indices(
  column: Int,
  row: Int,
  direction: room.Direction,
) -> Coordinate {
  case direction {
    room.Left -> #(column - 1, row)
    room.Right -> #(column + 1, row)
    room.Top -> #(column, row - 1)
    room.Bottom -> #(column, row + 1)
    room.TopLeft -> #(column - 1, row - 1)
    room.TopRight -> #(column + 1, row - 1)
    room.BottomLeft -> #(column - 1, row + 1)
    room.BottomRight -> #(column + 1, row + 1)
  }
}

// Checks if the given coordinates would be out of bounds.
fn coordinate_out_of_bounds(column: Int, row: Int) -> Bool {
  column < 0 || column >= dungeon_size || row < 0 || row >= dungeon_size
}

// Checks if the given position would be out of bounds.
fn point_out_of_bounds(position: vector.Vector) -> Bool {
  let size = total_size()
  position.x <. 0.0
  || position.x >=. size
  || position.y <. 0.0
  || position.y >=. size
}

// Randomly break walls to make dungeon feel less caverny.
fn break_walls(rooms: Rooms) -> Rooms {
  use rooms, #(column, row), _ <- dict.fold(rooms, rooms)

  let break_in_direction = fn(rooms: Rooms, dir: room.Direction) -> Rooms {
    // Check if there is a room to the right
    let #(next_column, next_row) = next_room_indices(column, row, dir)
    use <- bool.guard(coordinate_out_of_bounds(next_column, next_row), rooms)

    let next_room = dict.get(rooms, #(next_column, next_row))
    case next_room {
      Error(_) -> rooms
      Ok(next_room) -> {
        // Decide if we should break wall
        let break_roll: Float =
          random.float(0.0, 1.0)
          |> random.random_sample
        use <- bool.guard(break_roll >. break_rate, rooms)

        // Update current room to remove wall to next room
        let assert Ok(room) = dict.get(rooms, #(column, row))
        let room = room.set_navigable(room, dir, True)
        let rooms = dict.insert(rooms, #(column, row), room)

        // Update next room to remove wall to current room
        let next_room =
          room.set_navigable(next_room, room.inverse_direction(dir), True)
        dict.insert(rooms, #(next_column, next_row), next_room)
      }
    }
  }

  rooms
  |> break_in_direction(room.Right)
  |> break_in_direction(room.Bottom)
}

// Update corners based on cardinal directions.
fn compute_corner_walls(rooms: Rooms) -> Rooms {
  use rooms, #(column, row), r <- dict.fold(rooms, rooms)

  let open_corner = fn(
    room: room.Room,
    dir1: room.Direction,
    dir2: room.Direction,
    out_dir: room.Direction,
  ) -> room.Room {
    let can_go_in_dir =
      room.is_navigable(room, dir1) && room.is_navigable(room, dir2)
    use <- bool.guard(!can_go_in_dir, room)

    // These asserts are ok because if we can naviage then the room must exist already
    let #(next_column, next_row) = next_room_indices(column, row, out_dir)
    use <- bool.guard(coordinate_out_of_bounds(next_column, next_row), room)
    let next_room = dict.get(rooms, #(next_column, next_row))
    case next_room {
      Error(_) -> room
      Ok(next_room) -> {
        let can_go_in_dir =
          room.is_navigable(next_room, room.inverse_direction(dir1))
          && room.is_navigable(next_room, room.inverse_direction(dir2))
        case can_go_in_dir {
          True -> room.set_navigable(room, out_dir, True)
          _ -> room
        }
      }
    }
  }

  let r =
    r
    |> open_corner(room.Right, room.Bottom, room.BottomRight)
    |> open_corner(room.Left, room.Bottom, room.BottomLeft)
    |> open_corner(room.Right, room.Top, room.TopRight)
    |> open_corner(room.Left, room.Top, room.TopLeft)

  dict.insert(rooms, #(column, row), r)
}

/// Renders the dungeon to the screen.
pub fn draw(p: P5, dungeon: Dungeon) {
  // rendering with shadows depends on order so we are using ranges
  use col <- iterator.each(iterator.range(0, dungeon_size))
  use row <- iterator.each(iterator.range(0, dungeon_size))
  use r <- result.map(dict.get(dungeon.rooms, #(col, row)))

  room.draw(p, r, col, row, room_size)
}

/// Get the coordinate that the given point is in.
pub fn point_to_coordinate(point: vector.Vector) -> Coordinate {
  let column = float.truncate(point.x /. int.to_float(room_size))
  let row = float.truncate(point.y /. int.to_float(room_size))
  #(column, row)
}

// Gets the direction one needs to go to move from one coordinate to another.
// Returns an error if the coordinates are the same room.
fn coordinate_direction(
  from: Coordinate,
  to: Coordinate,
) -> Result(room.Direction, Nil) {
  case from, to {
    // ↓
    #(fc, fr), #(tc, tr) if fc == tc && fr < tr -> Ok(room.Bottom)
    // ↘
    #(fc, fr), #(tc, tr) if fc < tc && fr < tr -> Ok(room.BottomRight)
    // ↑
    #(fc, fr), #(tc, tr) if fc == tc && fr > tr -> Ok(room.Top)
    // ↖
    #(fc, fr), #(tc, tr) if fc > tc && fr > tr -> Ok(room.TopLeft)
    // →
    #(fc, fr), #(tc, tr) if fc < tc && fr == tr -> Ok(room.Right)
    // ↗
    #(fc, fr), #(tc, tr) if fc < tc && fr > tr -> Ok(room.TopRight)
    // ←
    #(fc, fr), #(tc, tr) if fc > tc && fr == tr -> Ok(room.Left)
    // ↙
    #(fc, fr), #(tc, tr) if fc > tc && fr < tr -> Ok(room.BottomLeft)
    _, _ -> Error(Nil)
  }
}

/// Checks if it is possible to move from one position to another.
pub fn can_move(
  dungeon: Dungeon,
  from: vector.Vector,
  to: vector.Vector,
) -> Bool {
  // Can't move out of bounds
  use <- bool.guard(point_out_of_bounds(to), False)

  // Find the coordinates that correspond to the start and end points
  let from_coordinate = point_to_coordinate(from)
  let to_coordinate = point_to_coordinate(to)

  // Check that the start and end are both rooms
  let from_room = dict.get(dungeon.rooms, from_coordinate)
  let to_room = dict.get(dungeon.rooms, to_coordinate)

  case from_room, to_room {
    Ok(from), Ok(_) -> {
      // Check that there is no wall blocking the rooms
      let dir = coordinate_direction(from_coordinate, to_coordinate)
      case dir {
        Ok(dir) -> room.is_navigable(from, dir)
        // Same room
        Error(_) -> True
      }
    }
    _, _ -> False
  }
}
