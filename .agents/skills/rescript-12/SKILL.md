---
name: rescript-12
description: Write ReScript v12 code. Use when working with ReScript projects, especially v12. Covers critical syntax differences from JavaScript/TypeScript, common pitfalls, and stdlib usage.
---

# ReScript v12 Development Guide

This skill provides guidance for writing ReScript v12 code, particularly for avoiding common syntax traps that trip up agents unfamiliar with the language.

## Critical Syntax Rules

### Refs (Mutable State)

**DO NOT use** `!ref` or `ref := value`. This syntax is deprecated in v12.

**USE** `.contents` to read and write:

```res
// Creating a ref
let count = ref(0)

// Reading
let current = count.contents

// Writing
count.contents = count.contents + 1
```

### Loops

**DO NOT use** traditional JavaScript-style `for` loops:
```res
// WRONG - will cause parser errors
for (let i = 0; i < 10; i++) {
  Console.log(i)
}
```

**USE** `while` loops with manual increment:
```res
// Correct ReScript v12
let i = ref(0)
while i.contents < 10 {
  Console.log(Int.toString(i.contents))
  i.contents = i.contents + 1
}
```

**OR USE** functional alternatives:
```res
// Array.forEach
[1, 2, 3]->Array.forEach(x => {
  Console.log(Int.toString(x))
})

// Array.reduce
let sum = [1, 2, 3]->Array.reduce(0, (acc, x) => acc + x)
```

### Array Creation

**BE CAREFUL** with labeled arguments. The `length:` label can collide with JSX `:` characters in certain contexts.

```res
// Safe ways to create arrays
let arr = Array.make(10, 0)  // Correct: no label
let arr2 = Belt.Array.make(10, 0)  // Also safe

// AVOID labeled arguments that might conflict with JSX in the same file
```

### Array Reading vs Writing — Critical!

**READING** an array returns an option:
```res
let arr = Belt.Array.make(10, Dead)
let val = arr[5]  // val has type: option<cell>
// Must pattern match or use switch:
switch arr[5] {
| Some(cell) => ...
| None => ...
}
```

**WRITING** takes the raw value — do NOT wrap in `Some`:
```res
// WRONG - will cause type errors
arr[5] = Some(Alive)

// CORRECT - write raw value directly
arr[5] = Alive
```

### Flat 1D Arrays for Grids (Recommended)

When implementing 2D grids (like game boards), use a **flat 1D array** instead of nested arrays. This avoids option-wrapping issues from double indexing:

```res
// Instead of array<array<cell>> which causes grid[row][col] to return option<option<cell>>
type cell = Alive | Dead

// Flat 1D approach: index = r * cols + c
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
```

### Unit Discarding

When mutating inside expressions, you must discard the unit result:

```res
// WRONG
let _ = count.contents = count.contents + 1  // Assignment returns unit in this context

// CORRECT - use a separate statement
count.contents = count.contents + 1

// OR use this pattern for expression context
let _ = {
  count.contents = count.contents + 1
  ()
}
```

### Variants

**DO NOT confuse** variant constructors with types:

```res
// Define type
type state = Alive | Dead

// Use constructors (no prefix)
let s = Alive
switch s {
| Alive => Console.log("alive")
| Dead => Console.log("dead")
}

// AVOID: Dead (capital D) is a constructor, not a type
// If you need a type, use: type state = ...
```

### Continue in Loops

ReScript does NOT have a `continue` keyword. Use boolean flags or restructure:

```res
// Instead of continue, use if statements
let result = ref(list{})
let i = ref(0)
while i.contents < 10 {
  if i.contents !== 5 {
    // Skip 5
    result.contents = list{i.contents, ...result.contents}
  }
  i.contents = i.contents + 1
}
```

## React/JSX Patterns

### JSX String Children

**ALWAYS** wrap string children in `React.string()`:

```res
// WRONG - will not render
<div>{"Hello World"}</div>

// CORRECT
<div>{React.string("Hello World")}</div>
```

### useEffect Return Types

`React.useEffect0`, `React.useEffect1`, `React.useEffect2` expect specific return types:

```res
// useEffect2 expects: (unit => option<unit => unit>)
React.useEffect2(() => {
  if someCondition {
    let id = Js.Global.setInterval(...)
    Some(() => Js.Global.clearInterval(id))  // Return Some(cleanup)
  } else {
    None  // Must return None, not omitted
  }
}, (dep1, dep2))
```

### JSX Children Must Be Arrays

JSX children expect `array<React.element>`, not `list`. Convert if needed:

