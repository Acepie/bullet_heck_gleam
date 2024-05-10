import dungeon
import gleam/dict
import gleam/int
import gleam/iterator.{repeatedly, take}
import gleam/list
import pit
import room
import startest.{describe, it}
import startest/expect
import vector

fn validate_room_is_traversable(d: dungeon.Dungeon) {
  let rooms =
    d.rooms
    |> dict.to_list()

  {
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

  d
}

fn validate_pits(d: dungeon.Dungeon) {
  let pits = d.pits

  {
    use pit1 <- list.each(pits)
    use pit2 <- list.each(pits)

    expect.to_be_true(
      pit1 == pit2 || vector.distance(pit1.position, pit2.position) >. 80.0,
    )
    expect.to_be_true(
      vector.distance(pit1.position, vector.Vector(350.0, 350.0, 0.0)) >. 80.0,
    )
  }

  d
}

fn validate_obstacles(d: dungeon.Dungeon) {
  let pits = d.pits
  let obstacles = d.obstacles

  {
    use pit <- list.each(pits)
    use obstacle <- list.each(obstacles)

    expect.to_be_true(vector.distance(pit.position, obstacle.position) >. 80.0)
  }

  d
}

pub fn dungeon_tests() {
  describe("dungeon", [
    it("generate_dungeon", fn() {
      {
        use <- repeatedly
        dungeon.generate_dungeon()
        |> validate_room_is_traversable
        |> validate_pits
        |> validate_obstacles
      }
      |> take(30)

      Nil
    }),
    it("can_move", fn() {
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
      let dungeon = dungeon.Dungeon(rooms: rooms, pits: [], obstacles: [])

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
    it("is_over_pit", fn() {
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
      let dungeon =
        dungeon.Dungeon(
          rooms: rooms,
          pits: [pit.Pit(position: vector.Vector(0.0, 0.0, 0.0), size: 30.0)],
          obstacles: [],
        )

      expect.to_be_true(dungeon.is_over_pit(
        dungeon,
        vector.Vector(0.0, 0.0, 0.0),
      ))
      expect.to_be_true(dungeon.is_over_pit(
        dungeon,
        vector.Vector(15.0, 0.0, 0.0),
      ))
      expect.to_be_true(dungeon.is_over_pit(
        dungeon,
        vector.Vector(20.0, 0.0, 0.0),
      ))
      expect.to_be_true(dungeon.is_over_pit(
        dungeon,
        vector.Vector(15.0, 15.0, 0.0),
      ))
      expect.to_be_false(dungeon.is_over_pit(
        dungeon,
        vector.Vector(35.0, 15.0, 0.0),
      ))
    }),
  ])
}
