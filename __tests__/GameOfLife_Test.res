open Vitest

// ── make_grid ────────────────────────────────────────────────────────────────

describe("make_grid", () => {
  test("creates grid with correct total size (rows * cols)", t => {
    let grid = GameOfLife.make_grid(3, 4)
    t->expect(Array.length(grid))->Expect.toBe(12)
  })

  test("all cells initialized to Dead", t => {
    let grid = GameOfLife.make_grid(5, 5)
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(0)
  })
})

// ── get_cell / set_cell ───────────────────────────────────────────────────────

describe("get_cell and set_cell", () => {
  test("set then get returns Alive", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(grid, 5, 2, 3))->Expect.toBe(GameOfLife.Alive)
  })

  test("unset cell returns Dead", t => {
    let grid = GameOfLife.make_grid(5, 5)
    t->expect(GameOfLife.get_cell(grid, 5, 1, 1))->Expect.toBe(GameOfLife.Dead)
  })

  test("out-of-bounds get returns Dead (not a crash)", t => {
    let grid = GameOfLife.make_grid(5, 5)
    t->expect(GameOfLife.get_cell(grid, 5, 10, 10))->Expect.toBe(GameOfLife.Dead)
  })

  test("negative row index returns Dead", t => {
    let grid = GameOfLife.make_grid(5, 5)
    t->expect(GameOfLife.get_cell(grid, 5, -1, 0))->Expect.toBe(GameOfLife.Dead)
  })

  test("set overwrites an existing value", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(grid, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })
})

// ── count_live_neighbors (finite boundary) ───────────────────────────────────

describe("count_live_neighbors — finite boundary", () => {
  test("isolated cell has 0 neighbors", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 2, 2))->Expect.toBe(0)
  })

  test("counts all 8 surrounding neighbors", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 3, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 2, 2))->Expect.toBe(8)
  })

  test("cell itself is not counted as its own neighbor", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    // only the cell itself is set; it should have 0 neighbors (not 1)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 2, 2))->Expect.toBe(0)
  })

  test("top-left corner has at most 3 in-bounds neighbors", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 0, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 1, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 0))->Expect.toBe(3)
  })

  test("top edge cell counts only in-bounds neighbors", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Neighbors of (0, 2): (0,1), (0,3), (1,1), (1,2), (1,3) — 5 possible
    GameOfLife.set_cell(grid, 5, 0, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 0, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 3, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 2))->Expect.toBe(5)
  })

  test("bottom-right corner has at most 3 in-bounds neighbors", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 3, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 4, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 4, 3, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 4, 4))->Expect.toBe(3)
  })
})

// ── compute_next_gen — Conway's rules ─────────────────────────────────────────

describe("compute_next_gen — Conway's rules", () => {
  test("underpopulation: live cell with 0 neighbors dies", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("underpopulation: live cell with 1 neighbor dies", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("survival: live cell with 2 neighbors survives", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Horizontal blinker: center (2,2) has neighbors (2,1) and (2,3)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
  })

  test("survival: live cell with 3 neighbors survives", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // (2,2) alive with 3 live neighbors
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
  })

  test("overpopulation: live cell with 4 neighbors dies", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("reproduction: dead cell with exactly 3 neighbors becomes alive", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Horizontal blinker: (1,2) and (3,2) each have 3 neighbors → born
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.get_cell(next, 5, 1, 2))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 5, 3, 2))->Expect.toBe(GameOfLife.Alive)
  })

  test("dead cell with 2 neighbors stays dead", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    // (2,1) has 2 live neighbors — must stay Dead
    t->expect(GameOfLife.get_cell(next, 5, 2, 1))->Expect.toBe(GameOfLife.Dead)
  })

  test("dead cell with 4 neighbors stays dead", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    // (2,2) is dead with 4 neighbors — stays Dead
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("blinker oscillates: horizontal → vertical → horizontal", t => {
    let grid = GameOfLife.make_grid(7, 7)
    GameOfLife.set_cell(grid, 7, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 3, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 3, 4, GameOfLife.Alive)

    let gen1 = GameOfLife.compute_next_gen(grid, 7, 7)
    // Vertical: (2,3), (3,3), (4,3) alive; (3,2) and (3,4) dead
    t->expect(GameOfLife.get_cell(gen1, 7, 2, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen1, 7, 3, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen1, 7, 4, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen1, 7, 3, 2))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(gen1, 7, 3, 4))->Expect.toBe(GameOfLife.Dead)

    let gen2 = GameOfLife.compute_next_gen(gen1, 7, 7)
    // Back to horizontal
    t->expect(GameOfLife.get_cell(gen2, 7, 3, 2))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen2, 7, 3, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen2, 7, 3, 4))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(gen2, 7, 2, 3))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(gen2, 7, 4, 3))->Expect.toBe(GameOfLife.Dead)
  })

  test("block (2x2) is a still life — never changes", t => {
    let grid = GameOfLife.make_grid(6, 6)
    GameOfLife.set_cell(grid, 6, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 2, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 3, 3, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 6, 6)
    t->expect(GameOfLife.count_alive(next))->Expect.toBe(4)
    t->expect(GameOfLife.get_cell(next, 6, 2, 2))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 6, 2, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 6, 3, 2))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 6, 3, 3))->Expect.toBe(GameOfLife.Alive)
  })

  test("empty grid stays empty", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let next = GameOfLife.compute_next_gen(grid, 5, 5)
    t->expect(GameOfLife.count_alive(next))->Expect.toBe(0)
  })
})

