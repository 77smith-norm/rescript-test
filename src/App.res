@val external windowInnerWidth: int = "window.innerWidth"
@val external addEventListener: (string, unit => unit) => unit = "window.addEventListener"
@val external removeEventListener: (string, unit => unit) => unit = "window.removeEventListener"
@val external localStorageGetItem: string => Nullable.t<string> = "localStorage.getItem"
@val external localStorageSetItem: (string, string) => unit = "localStorage.setItem"

type savedPreset = {name: string, cells: string}

let computeCellSize = (cols: int): int => {
  let available = windowInnerWidth - 32
  let size = available / cols
  if size > 15 { 15 } else if size < 8 { 8 } else { size }
}

let storageKey = "gol:custom-presets"

let loadFromStorage = (): array<savedPreset> => {
  switch Nullable.toOption(localStorageGetItem(storageKey)) {
  | None => []
  | Some(raw) =>
    switch JSON.parseOrThrow(raw) {
    | json =>
      switch json {
      | Array(items) =>
        items->Array.filterMap(item =>
          switch item {
          | Object(obj) =>
            switch (obj->Dict.get("name"), obj->Dict.get("cells")) {
            | (Some(String(name)), Some(String(cells))) => Some({name, cells})
            | _ => None
            }
          | _ => None
          }
        )
      | _ => []
      }
    | exception _ => []
    }
  }
}

let saveToStorage = (presets: array<savedPreset>): unit => {
  let json = JSON.stringifyAny(presets->Array.map(p => {"name": p.name, "cells": p.cells}))
  switch json {
  | Some(s) => localStorageSetItem(storageKey, s)
  | None => ()
  }
}

