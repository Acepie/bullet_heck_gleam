import bullet
import dungeon
import enemy
import gleam/bool
import gleam/int
import gleam/list
import obstacle
import p5js_gleam.{type Assets, type P5}
import p5js_gleam/bindings as p5
import player
import utils
import vector

/// Represents the overall game state
type WorldState {
  /// The start screen of the game.
  StartScreen
  /// State of the world when the game is active.
  GameRunning(
    dungeon: dungeon.Dungeon,
    player: player.Player,
    bullets: List(bullet.Bullet),
    enemies: List(enemy.Enemy),
    score: Int,
  )
  /// The game over screen when the player has lost.
  GameOver(fell_in_pit: Bool, score: Int)
}

fn preload(p: P5) -> Assets {
  let minecraftia = p5.load_font(p, "./fonts/Minecraftia-Regular.ttf")
  let worksans = p5.load_font(p, "./fonts/WorkSans-Medium.ttf")

  p5js_gleam.initialize_assets()
  |> p5js_gleam.insert_font("minecraftia", minecraftia)
  |> p5js_gleam.insert_font("worksans", worksans)
}

fn setup(p: P5) -> WorldState {
  let canvas_size = dungeon.total_size()
  p5.create_canvas(p, canvas_size, canvas_size)
  StartScreen
}

fn draw(p: P5, state: WorldState, assets: Assets) {
  let center_text = fn(txt: String) {
    let canvas_size = dungeon.total_size()
    canvas_size /. 2.0 -. p5.text_width(p, txt) /. 2.0
  }
  let h1 = 40
  let h2 = 30
  let h3 = 22
  let h4 = 18
  let par = 14
  let assert Ok(minecraftia) = p5js_gleam.get_font(assets, "minecraftia")
  let assert Ok(worksans) = p5js_gleam.get_font(assets, "worksans")
  let canvas_size = dungeon.total_size()

  p5.background(p, "#000000")
  case state {
    StartScreen -> {
      let title = "BULLET HECK"
      let start = "Press 'SPACE' to start"
      let ctrl = "Controls"
      let ctrl_move = "Use arrow keys or WASD to move"
      let ctrl_jump = "Press SPACE to jump"
      let ctrl_shoot = "Use mouse to aim, click to shoot"

      p
      |> p5.fill("#0f0f0f")
      |> p5.rect(0.0, 0.0, canvas_size, canvas_size)
      |> p5.text_size(h1)
      |> p5.fill("#ffffff")
      |> p5.text_font(minecraftia)
      |> p5.text(title, center_text(title), canvas_size /. 2.0 +. 5.0)
      |> p5.text_font(worksans)
      |> p5.text_size(h4)
      |> p5.text(start, center_text(start), canvas_size /. 2.0 +. 20.0)
      // controls
      |> p5.fill("#969696")
      |> p5.text(ctrl, center_text(ctrl), canvas_size /. 2.0 +. 200.0)
      |> p5.text_size(par)
      |> p5.text(ctrl_move, center_text(ctrl_move), canvas_size /. 2.0 +. 225.0)
      |> p5.text(ctrl_jump, center_text(ctrl_jump), canvas_size /. 2.0 +. 245.0)
      |> p5.text(
        ctrl_shoot,
        center_text(ctrl_shoot),
        canvas_size /. 2.0 +. 265.0,
      )
    }
    GameRunning(dungeon, player, bullets, enemies, score) -> {
      dungeon.draw(p, dungeon)
      list.each(enemies, enemy.draw(p, _))
      list.each(bullets, bullet.draw(p, _))
      player.draw(p, player)

      // Render UI
      let hp_x = 22.0
      let score_x = canvas_size -. 100.0

      p
      |> p5.no_stroke()
      |> p5.fill("#660000")
      |> p5.rect(0.0, 0.0, canvas_size, 36.0)
      // draw health bar
      |> p5.fill("#28e200")
      |> p5.rect(hp_x +. 15.0, 12.0, int.to_float(player.current_health), 10.0)
      |> p5.fill("#ffffff")
      |> p5.text_size(par)
      |> p5.text("HP:", 10.0, hp_x)
      // draw score
      |> p5.text("Score:", score_x, 22.0)
      |> p5.text(int.to_string(score), score_x +. 45.0, 22.0)
    }
    GameOver(fell_in_pit, score) -> {
      let canvas_size = dungeon.total_size()
      let game_over = "GAME OVER"
      let final_score = "Final Score: "
      let restart = "Press 'R' to play again"
      let score_text = final_score <> int.to_string(score)
      let cause_of_death = case fell_in_pit {
        True -> "You fell to your death."
        False -> "Turns out, red things hurt."
      }

      p
      |> p5.fill("#0f0f0f")
      |> p5.rect(0.0, 0.0, canvas_size, canvas_size)
      |> p5.fill("#e20000")
      |> p5.text_size(h2)
      |> p5.text_font(minecraftia)
      |> p5.text(game_over, center_text(game_over), canvas_size /. 2.0 -. 25.0)
      |> p5.text_size(h3)
      |> p5.text_font(worksans)
      |> p5.text(
        cause_of_death,
        center_text(cause_of_death),
        canvas_size /. 2.0 -. 15.0,
      )
      |> p5.fill("#ffffff")
      |> p5.text(
        score_text,
        center_text(score_text),
        canvas_size /. 2.0 +. 45.0,
      )
      |> p5.text_size(h4)
      |> p5.text(restart, center_text(restart), canvas_size /. 2.0 +. 70.0)
    }
  }
}