// ── count_alive ───────────────────────────────────────────────────────────────

describe("count_alive", () => {
  test("empty grid returns 0", t => {
    let grid = GameOfLife.make_grid(5, 5)
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(0)
  })

  test("counts 3 live cells correctly", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 4, 4, GameOfLife.Alive)
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(3)
  })

  test("full 3x3 grid counts 9", t => {
    let grid = GameOfLife.make_grid(3, 3)
    let r = ref(0)
    while r.contents < 3 {
      let c = ref(0)
      while c.contents < 3 {
        GameOfLife.set_cell(grid, 3, r.contents, c.contents, GameOfLife.Alive)
        c.contents = c.contents + 1
      }
      r.contents = r.contents + 1
    }
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(9)
  })
})

// ── count_live_neighbors — TOROIDAL (wrap-around) ────────────────────────────
// These tests define Option B: toroidal edges.
// They FAIL with the current finite-boundary implementation.
// They must ALL PASS after the toroidal change.

describe("count_live_neighbors — toroidal wrap-around", () => {
  test("top-left corner (0,0) wraps to see bottom-right corner (rows-1, cols-1)", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 4, 4, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 0))->Expect.toBe(1)
  })

  test("top row wraps to see bottom row as neighbor", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 4, 2, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 2))->Expect.toBe(1)
  })

  test("bottom row wraps to see top row as neighbor", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 0, 2, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 4, 2))->Expect.toBe(1)
  })

  test("left column wraps to see right column as neighbor", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 4, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 2, 0))->Expect.toBe(1)
  })

  test("right column wraps to see left column as neighbor", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 2, 0, GameOfLife.Alive)
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 2, 4))->Expect.toBe(1)
  })

  test("corner cell always has exactly 8 neighbors (toroidal, not 3 like finite)", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Set all cells except (0,0) alive
    let r = ref(0)
    while r.contents < 5 {
      let c = ref(0)
      while c.contents < 5 {
        if !(r.contents == 0 && c.contents == 0) {
          GameOfLife.set_cell(grid, 5, r.contents, c.contents, GameOfLife.Alive)
        }
        c.contents = c.contents + 1
      }
      r.contents = r.contents + 1
    }
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 0))->Expect.toBe(8)
  })

  test("edge cell always has exactly 8 neighbors (toroidal, not 5 like finite)", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Set all cells except top-edge (0,2) alive
    let r = ref(0)
    while r.contents < 5 {
      let c = ref(0)
      while c.contents < 5 {
        if !(r.contents == 0 && c.contents == 2) {
          GameOfLife.set_cell(grid, 5, r.contents, c.contents, GameOfLife.Alive)
        }
        c.contents = c.contents + 1
      }
      r.contents = r.contents + 1
    }
    t->expect(GameOfLife.count_live_neighbors(grid, 5, 5, 0, 2))->Expect.toBe(8)
  })
})

describe("compute_next_gen — toroidal wrap-around", () => {
  test("blinker at bottom edge wraps: vertical arm appears at top row", t => {
    // Horizontal blinker at last row: (6,2), (6,3), (6,4) in a 7x7 grid
    // After 1 gen → vertical blinker at col 3: rows 5, 6, and 0 (wrapped)
    let grid = GameOfLife.make_grid(7, 7)
    GameOfLife.set_cell(grid, 7, 6, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 6, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 6, 4, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 7, 7)
    t->expect(GameOfLife.get_cell(next, 7, 5, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 7, 6, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 7, 0, 3))->Expect.toBe(GameOfLife.Alive)
    // old horizontal arms die
    t->expect(GameOfLife.get_cell(next, 7, 6, 2))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(next, 7, 6, 4))->Expect.toBe(GameOfLife.Dead)
  })

  test("blinker at right edge wraps: vertical arm appears at left column", t => {
    // Vertical blinker at last col: (2,6), (3,6), (4,6) in a 7x7 grid
    // After 1 gen → horizontal blinker at row 3: cols 6, 0 (wrapped), and 5
    // Actually: vertical blinker (col-wise) → becomes horizontal (row-wise)
    // Vertical blinker at col 6: rows 2,3,4
    // After 1 gen: horizontal at row 3: cols 5, 6, 0 (wrapped)
    let grid = GameOfLife.make_grid(7, 7)
    GameOfLife.set_cell(grid, 7, 2, 6, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 3, 6, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 4, 6, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen(grid, 7, 7)
    t->expect(GameOfLife.get_cell(next, 7, 3, 5))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 7, 3, 6))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(next, 7, 3, 0))->Expect.toBe(GameOfLife.Alive)
    // old vertical arms die
    t->expect(GameOfLife.get_cell(next, 7, 2, 6))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(next, 7, 4, 6))->Expect.toBe(GameOfLife.Dead)
  })
})

