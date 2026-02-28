@react.component
let make = (~label: string, ~onClick: unit => unit) =>
  <button
    onClick={_ => onClick()}
    className="px-6 py-2 bg-purple-600 hover:bg-purple-700 rounded-lg font-medium transition-colors">
    {React.string(label)}
  </button>
