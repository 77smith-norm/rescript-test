@react.component
let make = () => {
  let (state, dispatch) = React.useReducer(GameOfLife.reducer, GameOfLife.initial_state)

  React.useEffect2(() => {
    if state.running {
      let id = setInterval(() => dispatch(GameOfLife.Step), state.speed)
      Some(() => clearInterval(id))
    } else {
      None
    }
  }, (state.running, state.speed))

  let cellSize = 15
  let gridWidth = state.cols * cellSize
  let gridHeight = state.rows * cellSize

  let renderCell = (r, c): React.element => {
    let cell = GameOfLife.get_cell(state.grid, state.cols, r, c)
    <div
      key={Int.toString(c)}
      onClick={_ => dispatch(GameOfLife.ToggleCell(r, c))}
      className={if cell == GameOfLife.Alive { "w-4 h-4 bg-white cursor-pointer" } else { "w-4 h-4 bg-slate-800 cursor-pointer" }}
    />
  }

  let renderRow = (r: int): React.element => {
    <div key={Int.toString(r)} className="flex">
      {React.array(Array.fromInitializer(~length=state.cols, c => renderCell(r, c)))}
    </div>
  }

  let renderGrid = (): React.element =>
    React.array(Array.fromInitializer(~length=state.rows, r => renderRow(r)))

  let handleSpeedChange = (e: ReactEvent.Form.t) => {
    let value: string = ReactEvent.Form.target(e)["value"]
    switch Int.fromString(value) {
    | Some(speed) => dispatch(GameOfLife.SetSpeed(600 - speed * 5))
    | None => ()
    }
  }

  <div className="min-h-screen bg-slate-900 text-white flex flex-col items-center p-8">
    <h1 className="text-4xl font-bold mb-8"> {React.string("Conway's Game of Life")} </h1>
    <div className="flex gap-4 mb-6">
      <button
        onClick={_ => dispatch(GameOfLife.Toggle)}
        className="px-6 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-medium"
      >
        {React.string(state.running ? "Pause" : "Play")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Step)}
        className="px-6 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg font-medium"
      >
        {React.string("Step")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Clear)}
        className="px-6 py-2 bg-red-600 hover:bg-red-700 rounded-lg font-medium"
      >
        {React.string("Clear")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.Randomize)}
        className="px-6 py-2 bg-green-600 hover:bg-green-700 rounded-lg font-medium"
      >
        {React.string("Randomize")}
      </button>
    </div>
    <div className="flex flex-col items-center gap-4 mb-6">
      <div
        style={{width: Int.toString(gridWidth) ++ "px", height: Int.toString(gridHeight) ++ "px"}}
        className="border border-slate-700"
      >
        {renderGrid()}
      </div>
      <div className="flex items-center gap-2">
        <label htmlFor="speed-slider" className="text-sm text-slate-400">
          {React.string("Speed:")}
        </label>
        <input
          id="speed-slider"
          type_="range"
          min="0"
          max="120"
          defaultValue="60"
          onChange={handleSpeedChange}
          className="w-48 h-2 bg-slate-700 rounded-lg appearance-none cursor-pointer"
        />
      </div>
    </div>
    <div className="flex gap-2 mb-6">
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Glider))}
        className="px-4 py-2 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium"
      >
        {React.string("Glider")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Blinker))}
        className="px-4 py-2 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium"
      >
        {React.string("Blinker")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.Pulsar))}
        className="px-4 py-2 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium"
      >
        {React.string("Pulsar")}
      </button>
      <button
        onClick={_ => dispatch(GameOfLife.LoadPreset(GameOfLife.RPentomino))}
        className="px-4 py-2 bg-slate-600 hover:bg-slate-500 rounded-lg font-medium"
      >
        {React.string("R-Pentomino")}
      </button>
    </div>
  </div>
}
