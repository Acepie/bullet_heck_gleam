import dungeon
import gleam/dict
import gleam/int
import gleam/iterator.{repeatedly, take}
import gleam/list
import room
import startest.{describe, it}
import startest/expect
import vector

pub fn validate_room_is_traversable(d: dungeon.Dungeon) {
  let rooms =
    d.rooms
    |> dict.to_list()

  use #(#(column, row), room) <- list.each(rooms)

  // Check direction is symmetrical
  // Returns if the direction is navigable
  let test_direction = fn(dir: room.Direction) -> Bool {
    case room.is_navigable(room, dir) {
      // Confirm the other room can navigate to this room
      True -> {
        let next_room_coords = dungeon.next_room_indices(column, row, dir)
        let next_room = dict.get(d.rooms, next_room_coords)
        expect.to_be_ok(next_room)
        let assert Ok(next_room) = next_room
        expect.to_be_true(room.is_navigable(
          next_room,
          room.inverse_direction(dir),
        ))
        True
      }
      // Confirm the other room can't navigate to this room or is empty
      False -> {
        let next_room_coords = dungeon.next_room_indices(column, row, dir)
        let next_room = dict.get(d.rooms, next_room_coords)

        case next_room {
          Error(_) -> Nil
          Ok(next_room) -> {
            expect.to_be_false(room.is_navigable(
              next_room,
              room.inverse_direction(dir),
            ))
          }
        }
        False
      }
    }
  }

  // Check each room has at least 1 other navigable room
  expect.to_be_true(
    list.any(
      [
        test_direction(room.Left),
        test_direction(room.Right),
        test_direction(room.Top),
        test_direction(room.Bottom),
        test_direction(room.TopLeft),
        test_direction(room.TopRight),
        test_direction(room.BottomLeft),
        test_direction(room.BottomRight),
      ],
      fn(x) { x },
    ),
  )
}

pub fn dungeon_tests() {
  describe("dungeon", [
    it("generated dungeons should always be traversable", fn() {
      {
        use <- repeatedly

        dungeon.generate_dungeon()
        |> validate_room_is_traversable
      }
      |> take(30)

      Nil
    }),
    it("can_move in a dungeon", fn() {
      let rooms =
        dict.new()
        |> dict.insert(#(1, 1), room.initialize_unbounded_room())
        |> dict.insert(#(1, 2), room.initialize_unbounded_room())
        |> dict.insert(
          #(2, 1),
          room.initialize_unbounded_room()
            |> room.set_navigable(room.Bottom, True),
        )
        |> dict.insert(
          #(2, 2),
          room.initialize_unbounded_room()
            |> room.set_navigable(room.Top, True),
        )
      let dungeon = dungeon.Dungeon(rooms: rooms)

      // to out of bounds
      expect.to_be_false(dungeon.can_move(
        dungeon,
        vector.Vector(0.0, 0.0, 0.0),
        vector.Vector(10_000.0, 0.0, 0.0),
      ))
      // from and to not real rooms
      expect.to_be_false(dungeon.can_move(
        dungeon,
        vector.Vector(0.0, 0.0, 0.0),
        vector.Vector(0.0, 0.0, 0.0),
      ))
      // from and to blocked by wall
      expect.to_be_false(dungeon.can_move(
        dungeon,
        vector.Vector(
          int.to_float(dungeon.room_size) *. 1.5,
          int.to_float(dungeon.room_size) *. 1.5,
          0.0,
        ),
        vector.Vector(
          int.to_float(dungeon.room_size) *. 1.5,
          int.to_float(dungeon.room_size) *. 2.5,
          0.0,
        ),
      ))
      // from and to are navigable
      expect.to_be_true(dungeon.can_move(
        dungeon,
        vector.Vector(
          int.to_float(dungeon.room_size) *. 2.5,
          int.to_float(dungeon.room_size) *. 1.5,
          0.0,
        ),
        vector.Vector(
          int.to_float(dungeon.room_size) *. 2.5,
          int.to_float(dungeon.room_size) *. 2.5,
          0.0,
        ),
      ))

      Nil
    }),
  ])
}
