import { spawn, plugin, file } from "bun";
import { join, dirname } from "node:path";
import { existsSync } from "node:fs";

console.log("Compiling gleam");
const build = spawn({
  cmd: ["gleam", "build"],
});

const baseDirectory = import.meta.dir.split("/");
baseDirectory.pop(); // pop /dev from end
const rootDirName = baseDirectory[baseDirectory.length - 1];
const rootDir = baseDirectory.join("/");
const srcDir = `${rootDir}/src`;
const testDir = `${rootDir}/test`;
const gleamOutputPath = `${rootDir}/build/dev/javascript/${rootDirName}`;

function outputGleamLocation(inputSourcePath: string) {
  return inputSourcePath
    .replace(srcDir, gleamOutputPath)
    .replace(testDir, gleamOutputPath)
    .replace(".gleam", ".mjs");
}

function sourceGleamLocation(outputPath: string) {
  if (outputPath.endsWith("_test.mjs")) {
    return outputPath
      .replace(gleamOutputPath, testDir)
      .replace(".mjs", ".gleam");
  } else {
    return outputPath
      .replace(gleamOutputPath, srcDir)
      .replace(".mjs", ".gleam");
  }
}

await build.exited;
if (build.exitCode != 0) {
  console.log("Compilation failed with code", build.exitCode);
  throw new Error(
    "Gleam failed to compile! Fix gleam errors before running the tests",
  );
} else {
  console.log("Compilation completed");
}

plugin({
  name: "Gleam Resolver",
  setup(builder) {
    builder
      .onLoad({ filter: /\.gleam$/ }, async ({ path }) => {
        const outputPath = outputGleamLocation(path);
        const fileContent = await file(outputPath).text();
        return {
          contents: fileContent,
          loader: "js",
        };
      })
      .onResolve({ filter: /\.mjs$/ }, ({ path, importer }) => {
        if (importer.endsWith(".gleam")) {
          if (path.startsWith(rootDir)) {
            return;
          }
          const fileToFind = join(dirname(outputGleamLocation(importer)), path);
          const gleamSource = sourceGleamLocation(fileToFind);
          if (existsSync(gleamSource)) {
            return {
              path: gleamSource,
            };
          } else {
            return {
              path: fileToFind,
            };
          }
        }
      });
  },
});
