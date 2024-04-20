# bullet_heck_gleam

A [gleam](https://gleam.run/) [rewrite](https://github.com/Acepie/GameAIBulletHell) of a bullet hell style game my friend and I made in college. The goal is mainly for myself to use gleam on a larger/more creative project. Uses [p5js bindings](https://github.com/Acepie/p5js_gleam) for running the project as a web game.

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
