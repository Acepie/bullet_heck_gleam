import player.{type Player, Player}
import startest.{describe, it}
import startest/expect
import vector.{Vector}

pub fn player_tests() {
  describe("player", [
    it("new_player", fn() {
      expect.to_equal(
        player.new_player(Vector(0.0, 0.0, 0.0)),
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("move", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(1.0, 2.0, 3.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.move,
        Player(
          position: Vector(1.0, 2.0, 3.0),
          velocity: vector.Vector(1.0, 2.0, 3.0),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("update_velocity", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(1.0, 1.0, 1.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.update_velocity,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(1.0, 1.0, 1.0),
          acceleration: vector.Vector(1.0, 1.0, 1.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(5.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.update_velocity,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(4.0, 0.0, 0.0),
          acceleration: vector.Vector(5.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("jump", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.jump,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.2),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 1.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.jump,
        Player(
          position: Vector(0.0, 0.0, 1.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("accelerate_x", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.accelerate_x(True),
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(2.0 /. 3.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.accelerate_x(False),
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(-2.0 /. 3.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("accelerate_y", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.accelerate_y(True),
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(0.0, 2.0 /. 3.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 0.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.accelerate_y(False),
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.0),
          acceleration: vector.Vector(0.0, -2.0 /. 3.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("stop_x", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(1.0, 1.0, 0.0),
            acceleration: vector.Vector(1.0, 1.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.stop_x,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 1.0, 0.0),
          acceleration: vector.Vector(0.0, 1.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("stop_y", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(1.0, 1.0, 0.0),
            acceleration: vector.Vector(1.0, 1.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.stop_y,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(1.0, 0.0, 0.0),
          acceleration: vector.Vector(1.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("apply_gravity", fn() {
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, 0.0),
            velocity: vector.Vector(0.0, 0.0, 1.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.apply_gravity,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.98),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
      expect.to_equal(
        Player(
            position: Vector(0.0, 0.0, -1.0),
            velocity: vector.Vector(0.0, 0.0, 1.0),
            acceleration: vector.Vector(0.0, 0.0, 0.0),
            last_fire_time: 0,
            last_hit_time: 0,
            current_health: 100,
            max_health: 100,
          )
          |> player.apply_gravity,
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 0.98),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        ),
      )
    }),
    it("is_player_dead", fn() {
      expect.to_be_false(
        Player(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 100,
          max_health: 100,
        )
        |> player.is_player_dead,
      )
      expect.to_be_true(
        Player(
          position: Vector(0.0, 0.0, -1.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          acceleration: vector.Vector(0.0, 0.0, 0.0),
          last_fire_time: 0,
          last_hit_time: 0,
          current_health: 0,
          max_health: 100,
        )
        |> player.is_player_dead,
      )
    }),
  ])
}