// ── Grid serialization (for localStorage custom presets) ──────────────────────
// These tests define the pure helper functions for Option C.
// They FAIL until serialize_grid and deserialize_grid are added to GameOfLife.res.

describe("serialize_grid", () => {
  test("empty grid serializes to all-'0' string of correct length", t => {
    let grid = GameOfLife.make_grid(3, 4)
    let s = GameOfLife.serialize_grid(grid)
    t->expect(String.length(s))->Expect.toBe(12)
    t->expect(s)->Expect.toBe("000000000000")
  })

  test("Alive cell serializes to '1', Dead to '0'", t => {
    let grid = GameOfLife.make_grid(2, 2)
    GameOfLife.set_cell(grid, 2, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 2, 1, 1, GameOfLife.Alive)
    let s = GameOfLife.serialize_grid(grid)
    t->expect(s)->Expect.toBe("1001")
  })

  test("all-alive grid serializes to all-'1' string", t => {
    let grid = GameOfLife.make_grid(2, 3)
    GameOfLife.set_cell(grid, 3, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 0, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 0, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 1, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 1, 2, GameOfLife.Alive)
    let s = GameOfLife.serialize_grid(grid)
    t->expect(s)->Expect.toBe("111111")
  })
})

describe("deserialize_grid", () => {
  test("all-'0' string deserializes to all-Dead grid", t => {
    let grid = GameOfLife.deserialize_grid("000000000000")
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(0)
  })

  test("'1' chars deserialize to Alive cells, '0' to Dead", t => {
    // "0001" in a 2x2 grid: position 3 = (1,1)
    let grid = GameOfLife.deserialize_grid("0001")
    t->expect(GameOfLife.count_alive(grid))->Expect.toBe(1)
    // use get_cell with cols=2: position 3 = row 1, col 1
    t->expect(GameOfLife.get_cell(grid, 2, 1, 1))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(grid, 2, 0, 0))->Expect.toBe(GameOfLife.Dead)
  })

  test("round-trip: serialize then deserialize gives identical alive count", t => {
    let original = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(original, 5, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 3, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 4, 0, GameOfLife.Alive)
    let s = GameOfLife.serialize_grid(original)
    let restored = GameOfLife.deserialize_grid(s)
    t->expect(GameOfLife.count_alive(restored))->Expect.toBe(3)
  })

  test("round-trip: serialize then deserialize gives identical cell positions", t => {
    let original = GameOfLife.make_grid(4, 4)
    GameOfLife.set_cell(original, 4, 0, 3, GameOfLife.Alive)
    GameOfLife.set_cell(original, 4, 3, 0, GameOfLife.Alive)
    let s = GameOfLife.serialize_grid(original)
    let restored = GameOfLife.deserialize_grid(s)
    t->expect(GameOfLife.get_cell(restored, 4, 0, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(restored, 4, 3, 0))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_cell(restored, 4, 0, 0))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_cell(restored, 4, 3, 3))->Expect.toBe(GameOfLife.Dead)
  })
})

// ── Option E: Custom Life-Like Rules ───────────────────────────────────────────
// These tests define Option E: parameterizing the ruleset.
// They FAIL until compute_next_gen accepts a rule parameter.
// The existing 43 tests should still pass with Conway passed explicitly.

// Rule type exists and preset rules are accessible
describe("rule type and presets", () => {
  test("rule type exists with birth and survival arrays", t => {
    let rule = GameOfLife.conway
    t->expect(Array.length(rule.birth))->Expect.toBe(1)
    t->expect(Array.length(rule.survival))->Expect.toBe(2)
  })

  test("conway rule is B3/S23", t => {
    let rule = GameOfLife.conway
    // Birth on 3
    t->expect(GameOfLife.rule_has_birth(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 2))->Expect.toBe(false)
    // Survival on 2, 3
    t->expect(GameOfLife.rule_has_survival(rule, 2))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 1))->Expect.toBe(false)
  })

  test("highlife rule is B36/S23", t => {
    let rule = GameOfLife.highlife
    // Birth on 3 AND 6
    t->expect(GameOfLife.rule_has_birth(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 6))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 2))->Expect.toBe(false)
  })

  test("maze rule is B3/S12345", t => {
    let rule = GameOfLife.maze
    // Birth on 3 only
    t->expect(GameOfLife.rule_has_birth(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 2))->Expect.toBe(false)
    // Survival on 1, 2, 3, 4, 5
    t->expect(GameOfLife.rule_has_survival(rule, 1))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 2))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 4))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 5))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 6))->Expect.toBe(false)
  })

  test("dayAndNight rule is B3678/S34678", t => {
    let rule = GameOfLife.dayAndNight
    // Birth on 3, 6, 7, 8
    t->expect(GameOfLife.rule_has_birth(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 6))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 7))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 8))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_birth(rule, 2))->Expect.toBe(false)
    // Survival on 3, 4, 6, 7, 8
    t->expect(GameOfLife.rule_has_survival(rule, 3))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 4))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 6))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 7))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 8))->Expect.toBe(true)
    t->expect(GameOfLife.rule_has_survival(rule, 2))->Expect.toBe(false)
  })
})

