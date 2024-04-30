import bullet
import dungeon
import gleam/bool
import gleam/list
import p5js_gleam.{type P5}
import p5js_gleam/bindings as p5
import player
import utils
import vector

/// Represents the overall game state
type WorldState {
  /// State of the world when the game is active
  GameRunning(
    dungeon: dungeon.Dungeon,
    player: player.Player,
    bullets: List(bullet.Bullet),
  )
  GameOver(fell_in_pitch: Bool)
  // enemies: List(Enemy),
}

fn setup(p: P5) -> WorldState {
  let canvas_size = dungeon.total_size()
  p5.create_canvas(p, canvas_size, canvas_size)
  let dungeon = dungeon.generate_dungeon()
  GameRunning(
    dungeon,
    player.new_player(vector.Vector(canvas_size /. 2.0, canvas_size /. 2.0, 0.0)),
    [],
  )
}

fn draw(p: P5, state: WorldState) {
  case state {
    GameRunning(dungeon, player, bullets) -> {
      p5.background(p, "#000000")
      dungeon.draw(p, dungeon)
      player.draw(p, player)
      list.each(bullets, bullet.draw(p, _))
      p
    }
    GameOver(_) -> {
      p5.background(p, "#000000")
    }
  }
}

fn on_key_pressed(key: String, _: Int, state: WorldState) -> WorldState {
  case key, state {
    " ", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.jump(player),
      )
    "w", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.accelerate_y(player, False),
      )
    "s", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.accelerate_y(player, True),
      )
    "a", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.accelerate_x(player, False),
      )
    "d", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.accelerate_x(player, True),
      )
    _, _ -> state
  }
}

fn on_key_released(key: String, _: Int, state: WorldState) -> WorldState {
  case key, state {
    "w", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.stop_y(player),
      )
    "s", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.stop_y(player),
      )
    "a", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.stop_x(player),
      )
    "d", GameRunning(dungeon, player, bullets) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        player: player.stop_x(player),
      )
    _, _ -> state
  }
}

fn on_mouse_clicked(x: Float, y: Float, state: WorldState) -> WorldState {
  case state {
    GameRunning(dungeon, player, bullets) -> {
      use <- bool.guard(!player.can_player_fire(player), state)

      let firing_direction =
        vector.vector_2d(vector.subtract(
          vector.Vector(x, y, 0.0),
          player.position,
        ))
      let player.Player(position: p, ..) = player
      GameRunning(
        dungeon: dungeon,
        bullets: [
          bullet.spawn_bullet(
            vector.Vector(p.x, p.y, 0.0),
            firing_direction,
            True,
          ),
          ..bullets
        ],
        player: player.Player(
          ..player,
          last_fire_time: utils.now_in_milliseconds(),
        ),
      )
    }
    _ -> state
  }
}

fn on_tick(state: WorldState) -> WorldState {
  case state {
    GameRunning(dungeon, player, bullets) -> {
      // Attempt to move player
      let old_position = player.position
      let moved = player.move(player)
      let player = case
        dungeon.can_move(dungeon, old_position, moved.position)
      {
        True -> moved
        // If they can't move then just apply gravity
        False ->
          player.Player(
            ..player,
            position: vector.Vector(
              old_position.x,
              old_position.y,
              old_position.z +. player.velocity.z,
            ),
          )
      }

      use <- bool.guard(
        player.position.z <. 0.0
          && dungeon.is_over_pit(dungeon, player.position),
        GameOver(False),
      )

      let player = player.update_velocity(player)
      let player = player.apply_gravity(player)

      let bullets =
        bullets
        |> list.filter(bullet.is_still_alive)

      let #(bullets, player) =
        list.fold(bullets, #([], player), fn(acc, b) {
          // If the bullet hits a wall then remove it
          use <- bool.guard(
            !dungeon.can_move(
              dungeon,
              b.position,
              bullet.advance_bullet(b).position,
            ),
            acc,
          )

          // Check if the bullet collides with something it can hit
          let #(bullets, player) = acc
          let player = case
            !b.belongs_to_player
            && bullet.collides_with(b, player.position, player.player_size)
          {
            True -> player.apply_damage(player, bullet.enemy_damage)
            False -> player
          }

          #([bullet.advance_bullet(b), ..bullets], player)
        })

      GameRunning(dungeon: dungeon, player: player, bullets: bullets)
    }
    _ -> state
  }
}

pub fn main() {
  p5js_gleam.create_sketch(init: setup, draw: draw)
  |> p5js_gleam.set_on_key_pressed(on_key_pressed)
  |> p5js_gleam.set_on_key_released(on_key_released)
  |> p5js_gleam.set_on_mouse_clicked(on_mouse_clicked)
  |> p5js_gleam.set_on_tick(on_tick)
  |> p5.start_sketch
}
