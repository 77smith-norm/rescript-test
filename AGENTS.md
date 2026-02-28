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

## Testing

**Unit tests are mandatory. Run them after every change.**

```bash
pnpm test
```

This runs `rescript && vitest run` — compiles first, then runs the suite. **All 27 tests must pass before you consider a task complete.**

### Test file location

`__tests__/GameOfLife_Test.res` — compiled to `__tests__/GameOfLife_Test.res.mjs`

Tests cover all pure functions in `GameOfLife.res`: `make_grid`, `get_cell`, `set_cell`, `count_live_neighbors`, `compute_next_gen` (all 4 Conway rules + blinker oscillation + block still life), and `count_alive`.

### TDD workflow

When implementing a new feature:
1. Add tests for the new behavior to `__tests__/GameOfLife_Test.res`
2. Compile: `npx rescript`
3. Confirm new tests fail (red)
4. Implement the feature in `GameOfLife.res`
5. Compile again: `npx rescript`
6. Run: `pnpm test` — all tests must be green

### Critical: Vitest version

**Use vitest v3, not v4.** rescript-vitest v2.1.1 is incompatible with Vitest v4 ("No test suite found" error). vitest is pinned to ^3 in package.json. Do NOT upgrade it.

### Test conventions

- Tests live in `__tests__/GameOfLife_Test.res` (add to the existing file)
- Use `open Vitest` at the top
- Pattern: `t->expect(actual)->Expect.toBe(expected)`
- Variants (`Alive`, `Dead`) compare correctly with `toBe` — they compile to strings in v12
- Do NOT test React components or DOM behavior — only pure `GameOfLife.res` functions

## Dead Code Analysis (reanalyze)

**Run after every change.** Dead code analysis is part of the quality gate.

```bash
# DCE analysis — text output
pnpm run res:analyze

# DCE analysis — JSON output (for agent parsing)
pnpm run res:analyze:json

# Full quality gate: DCE + tests
pnpm run check
```

`pnpm run check` = `res:analyze:json && pnpm test`. **Both must pass.**

### What reanalyze checks

- Dead values (functions/bindings that are never called)
- Dead types, record fields, variant cases (defined but never used)
- Uses `rescript-tools reanalyze -dce` — ships with the `rescript` package (v12.2+)
- Reads `.cmt` files from the previous build — always runs `rescript` first

### Clean output

A clean run looks like:
```
[ ]
```
(Empty JSON array, exit code 0.)

Any warnings mean the agent introduced dead code and must fix it before the task is complete.

### Annotations

When a value must exist but reanalyze can't see its caller (e.g. entry points called from JS):

```res
// Top of file — marks ALL items in the file as live
@@live

// Single value
@live
let myExternallyCalledFn = ...
```

For React entry points like `Main.res` — the `make` function is called from `index.html`, not from ReScript. Mark the whole file `@@live`.

**Do NOT add `@@live` to suppress genuine dead code.** Fix or remove unused code instead.

### Known baseline

- `Main.res` — marked `@@live` (entry point called from HTML)
- `Button.res` — removed (was genuinely unused scaffolding)
- `__tests__/` — compiled as `"type": "dev"` so test-only symbols don't generate false DCE warnings

## Project History

A log of what was built and when, for continuity across sessions.

| Session | Feature | Key Outcome |
|---------|---------|-------------|
| Session 1 | Scaffold + core game logic | ReScript v12 + React + Vite + Tailwind. Flat 1D grid, Conway rules, div-based renderer |
| Session 2 | Pattern presets | Glider, Blinker, Pulsar, R-Pentomino. Skill compounding began — session avoided all session 1 JSX traps |
| Session 3 | Responsive design | Dynamic cell size from viewport width. Agent hardcoded 390px and broke animation — manually fixed |
| Session 4 | Generation counter + live cell stats | Explicit reducer table in prime → clean first run, zero intervention |
| Option B | Toroidal edges | TDD: 9 failing tests written first. OpenCode implemented `count_live_neighbors` modulo wrap. 36/36 |
| Option C | localStorage custom presets | `serialize_grid`, `deserialize_grid` pure functions + App.res UI. 43/43. Used deprecated Js.Nullable APIs — fixed post-run |
| Harness | Unit test suite + reanalyze | Vitest setup, 43 tests across all pure functions. DCE analysis baseline: clean. `pnpm run check` = full quality gate |