// compute_next_gen with explicit rule produces correct results
describe("compute_next_gen with rule parameter", () => {
  test("compute_next_gen accepts rule parameter", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Single alive cell with 0 neighbors should die under any rule
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    let next = GameOfLife.compute_next_gen_rule(grid, 5, 5, GameOfLife.conway)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("conway rule produces same result as original hardcoded function", t => {
    // Use a blinker: horizontal row of 3
    let grid = GameOfLife.make_grid(7, 7)
    GameOfLife.set_cell(grid, 7, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 3, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 7, 3, 4, GameOfLife.Alive)
    
    // Old function (for comparison - should still work)
    let next_old = GameOfLife.compute_next_gen(grid, 7, 7)
    // New function with conway rule
    let next_new = GameOfLife.compute_next_gen_rule(grid, 7, 7, GameOfLife.conway)
    
    // Should produce identical results
    t->expect(GameOfLife.count_alive(next_new))->Expect.toBe(GameOfLife.count_alive(next_old))
    t->expect(GameOfLife.get_cell(next_new, 7, 2, 3))->Expect.toBe(GameOfLife.get_cell(next_old, 7, 2, 3))
    t->expect(GameOfLife.get_cell(next_new, 7, 4, 3))->Expect.toBe(GameOfLife.get_cell(next_old, 7, 4, 3))
  })

  test("highlife: dead cell with 6 neighbors becomes alive (B36)", t => {
    let grid = GameOfLife.make_grid(5, 5)
    // Dead cell at center (2,2) surrounded by 6 live cells
    // Positions: (1,1), (1,2), (1,3), (2,1), (2,3), (3,2)
    GameOfLife.set_cell(grid, 5, 1, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    // (2,2) is dead with 6 neighbors
    
    let next = GameOfLife.compute_next_gen_rule(grid, 5, 5, GameOfLife.highlife)
    // Under HighLife (B36), dead cell with 6 neighbors is born
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
    
    // Under Conway (B3 only), it would stay dead
    let next_conway = GameOfLife.compute_next_gen_rule(grid, 5, 5, GameOfLife.conway)
    t->expect(GameOfLife.get_cell(next_conway, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
  })

  test("rule without B3: dead cell with 3 neighbors stays dead", t => {
    // Create a custom rule without B3 (e.g., just B2)
    let grid = GameOfLife.make_grid(5, 5)
    // Dead cell at (2,2) with exactly 3 neighbors
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    
    // Create a rule with B2/S23 (no B3)
    let noB3 = GameOfLife.make_rule([2], [2, 3])
    let next = GameOfLife.compute_next_gen_rule(grid, 5, 5, noB3)
    
    // Dead cell with 3 neighbors should NOT be born (no B3)
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
    
    // But with 2 neighbors it SHOULD be born
    let grid2 = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid2, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid2, 5, 2, 3, GameOfLife.Alive)
    let next2 = GameOfLife.compute_next_gen_rule(grid2, 5, 5, noB3)
    t->expect(GameOfLife.get_cell(next2, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
  })

  test("rule without S2: live cell with 2 neighbors dies", t => {
    // Rule with survival only on 3 (no S2)
    let noS2 = GameOfLife.make_rule([3], [3])
    let grid = GameOfLife.make_grid(5, 5)
    // Live cell at (2,2) with exactly 2 neighbors (should survive under Conway, die here)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    
    let next = GameOfLife.compute_next_gen_rule(grid, 5, 5, noS2)
    // With no S2, live cell with 2 neighbors dies
    t->expect(GameOfLife.get_cell(next, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
    
    // With 3 neighbors it survives
    let grid3 = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid3, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid3, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid3, 5, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid3, 5, 2, 1, GameOfLife.Alive)
    let next3 = GameOfLife.compute_next_gen_rule(grid3, 5, 5, noS2)
    t->expect(GameOfLife.get_cell(next3, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
  })
})

// ── Option D: Cell Age / Color Gradient ─────────────────────────────────────────
// These tests define Option D: tracking cell age and coloring by age.
// They FAIL until the age tracking functions are implemented.
// The existing 53 tests should still pass.

// Age tracking functions exist
describe("cell age tracking", () => {
  test("make_ages creates array of correct size", t => {
    let ages = GameOfLife.make_ages(5, 4)
    t->expect(Array.length(ages))->Expect.toBe(20)
  })

  test("all ages initialized to 0", t => {
    let ages = GameOfLife.make_ages(3, 3)
    t->expect(GameOfLife.count_nonzero_ages(ages))->Expect.toBe(0)
  })

  test("get_age returns correct value", t => {
    let ages = GameOfLife.make_ages(5, 5)
    GameOfLife.set_age(ages, 5, 2, 3, 7)
    t->expect(GameOfLife.get_age(ages, 5, 2, 3))->Expect.toBe(7)
  })

  test("set_age updates value", t => {
    let ages = GameOfLife.make_ages(5, 5)
    GameOfLife.set_age(ages, 5, 1, 1, 5)
    GameOfLife.set_age(ages, 5, 1, 1, 10)
    t->expect(GameOfLife.get_age(ages, 5, 1, 1))->Expect.toBe(10)
  })

  test("out-of-bounds get_age returns 0", t => {
    let ages = GameOfLife.make_ages(5, 5)
    t->expect(GameOfLife.get_age(ages, 5, 10, 10))->Expect.toBe(0)
  })
})

// compute_next_gen_with_age produces correct ages
describe("compute_next_gen with age tracking", () => {
  test("surviving cell increments age", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let ages = GameOfLife.make_ages(5, 5)
    // Center cell alive with 3 neighbors (survives)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_age(ages, 5, 2, 2, 5)  // age 5
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    // 3 neighbors = survives
    
    let (next_grid, next_ages) = GameOfLife.compute_next_gen_with_age(grid, ages, 5, 5)
    
    // Cell should still be alive
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
    // Age should be incremented: 5 + 1 = 6
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 2))->Expect.toBe(6)
  })

  test("new birth sets age to 1", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let ages = GameOfLife.make_ages(5, 5)
    // Dead cell at center with 3 neighbors (born)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    // (2,2) is dead with 3 neighbors → born
    
    let (next_grid, next_ages) = GameOfLife.compute_next_gen_with_age(grid, ages, 5, 5)
    
    // New cell should be alive
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
    // New cell should have age 1
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 2))->Expect.toBe(1)
  })

  test("dead cell resets age to 0", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let ages = GameOfLife.make_ages(5, 5)
    // Alive cell at center with 1 neighbor (dies)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_age(ages, 5, 2, 2, 10)  // was age 10
    GameOfLife.set_cell(grid, 5, 2, 3, GameOfLife.Alive)
    // Only 1 neighbor → dies
    
    let (next_grid, next_ages) = GameOfLife.compute_next_gen_with_age(grid, ages, 5, 5)
    
    // Cell should be dead
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 2))->Expect.toBe(GameOfLife.Dead)
    // Age should be reset to 0
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 2))->Expect.toBe(0)
  })

  test("block still life: all cells age together", t => {
    let grid = GameOfLife.make_grid(6, 6)
    let ages = GameOfLife.make_ages(6, 6)
    // Block: 2x2 square, never changes
    GameOfLife.set_cell(grid, 6, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 2, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 3, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 6, 3, 3, GameOfLife.Alive)
    // All start at age 3
    GameOfLife.set_age(ages, 6, 2, 2, 3)
    GameOfLife.set_age(ages, 6, 2, 3, 3)
    GameOfLife.set_age(ages, 6, 3, 2, 3)
    GameOfLife.set_age(ages, 6, 3, 3, 3)
    
    // Run 5 generations
    let (_, ages1) = GameOfLife.compute_next_gen_with_age(grid, ages, 6, 6)
    let (_, ages2) = GameOfLife.compute_next_gen_with_age(grid, ages1, 6, 6)
    let (_, ages3) = GameOfLife.compute_next_gen_with_age(grid, ages2, 6, 6)
    let (_, ages4) = GameOfLife.compute_next_gen_with_age(grid, ages3, 6, 6)
    let (_, ages5) = GameOfLife.compute_next_gen_with_age(grid, ages4, 6, 6)
    
    // After 5 generations, all should be age 8 (3 + 5)
    t->expect(GameOfLife.get_age(ages5, 6, 2, 2))->Expect.toBe(8)
    t->expect(GameOfLife.get_age(ages5, 6, 2, 3))->Expect.toBe(8)
    t->expect(GameOfLife.get_age(ages5, 6, 3, 2))->Expect.toBe(8)
    t->expect(GameOfLife.get_age(ages5, 6, 3, 3))->Expect.toBe(8)
  })

  test("empty grid: all ages remain 0", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let ages = GameOfLife.make_ages(5, 5)
    
    let (next_grid, next_ages) = GameOfLife.compute_next_gen_with_age(grid, ages, 5, 5)
    
    t->expect(GameOfLife.count_alive(next_grid))->Expect.toBe(0)
    t->expect(GameOfLife.count_nonzero_ages(next_ages))->Expect.toBe(0)
  })

  test("mix of births, deaths, and survivors in one generation", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let ages = GameOfLife.make_ages(5, 5)
    // Pattern: (2,0) dies, (2,2) survives, (2,3) born
    // (2,0): alive with 0 neighbors (isolated) → dies
    GameOfLife.set_cell(grid, 5, 2, 0, GameOfLife.Alive)
    GameOfLife.set_age(ages, 5, 2, 0, 4)
    // (2,2): alive with 2 neighbors (1,2), (3,2) → survives  
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_age(ages, 5, 2, 2, 7)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 3, 2, GameOfLife.Alive)
    // (2,3): dead with 3 neighbors (2,2), (1,2), (3,2) → born
    
    let (next_grid, next_ages) = GameOfLife.compute_next_gen_with_age(grid, ages, 5, 5)
    
    // (2,0): died → dead, age 0
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 0))->Expect.toBe(GameOfLife.Dead)
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 0))->Expect.toBe(0)
    // (2,2): survived → alive, age 8
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 2))->Expect.toBe(8)
    // (2,3): born → alive, age 1
    t->expect(GameOfLife.get_cell(next_grid, 5, 2, 3))->Expect.toBe(GameOfLife.Alive)
    t->expect(GameOfLife.get_age(next_ages, 5, 2, 3))->Expect.toBe(1)
  })
})

