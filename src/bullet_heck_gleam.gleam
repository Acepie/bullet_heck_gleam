import dungeon
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import player
import vector

/// Represents the overall game state
type WorldState {
  /// State of the world when the game is active
  GameRunning(dungeon: dungeon.Dungeon, player: player.Player)
  // bullets: List(Bullet),
  // enemies: List(Enemy),
  // player: Player,
}

fn setup(p: P5) -> WorldState {
  let canvas_size = dungeon.total_size()
  p5.create_canvas(p, canvas_size, canvas_size)
  let dungeon = dungeon.generate_dungeon()
  GameRunning(
    dungeon,
    player.new_player(vector.Vector(canvas_size /. 2.0, canvas_size /. 2.0, 0.0)),
  )
}

fn draw(p: P5, state: WorldState) {
  p5.background(p, "#000000")
  dungeon.draw(p, state.dungeon)
  player.draw(p, state.player)
}

fn on_key_pressed(key: String, _: Int, state: WorldState) -> WorldState {
  case key {
    " " -> GameRunning(..state, player: player.jump(state.player))
    "w" ->
      GameRunning(..state, player: player.accelerate_y(state.player, False))
    "s" -> GameRunning(..state, player: player.accelerate_y(state.player, True))
    "a" ->
      GameRunning(..state, player: player.accelerate_x(state.player, False))
    "d" -> GameRunning(..state, player: player.accelerate_x(state.player, True))
    _ -> state
  }
}

fn on_key_released(key: String, _: Int, state: WorldState) -> WorldState {
  case key {
    "w" | "s" -> GameRunning(..state, player: player.stop_y(state.player))
    "a" | "d" -> GameRunning(..state, player: player.stop_x(state.player))
    _ -> state
  }
}

fn on_mouse_moved(x: Float, y: Float, state: WorldState) -> WorldState {
  GameRunning(
    ..state,
    player: player.look_toward(state.player, vector.Vector(x, y, 0.0)),
  )
}

fn on_tick(state: WorldState) -> WorldState {
  // Attempt to move player
  let old_position = state.player.position
  let moved = player.move(state.player)
  let player = case
    dungeon.can_move(state.dungeon, old_position, moved.position)
  {
    True -> moved
    // If they can't move then just apply gravity
    False ->
      player.Player(
        ..state.player,
        position: vector.Vector(
          old_position.x,
          old_position.y,
          old_position.z +. state.player.velocity.z,
        ),
      )
  }

  let player = player.update_velocity(player)
  let player = player.apply_gravity(player)
  GameRunning(..state, player: player)
}

pub fn main() {
  p5js_gleam.create_sketch(init: setup, draw: draw)
  |> p5js_gleam.set_on_key_pressed(on_key_pressed)
  |> p5js_gleam.set_on_key_released(on_key_released)
  |> p5js_gleam.set_on_mouse_moved(on_mouse_moved)
  |> p5js_gleam.set_on_tick(on_tick)
  |> p5.start_sketch
}
