import gleam/float
import gleam_community/maths/elementary

/// Represents a 3D Vector.
pub type Vector {
  Vector(x: Float, y: Float, z: Float)
}

/// Adds 2 vectors together.
pub fn vector_add(v1: Vector, v2: Vector) -> Vector {
  Vector(v1.x +. v2.x, v1.y +. v2.y, v1.z +. v2.z)
}

/// Subtracts the second vector from the first vector.
pub fn vector_subtract(v1: Vector, v2: Vector) -> Vector {
  Vector(v1.x -. v2.x, v1.y -. v2.y, v1.z -. v2.z)
}

/// Computes the dot product of 2 vectors.
pub fn vector_dot(v1: Vector, v2: Vector) -> Float {
  v1.x *. v2.x +. v1.y *. v2.y +. v1.z *. v2.z
}

/// Computes the cross product of 2 vectors.
pub fn vector_cross(v1: Vector, v2: Vector) -> Vector {
  let yz = v1.y *. v2.z -. v1.z *. v2.y
  let zx = v1.z *. v2.x -. v1.x *. v2.z
  let xy = v1.x *. v2.y -. v1.y *. v2.x
  Vector(yz, zx, xy)
}

/// Multiplies the vector by some value.
pub fn vector_multiply(v: Vector, mult: Float) -> Vector {
  Vector(v.x *. mult, v.y *. mult, v.z *. mult)
}

/// Divides the vector by some value.
pub fn vector_divide(v: Vector, mult: Float) -> Vector {
  Vector(v.x /. mult, v.y /. mult, v.z /. mult)
}

/// Computes the square of the magnitude of the vector.
/// Mainly used for performance when computing square roots is unnecessary.
pub fn vector_magnitude_squared(v: Vector) -> Float {
  v.x *. v.x +. v.y *. v.y +. v.z *. v.z
}

/// Computes the magnitude of the vector.
pub fn vector_magnitude(v: Vector) -> Float {
  // magnitude square is always positive
  let assert Ok(mag) = float.square_root(vector_magnitude_squared(v))
  mag
}

/// Computes a vector of the same heading with a magnitude of 1.
pub fn vector_normalize(v: Vector) -> Vector {
  vector_divide(v, vector_magnitude(v))
}

/// Computes a vector of the same heading with maximum magnitude.
pub fn vector_limit(v: Vector, limit: Float) -> Vector {
  let lim_squared = limit *. limit
  case vector_magnitude_squared(v) {
    m if m <=. lim_squared -> v
    _ -> vector_multiply(vector_normalize(v), limit)
  }
}

/// Computes the distance between 2 vectors.
pub fn vector_distance(v1: Vector, v2: Vector) -> Float {
  vector_magnitude(vector_subtract(v1, v2))
}

/// Creates a 2d version of the vector.
pub fn vector_2d(v: Vector) -> Vector {
  Vector(v.x, v.y, 0.0)
}

/// Computes the heading in radians of a vector.
pub fn vector_heading2d(v: Vector) -> Float {
  let res = elementary.atan2(v.y, v.x)
  case res {
    r if r <. 0.0 -> r +. 2.0 *. elementary.pi()
    _ -> res
  }
}

/// Rotates a vector around the z axis by the given amount in radians.
pub fn vector_rotate2d(v: Vector, rotation: Float) -> Vector {
  let heading = vector_heading2d(v) +. rotation
  let mag = vector_magnitude(vector_2d(v))
  Vector(elementary.cos(heading) *. mag, elementary.sin(heading) *. mag, v.z)
}
