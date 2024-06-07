import behavior_tree/behavior_tree
import dungeon
import enemy.{type Enemy, Enemy}
import gleam/dict
import player
import room
import startest.{describe, it}
import startest/expect
import utils
import vector.{Vector}

fn dummy_btree(
  i: behavior_tree.BehaviorInput(Enemy, enemy.Inputs),
) -> behavior_tree.BehaviorResult(Enemy, enemy.AdditionalOutputs) {
  let behavior_tree.BehaviorInput(e, _) = i
  behavior_tree.BehaviorResult(True, e, enemy.AdditionalOutputs(bullets: []))
}

pub fn enemy_tests() {
  describe("enemy", [
    it("new_enemy", fn() {
      let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))
      expect.to_equal(enemy.position, Vector(0.0, 0.0, 0.0))
      expect.to_equal(enemy.velocity, Vector(0.0, 0.0, 0.0))
      expect.to_equal(enemy.current_health, 80)
      expect.to_equal(enemy.max_health, 80)
    }),
    it("apply_gravity", fn() {
      let enemy =
        Enemy(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        )
        |> enemy.apply_gravity
      expect.to_equal(enemy.velocity, vector.Vector(0.0, 0.0, 0.98))
      expect.to_equal(enemy.position, vector.Vector(0.0, 0.0, 0.0))
      let enemy =
        Enemy(
          position: Vector(0.0, 0.0, -1.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        )
        |> enemy.apply_gravity
      expect.to_equal(enemy.position, vector.Vector(0.0, 0.0, 0.0))
      expect.to_equal(enemy.velocity, vector.Vector(0.0, 0.0, 0.98))
    }),
    it("apply_damage", fn() {
      let enemy =
        Enemy(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        )
        |> enemy.apply_damage(20)
      expect.to_equal(enemy.current_health, 80)
    }),
    it("is_enemy_dead", fn() {
      expect.to_be_false(
        Enemy(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        )
        |> enemy.is_enemy_dead,
      )
      expect.to_be_true(
        Enemy(
          position: Vector(0.0, 0.0, -1.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 0,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        )
        |> enemy.is_enemy_dead,
      )
    }),
    it("collides_with", fn() {
      expect.to_be_false(enemy.collides_with(
        Enemy(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        ),
        Vector(10.0, 0.0, 0.0),
        1.0,
      ))
      expect.to_be_true(enemy.collides_with(
        Enemy(
          position: Vector(0.0, 0.0, 0.0),
          velocity: vector.Vector(0.0, 0.0, 1.0),
          rotation: 0.0,
          current_health: 100,
          max_health: 100,
          path: [],
          last_path_updated: 0,
          btree: dummy_btree,
        ),
        Vector(0.0, 0.0, 0.0),
        1.0,
      ))
    }),
  ])

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
  let dungeon = dungeon.Dungeon(rooms: rooms, pits: [], obstacles: [])

  describe("enemy behaviors", [
    it("has_path_behavior", fn() {
      let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.has_path_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs([], dungeon, player.new_player(Vector(0.0, 0.0, 0.0))),
        ))
      expect.to_be_false(success)
      expect.to_equal(out_enemy, enemy)

      let enemy = Enemy(..enemy, path: [Vector(0.0, 0.0, 0.0)])

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.has_path_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs([], dungeon, player.new_player(Vector(0.0, 0.0, 0.0))),
        ))
      expect.to_be_true(success)
      expect.to_equal(out_enemy, enemy)
    }),
    it("path_is_stale_behavior", fn() {
      let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.path_is_stale_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs([], dungeon, player.new_player(Vector(0.0, 0.0, 0.0))),
        ))
      expect.to_be_true(success)
      expect.to_equal(out_enemy, enemy)

      let enemy = Enemy(..enemy, last_path_updated: utils.now_in_milliseconds())

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.path_is_stale_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs([], dungeon, player.new_player(Vector(0.0, 0.0, 0.0))),
        ))
      expect.to_be_false(success)
      expect.to_equal(out_enemy, enemy)
    }),
    it("random_path_behavior", fn() {
      let enemy = enemy.new_enemy(Vector(0.0, 0.0, 0.0))

      let behavior_tree.BehaviorResult(success, out_enemy, _) =
        enemy.random_path_behavior(behavior_tree.BehaviorInput(
          enemy,
          enemy.Inputs([], dungeon, player.new_player(Vector(0.0, 0.0, 0.0))),
        ))
      expect.to_be_true(success)
      expect.to_not_equal(out_enemy.path, [])
      expect.to_not_equal(out_enemy.last_path_updated, 0)
    }),
  ])
}
