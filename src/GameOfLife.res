type cell = Alive | Dead

type rule = {
  birth: array<int>,
  survival: array<int>,
}

let make_rule = (birth: array<int>, survival: array<int>): rule =>
  {birth, survival}

let rule_has_birth = (rule: rule, n: int): bool =>
  Belt.Array.some(rule.birth, x => x == n)

let rule_has_survival = (rule: rule, n: int): bool =>
  Belt.Array.some(rule.survival, x => x == n)

let conway: rule = make_rule([3], [2, 3])
let highlife: rule = make_rule([3, 6], [2, 3])
let maze: rule = make_rule([3], [1, 2, 3, 4, 5])
let dayAndNight: rule = make_rule([3, 6, 7, 8], [3, 4, 6, 7, 8])

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

let compute_next_gen_rule = (grid, rows, cols, rule: rule) => {
  let next = make_grid(rows, cols)
  let r = ref(0)
  while r.contents < rows {
    let c = ref(0)
    while c.contents < cols {
      let n = count_live_neighbors(grid, rows, cols, r.contents, c.contents)
      let new_cell = switch get_cell(grid, cols, r.contents, c.contents) {
        | Alive =>
          if rule_has_survival(rule, n) { Alive }
          else { Dead }
        | Dead  =>
          if rule_has_birth(rule, n) { Alive }
          else { Dead }
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

let serialize_grid = (grid: array<cell>): string =>
  Array.reduce(grid, "", (acc, cell) =>
    acc ++ switch cell {
      | Alive => "1"
      | Dead => "0"
    }
  )

let deserialize_grid = (s: string): array<cell> =>
  Array.fromInitializer(~length=String.length(s), i =>
    switch String.get(s, i) {
    | Some("1") => Alive
    | _ => Dead
    }
  )

// Age tracking
let make_ages = (rows: int, cols: int): array<int> =>
  Belt.Array.make(rows * cols, 0)

let get_age = (ages: array<int>, cols: int, r: int, c: int): int =>
  switch Belt.Array.get(ages, r * cols + c) {
  | Some(age) => age
  | None => 0
  }

let set_age = (ages: array<int>, cols: int, r: int, c: int, value: int): unit => {
  let _ = Belt.Array.set(ages, r * cols + c, value)
}

let count_nonzero_ages = (ages: array<int>): int =>
  Array.reduce(ages, 0, (acc, age) => if age > 0 { acc + 1 } else { acc })

let compute_next_gen_with_age = (grid, ages, rows, cols) => {
  let next_grid = make_grid(rows, cols)
  let next_ages = make_ages(rows, cols)
  let r = ref(0)
  while r.contents < rows {
    let c = ref(0)
    while c.contents < cols {
      let n = count_live_neighbors(grid, rows, cols, r.contents, c.contents)
      let current_cell = get_cell(grid, cols, r.contents, c.contents)
      let current_age = get_age(ages, cols, r.contents, c.contents)
      let (new_cell, new_age) = switch current_cell {
        | Alive =>
          if n < 2 || n > 3 {
            (Dead, 0)
          } else {
            (Alive, current_age + 1)
          }
        | Dead  =>
          if n == 3 {
            (Alive, 1)
          } else {
            (Dead, 0)
          }
      }
      set_cell(next_grid, cols, r.contents, c.contents, new_cell)
      set_age(next_ages, cols, r.contents, c.contents, new_age)
      c.contents = c.contents + 1
    }
    r.contents = r.contents + 1
  }
  (next_grid, next_ages)
}

let compute_age_color = (age: int): string => {
  let lightness = 20 + (age * 3)
  let capped_lightness = if lightness > 80 { 80 } else { lightness }
  "hsl(200, 70%, " ++ Int.toString(capped_lightness) ++ "%)"
}

// RLE encoding/decoding
let encode_rle = (grid: array<cell>, rows: int, cols: int): string => {
  let sb: ref<string> = ref("")
  sb.contents = "x = " ++ Int.toString(cols) ++ ", y = " ++ Int.toString(rows) ++ ", rule = B3/S23" ++ "\n"
  let r = ref(0)
  while r.contents < rows {
    let c = ref(0)
    let runChar = ref(None)
    let runCount = ref(0)
    while c.contents < cols {
      let cell = get_cell(grid, cols, r.contents, c.contents)
      let ch = switch cell {
        | Alive => "o"
        | Dead => "b"
      }
      switch runChar.contents {
        | Some(prevChar) =>
          if prevChar == ch {
            runCount.contents = runCount.contents + 1
          } else {
            if runCount.contents > 1 {
              sb.contents = sb.contents ++ Int.toString(runCount.contents)
            }
            sb.contents = sb.contents ++ prevChar
            runChar.contents = Some(ch)
            runCount.contents = 1
          }
        | None => {
          runChar.contents = Some(ch)
          runCount.contents = 1
        }
      }
      c.contents = c.contents + 1
    }
    // Flush remaining run
    switch runChar.contents {
      | Some(prevChar) => {
        if runCount.contents > 1 {
          sb.contents = sb.contents ++ Int.toString(runCount.contents)
        }
        sb.contents = sb.contents ++ prevChar
      }
      | None => ()
    }
    sb.contents = sb.contents ++ "\n"
    r.contents = r.contents + 1
  }
  sb.contents = sb.contents ++ "!"
  sb.contents
}

let parseDigits = (s: string, start: int): option<(int, int)> => {
  // Returns (number, endPosition) or None
  let len = String.length(s)
  let i = ref(start)
  let num = ref(0)
  let stop = ref(false)
  while i.contents < len && !stop.contents {
    let ch = String.get(s, i.contents)
    switch ch {
      | Some(d) if d >= "0" && d <= "9" => {
        switch Int.fromString(d) {
              | Some(n) => num.contents = num.contents * 10 + n
              | None => ()
            }
        i.contents = i.contents + 1
      }
      | _ => stop.contents = true
    }
  }
  if i.contents > start {
    Some((num.contents, i.contents))
  } else {
    None
  }
}

let decode_rle = (s: string): option<(array<cell>, int, int)> => {
  let cleaned = String.trim(s)
  if String.length(cleaned) == 0 {
    None
  } else {
    // Parse header for dimensions
    let rows = ref(0)
    let cols = ref(0)
    let headerFound = ref(false)
    let lines = String.split(cleaned, "
")
    Array.forEach(lines, line => {
      let trimmedLine = String.trim(line)
      if !headerFound.contents && String.includes(trimmedLine, "x =") {
        // Try to extract x and y
        let parts = String.split(trimmedLine, ",")
        Array.forEach(parts, part => {
          let p = String.trim(part)
          if String.includes(p, "x =") {
            let afterX = String.slice(p, ~start=String.indexOf(p, "x =") + 3)
            let trimmedAfter = String.trim(afterX)
            let endIdx = String.indexOf(trimmedAfter, " ")
            let valStr = switch endIdx {
              | -1 => trimmedAfter
              | idx => String.slice(trimmedAfter, ~start=0, ~end=idx)
            }
            switch Int.fromString(valStr) {
              | Some(n) => cols.contents = n
              | None => ()
            }
          } else if String.includes(p, "y =") {
            let afterY = String.slice(p, ~start=String.indexOf(p, "y =") + 3)
            let trimmedAfter = String.trim(afterY)
            let endIdx = String.indexOf(trimmedAfter, " ")
            let valStr = switch endIdx {
              | -1 => trimmedAfter
              | idx => String.slice(trimmedAfter, ~start=0, ~end=idx)
            }
            switch Int.fromString(valStr) {
              | Some(n) => rows.contents = n
              | None => ()
            }
          }
        })
        headerFound.contents = true
      }
    })
    
    if rows.contents == 0 || cols.contents == 0 {
      None
    } else {
      // Create grid
      let grid = make_grid(rows.contents, cols.contents)
      let currentRow = ref(0)
      let currentCol = ref(0)
      let parsingBody = ref(false)
      Array.forEach(lines, line => {
        let trimmedLine = String.trim(line)
        if !parsingBody.contents && String.includes(trimmedLine, "x =") {
          parsingBody.contents = true
        }
        if parsingBody.contents && trimmedLine != "" && !String.includes(trimmedLine, "x =") {
          currentCol.contents = 0
          let i = ref(0)
          let len = String.length(trimmedLine)
          while i.contents < len {
            let ch = String.get(trimmedLine, i.contents)
            switch ch {
              | Some("!") => i.contents = len
              | Some("$") => {
                currentRow.contents = currentRow.contents + 1
                currentCol.contents = 0
                i.contents = i.contents + 1
              }
              | Some(d) if d >= "0" && d <= "9" => {
                switch parseDigits(trimmedLine, i.contents) {
                  | Some((num, newPos)) => {
                    let nextCh = String.get(trimmedLine, newPos)
                    switch nextCh {
                      | Some("o") => {
                        let j = ref(0)
                        while j.contents < num && currentCol.contents < cols.contents {
                          set_cell(grid, cols.contents, currentRow.contents, currentCol.contents, Alive)
                          currentCol.contents = currentCol.contents + 1
                          j.contents = j.contents + 1
                        }
                      }
                      | Some("b") => {
                        let j = ref(0)
                        while j.contents < num && currentCol.contents < cols.contents {
                          set_cell(grid, cols.contents, currentRow.contents, currentCol.contents, Dead)
                          currentCol.contents = currentCol.contents + 1
                          j.contents = j.contents + 1
                        }
                      }
                      | _ => ()
                    }
                    i.contents = newPos + 1
                  }
                  | None => i.contents = i.contents + 1
                }
              }
              | Some("o") => {
                if currentCol.contents < cols.contents {
                  set_cell(grid, cols.contents, currentRow.contents, currentCol.contents, Alive)
                  currentCol.contents = currentCol.contents + 1
                }
                i.contents = i.contents + 1
              }
              | Some("b") => {
                if currentCol.contents < cols.contents {
                  set_cell(grid, cols.contents, currentRow.contents, currentCol.contents, Dead)
                  currentCol.contents = currentCol.contents + 1
                }
                i.contents = i.contents + 1
              }
              | _ => i.contents = i.contents + 1
            }
          }
          // Move to next row after processing this line
          currentRow.contents = currentRow.contents + 1
        }
      })
      if currentRow.contents > rows.contents {
        None
      } else {
        Some((grid, rows.contents, cols.contents))
      }
    }
  }
}

type action =
  | Toggle
  | Step
  | Clear
  | Randomize
  | SetSpeed(int)
  | ToggleCell(int, int)
  | LoadPreset(preset)
  | LoadCustomPreset(array<cell>)
  | SetRule(rule)

type state = {
  grid: array<cell>,
  rows: int,
  cols: int,
  running: bool,
  speed: int,
  generation: int,
  rule: rule,
  ages: array<int>,
}

let reducer = (state, action) =>
  switch action {
  | Toggle => {...state, running: !state.running}
  | Step   =>
    let (next_grid, next_ages) = compute_next_gen_with_age(state.grid, state.ages, state.rows, state.cols)
    {...state, grid: next_grid, ages: next_ages, generation: state.generation + 1}
  | Clear  =>
    let new_ages = make_ages(state.rows, state.cols)
    {...state, grid: make_grid(state.rows, state.cols), ages: new_ages, running: false, generation: 0}
  | Randomize =>
    let new_ages = make_ages(state.rows, state.cols)
    {...state, grid: randomize_grid(state.rows, state.cols), ages: new_ages, generation: 0}
  | SetSpeed(speed) => {...state, speed}
  | ToggleCell(r, c) =>
    let next_grid = Belt.Array.copy(state.grid)
    let next_ages = Belt.Array.copy(state.ages)
    let cur = get_cell(next_grid, state.cols, r, c)
    set_cell(next_grid, state.cols, r, c, switch cur { | Alive => Dead | Dead => Alive })
    {...state, grid: next_grid, ages: next_ages}
  | LoadPreset(p) =>
    let new_ages = make_ages(state.rows, state.cols)
    {...state, grid: load_preset(p, state.rows, state.cols), ages: new_ages, running: false, generation: 0}
  | LoadCustomPreset(cells) =>
    let new_ages = make_ages(state.rows, state.cols)
    {...state, grid: cells, ages: new_ages, running: false, generation: 0}
  | SetRule(r) => {...state, rule: r}
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
  rule: conway,
  ages: make_ages(rows, cols),
}
