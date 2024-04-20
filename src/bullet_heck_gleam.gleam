import dungeon
import gleam/option
import p5js_gleam.{type P5, SketchConfig}
import p5js_gleam/bindings as p5
import room

/// Represents the overall game state
type WorldState {
  WorldState(dungeon: dungeon.Dungeon)
  // bullets: List(Bullet),
  // enemies: List(Enemy),
  // player: Player,
}

fn setup(p: P5) -> WorldState {
  p5.create_canvas(p, 800.0, 600.0)
  WorldState(
    dungeon.Dungeon([
      [
        option.Some(room.Room(True, True, True, False, True, True, True, True)),
        option.Some(room.Room(True, True, False, True, True, True, True, True)),
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.None,
      ],
      [
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.None,
        option.None,
      ],
      [
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.None,
        option.None,
      ],
      [
        option.None,
        option.None,
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
        option.Some(room.Room(True, True, True, True, True, True, True, True)),
      ],
    ]),
  )
}

fn draw(p: P5, state: WorldState) {
  p5.background(p, "#ffffff")
  p5.fill(p, "#000000")
  dungeon.draw_dungeon(p, state.dungeon)
}

pub fn main() {
  p5.start_sketch(SketchConfig(
    init: setup,
    draw: draw,
    on_tick: option.None,
    on_key: option.None,
    on_mouse: option.None,
  ))
}
