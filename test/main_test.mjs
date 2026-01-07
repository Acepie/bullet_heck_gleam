import { vi, test } from 'vitest';
import { main } from "./bullet_heck_gleam_test.gleam";

vi.spyOn(process, "exit").mockImplementation(() => { })
test("Test Runner", async () => {
  await main();
})
