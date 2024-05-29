import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/iterator
import gleam/list
import gleam/result
import obstacle.{type Obstacle}
import p5js_gleam.{type P5}
import pit.{type Pit}
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

const pit_count = 5

const pit_size = 20.0

const minimum_pit_distance = 80.0

const obstacle_rate = 0.5

const obstacle_limit = 3

type Coordinate =
  #(Int, Int)

type Rooms =
  Dict(Coordinate, room.Room)

/// Represents the dungeon and all its hazards.
pub type Dungeon {
  Dungeon(
    /// The different rooms in the dungeon.
    rooms: Rooms,
    /// The pits in the dungeon.
    pits: List(Pit),
    /// The obstacles in the dungeon.
    obstacles: List(Obstacle),
  )
}

/// Creates the initial game dungeon.
pub fn generate_dungeon() -> Dungeon {
  let center = center()
  let rooms =
    dict.new()
    |> generate_rooms(center, center, 0, room.Left)
    |> break_walls
    |> compute_corner_walls
  let pits = generate_pits(rooms)
  let obstacles = generate_obstacles(rooms, pits)
  Dungeon(rooms, pits, obstacles)
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
    use <- bool.guard(
      // Do not try to go back where you came from
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

// Creates pits in random rooms in the dungeon.
fn generate_pits(rooms: Rooms) -> List(Pit) {
  list.range(1, pit_count)
  |> list.fold([], fn(pits, _) {
    // Get a location to place the pit
    let position = get_location_to_place_pit(rooms, pits)
    [pit.Pit(position, pit_size), ..pits]
  })
}

// Creates obstacles in random rooms in the dungeon.
fn generate_obstacles(rooms: Rooms, pits: List(Pit)) -> List(Obstacle) {
  use obstacles, coordinate, _ <- dict.fold(rooms, [])

  // Roll if room should have obstacles
  let obstacle_roll: Float =
    random.float(0.0, 1.0)
    |> random.random_sample
  use <- bool.guard(obstacle_roll >. obstacle_rate, obstacles)

  let point = coordinate_to_point(coordinate)

  // Roll number of obstacles to place
  let obstacle_count: Int =
    random.int(0, obstacle_limit)
    |> random.random_sample

  use obstacles, _ <- list.fold(list.range(1, obstacle_count), obstacles)

  case attempt_place_obstacle(point, pits, 0) {
    Error(_) -> obstacles
    Ok(obstacle) -> [obstacle, ..obstacles]
  }
}

// Attempts to place an obstacle in a room. Returns an error if it fails.
fn attempt_place_obstacle(
  point: vector.Vector,
  pits: List(Pit),
  tries: Int,
) -> Result(Obstacle, Nil) {
  use <- bool.guard(tries > 3, Error(Nil))
  // Get a random offset from the point
  let max_offset = { int.to_float(room_size) -. obstacle.size } /. 2.0
  let offset_x =
    random.float(max_offset *. -1.0, max_offset)
    |> random.random_sample
  let offset_y =
    random.float(max_offset *. -1.0, max_offset)
    |> random.random_sample
  let position = vector.add(point, vector.Vector(offset_x, offset_y, 0.0))

  // Check if the obstacle is too close to a pit
  case too_close_to_existing_pit(pits, position) {
    True -> attempt_place_obstacle(point, pits, tries + 1)
    False -> Ok(obstacle.Obstacle(position))
  }
}

// Check if a position is too close to an existing pit.
fn too_close_to_existing_pit(pits: List(Pit), position: vector.Vector) -> Bool {
  use pit <- list.any(pits)
  let distance = vector.distance(pit.position, position)
  distance <. minimum_pit_distance
}

// Check if a position is too close to where the player spawns.
fn too_close_to_player_spawn(position: vector.Vector) -> Bool {
  let c = center()
  vector.distance(coordinate_to_point(#(c, c)), position)
  <. minimum_pit_distance
}

// Get a random location to place a pit.
// Pits should not be too close to existing pits and should not be too close to where the player starts.
fn get_location_to_place_pit(rooms: Rooms, pits: List(Pit)) -> vector.Vector {
  // Get a room to place the pit in
  let point = get_random_point_in_room(rooms)

  // Get a random offset from the point
  let offset_x =
    random.float(-30.0, 30.0)
    |> random.random_sample
  let offset_y =
    random.float(-30.0, 30.0)
    |> random.random_sample
  let position = vector.add(point, vector.Vector(offset_x, offset_y, 0.0))

  case
    too_close_to_existing_pit(pits, position)
    || too_close_to_player_spawn(position)
  {
    True -> get_location_to_place_pit(rooms, pits)
    _ -> position
  }
}

// Get a random point by generating random coordinates until a room is found.
fn get_random_point_in_room(rooms: Rooms) -> vector.Vector {
  let random_x =
    random.int(0, dungeon_size)
    |> random.random_sample
  let random_y =
    random.int(0, dungeon_size)
    |> random.random_sample
  let coordinate = #(random_x, random_y)
  case dict.get(rooms, coordinate) {
    Error(_) -> get_random_point_in_room(rooms)
    Ok(_) -> coordinate_to_point(coordinate)
  }
}

// Given a coordinate find the center point of the room.
fn coordinate_to_point(coordinate: Coordinate) -> vector.Vector {
  let x =
    int.to_float(coordinate.0 * room_size) +. int.to_float(room_size) /. 2.0
  let y =
    int.to_float(coordinate.1 * room_size) +. int.to_float(room_size) /. 2.0
  vector.Vector(x, y, 0.0)
}

/// Renders the dungeon to the screen.
pub fn draw(p: P5, dungeon: Dungeon) {
  // Draw rooms
  {
    // rendering with shadows depends on order so we are using ranges
    use col <- iterator.each(iterator.range(0, dungeon_size))
    use row <- iterator.each(iterator.range(0, dungeon_size))
    use r <- result.map(dict.get(dungeon.rooms, #(col, row)))

    room.draw(p, r, col, row, room_size)
  }

  // Draw pits
  {
    use pit <- list.each(dungeon.pits)
    pit.draw(p, pit)
  }

  // Draw obstacles
  {
    use obstacle <- list.each(dungeon.obstacles)
    obstacle.draw(p, obstacle)
  }
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

/// Checks if a point is on top of a pit.
pub fn is_over_pit(dungeon: Dungeon, position: vector.Vector) -> Bool {
  use pit <- list.any(dungeon.pits)
  vector.distance(pit.position, position) <. pit.size
}
