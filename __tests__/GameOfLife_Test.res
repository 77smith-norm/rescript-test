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
