import gleam/bool
import gleam/int
import gleam/iterator
import gleam/list
import gleam/option
import gleam/result
import glearray.{type Array}
import p5js_gleam.{type P5}
import prng/random
import room

const dungeon_size = 7

const max_depth = dungeon_size

const room_rate = 0.8

const break_rate = 0.3

fn center() -> Int {
  dungeon_size / 2
}

const room_size = 100

pub fn total_size() -> Float {
  int.to_float(dungeon_size * room_size)
}

type Rooms =
  Array(Array(option.Option(room.Room)))

pub type Dungeon {
  Dungeon(rooms: Rooms)
}

/// Creates the initial game dungeon.
pub fn generate_dungeon() -> Dungeon {
  let center = center()
  let rooms =
    glearray.from_list(list.repeat(
      glearray.from_list(list.repeat(option.None, dungeon_size)),
      dungeon_size,
    ))
  let rooms = generate_rooms(rooms, center, center, 0, room.Left)
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
  let r = room.initialize_unbounded_room()
  let r = case recursion_depth {
    0 -> r
    _ -> room.set_wall(r, previous_direction, True)
  }

  // Initialize the current room
  let assert Ok(rooms) = set_room(rooms, option.Some(r), column, row)

  // Exit if we've recursed too far
  use <- bool.guard(recursion_depth > max_depth, rooms)

  let rooms =
    advance_direction(
      rooms,
      column,
      row,
      room.Left,
      recursion_depth,
      previous_direction,
    )
  let rooms =
    advance_direction(
      rooms,
      column,
      row,
      room.Right,
      recursion_depth,
      previous_direction,
    )
  let rooms =
    advance_direction(
      rooms,
      column,
      row,
      room.Top,
      recursion_depth,
      previous_direction,
    )
  let rooms =
    advance_direction(
      rooms,
      column,
      row,
      room.Bottom,
      recursion_depth,
      previous_direction,
    )

  rooms
}

fn advance_direction(
  rooms: Rooms,
  column: Int,
  row: Int,
  direction: room.Direction,
  recursion_depth: Int,
  previous_direction: room.Direction,
) -> Rooms {
  // Do not try to go back where you came from
  use <- bool.guard(
    direction == previous_direction && recursion_depth != 0,
    rooms,
  )
  let #(next_column, next_row) = next_room_indices(column, row, direction)
  // Do not try to go out of bounds
  use <- bool.guard(out_of_bounds(next_column, next_row), rooms)
  // Do not go some place that already has a room
  let assert Ok(col) = glearray.get(rooms, next_column)
  let assert Ok(next_room) = glearray.get(col, next_row)
  use <- bool.guard(option.is_some(next_room), rooms)
  // Decide if we should advance
  let room_roll: Float =
    random.float(0.0, 1.0)
    |> random.random_sample
  case room_roll <. room_rate {
    True -> {
      // Update current room to remove wall to next room
      let assert Ok(col) = glearray.get(rooms, column)
      let assert Ok(option.Some(room)) = glearray.get(col, row)
      let room = room.set_wall(room, direction, True)
      let assert Ok(rooms) = set_room(rooms, option.Some(room), column, row)
      // Advance to next room and recur
      generate_rooms(
        rooms,
        next_column,
        next_row,
        recursion_depth + 1,
        room.inverse_direction(direction),
      )
    }
    False -> rooms
  }
}

// Gets the indices of the room that would be in the given direction from the given indices
fn next_room_indices(
  column: Int,
  row: Int,
  direction: room.Direction,
) -> #(Int, Int) {
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

// Checks if the given indices would be out of bounds
fn out_of_bounds(column: Int, row: Int) -> Bool {
  column < 0 || column >= dungeon_size || row < 0 || row >= dungeon_size
}

/// Renders the dungeon to the screen.
pub fn draw_dungeon(p: P5, dungeon: Dungeon) {
  use r, col, row <- iter_rooms(dungeon)
  case r {
    option.Some(r) -> room.draw_room(p, r, col, row, room_size)
    option.None -> p
  }
}

// creates an iterator to traverse the dungeon rooms
fn iter_rooms(
  dungeon: Dungeon,
  f: fn(option.Option(room.Room), Int, Int) -> a,
) -> Nil {
  let col_iter =
    dungeon.rooms
    |> glearray.iterate
    |> iterator.index
  use #(column, column_number) <- iterator.each(col_iter)

  let row_iter =
    column
    |> glearray.iterate
    |> iterator.index

  use #(room, row_number) <- iterator.each(row_iter)
  f(room, column_number, row_number)
}

// updates the room at the given indices
fn set_room(
  rooms: Rooms,
  room: option.Option(room.Room),
  column: Int,
  row: Int,
) -> Result(Rooms, Nil) {
  let col = glearray.get(rooms, column)
  use col <- result.try(col)
  let new_col = glearray.copy_set(col, row, room)
  use new_col <- result.try(new_col)
  glearray.copy_set(rooms, column, new_col)
}