---

## Roadmap

Features planned for future OpenCode sessions, in order. Each should follow the TDD pattern: write failing tests first, confirm red, then prime and spawn.

### Option D — Cell Age / Color Gradient

Cells accumulate age over time. Surviving cells increment age each generation; newly born cells start at age 1; dead cells reset to 0. The renderer colors cells by age — creating a visual gradient that shows which parts of the grid are actively changing vs. stable.

**Pure logic changes:**
- Add `ages: array<int>` alongside `grid` in state
- Refactor `compute_next_gen` to return `(next_grid, next_ages)` tuple, or a record
- Rule: surviving cell → age + 1; new birth → 1; death → 0
- New function: `compute_age_color(age: int): string` → CSS color value

**Tests to write first:**
- Surviving cell increments age
- New birth sets age to 1
- Dead cell resets age to 0
- Block still life: all cells reach age N after N generations
- Empty grid: all ages remain 0

**Harness interest:** Adds parallel state arrays with non-trivial interaction. First test of whether OpenCode can evolve two arrays in lockstep correctly.

---

### Option E — Custom Life-Like Rules

Parameterize the ruleset so Conway (`B3/S23`) is just one option. Add a `rule` field to state with birth and survival neighbor count sets. Include preset rules selectable from the UI.

**Preset rules to include:**
- Conway: `B3/S23` (birth on 3, survive on 2-3) — current hardcoded behavior
- HighLife: `B36/S23` (adds glider replication)
- Maze: `B3/S12345` (generates maze-like structures)
- Day & Night: `B3678/S34678` (symmetric, self-complementary)

**Pure logic changes:**
- Add `type rule = { birth: array<int>, survival: array<int> }` to GameOfLife.res
- Refactor `compute_next_gen` to accept a `rule` parameter
- Add `type action = ... | SetRule(rule)` and reducer case
- Add preset rule definitions as named constants

**Tests to write first:**
- Blinker survives under Conway but verify behavior changes under rules where `S2` is absent
- Dead cell with 3 neighbors: born under Conway, not under a rule without `B3`
- Rule round-trip: changing rule and back produces expected results
- Verify existing 36 tests still pass with the Conway rule passed explicitly

**Harness interest:** First real *refactor* — changing an existing function signature rather than adding beside it. Tests protect existing behavior while prime describes the new shape.

---

### Option F — RLE Import / Export

