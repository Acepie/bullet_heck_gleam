import gleam/float
import gleam/string
import gleam_community/maths
import gleeunit/should.{equal}

import vector.{type Vector, Vector}

const precision = 0.000001

fn approximate_vector_equal(v1: Vector, v2: Vector) {
  let x = float.loosely_equals(v1.x, v2.x, precision)
  let y = float.loosely_equals(v1.y, v2.y, precision)
  let z = float.loosely_equals(v1.z, v2.z, precision)

  case x, y, z {
    True, True, True -> Nil
    _, _, _ ->
      panic as string.concat([
          "Expected vector ",
          string.inspect(v1),
          " to be approximately equal to ",
          string.inspect(v2),
        ])
  }
}

pub fn add_test() {
  equal(
    vector.add(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)),
    Vector(5.0, 7.0, 9.0),
  )
}

pub fn subtract_test() {
  equal(
    vector.subtract(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)),
    Vector(-3.0, -3.0, -3.0),
  )
}

pub fn dot_test() {
  equal(vector.dot(Vector(1.0, 2.0, 3.0), Vector(4.0, 5.0, 6.0)), 32.0)
}

pub fn cross_test() {
  equal(
    vector.cross(Vector(1.0, 2.0, 3.0), Vector(2.0, -1.0, 0.0)),
    Vector(3.0, 6.0, -5.0),
  )
}

pub fn multiply_test() {
  equal(vector.multiply(Vector(1.0, 2.0, 3.0), 2.0), Vector(2.0, 4.0, 6.0))
}

pub fn divide_test() {
  equal(vector.divide(Vector(2.0, 4.0, 6.0), 2.0), Vector(1.0, 2.0, 3.0))
}

pub fn vector_mag_squared_test() {
  equal(vector.magnitude_squared(Vector(1.0, 2.0, 3.0)), 14.0)
}

pub fn vector_mag_test() {
  equal(vector.magnitude(Vector(3.0, 4.0, 0.0)), 5.0)
}

pub fn normalize_test() {
  equal(vector.normalize(Vector(3.0, 4.0, 0.0)), Vector(0.6, 0.8, 0.0))
}

pub fn limit_test() {
  equal(vector.limit(Vector(3.0, 4.0, 0.0), 6.0), Vector(3.0, 4.0, 0.0))
  equal(vector.limit(Vector(3.0, 4.0, 0.0), 1.0), Vector(0.6, 0.8, 0.0))
}

pub fn distance_test() {
  equal(vector.distance(Vector(1.0, 2.0, 3.0), Vector(4.0, 2.0, 7.0)), 5.0)
}

pub fn heading2d_test() {
  equal(vector.heading2d(Vector(0.0, 1.0, 0.0)), maths.pi() /. 2.0)
  equal(vector.heading2d(Vector(1.0, 0.0, 0.0)), 0.0)
  equal(vector.heading2d(Vector(0.0, -1.0, 0.0)), maths.pi() *. 1.5)
  equal(vector.heading2d(Vector(-1.0, 0.0, 0.0)), maths.pi())
}

pub fn rotate2d_test() {
  approximate_vector_equal(
    vector.rotate2d(Vector(0.0, 1.0, 0.0), maths.pi()),
    Vector(0.0, -1.0, 0.0),
  )
  approximate_vector_equal(
    vector.rotate2d(Vector(1.0, 0.0, 0.0), maths.pi() /. 2.0),
    Vector(0.0, 1.0, 0.0),
  )
}

pub fn from_angle2d_test() {
  approximate_vector_equal(vector.from_angle2d(0.0), Vector(1.0, 0.0, 0.0))
  approximate_vector_equal(
    vector.from_angle2d(maths.pi()),
    Vector(-1.0, 0.0, 0.0),
  )
  approximate_vector_equal(
    vector.from_angle2d(maths.pi() /. 2.0),
    Vector(0.0, 1.0, 0.0),
  )
}
