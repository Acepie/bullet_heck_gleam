import behavior_tree/behavior_tree
import dungeon
import enemy.{type Enemy, Enemy}
import gleam/dict
import gleam/yielder
import gleeunit/should.{be_false, be_true, equal, not_equal}
import player
import room
import utils
import vector.{Vector}

fn dummy_btree(
  i: behavior_tree.BehaviorInput(Enemy, enemy.Inputs),
) -> behavior_tree.BehaviorResult(Enemy, enemy.AdditionalOutputs) {
  let behavior_tree.BehaviorInput(e, _) = i
  behavior_tree.BehaviorResult(True, e, enemy.AdditionalOutputs(bullets: []))
}

pub fn new_enemy_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))
  equal(enemy.position, Vector(0.0, 0.0, 0.0))
  equal(enemy.velocity, Vector(0.0, 0.0, 0.0))
  equal(enemy.current_health, 80)
  equal(enemy.max_health, 80)
}

pub fn apply_gravity_test() {
  let enemy =
    Enemy(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    )
    |> enemy.apply_gravity
  equal(enemy.velocity, vector.Vector(0.0, 0.0, 0.98))
  equal(enemy.position, vector.Vector(0.0, 0.0, 0.0))
  let enemy =
    Enemy(
      position: Vector(0.0, 0.0, -1.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    )
    |> enemy.apply_gravity
  equal(enemy.position, vector.Vector(0.0, 0.0, 0.0))
  equal(enemy.velocity, vector.Vector(0.0, 0.0, 0.98))
}

pub fn apply_damage_test() {
  let enemy =
    Enemy(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    )
    |> enemy.apply_damage(20)
  equal(enemy.current_health, 80)
}

pub fn us_enemy_dead_test() {
  be_false(
    Enemy(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    )
    |> enemy.is_enemy_dead,
  )
  be_true(
    Enemy(
      position: Vector(0.0, 0.0, -1.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 0,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    )
    |> enemy.is_enemy_dead,
  )
}

pub fn collides_with_test() {
  be_false(enemy.collides_with(
    Enemy(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    ),
    Vector(10.0, 0.0, 0.0),
    1.0,
  ))
  be_true(enemy.collides_with(
    Enemy(
      position: Vector(0.0, 0.0, 0.0),
      velocity: vector.Vector(0.0, 0.0, 1.0),
      rotation: 0.0,
      rotational_velocity: 0.0,
      current_health: 100,
      max_health: 100,
      path: [],
      last_path_updated: 0,
      spotted_player: False,
      last_bullet_fired: 0,
      btree: dummy_btree,
    ),
    Vector(0.0, 0.0, 0.0),
    1.0,
  ))
}

fn mock_dungeon() {
  // Creating a mock dungeon for tests.
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
    |> dict.insert(
      #(4, 1),
      room.initialize_unbounded_room()
        |> room.set_navigable(room.Bottom, True)
        |> room.set_navigable(room.Right, True),
    )
    |> dict.insert(
      #(4, 2),
      room.initialize_unbounded_room()
        |> room.set_navigable(room.Top, True),
    )
    |> dict.insert(
      #(5, 1),
      room.initialize_unbounded_room()
        |> room.set_navigable(room.Left, True)
        |> room.set_navigable(room.Right, True),
    )
    |> dict.insert(
      #(6, 1),
      room.initialize_unbounded_room()
        |> room.set_navigable(room.Left, True)
        |> room.set_navigable(room.Bottom, True),
    )
    |> dict.insert(
      #(6, 2),
      room.initialize_unbounded_room()
        |> room.set_navigable(room.Left, True)
        |> room.set_navigable(room.Top, True),
    )
  dungeon.Dungeon(rooms: rooms, pits: [], obstacles: [])
}

pub fn has_path_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.has_path_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_false(success)
  equal(out_enemy, enemy)

  let enemy = Enemy(..enemy, path: [Vector(0.0, 0.0, 0.0)])

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.has_path_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy, enemy)
}

pub fn path_is_stale_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.path_is_stale_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy, enemy)

  let enemy = Enemy(..enemy, last_path_updated: utils.now_in_milliseconds())

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.path_is_stale_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_false(success)
  equal(out_enemy, enemy)
}

