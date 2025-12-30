import gleeunit/should.{equal}
import obstacle.{Obstacle}
import vector.{Vector}

pub fn collides_with_test() {
  equal(
    obstacle.collides_with(
      Obstacle(Vector(0.0, 0.0, 0.0)),
      Vector(10.0, 0.0, 0.0),
      1.0,
    ),
    False,
  )
  equal(
    obstacle.collides_with(
      Obstacle(Vector(0.0, 0.0, 0.0)),
      Vector(0.0, 0.0, 0.0),
      1.0,
    ),
    True,
  )
}
