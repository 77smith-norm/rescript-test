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
    <div className="text-slate-400 text-sm"> {React.string("Grid rendering: TODO")} </div>
  </div>
}