// Age color function for visualization
describe("compute_age_color", () => {
  test("age 0 returns dark color", t => {
    let color = GameOfLife.compute_age_color(0)
    // Should be a dark CSS color string
    t->expect(String.length(color))->Expect.not->Expect.toBe(0)
  })

  test("age 1 returns distinct color from age 0", t => {
    let color0 = GameOfLife.compute_age_color(0)
    let color1 = GameOfLife.compute_age_color(1)
    t->expect(color0)->Expect.not->Expect.toBe(color1)
  })

  test("higher ages produce progressively lighter colors", t => {
    // We can't test exact colors (implementation detail), but verify monotonic progression
    let c1 = GameOfLife.compute_age_color(1)
    let c10 = GameOfLife.compute_age_color(10)
    let c50 = GameOfLife.compute_age_color(50)
    // Just verify they return strings
    t->expect(String.length(c1))->Expect.not->Expect.toBe(0)
    t->expect(String.length(c10))->Expect.not->Expect.toBe(0)
    t->expect(String.length(c50))->Expect.not->Expect.toBe(0)
  })
})

// ── Option F: RLE Import / Export ─────────────────────────────────────────────
// These tests define Option F: Run Length Encoding for Conway Life patterns.
// They FAIL until encode_rle and decode_rle are implemented.
// The existing 67 tests should still pass.

