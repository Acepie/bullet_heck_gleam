import behavior_tree/behavior_tree.{BehaviorInput, BehaviorResult}
import gleam/list
import gleeunit/should.{be_false, be_true, equal}

fn identity_tree(input) {
  let BehaviorInput(entity, _) = input
  BehaviorResult(True, entity, 0)
}

fn add_n_tree(input) {
  let BehaviorInput(entity, i) = input
  BehaviorResult(True, entity + i, 0)
}

fn failing_add_n_tree(input) {
  let BehaviorInput(entity, i) = input
  BehaviorResult(False, entity + i, 0)
}

fn add_n_and_output_prev_tree(input) {
  let BehaviorInput(entity, i) = input
  BehaviorResult(True, entity + i, [entity])
}

pub fn not_test() {
  let BehaviorResult(result, _, _) =
    behavior_tree.not(identity_tree)(BehaviorInput(0, 0))
  be_false(result)
  let BehaviorResult(result, _, _) =
    behavior_tree.not(behavior_tree.not(identity_tree))(BehaviorInput(0, 0))
  be_true(result)
}

pub fn true_test() {
  let BehaviorResult(result, _, _) =
    behavior_tree.not(identity_tree)(BehaviorInput(0, 0))
  be_false(result)
  let BehaviorResult(result, _, _) =
    behavior_tree.true(behavior_tree.not(identity_tree))(BehaviorInput(0, 0))
  be_true(result)
}

pub fn selector_test() {
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
  be_true(result)
  equal(e, 3)

  let BehaviorResult(result, e, _) =
    behavior_tree.selector(
      [failing_add_n_tree, failing_add_n_tree, failing_add_n_tree],
      1,
      fn(i, _) { i },
      fn(_, o) { o },
    )(BehaviorInput(0, 1))
  be_false(result)
  equal(e, 3)

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
  be_true(result)
  equal(e, 8)
}

pub fn sequence_test() {
  let BehaviorResult(result, e, _) =
    behavior_tree.sequence(
      [add_n_tree, failing_add_n_tree, add_n_tree, identity_tree],
      1,
      fn(i, _) { i },
      fn(_, o) { o },
    )(BehaviorInput(0, 1))
  be_false(result)
  equal(e, 2)

  let BehaviorResult(result, e, _) =
    behavior_tree.sequence(
      [add_n_tree, add_n_tree, add_n_tree, identity_tree],
      1,
      fn(i, _) { i },
      fn(_, o) { o },
    )(BehaviorInput(0, 1))
  be_true(result)
  equal(e, 3)

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
  be_true(result)
  equal(e, 8)
  equal(a, [])

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
  be_true(result)
  equal(e, 4)
  equal(a, [0, 1, 2, 3])
}

pub fn all_test() {
  let BehaviorResult(result, e, _) =
    behavior_tree.all(
      [add_n_tree, failing_add_n_tree, add_n_tree, identity_tree],
      1,
      fn(i, _) { i },
      fn(_, o) { o },
    )(BehaviorInput(0, 1))
  be_true(result)
  equal(e, 3)

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
  be_true(result)
  equal(e, 4)
  equal(a, [0, 1, 2, 3])
}
