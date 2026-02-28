# AGENTS.md — Conway's Game of Life (ReScript v12)

## Project Overview

Conway's Game of Life in ReScript v12 + React + Vite + Tailwind CSS v4. This is a harness engineering experiment comparing local LLM agents (OpenCode/Qwen3.5-35B on crosby) against cloud agents. The app is deployed to GitHub Pages.

**Live URL:** https://77smith-norm.github.io/rescript-test/

## Tech Stack

- **Language:** ReScript v12
- **UI:** React 19 + JSX v4
- **Build:** Vite v7 + ReScript compiler (`rescript` CLI)
- **Styling:** Tailwind CSS v4
- **Package manager:** pnpm
- **Deploy:** GitHub Pages via GitHub Actions

## Project Location

`/Users/norm/Developer/rescript-test/`

## Current State (as of 2026-02-28)

✅ **Complete and deployed:**
- Flat 1D array grid (20 rows × 40 cols)
- Conway's Game of Life rules
- Div-based grid renderer with click-to-toggle
- Controls: Play/Pause, Step, Clear, Randomize
- Speed slider
- Pattern presets: Glider, Blinker, Pulsar, R-Pentomino
- Responsive design (dynamic cell size from window.innerWidth)

## Build & Test

```bash
# Compile ReScript
npx rescript

# Run dev server
npm run dev

# Production build (Vite)
npm run build
```

**Always run `npx rescript` after any `.res` file change and fix all errors before moving on.**

## Project Structure

```
src/
  GameOfLife.res     — Game logic: cell types, grid ops, reducer, presets
  App.res            — Main React component: layout, grid renderer, controls
  Button.res         — Reusable button component
  Main.res           — Entry point
.agents/skills/
  rescript-12/SKILL.md  — MUST READ before writing any ReScript
.github/workflows/
  deploy.yml         — GitHub Actions: rescript build → vite build → Pages deploy
```

## Skill Reference

**ALWAYS read `.agents/skills/rescript-12/SKILL.md` before writing any ReScript.**

It documents critical v12 syntax rules, JSX patterns, and every trap that has caused compile failures in this project. Reading it first has been proven to prevent repeat mistakes.

## Off-Limits

- Do NOT modify `Button.res`, `Main.res`, or `rescript.json`
- Do NOT change the grid dimensions (rows=20, cols=40 defined in `GameOfLife.res`)
- Do NOT remove or change existing actions/reducer cases
- Do NOT install new npm packages without checking first

## Known Issues — Read Before Writing Code

These are real failures from previous agent runs. Don't repeat them.

### 1. `@rescript/runtime` must be in package.json

ReScript v12 compiled output imports from `@rescript/runtime`. pnpm nests it as a transitive dep of `rescript`, but Vite/Rollup cannot resolve it on CI unless it is listed **explicitly** in `package.json` dependencies.

**It is already added. Do not remove it.**

```json
"@rescript/runtime": "12.2.0"
```

### 2. Do NOT hardcode viewport widths

When writing responsive layout code, read the actual viewport:

```res
@val external windowInnerWidth: int = "window.innerWidth"
```

**WRONG — hardcodes iPhone width, breaks on every other device:**
```res
let maxWidth = 390 - 32  // ← never do this
```

**CORRECT:**
```res
let available = windowInnerWidth - 32
let cellSize = if available / cols > 15 { 15 } else { available / cols }
```

### 3. Do NOT touch existing useEffect hooks unless asked

When adding new effects (e.g. a resize listener), add a separate `useEffect0`. Do NOT modify the existing animation `useEffect2` — it controls the game loop and breaking it stops the simulation.

**WRONG — agent replaced the animation effect with a fake one:**
```res
// Previous agent replaced the real animation loop with this:
let _ = setInterval(() => (), 1000)  // ← useless, breaks Play/Pause
Some(() => ())
```

**CORRECT pattern for adding a resize listener:**
```res
// Keep the existing animation effect untouched:
React.useEffect2(() => {
  if state.running {
    let id = setInterval(() => dispatch(GameOfLife.Step), state.speed)
    Some(() => clearInterval(id))
  } else {
    None
  }
}, (state.running, state.speed))

// Add resize listener as a separate useEffect0:
React.useEffect0(() => {
  let handler = () => setCellSize(_ => computeCellSize(GameOfLife.cols))
  addEventListener("resize", handler)
  Some(() => removeEventListener("resize", handler))
})
```

### 4. Externals for browser APIs

To access browser globals in ReScript, declare them as externals:

```res
@val external windowInnerWidth: int = "window.innerWidth"
@val external addEventListener: (string, unit => unit) => unit = "window.addEventListener"
@val external removeEventListener: (string, unit => unit) => unit = "window.removeEventListener"
```

Do NOT try to access `window.innerWidth` as plain ReScript — it won't compile.

### 5. ReScript JSX and syntax traps (summary — full details in rescript-12 skill)

- `type_="range"` not `type="range"` — `type` is a reserved keyword
- `{React.string("Speed:")}` not `>Speed:</` — bare text with `:` breaks the parser
- Inline style is a record: `style={{width: "600px"}}` not `{"width": 600}`
- `Array.fromInitializer(~length=n, i => ...)` — `List.range` does not exist
- Wrap JSX array output in `React.array(...)`
- `ReactEvent.Form.target(e)["value"]` — `ReactEvent.FormTarget` does not exist

## GitHub Actions Deploy

The workflow at `.github/workflows/deploy.yml` runs on every push to `main`:

1. `pnpm install` — installs all deps including `@rescript/runtime`
2. `pnpm res:build` — compiles `.res` → `.res.mjs`
3. `pnpm build` — Vite bundles `.res.mjs` + React → `dist/`
4. Deploys `dist/` to GitHub Pages

**To check a deploy:** `gh run list --repo 77smith-norm/rescript-test`
**To read failure logs:** `gh run view <id> --log-failed`
**Live site:** https://77smith-norm.github.io/rescript-test/

## Session 4 — Generation Counter + Live Cell Stats (2026-02-28)

**Result: ✅ Clean on first run.** Agent (session 0738e01c) got every reducer case correct with zero intervention needed.

### What the agent got right
- Added `generation: int` to state type and `initial_state`
- Correctly incremented on `Step`, reset on `Clear`/`Randomize`/`LoadPreset`
- Correctly left `Toggle`, `SetSpeed`, `ToggleCell` untouched
- Computed `liveCount` as derived data in `App.res` (did NOT add it to state)
- Used `count_alive` helper as instructed

### Assessment
The explicit reducer table in the prime prompt ("this table is the entire correctness requirement") was the key. When the expected behaviour is spelled out row by row with no ambiguity, the agent executes correctly. Vague prompts leave room for mistakes; precise tables do not.

### Harness observation
Three sessions with skill file updates → measurable improvement. The agent is no longer tripping on JSX syntax. The prime prompt quality is now the primary variable in output quality.