Run Length Encoding is the standard format for Conway Life patterns. Add a UI panel where users can paste RLE text to load any pattern from [conwaylife.com](https://conwaylife.com), and export the current grid as RLE to share.

**RLE format basics:**
- Header: `x = cols, y = rows, rule = B3/S23`
- Body: runs of `b` (dead) and `o` (alive), `$` = end of row, `!` = end of pattern
- Numbers prefix runs: `3o` = three alive cells, `2b` = two dead cells

**Pure logic changes:**
- New functions: `encode_rle(grid, rows, cols) → string`
- `decode_rle(s) → option<(array<cell>, int, int)>` (grid + dimensions, or None on parse failure)

**Tests to write first:**
- Glider encodes to its canonical RLE string
- Blinker encodes correctly
- Decode a known RLE string and verify cell positions
- Round-trip: encode then decode gives identical grid
- Invalid RLE returns None gracefully

**Harness interest:** Entirely new pure module with rich, ground-truth test cases. Real-world utility — any pattern from the Conway wiki can be imported.

---

### Option G — URL State / Pattern Sharing

Encode the current grid state (or a custom preset) into the URL hash so patterns can be shared by link. Load state from URL on mount if a hash is present.

**Pure logic changes:**
- `encode_url_state(grid) → string` — compact encoding (base64 or hex of the binary string)
- `decode_url_state(s) → option<array<cell>>` — decode and validate, return None on failure
- `useEffect0` in App.res to read `window.location.hash` on mount
- Update hash whenever a custom preset is saved

**Tests to write first:**
- Round-trip: encode then decode gives identical grid
- Known grid produces stable, reproducible URL string
- Malformed hash returns None without crashing
- Empty grid encodes/decodes correctly

**Harness interest:** Encoding is pure and highly testable. The mount behavior is a new pattern. Tests for the encoding layer are definitive even without DOM testing.

---

## Done When (Updated — All Future Sessions)

Every future OpenCode session must satisfy:

```bash
pnpm run check
```

Which runs: `rescript && rescript-tools reanalyze -dce -json && vitest run`

**Acceptance criteria:**
1. `pnpm run check` exits with code 0
2. DCE output is `[]` (no dead code introduced)
3. All tests pass (count increases as new tests are added)
4. The change is committed and pushed to origin/main

## Option E — Custom Life-Like Rules (2026-02-28)

**Result: ✅ Clean first run.** OpenCode session `option-e` implemented all changes correctly with zero steering.

### What was built
- `rule` type: `{ birth: array<int>, survival: array<int> }`
- `make_rule(birth, survival)` constructor
- `rule_has_birth(rule, n)` / `rule_has_survival(rule, n)` helpers using `Belt.Array.some`
- Preset rules: `conway` (B3/S23), `highlife` (B36/S23), `maze` (B3/S12345), `dayAndNight` (B3678/S34678)
- `compute_next_gen_rule(grid, rows, cols, rule)` — parameterized version, old `compute_next_gen` preserved for backward compat
- `SetRule(rule)` action + reducer case
- `rule: rule` field added to state + `initial_state`
- Rule selector UI in App.res: 4 buttons, active rule highlighted in purple, current rule label displayed

### Harness engineering notes
- **TDD worked cleanly.** 10 failing tests written first, all 53 pass post-implementation.
- **Key insight:** Agent used `Belt.Array.some` for membership checks — clean, idiomatic ReScript.
- **Pattern to note:** Agent preserved `compute_next_gen` alongside new `compute_next_gen_rule` exactly as instructed. Backward-compat enforcement through existing tests worked as designed.
- **No JSX traps.** The rescript-12 skill is fully compounding now — agent avoided all known pitfalls.

### Commits
- `aac88ce` — Option E: failing tests (red state)
- `d5b14bc` — Implement Option E: Custom Life-Like Rules

## Option D — Cell Age / Color Gradient (2026-02-28)

**Result: ✅ Clean first run.** OpenCode session `option-e` (reused) implemented all changes correctly.

### What was built
- `make_ages(rows, cols)` — creates zeros array of size rows*cols
- `get_age(ages, cols, r, c)` — safe get (0 for out-of-bounds)
- `set_age(ages, cols, r, c, value)` — updates age at position
- `count_nonzero_ages(ages)` — helper for tests
- `compute_next_gen_with_age(grid, ages, rows, cols)` — returns `(next_grid, next_ages)` tuple with Conway rules: survive → age+1, born → age=1, die → age=0
- `compute_age_color(age: int): string` — HSL color `hsl(200, 70%, ${lightness}%)` capped at 80% lightness
- `ages: array<int>` added to state + initial_state + all reducer cases (Clear/Randomize/LoadPreset/LoadCustomPreset reset, ToggleCell copies, Step uses compute_next_gen_with_age)
- App.res: cells colored by age, "Max Age" stat displayed

### Harness notes
- Agent fixed a `Expect.toBeGreaterThan` call in my test — that assertion doesn't exist in rescript-vitest. Good catch.
- Stale `.mjs` caused a false failure during check-in. Always compile before running tests.
- Old `compute_next_gen` still intact (tests protect it), new `compute_next_gen_with_age` alongside it.

### Commits
- `9d5b34f` — Option D: failing tests (red state)
- `ff521a1` — Implement Option D: Cell Age / Color Gradient
