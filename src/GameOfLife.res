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
        let nr = r + di.contents
        let nc = c + dj.contents
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
          if get_cell(grid, cols, nr, nc) == Alive {
            count.contents = count.contents + 1
          }
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

type action =
  | Toggle
  | Step
  | Clear
  | Randomize
  | SetSpeed(int)
  | ToggleCell(int, int)

type state = {
  grid: array<cell>,
  rows: int,
  cols: int,
  running: bool,
  speed: int,
}

let reducer = (state, action) =>
  switch action {
  | Toggle => {...state, running: !state.running}
  | Step   => {...state, grid: compute_next_gen(state.grid, state.rows, state.cols)}
  | Clear  => {...state, grid: make_grid(state.rows, state.cols), running: false}
  | Randomize => {...state, grid: randomize_grid(state.rows, state.cols)}
  | SetSpeed(speed) => {...state, speed}
  | ToggleCell(r, c) =>
    let next = Belt.Array.copy(state.grid)
    let cur = get_cell(next, state.cols, r, c)
    set_cell(next, state.cols, r, c, switch cur { | Alive => Dead | Dead => Alive })
    {...state, grid: next}
  }

let rows = 20
let cols = 40

let initial_state = {
  grid: make_grid(rows, cols),
  rows,
  cols,
  running: false,
  speed: 100,
}
