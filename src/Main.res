@@live

switch ReactDOM.querySelector("#root") {
| None => ()
| Some(root) =>
  ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
}
