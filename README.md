# bullet_heck_gleam

A [gleam](https://gleam.run/) [rewrite](https://github.com/Acepie/GameAIBulletHell) of a bullet hell style game my friend and I made in college. The goal is mainly for myself to use gleam on a larger/more creative project. Uses [p5js bindings](https://github.com/Acepie/p5js_gleam) for running the project as a web game.

![Screenshot 2024-06-07 104207](https://github.com/Acepie/bullet_heck_gleam/assets/5996838/a7da1f31-9264-4038-8678-54a439b53b49)

![Screenshot 2024-06-07 104215](https://github.com/Acepie/bullet_heck_gleam/assets/5996838/eacdd48e-c28f-4f5b-9f52-d9d074f366c8)

## How To Play

### Controls

- Use the arrow keys or WASD to move
- Press "space" to jump
- Press "shift" or hold down the mouse button to fire bullets
- Press "R" to restart

## Features

- Levels are procedurally generated
- Enemies use A\* to find their way toward the player
- Enemies avoid walls, pits, obstacles, and each other
- Enemies jump over pits when convenient and possible based on current velocity
- Enemy behaviors utilize behavior trees (patrolling until they spot the player, then chasing the player, and firing if within range)
- The player can jump over pits and enemies, but not over obstacles
- Pits instantly kill the player
- After getting hit, the player and enemies are briefly invulnerable to avoid continuous damage
- If the player kills all enemies in a room, they will be spawned in the next randomly-generated room

## Development

This project is using [esgleam](https://hexdocs.pm/esgleam/) for bundling the project into a web page.

```sh
gleam run -m esgleam/bundle
```

This works really nicely with [watchexec](https://github.com/watchexec/watchexec) for local dev

Terminal 1:

```sh
watchexec -e gleam gleam run -m esgleam/bundle
```

Terminal 2:

```sh
gleam run -m esgleam/serve
```
