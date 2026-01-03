import bullet.{Bullet}
import gleeunit/should.{equal}
import vector.{Vector}

pub fn advance_bullet_test() {
  equal(
    bullet.advance_bullet(Bullet(
      Vector(0.0, 0.0, 0.0),
      Vector(5.0, 0.0, 0.0),
      True,
      0,
    )),
    Bullet(Vector(5.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
  )
}

pub fn collides_with_test() {
  equal(
    bullet.collides_with(
      Bullet(Vector(0.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
      Vector(10.0, 0.0, 0.0),
      1.0,
    ),
    False,
  )
  equal(
    bullet.collides_with(
      Bullet(Vector(0.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
      Vector(0.0, 0.0, 0.0),
      1.0,
    ),
    True,
  )
}