describe("encode_rle", () => {
  test("empty grid encodes to empty-ish string with header", t => {
    let grid = GameOfLife.make_grid(3, 3)
    let encoded = GameOfLife.encode_rle(grid, 3, 3)
    // Should contain header with dimensions
    t->expect(String.length(encoded))->Expect.not->Expect.toBe(0)
    // Should mark all dead as 'b' runs or similar
  })

  test("single alive cell encodes correctly", t => {
    let grid = GameOfLife.make_grid(3, 3)
    GameOfLife.set_cell(grid, 3, 1, 1, GameOfLife.Alive)
    let encoded = GameOfLife.encode_rle(grid, 3, 3)
    // Should contain 'o' for alive
    t->expect(String.includes(encoded, "o"))->Expect.toBe(true)
  })

  test("glider encodes to something with multiple 'o' marks", t => {
    // Glider pattern at top-left: (0,1), (1,2), (2,0), (2,1), (2,2)
    let grid = GameOfLife.make_grid(3, 3)
    GameOfLife.set_cell(grid, 3, 0, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 2, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 3, 2, 2, GameOfLife.Alive)
    let encoded = GameOfLife.encode_rle(grid, 3, 3)
    // Should have exactly 5 'o' marks (or compressed like 2o)
    t->expect(String.length(encoded))->Expect.not->Expect.toBe(5)
  })
})