fn spawn_enemies(dungeon: dungeon.Dungeon) -> List(enemy.Enemy) {
  let enemies_to_spawn = 4
  use _ <- list.map(list.range(0, enemies_to_spawn - 1))

  let position =
    dungeon.get_location_to_place_object(dungeon.rooms, dungeon.pits)
  enemy.new_enemy(position)
}

fn on_key_pressed(key: String, _: Int, state: WorldState) -> WorldState {
  case key, state {
    "r", _ -> StartScreen
    " ", StartScreen -> {
      let canvas_size = dungeon.total_size()
      let dungeon = dungeon.generate_dungeon()

      GameRunning(
        dungeon,
        player.new_player(vector.Vector(
          canvas_size /. 2.0,
          canvas_size /. 2.0,
          0.0,
        )),
        [],
        spawn_enemies(dungeon),
        0,
      )
    }
    " ", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.jump(player),
        score: score,
      )
    "w", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.accelerate_y(player, False),
        score: score,
      )
    "s", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.accelerate_y(player, True),
        score: score,
      )
    "a", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.accelerate_x(player, False),
        score: score,
      )
    "d", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.accelerate_x(player, True),
        score: score,
      )
    _, _ -> state
  }
}

fn on_key_released(key: String, _: Int, state: WorldState) -> WorldState {
  case key, state {
    "w", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.stop_y(player),
        score: score,
      )
    "s", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.stop_y(player),
        score: score,
      )
    "a", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.stop_x(player),
        score: score,
      )
    "d", GameRunning(dungeon, player, bullets, enemies, score) ->
      GameRunning(
        dungeon: dungeon,
        bullets: bullets,
        enemies: enemies,
        player: player.stop_x(player),
        score: score,
      )
    _, _ -> state
  }
}

fn on_mouse_clicked(x: Float, y: Float, state: WorldState) -> WorldState {
  case state {
    GameRunning(dungeon, player, bullets, enemies, score) -> {
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
        enemies: enemies,
        player: player.Player(
          ..player,
          last_fire_time: utils.now_in_milliseconds(),
        ),
        score: score,
      )
    }
    _ -> state
  }
}

fn on_tick(state: WorldState) -> WorldState {
  case state {
    GameRunning(dungeon, player, bullets, enemies, score) -> {
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
        player.position.z <=. 0.0
          && dungeon.is_over_pit(dungeon, player.position),
        GameOver(True, score),
      )

      let player = player.update_velocity(player)
      let player = player.apply_gravity(player)
      let player =
        list.fold(dungeon.obstacles, player, fn(player, o) {
          case
            obstacle.collides_with(o, player.position, player.player_size)
            && !player.is_player_invulnerable(player)
          {
            True -> player.apply_damage(player, obstacle.damage)
            False -> player
          }
        })

      let bullets =
        bullets
        |> list.filter(bullet.is_still_alive)

      let #(bullets, player) =
        list.fold(bullets, #([], player), fn(acc, b) {
          use <- bool.guard(
            !dungeon.can_move(
              dungeon,
              b.position,
              bullet.advance_bullet(b).position,
            ),
            acc,
          )
          // If the bullet hits a wall then remove it

          // Check if the bullet collides with something it can hit
          let #(bullets, player) = acc
          let player = case
            !b.belongs_to_player
            && bullet.collides_with(b, player.position, player.player_size)
            && !player.is_player_invulnerable(player)
          {
            True -> player.apply_damage(player, bullet.enemy_damage)
            False -> player
          }

          #([bullet.advance_bullet(b), ..bullets], player)
        })

      use <- bool.guard(player.is_player_dead(player), GameOver(False, score))

      GameRunning(
        dungeon: dungeon,
        player: player,
        bullets: bullets,
        enemies: enemies,
        score: score,
      )
    }
    _ -> state
  }
}

pub fn main() {
  p5js_gleam.create_sketch_with_preloading(
    init: setup,
    draw: draw,
    preload: preload,
  )
  |> p5js_gleam.set_on_key_pressed(on_key_pressed)
  |> p5js_gleam.set_on_key_released(on_key_released)
  |> p5js_gleam.set_on_mouse_clicked(on_mouse_clicked)
  |> p5js_gleam.set_on_tick(on_tick)
  |> p5.start_sketch
}