@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(GameOfLife.reducer, GameOfLife.initial_state)
  let (cellSize, setCellSize) = React.useState(() => computeCellSize(GameOfLife.cols))
  let (customPresets, setCustomPresets) = React.useState(() => loadFromStorage())
  let (presetName, setPresetName) = React.useState(() => "")

  // Animation interval
  React.useEffect2(() => {
    if state.running {
      let id = setInterval(() => dispatch(GameOfLife.Step), state.speed)
      Some(() => clearInterval(id))
    } else {
      None
    }
  }, (state.running, state.speed))

  // Responsive cell size — updates on window resize
  React.useEffect0(() => {
    let handler = () => setCellSize(_ => computeCellSize(GameOfLife.cols))
    addEventListener("resize", handler)
    Some(() => removeEventListener("resize", handler))
  })

  let gridWidth = state.cols * cellSize
  let gridHeight = state.rows * cellSize

  let renderCell = (r, c): React.element => {
    let age = GameOfLife.get_age(state.ages, state.cols, r, c)
    let color = GameOfLife.compute_age_color(age)
    <div
      key={Int.toString(c)}
      onClick={_ => dispatch(GameOfLife.ToggleCell(r, c))}
      className="cursor-pointer"
      style={{width: Int.toString(cellSize) ++ "px", height: Int.toString(cellSize) ++ "px", backgroundColor: color}}
    />
  }

  let renderRow = (r: int): React.element => {
    <div key={Int.toString(r)} className="flex">
      {React.array(Array.fromInitializer(~length=state.cols, c => renderCell(r, c)))}
    </div>
  }

  let renderGrid = (): React.element =>
    React.array(Array.fromInitializer(~length=state.rows, r => renderRow(r)))

  let liveCount = GameOfLife.count_alive(state.grid)

  let maxAge = state.ages->Array.reduce(0, (acc, age) => if age > acc { age } else { acc })

  let ruleLabel = switch state.rule {
    | _ if state.rule == GameOfLife.conway => "Conway (B3/S23)"
    | _ if state.rule == GameOfLife.highlife => "HighLife (B36/S23)"
    | _ if state.rule == GameOfLife.maze => "Maze (B3/S12345)"
    | _ if state.rule == GameOfLife.dayAndNight => "Day & Night (B3678/S34678)"
    | _ => "Custom"
  }

  let handleSpeedChange = (e: ReactEvent.Form.t) => {
    let value: string = ReactEvent.Form.target(e)["value"]
    switch Int.fromString(value) {
    | Some(speed) => dispatch(GameOfLife.SetSpeed(600 - speed * 5))
    | None => ()
    }
  }

  <div className="min-h-screen bg-slate-900 text-white flex flex-col items-center p-3 md:p-8">
    <h1 className="text-2xl md:text-4xl font-bold mb-4 md:mb-8">
      {React.string("Conway's Game of Life")}
    </h1>
    <div className="flex flex-wrap gap-2 mb-4 justify-center">
      <button
        onClick={_ => dispatch(GameOfLife.Toggle)}
        className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-medium"
      >
        {React.string(state.running ? "Pause" : "Play")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Step)}
        className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg font-medium"
      >
        {React.string("Step")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Clear)}
        className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg font-medium"
      >
        {React.string("Clear")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Randomize)}
        className="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg font-medium"
      >
        {React.string("Randomize")}
      </button>
    </div>
    <div className="flex flex-wrap gap-2 mb-4 justify-center">
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Glider))}
        className="px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm"
      >
        {React.string("Glider")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Blinker))}
        className="px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm"
      >
        {React.string("Blinker")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Pulsar))}
        className="px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm"
      >
        {React.string("Pulsar")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.RPentomino))}
        className="px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm"
      >
        {React.string("R-Pentomino")}
      </button>
    </div>
    <div className="flex flex-wrap gap-2 mb-4 justify-center">
      <button
        onClick={_ => dispatch(GameOfLife.SetRule(GameOfLife.conway))}
        className={if state.rule == GameOfLife.conway { "px-3 py-1 bg-purple-700 hover:bg-purple-600 rounded-lg font-medium text-sm" } else { "px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm" }}
      >
        {React.string("Conway")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.SetRule(GameOfLife.highlife))}
        className={if state.rule == GameOfLife.highlife { "px-3 py-1 bg-purple-700 hover:bg-purple-600 rounded-lg font-medium text-sm" } else { "px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm" }}
      >
        {React.string("HighLife")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.SetRule(GameOfLife.maze))}
        className={if state.rule == GameOfLife.maze { "px-3 py-1 bg-purple-700 hover:bg-purple-600 rounded-lg font-medium text-sm" } else { "px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm" }}
      >
        {React.string("Maze")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.SetRule(GameOfLife.dayAndNight))}
        className={if state.rule == GameOfLife.dayAndNight { "px-3 py-1 bg-purple-700 hover:bg-purple-600 rounded-lg font-medium text-sm" } else { "px-3 py-1 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium text-sm" }}
      >
        {React.string("Day & Night")}
      </button>
    </div>
    <div className="flex gap-6 mb-3 text-sm font-mono">
      <span className="text-slate-400">
        {React.string("Gen: " ++ Int.toString(state.generation))}
      </span>
      <span className="text-slate-400">
        {React.string("Live: " ++ Int.toString(liveCount))}
      </span>
      <span className="text-slate-400">
        {React.string("Max Age: " ++ Int.toString(maxAge))}
      </span>
      <span className="text-slate-400">
        {React.string("Rule: " ++ ruleLabel)}
      </span>
    </div>
    <div className="flex flex-col items-center gap-4 mb-6">
      <div
        style={{width: Int.toString(gridWidth) ++ "px", height: Int.toString(gridHeight) ++ "px"}}
        className="border border-slate-700"
      >
        {renderGrid()}
      </div>
      <div className="flex items-center gap-2 w-full max-w-xs">
        <label htmlFor="speed-slider" className="text-sm text-slate-400 whitespace-nowrap">
          {React.string("Speed:")}
        </label>
        <input
          id="speed-slider"
          type_="range"
          min="0"
          max="120"
          defaultValue="60"
          onChange={handleSpeedChange}
          className="flex-1 h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer"
        />
      </div>
      <div className="flex flex-wrap gap-2 mt-4 justify-center items-center">
        <input
          type_="text"
          placeholder="Preset name..."
          value={presetName}
          onChange={e => setPresetName(_ => ReactEvent.Form.target(e)["value"])}
          className="px-3 py-1 bg-slate-700 rounded-lg text-sm text-white border border-slate-600 focus:outline-none"
        />
        <button
          onClick={_ => {
            let trimmed = String.trim(presetName)
            if String.length(trimmed) > 0 && !Array.some(customPresets, p => p.name == trimmed) {
              let newPreset = {name: trimmed, cells: GameOfLife.serialize_grid(state.grid)}
              let updated = Array.concat(customPresets, [newPreset])
              setCustomPresets(_ => updated)
              saveToStorage(updated)
              setPresetName(_ => "")
            }
          }}
          className="px-3 py-1 bg-yellow-600 hover:bg-yellow-500 rounded-lg font-medium text-sm"
        >
          {React.string("Save Preset")}
        </button>
      </div>
      {if Array.length(customPresets) > 0 {
        <div className="flex flex-wrap gap-2 mt-2 justify-center">
          {React.array(customPresets->Array.map(p =>
            <div key={p.name} className="flex items-center gap-1">
              <button
                onClick={_ => {
                  let cells = GameOfLife.deserialize_grid(p.cells)
                  dispatch(GameOfLife.LoadCustomPreset(cells))
                }}
                className="px-3 py-1 bg-teal-700 hover:bg-teal-600 rounded-lg font-medium text-sm"
              >
                {React.string(p.name)}
              </button>
              <button
                onClick={_ => {
                  let updated = Array.filter(customPresets, q => q.name != p.name)
                  setCustomPresets(_ => updated)
                  saveToStorage(updated)
                }}
                className="px-2 py-1 bg-slate-700 hover:bg-red-700 rounded text-xs"
              >
                {React.string("×")}
              </button>
            </div>
          ))}
        </div>
      } else {
        React.null
      }}
    </div>
  </div>
}