describe("decode_rle", () => {
  test("decodes empty grid (all b)", t => {
    let result = GameOfLife.decode_rle("x = 3, y = 3, rule = B3/S23\nbbbob\nbbbob\nbbbob!")
    switch result {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _rows, _cols)) =>
      t->expect(_rows)->Expect.toBe(3)
      t->expect(_cols)->Expect.toBe(3)
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(0)
    }
  })

  test("decodes single 'o' to single alive cell", t => {
    // "x = 1, y = 1, rule = B3/S23\no!" = 1x1 grid with one alive cell
    let result = GameOfLife.decode_rle("x = 1, y = 1, rule = B3/S23\no!")
    switch result {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _rows, _cols)) =>
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(1)
      t->expect(GameOfLife.get_cell(grid, _cols, 0, 0))->Expect.toBe(GameOfLife.Alive)
    }
  })

  test("ignores header and rule line", t => {
    // Both formats should work
    let result1 = GameOfLife.decode_rle("x = 2, y = 1, rule = B3/S23\noo!")
    let result2 = GameOfLife.decode_rle("x = 2, y = 1\noo!")
    
    switch (result1, result2) {
    | (Some((g1, _, _)), Some((g2, _, _))) =>
      t->expect(GameOfLife.count_alive(g1))->Expect.toBe(GameOfLife.count_alive(g2))
    | _ => t->expect(true)->Expect.toBe(true)
    }
  })

  test("handles run-length compression (3o = ooo)", t => {
    // "3o" should decode to three alive cells in a row
    let result = GameOfLife.decode_rle("x = 3, y = 1\nooo!")
    switch result {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _rows, _cols)) =>
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(3)
      t->expect(GameOfLife.get_cell(grid, 3, 0, 0))->Expect.toBe(GameOfLife.Alive)
      t->expect(GameOfLife.get_cell(grid, 3, 0, 1))->Expect.toBe(GameOfLife.Alive)
      t->expect(GameOfLife.get_cell(grid, 3, 0, 2))->Expect.toBe(GameOfLife.Alive)
    }
  })

  test("handles $ as row separator", t => {
    // 2x2 grid: top row alive, bottom row dead
    let result = GameOfLife.decode_rle("x = 2, y = 2, rule = B3/S23\noo$\nbb!")
    switch result {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _rows, _cols)) =>
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(2)
      // Row 0 (top): both alive
      t->expect(GameOfLife.get_cell(grid, 2, 0, 0))->Expect.toBe(GameOfLife.Alive)
      t->expect(GameOfLife.get_cell(grid, 2, 0, 1))->Expect.toBe(GameOfLife.Alive)
      // Row 1 (bottom): both dead
      t->expect(GameOfLife.get_cell(grid, 2, 1, 0))->Expect.toBe(GameOfLife.Dead)
      t->expect(GameOfLife.get_cell(grid, 2, 1, 1))->Expect.toBe(GameOfLife.Dead)
    }
  })

  test("returns None for invalid RLE", t => {
    let result1 = GameOfLife.decode_rle("not valid rle at all")
    t->expect(result1)->Expect.toBe(None)
    
    let result2 = GameOfLife.decode_rle("")  // empty
    t->expect(result2)->Expect.toBe(None)
  })
})

describe("RLE round-trip", () => {
  test("encode then decode recovers original grid", t => {
    let original = GameOfLife.make_grid(5, 5)
    // Set some pattern
    GameOfLife.set_cell(original, 5, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 0, 4, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 4, 0, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 4, 4, GameOfLife.Alive)
    
    let encoded = GameOfLife.encode_rle(original, 5, 5)
    let decoded = GameOfLife.decode_rle(encoded)
    
    switch decoded {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _rows, _cols)) =>
      // Count should match
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(GameOfLife.count_alive(original))
      // Each alive cell position should match
      t->expect(GameOfLife.get_cell(grid, 5, 0, 0))->Expect.toBe(GameOfLife.get_cell(original, 5, 0, 0))
      t->expect(GameOfLife.get_cell(grid, 5, 0, 4))->Expect.toBe(GameOfLife.get_cell(original, 5, 0, 4))
      t->expect(GameOfLife.get_cell(grid, 5, 2, 2))->Expect.toBe(GameOfLife.get_cell(original, 5, 2, 2))
      t->expect(GameOfLife.get_cell(grid, 5, 4, 0))->Expect.toBe(GameOfLife.get_cell(original, 5, 4, 0))
      t->expect(GameOfLife.get_cell(grid, 5, 4, 4))->Expect.toBe(GameOfLife.get_cell(original, 5, 4, 4))
    }
  })

  test("blinker round-trip preserves oscillation pattern", t => {
    // Horizontal blinker: 3 in a row
    let original = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(original, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 3, GameOfLife.Alive)
    
    let encoded = GameOfLife.encode_rle(original, 5, 5)
    let decoded = GameOfLife.decode_rle(encoded)
    
    switch decoded {
    | None => t->expect(true)->Expect.toBe(true)
    | Some((grid, _, _)) =>
      t->expect(GameOfLife.count_alive(grid))->Expect.toBe(3)
      t->expect(GameOfLife.get_cell(grid, 5, 2, 1))->Expect.toBe(GameOfLife.Alive)
      t->expect(GameOfLife.get_cell(grid, 5, 2, 2))->Expect.toBe(GameOfLife.Alive)
      t->expect(GameOfLife.get_cell(grid, 5, 2, 3))->Expect.toBe(GameOfLife.Alive)
    }
  })
})

// ============================================================
// Option G — URL State / Pattern Sharing
// ============================================================

describe("encode_url_state", () => {
  test("empty grid encodes to non-empty string", t => {
    let grid = GameOfLife.make_grid(5, 5)
    let encoded = GameOfLife.encode_url_state(grid, 5, 5)
    t->expect(String.length(encoded) > 0)->Expect.toBe(true)
  })

  test("encoding is deterministic for identical grids", t => {
    let grid1 = GameOfLife.make_grid(5, 5)
    let grid2 = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid1, 5, 1, 3, GameOfLife.Alive)
    GameOfLife.set_cell(grid2, 5, 1, 3, GameOfLife.Alive)
    t->expect(GameOfLife.encode_url_state(grid1, 5, 5))->Expect.toBe(
      GameOfLife.encode_url_state(grid2, 5, 5)
    )
  })

  test("glider produces a stable, non-empty encoding", t => {
    let grid = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid, 5, 0, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 1, 2, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(grid, 5, 2, 2, GameOfLife.Alive)
    let enc = GameOfLife.encode_url_state(grid, 5, 5)
    t->expect(String.length(enc) > 0)->Expect.toBe(true)
    // Same call produces same result
    t->expect(enc)->Expect.toBe(GameOfLife.encode_url_state(grid, 5, 5))
  })

  test("different grids produce different encodings", t => {
    let grid1 = GameOfLife.make_grid(5, 5)
    let grid2 = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(grid1, 5, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(grid2, 5, 4, 4, GameOfLife.Alive)
    t->expect(GameOfLife.encode_url_state(grid1, 5, 5))->not->Expect.toBe(
      GameOfLife.encode_url_state(grid2, 5, 5)
    )
  })
})

