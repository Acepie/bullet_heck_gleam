import gleeunit/should.{be_false, be_true, equal, not_equal}
import player.{Player}
import vector.{Vector}

pub fn new_player_test() {
  equal(
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
}

pub fn move_test() {
  equal(
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
}

pub fn update_velocity_test() {
  equal(
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
  equal(
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
}

pub fn jump_test() {
  equal(
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
  equal(
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
}

pub fn accelerate_x_test() {
  equal(
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
  equal(
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
}

pub fn accelerate_y_test() {
  equal(
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
  equal(
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
}

pub fn stop_x_test() {
  equal(
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
}

pub fn stop_y_test() {
  equal(
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
}

pub fn apply_gravity_test() {
  equal(
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
  equal(
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
}

pub fn apply_damage_test() {
  let player =
    Player(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      acceleration: vector.Vector(0.0, 0.0, 0.0),
      last_fire_time: 0,
      last_hit_time: 0,
      current_health: 100,
      max_health: 100,
    )
    |> player.apply_damage(20)
  equal(player.current_health, 80)
  not_equal(player.last_hit_time, 0)
}

pub fn is_player_dead_test() {
  be_false(
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
  be_true(
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
}