pub fn random_path_behavior_test() {
  // This enemy can only go up so their target will always be up
  let enemy = enemy.new_enemy(Vector(250.0, 150.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.random_path_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy.path, [Vector(250.0, 250.0, 0.0)])
  not_equal(out_enemy.last_path_updated, 0)

  let _ =
    {
      use <- yielder.repeatedly
      // This enemy can go multiple different directions
      let enemy = enemy.new_enemy(Vector(450.0, 150.0, 0.0))

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.random_path_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs(
            [],
            mock_dungeon(),
            player.new_player(Vector(0.0, 0.0, 0.0)),
          ),
        ))
      be_true(success)
      not_equal(out_enemy.path, [])
      not_equal(out_enemy.last_path_updated, 0)
    }
    |> yielder.take(10)

  Nil
}

pub fn in_range_of_player_behavior_test() {
  let enemy = enemy.new_enemy(Vector(150.0, 150.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_range_of_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(150.0, 150.0, 0.0)),
      ),
    ))
  be_true(success)
  equal(out_enemy, enemy)

  let enemy = enemy.new_enemy(Vector(110.0, 150.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_range_of_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(190.0, 150.0, 0.0)),
      ),
    ))
  be_false(success)
  equal(out_enemy, enemy)

  let enemy = enemy.new_enemy(Vector(250.0, 190.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_range_of_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(250.0, 210.0, 0.0)),
      ),
    ))
  be_true(success)
  equal(out_enemy, enemy)

  let enemy = enemy.new_enemy(Vector(150.0, 190.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_range_of_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(150.0, 210.0, 0.0)),
      ),
    ))
  be_false(success)
  equal(out_enemy, enemy)
}

pub fn spot_player_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.spot_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  be_true(out_enemy.spotted_player)
}

pub fn spotted_player_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.spotted_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_false(success)
  equal(out_enemy, enemy)

  let enemy = Enemy(..enemy, spotted_player: True)

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.spotted_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy, enemy)
}

pub fn path_player_behavior_test() {
  let enemy = enemy.new_enemy(Vector(150.0, 150.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.path_to_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(150.0, 150.0, 0.0)),
      ),
    ))
  be_true(success)
  equal(out_enemy.path, enemy.path)

  let enemy = enemy.new_enemy(Vector(450.0, 250.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.path_to_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(650.0, 250.0, 0.0)),
      ),
    ))
  be_true(success)
  equal(out_enemy.path, [
    Vector(450.0, 150.0, 0.0),
    Vector(550.0, 150.0, 0.0),
    Vector(650.0, 150.0, 0.0),
  ])
}

pub fn in_air_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_air_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_false(success)
  equal(out_enemy, enemy)

  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 1.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.in_air_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(0.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy, enemy)
}

pub fn move_in_air_behavior_test() {
  let enemy = enemy.new_enemy(Vector(250.0, 150.0, 10.0))
  let enemy = Enemy(..enemy, velocity: Vector(0.0, 100.0, -1.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.move_in_air_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs(
        [],
        mock_dungeon(),
        player.new_player(Vector(150.0, 150.0, 0.0)),
      ),
    ))
  be_true(success)
  equal(out_enemy, Enemy(..enemy, position: Vector(250.0, 250.0, 9.0)))

  let behavior_tree.BehaviorResult(success, out_enemy2, _) =
    enemy.move_in_air_behavior(behavior_tree.BehaviorInput(
      out_enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(150.0, 150.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy2, Enemy(..enemy, position: Vector(250.0, 250.0, 8.0)))
}

pub fn is_facing_player_behavior_test() {
  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.is_facing_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(30.0, 0.0, 0.0))),
    ))
  be_true(success)
  equal(out_enemy, enemy)

  let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

  let behavior_tree.BehaviorResult(success, out_enemy, _) =
    enemy.is_facing_player_behavior(behavior_tree.BehaviorInput(
      enemy,
      enemy.Inputs([], mock_dungeon(), player.new_player(Vector(30.0, 30.0, 0.0))),
    ))
  be_false(success)
  equal(out_enemy, enemy)
}
