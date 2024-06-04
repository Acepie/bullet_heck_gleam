import behavior_tree/behavior_tree.{
  type BehaviorTree, BehaviorInput, BehaviorResult,
}
import gleam/list
import startest.{describe, it}
import startest/expect

pub fn behavior_tree_tests() {
  let identity_tree: BehaviorTree(Int, Int, Int) = fn(input) {
    let BehaviorInput(entity, _) = input
    BehaviorResult(True, entity, 0)
  }
  let add_n_tree: BehaviorTree(Int, Int, Int) = fn(input) {
    let BehaviorInput(entity, i) = input
    BehaviorResult(True, entity + i, 0)
  }
  let failing_add_n_tree: BehaviorTree(Int, Int, Int) = fn(input) {
    let BehaviorInput(entity, i) = input
    BehaviorResult(False, entity + i, 0)
  }
  let add_n_and_output_prev_tree: BehaviorTree(Int, Int, List(Int)) = fn(input) {
    let BehaviorInput(entity, i) = input
    BehaviorResult(True, entity + i, [entity])
  }

  describe("behavior_tree", [
    it("not", fn() {
      let BehaviorResult(result, _, _) =
        behavior_tree.not(identity_tree)(BehaviorInput(0, 0))
      expect.to_be_false(result)
      let BehaviorResult(result, _, _) =
        behavior_tree.not(behavior_tree.not(identity_tree))(BehaviorInput(0, 0))
      expect.to_be_true(result)
    }),
    it("true", fn() {
      let BehaviorResult(result, _, _) =
        behavior_tree.not(identity_tree)(BehaviorInput(0, 0))
      expect.to_be_false(result)
      let BehaviorResult(result, _, _) =
        behavior_tree.true(behavior_tree.not(identity_tree))(BehaviorInput(0, 0))
      expect.to_be_true(result)
    }),
    it("selector", fn() {
      let BehaviorResult(result, e, _) =
        behavior_tree.selector(
          [
            failing_add_n_tree,
            failing_add_n_tree,
            failing_add_n_tree,
            identity_tree,
            failing_add_n_tree,
            failing_add_n_tree,
          ],
          1,
          fn(i, _) { i },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 3)

      let BehaviorResult(result, e, _) =
        behavior_tree.selector(
          [failing_add_n_tree, failing_add_n_tree, failing_add_n_tree],
          1,
          fn(i, _) { i },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_false(result)
      expect.to_equal(e, 3)

      let BehaviorResult(result, e, _) =
        behavior_tree.selector(
          [
            behavior_tree.not(add_n_and_output_prev_tree),
            behavior_tree.not(add_n_and_output_prev_tree),
            behavior_tree.not(add_n_and_output_prev_tree),
            add_n_and_output_prev_tree,
          ],
          [],
          fn(i, a) {
            let assert Ok(a) = list.first(a)
            i + a
          },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 8)
    }),
    it("sequence", fn() {
      let BehaviorResult(result, e, _) =
        behavior_tree.sequence(
          [add_n_tree, failing_add_n_tree, add_n_tree, identity_tree],
          1,
          fn(i, _) { i },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_false(result)
      expect.to_equal(e, 2)

      let BehaviorResult(result, e, _) =
        behavior_tree.sequence(
          [add_n_tree, add_n_tree, add_n_tree, identity_tree],
          1,
          fn(i, _) { i },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 3)

      let BehaviorResult(result, e, a) =
        behavior_tree.sequence(
          [
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
          ],
          [],
          fn(i, a) {
            let assert Ok(a) = list.first(a)
            i + a
          },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 8)
      expect.to_equal(a, [])

      let BehaviorResult(result, e, a) =
        behavior_tree.sequence(
          [
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
          ],
          [],
          fn(i, _) { i },
          list.append,
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 4)
      expect.to_equal(a, [0, 1, 2, 3])
    }),
    it("all", fn() {
      let BehaviorResult(result, e, _) =
        behavior_tree.all(
          [add_n_tree, failing_add_n_tree, add_n_tree, identity_tree],
          1,
          fn(i, _) { i },
          fn(_, o) { o },
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 3)

      let BehaviorResult(result, e, a) =
        behavior_tree.all(
          [
            add_n_and_output_prev_tree,
            behavior_tree.not(add_n_and_output_prev_tree),
            add_n_and_output_prev_tree,
            add_n_and_output_prev_tree,
          ],
          [],
          fn(i, _) { i },
          list.append,
        )(BehaviorInput(0, 1))
      expect.to_be_true(result)
      expect.to_equal(e, 4)
      expect.to_equal(a, [0, 1, 2, 3])
    }),
  ])
}