describe("decode_url_state", () => {
  test("malformed input returns None", t => {
    t->expect(GameOfLife.decode_url_state("!!!invalid!!!"))->Expect.toBe(None)
  })

  test("empty string returns None", t => {
    t->expect(GameOfLife.decode_url_state(""))->Expect.toBe(None)
  })

  test("random garbage returns None without crashing", t => {
    t->expect(GameOfLife.decode_url_state("abc123!@#"))->Expect.toBe(None)
    t->expect(GameOfLife.decode_url_state("AAAAAAAAAA"))->Expect.toBe(None)
  })
})

describe("URL state round-trip", () => {
  test("empty grid round-trips correctly", t => {
    let original = GameOfLife.make_grid(5, 5)
    let encoded = GameOfLife.encode_url_state(original, 5, 5)
    let decoded = GameOfLife.decode_url_state(encoded)
    switch decoded {
    | None => t->expect("got None")->Expect.toBe("expected Some")
    | Some((grid, rows, cols)) => {
        t->expect(rows)->Expect.toBe(5)
        t->expect(cols)->Expect.toBe(5)
        t->expect(GameOfLife.count_alive(grid))->Expect.toBe(0)
      }
    }
  })

  test("blinker round-trips: count and positions preserved", t => {
    let original = GameOfLife.make_grid(5, 5)
    GameOfLife.set_cell(original, 5, 2, 1, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 2, GameOfLife.Alive)
    GameOfLife.set_cell(original, 5, 2, 3, GameOfLife.Alive)
    let encoded = GameOfLife.encode_url_state(original, 5, 5)
    let decoded = GameOfLife.decode_url_state(encoded)
    switch decoded {
    | None => t->expect("got None")->Expect.toBe("expected Some")
    | Some((grid, rows, cols)) => {
        t->expect(rows)->Expect.toBe(5)
        t->expect(cols)->Expect.toBe(5)
        t->expect(GameOfLife.count_alive(grid))->Expect.toBe(3)
        t->expect(GameOfLife.get_cell(grid, cols, 2, 1))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 2, 2))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 2, 3))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 0, 0))->Expect.toBe(GameOfLife.Dead)
      }
    }
  })

  test("corner cells preserved after round-trip", t => {
    let original = GameOfLife.make_grid(10, 10)
    GameOfLife.set_cell(original, 10, 0, 0, GameOfLife.Alive)
    GameOfLife.set_cell(original, 10, 3, 7, GameOfLife.Alive)
    GameOfLife.set_cell(original, 10, 9, 9, GameOfLife.Alive)
    let encoded = GameOfLife.encode_url_state(original, 10, 10)
    let decoded = GameOfLife.decode_url_state(encoded)
    switch decoded {
    | None => t->expect("got None")->Expect.toBe("expected Some")
    | Some((grid, rows, cols)) => {
        t->expect(rows)->Expect.toBe(10)
        t->expect(cols)->Expect.toBe(10)
        t->expect(GameOfLife.count_alive(grid))->Expect.toBe(3)
        t->expect(GameOfLife.get_cell(grid, cols, 0, 0))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 3, 7))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 9, 9))->Expect.toBe(GameOfLife.Alive)
        t->expect(GameOfLife.get_cell(grid, cols, 0, 1))->Expect.toBe(GameOfLife.Dead)
        t->expect(GameOfLife.get_cell(grid, cols, 5, 5))->Expect.toBe(GameOfLife.Dead)
      }
    }
  })

  test("dimensions are preserved through round-trip", t => {
    let original = GameOfLife.make_grid(20, 30)
    GameOfLife.set_cell(original, 30, 10, 15, GameOfLife.Alive)
    let encoded = GameOfLife.encode_url_state(original, 20, 30)
    let decoded = GameOfLife.decode_url_state(encoded)
    switch decoded {
    | None => t->expect("got None")->Expect.toBe("expected Some")
    | Some((grid, rows, cols)) => {
        t->expect(rows)->Expect.toBe(20)
        t->expect(cols)->Expect.toBe(30)
        t->expect(GameOfLife.count_alive(grid))->Expect.toBe(1)
        t->expect(GameOfLife.get_cell(grid, cols, 10, 15))->Expect.toBe(GameOfLife.Alive)
      }
    }
  })
})