```res
// Use Array.map, not List.map
<div>
  {Array.map(item => <span>{React.string(item)}</span>, items)}
</div>
```

### Event Handlers

```res
// onChange handler pattern
<select
  onChange={e => {
    let value = ReactEvent.FormTarget.value(e)
    dispatch(MyAction(Int.fromString(value)))
  }}>
  ...
</select>
```

Note: Use `Int.fromString` which returns `option<int>`, not `Int.of_string`.

## Reducer Best Practices

### Actions Should Not Mutate Unrelated State

Be careful that actions don't accidentally change state you didn't intend:

```res
// WRONG - Step should NOT touch running state, or it breaks interval loops
| Step =>
  let new_grid = compute_next_gen(state.grid, ...)
  {...state, grid: new_grid, running: false}  // This breaks the animation!

// CORRECT - Step only advances the grid
| Step =>
  {...state, grid: compute_next_gen(state.grid, ...)}
```

### Use Separate Actions for Different Concerns

Instead of one action doing multiple things, create separate actions:

```res
// Instead of having Step also update running state:
| Step => compute_next_gen(...)
| Toggle => toggle running
| ToggleCell(r, c) => toggle specific cell
```

## v12 Migration Quick Reference

| Old (v11) | New (v12) |
|-----------|-----------|
| `!ref` | `ref.contents` |
| `ref := val` | `ref.contents = val` |
| `@bs.as("x")` | `@as("x")` |
| `@bs.send` | `@send` |
| `@bs.new` | `@new` |
| `lnot(a)` | `~~~a` |
| `land(a, b)` | `a &&& b` |
| `lor(a, b)` | `a \|\| b` |
| `lxor(a, b)` | `a ^^^ b` |
| `lsl(a, b)` | `a << b` |
| `lsr(a, b)` | `a >> b` |
| `asr(a, b)` | `a >>> b` |
| `Error.t` | `JsError.t` |
| `Js.Exn.Error` | `JsExn` |
| `assert 1 == 2` | `assert(1 == 2)` |
| `rescript build` | `rescript` |
| `rescript build -w` | `rescript watch` |
| `Js.Global.setInterval` | `setInterval` (global) |

## Standard Library

ReScript v12 ships with a new stdlib. Common imports:

```res
// Most modules are auto-opened, but if needed:
open Array
open Belt.Array
open List
open String
open Int
open Bool
```

### Common Array Operations

```res
let arr = [1, 2, 3]

// Get element (returns option)
let first = arr[0]  // Some(1)
let tenth = arr[10]  // None

// Set element
arr[0] = 10

// Map
let doubled = arr->Array.map(x => x * 2)

// Filter
let evens = arr->Array.filter(x => x mod 2 == 0)

// Reduce
let sum = arr->Array.reduce(0, (acc, x) => acc + x)

// Push (mutates)
arr->Array.push(4)
```

### Console Output

```res
Console.log("hello")      // prints to console
Console.log2("a", "b")    // prints multiple values
```

## DOM/HTML in ReScript

When working with JSX, remember:

1. **Capitalize components**: `<MyComponent />` not `<myComponent />`
2. **Attributes use ReScript syntax**: `className` not `class`, `onClick` not `onclick`
3. **No `for` attribute**: use `htmlFor`
4. **Inline styles**: pass a JS object, not a string
5. **String children**: wrap in `React.string()`

```res
<div onClick={_ => Console.log("clicked")} className="container">
  <span style={{"color": "red"}}>Hello</span>
</div>
```

## Build Commands

```bash
# Build
rescript

# Watch mode
rescript watch

# Format
rescript format
```

## Common Error Patterns

1. **JSX parser collision**: If you see errors about `:` or `=`, check for JSX conflicts in your code
2. **Unit expected**: You're likely using an expression that returns `unit` where a value is expected — add `let _ =` wrapper or separate statements
3. **Unbound variant**: Make sure you've defined the type first: `type myType = Variant1 | Variant2`
4. **"This has type X but expected Y" on array access**: Check if you're writing `Some(val)` to an array that should hold raw values
5. **"Function takes X arguments but got Y" in useEffect**: Check that both branches return the same type (e.g., both return `None`, not one returning a value and one returning `None`)

## Project Structure

Typical ReScript project:

```
project/
├── src/
│   ├── Main.res      # Entry point
│   ├── Component.res # Components
│   └── Utils.res     # Utilities
├── rescript.json     # Build config (was bsconfig.json)
└── package.json
```
