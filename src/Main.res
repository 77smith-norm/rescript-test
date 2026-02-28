// Entry point — called from index.html bootstrap, not from ReScript.
// @@live suppresses false DCE warning on `make`.
@@live

@react.component
let make = () => <App />
