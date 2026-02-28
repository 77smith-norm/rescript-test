type cell = Alive | Dead

// 1D flat array: grid[r * cols + c]
let make_grid = (rows: int, cols: int): array<cell> =>
  Belt.Array.make(rows * cols, Dead)

let get_cell = (grid: array<cell>, cols: int, r: int, c: int): cell =>
  switch grid[r * cols + c] {
  | Some(cell) => cell
  | None => Dead
  }

let set_cell = (grid: array<cell>, cols: int, r: int, c: int, val: cell): unit => {
  let _ = Belt.Array.set(grid, r * cols + c, val)
}

let count_live_neighbors = (grid, rows, cols, r, c) => {
  let count = ref(0)
  let di = ref(-1)
  while di.contents <= 1 {
    let dj = ref(-1)
    while dj.contents <= 1 {
      if !(di.contents == 0 && dj.contents == 0) {
        let nr = (r + di.contents + rows) % rows
        let nc = (c + dj.contents + cols) % cols
        if get_cell(grid, cols, nr, nc) == Alive {
          count.contents = count.contents + 1
        }
      }
      dj.contents = dj.contents + 1
    }
    di.contents = di.contents + 1
  }
  count.contents
}

let compute_next_gen = (grid, rows, cols) => {
  let next = make_grid(rows, cols)
  let r = ref(0)
  while r.contents < rows {
    let c = ref(0)
    while c.contents < cols {
      let n = count_live_neighbors(grid, rows, cols, r.contents, c.contents)
      let new_cell = switch get_cell(grid, cols, r.contents, c.contents) {
        | Alive => if n < 2 || n > 3 { Dead } else { Alive }
        | Dead  => if n == 3 { Alive } else { Dead }
      }
      set_cell(next, cols, r.contents, c.contents, new_cell)
      c.contents = c.contents + 1
    }
    r.contents = r.contents + 1
  }
  next
}

type preset = Glider | Blinker | Pulsar | RPentomino

let load_preset = (p: preset, rows: int, cols: int): array<cell> => {
  let grid = make_grid(rows, cols)
  let center_r = rows / 2
  let center_c = cols / 2

  switch p {
  | Glider => {
    let offsets = [(0, 1), (1, 2), (2, 0), (2, 1), (2, 2)]
    let _ = Array.forEach(offsets, offset => {
      let (dr, dc) = offset
      let r = 1 + dr
      let c = 1 + dc
      set_cell(grid, cols, r, c, Alive)
    })
  }
  | Blinker => {
    let offsets = [(0, 0), (0, 1), (0, 2)]
    let _ = Array.forEach(offsets, offset => {
      let (dr, dc) = offset
      set_cell(grid, cols, center_r + dr, center_c - 1 + dc, Alive)
    })
  }
  | Pulsar => {
    let offsets = [
      (-4, -1), (-4, -2), (-4, -3), (-4, 1), (-4, 2), (-4, 3),
      (-3, -1), (-3, -2), (-3, -3), (-3, 1), (-3, 2), (-3, 3),
      (-2, -1), (-2, -2), (-2, -3), (-2, 1), (-2, 2), (-2, 3),
      (-1, -4), (-1, -3), (-1, -2), (-1, -1), (-1, 1), (-1, 2), (-1, 3), (-1, 4),
      (1, -4), (1, -3), (1, -2), (1, -1), (1, 1), (1, 2), (1, 3), (1, 4),
      (2, -1), (2, -2), (2, -3), (2, 1), (2, 2), (2, 3),
      (3, -1), (3, -2), (3, -3), (3, 1), (3, 2), (3, 3),
      (4, -1), (4, -2), (4, -3), (4, 1), (4, 2), (4, 3),
    ]
    let _ = Array.forEach(offsets, offset => {
      let (dr, dc) = offset
      set_cell(grid, cols, center_r + dr, center_c + dc, Alive)
    })
  }
  | RPentomino => {
    let offsets = [(0, 1), (0, 2), (1, 0), (1, 1), (2, 1)]
    let _ = Array.forEach(offsets, offset => {
      let (dr, dc) = offset
      set_cell(grid, cols, center_r + dr, center_c + dc, Alive)
    })
  }
  }
  grid
}

// Simple LCG pseudo-random
let random_state = ref(12345)
let next_rand = () => {
  let x = random_state.contents * 1103515245 + 12345
  random_state.contents = x &&& 0x7fffffff
  random_state.contents
}

let randomize_grid = (rows, cols) => {
  let grid = make_grid(rows, cols)
  let r = ref(0)
  while r.contents < rows {
    let c = ref(0)
    while c.contents < cols {
      let v = (next_rand() >>> 15) &&& 1
      set_cell(grid, cols, r.contents, c.contents, if v == 1 { Alive } else { Dead })
      c.contents = c.contents + 1
    }
    r.contents = r.contents + 1
  }
  grid
}

let count_alive = (grid: array<cell>): int =>
  Array.reduce(grid, 0, (acc, cell) => if cell == Alive { acc + 1 } else { acc })

type action =
  | Toggle
  | Step
  | Clear
  | Randomize
  | SetSpeed(int)
  | ToggleCell(int, int)
  | LoadPreset(preset)

type state = {
  grid: array<cell>,
  rows: int,
  cols: int,
  running: bool,
  speed: int,
  generation: int,
}

let reducer = (state, action) =>
  switch action {
  | Toggle => {...state, running: !state.running}
  | Step   => {...state, grid: compute_next_gen(state.grid, state.rows, state.cols), generation: state.generation + 1}
  | Clear  => {...state, grid: make_grid(state.rows, state.cols), running: false, generation: 0}
  | Randomize => {...state, grid: randomize_grid(state.rows, state.cols), generation: 0}
  | SetSpeed(speed) => {...state, speed}
  | ToggleCell(r, c) =>
    let next = Belt.Array.copy(state.grid)
    let cur = get_cell(next, state.cols, r, c)
    set_cell(next, state.cols, r, c, switch cur { | Alive => Dead | Dead => Alive })
    {...state, grid: next}
  | LoadPreset(p) =>
    {...state, grid: load_preset(p, state.rows, state.cols), running: false, generation: 0}
  }

let rows = 20
let cols = 40

let initial_state = {
  grid: make_grid(rows, cols),
  rows,
  cols,
  running: false,
  speed: 100,
  generation: 0,
}
