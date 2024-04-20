import gleam/list
import gleam/option
import p5js_gleam.{type P5}
import room

const dungeon_size = 7

const room_size = 100

pub type Dungeon {
  Dungeon(rooms: List(List(option.Option(room.Room))))
}

pub fn draw_dungeon(p: P5, dungeon: Dungeon) {
  use r, col, row <- iter_rooms(dungeon)
  room.draw_room(p, r, col, row, room_size)
}

fn iter_rooms(dungeon: Dungeon, f: fn(room.Room, Int, Int) -> a) {
  use column, column_number <- list.index_map(dungeon.rooms)
  use room, row_number <- list.index_map(column)
  use room <- option.map(room)
  f(room, column_number, row_number)
}
