import dungeon
import gleam/option
import p5js_gleam.{type P5, SketchConfig}
import p5js_gleam/bindings as p5

/// Represents the overall game state
type WorldState {
  /// State of the world when the game is active
  GameRunning(dungeon: dungeon.Dungeon)
  // bullets: List(Bullet),
  // enemies: List(Enemy),
  // player: Player,
}

fn setup(p: P5) -> WorldState {
  let canvas_size = dungeon.total_size()
  p5.create_canvas(p, canvas_size, canvas_size)
  let dungeon = dungeon.generate_dungeon()
  GameRunning(dungeon)
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
