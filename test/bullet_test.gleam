import bullet.{type Bullet, Bullet}
import startest.{describe, it}
import startest/expect
import vector.{Vector}

pub fn bullet_tests() {
  describe("bullet", [
    it("advance_bullet", fn() {
      expect.to_equal(
        bullet.advance_bullet(Bullet(
          Vector(0.0, 0.0, 0.0),
          Vector(5.0, 0.0, 0.0),
          True,
          0,
        )),
        Bullet(Vector(5.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
      )
    }),
    it("collides_with", fn() {
      expect.to_equal(
        bullet.collides_with(
          Bullet(Vector(0.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
          Vector(10.0, 0.0, 0.0),
          1.0,
        ),
        False,
      )
      expect.to_equal(
        bullet.collides_with(
          Bullet(Vector(0.0, 0.0, 0.0), Vector(5.0, 0.0, 0.0), True, 0),
          Vector(0.0, 0.0, 0.0),
          1.0,
        ),
        True,
      )
    }),
  ])
}
