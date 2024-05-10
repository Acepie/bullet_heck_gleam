import obstacle.{type Obstacle, Obstacle}
import startest.{describe, it}
import startest/expect
import vector.{Vector}

pub fn obstacle_tests() {
  describe("obstacle", [
    it("collides_with", fn() {
      expect.to_equal(
        obstacle.collides_with(
          Obstacle(Vector(0.0, 0.0, 0.0)),
          Vector(10.0, 0.0, 0.0),
          1.0,
        ),
        False,
      )
      expect.to_equal(
        obstacle.collides_with(
          Obstacle(Vector(0.0, 0.0, 0.0)),
          Vector(0.0, 0.0, 0.0),
          1.0,
        ),
        True,
      )
    }),
  ])
}
