import gleam/float
import gleam_community/maths/elementary

/// Represents a 3D Vector.
pub type Vector {
  Vector(x: Float, y: Float, z: Float)
}

/// Adds 2 vectors together.
pub fn add(v1: Vector, v2: Vector) -> Vector {
  Vector(v1.x +. v2.x, v1.y +. v2.y, v1.z +. v2.z)
}

/// Subtracts the second vector from the first vector.
pub fn subtract(v1: Vector, v2: Vector) -> Vector {
  Vector(v1.x -. v2.x, v1.y -. v2.y, v1.z -. v2.z)
}

/// Computes the dot product of 2 vectors.
pub fn dot(v1: Vector, v2: Vector) -> Float {
  v1.x *. v2.x +. v1.y *. v2.y +. v1.z *. v2.z
}

/// Computes the cross product of 2 vectors.
pub fn cross(v1: Vector, v2: Vector) -> Vector {
  let yz = v1.y *. v2.z -. v1.z *. v2.y
  let zx = v1.z *. v2.x -. v1.x *. v2.z
  let xy = v1.x *. v2.y -. v1.y *. v2.x
  Vector(yz, zx, xy)
}

/// Multiplies the vector by some value.
pub fn multiply(v: Vector, mult: Float) -> Vector {
  Vector(v.x *. mult, v.y *. mult, v.z *. mult)
}

/// Divides the vector by some value.
pub fn divide(v: Vector, mult: Float) -> Vector {
  Vector(v.x /. mult, v.y /. mult, v.z /. mult)
}

/// Computes the square of the magnitude of the vector.
/// Mainly used for performance when computing square roots is unnecessary.
pub fn magnitude_squared(v: Vector) -> Float {
  v.x *. v.x +. v.y *. v.y +. v.z *. v.z
}

/// Computes the magnitude of the vector.
pub fn magnitude(v: Vector) -> Float {
  // magnitude square is always positive
  let assert Ok(mag) = float.square_root(magnitude_squared(v))
  mag
}

/// Computes a vector of the same heading with a magnitude of 1.
pub fn normalize(v: Vector) -> Vector {
  divide(v, magnitude(v))
}

/// Computes a vector of the same heading with maximum magnitude.
pub fn limit(v: Vector, limit: Float) -> Vector {
  let lim_squared = limit *. limit
  case magnitude_squared(v) {
    m if m <=. lim_squared -> v
    _ -> multiply(normalize(v), limit)
  }
}

/// Computes the distance between 2 vectors.
pub fn distance(v1: Vector, v2: Vector) -> Float {
  magnitude(subtract(v1, v2))
}

/// Creates a 2d version of the vector.
pub fn vector_2d(v: Vector) -> Vector {
  Vector(v.x, v.y, 0.0)
}

/// Computes the heading in radians of a vector.
pub fn heading2d(v: Vector) -> Float {
  let res = elementary.atan2(v.y, v.x)
  case res {
    r if r <. 0.0 -> r +. 2.0 *. elementary.pi()
    _ -> res
  }
}

/// Rotates a vector around the z axis by the given amount in radians.
pub fn rotate2d(v: Vector, rotation: Float) -> Vector {
  let heading = heading2d(v) +. rotation
  let mag = magnitude(vector_2d(v))
  Vector(elementary.cos(heading) *. mag, elementary.sin(heading) *. mag, v.z)
}

/// Create a vector around the z axis by the given amount in radians.
pub fn from_angle2d(rotation: Float) -> Vector {
  rotate2d(Vector(1.0, 0.0, 0.0), rotation)
}
