import gleam/float
import gleam/string
import gleam_community/maths/elementary
import startest.{describe, it}
import startest/assertion_error.{AssertionError}
import startest/expect
import vector.{type Vector, Vector}

const precision = 0.000001

fn approximate_vector_equal(v1: Vector, v2: Vector) {
  let x = float.loosely_equals(v1.x, v2.x, precision)
  let y = float.loosely_equals(v1.y, v2.y, precision)
  let z = float.loosely_equals(v1.z, v2.z, precision)

  case x, y, z {
    True, True, True -> Nil
    _, _, _ ->
      AssertionError(
        string.concat([
          "Expected vector ",
          string.inspect(v1),
          " to be approximately equal to ",
          string.inspect(v2),
        ]),
        string.inspect(v1),
        string.inspect(v2),
      )
      |> assertion_error.raise
  }
}

pub fn vector_tests() {
  describe("vector", [
    it("vector_add_test", fn() {
      expect.to_equal(
        vector.vector_add(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)),
        Vector(5.0, 7.0, 9.0),
      )
    }),
    it("vector_subtract_test", fn() {
      expect.to_equal(
        vector.vector_subtract(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)),
        Vector(-3.0, -3.0, -3.0),
      )
    }),
    it("vector_dot_test", fn() {
      expect.to_equal(
        vector.vector_dot(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)),
        32.0,
      )
    }),
    it("vector_cross_test", fn() {
      expect.to_equal(
        vector.vector_cross(Vector(1.0, 2.0, 3.0), Vector(2.0, -1.0, 0.0)),
        Vector(3.0, 6.0, -5.0),
      )
    }),
    it("vector_multiply_test", fn() {
      expect.to_equal(
        vector.vector_multiply(Vector(1.0, 2.0, 3.0), 2.0),
        Vector(2.0, 4.0, 6.0),
      )
    }),
    it("vector_divide_test", fn() {
      expect.to_equal(
        vector.vector_divide(Vector(2.0, 4.0, 6.0), 2.0),
        Vector(1.0, 2.0, 3.0),
      )
    }),
    it("vector_mag_squared_test", fn() {
      expect.to_equal(
        vector.vector_magnitude_squared(Vector(1.0, 2.0, 3.0)),
        14.0,
      )
    }),
    it("vector_mag_test", fn() {
      expect.to_equal(vector.vector_magnitude(Vector(3.0, 4.0, 0.0)), 5.0)
    }),
    it("vector_normalize_test", fn() {
      expect.to_equal(
        vector.vector_normalize(Vector(3.0, 4.0, 0.0)),
        Vector(0.6, 0.8, 0.0),
      )
    }),
    it("vector_limit_test", fn() {
      expect.to_equal(
        vector.vector_limit(Vector(3.0, 4.0, 0.0), 6.0),
        Vector(3.0, 4.0, 0.0),
      )
      expect.to_equal(
        vector.vector_limit(Vector(3.0, 4.0, 0.0), 1.0),
        Vector(0.6, 0.8, 0.0),
      )
    }),
    it("vector_distance_test", fn() {
      expect.to_equal(
        vector.vector_distance(Vector(1.0, 2.0, 3.0), Vector(4.0, 2.0, 7.0)),
        5.0,
      )
    }),
    it("vector_heading2d_test", fn() {
      expect.to_equal(
        vector.vector_heading2d(Vector(0.0, 1.0, 0.0)),
        elementary.pi() /. 2.0,
      )
      expect.to_equal(vector.vector_heading2d(Vector(1.0, 0.0, 0.0)), 0.0)
      expect.to_equal(
        vector.vector_heading2d(Vector(0.0, -1.0, 0.0)),
        elementary.pi() *. 1.5,
      )
      expect.to_equal(
        vector.vector_heading2d(Vector(-1.0, 0.0, 0.0)),
        elementary.pi(),
      )
    }),
    it("vector_rotate2d_test", fn() {
      approximate_vector_equal(
        vector.vector_rotate2d(Vector(0.0, 1.0, 0.0), elementary.pi()),
        Vector(0.0, -1.0, 0.0),
      )
      approximate_vector_equal(
        vector.vector_rotate2d(Vector(1.0, 0.0, 0.0), elementary.pi() /. 2.0),
        Vector(0.0, 1.0, 0.0),
      )
    }),
  ])
}
