# Conway's Game of Life — Project Context

## Project Overview

Build a Conway's Game of Life implementation in ReScript v12. This is a learning project to explore ReScript syntax and compare local LLM coding agents (OpenCode with Qwen3.5-35B) against cloud agents (Codex, Claude).

## Tech Stack

- **Language:** ReScript v12
- **Build:** Vite + ReScript compiler
- **Rendering:** HTML5 Canvas or DOM-based
- **State:** Game grid stored as 2D array

## Project Location

`/Users/norm/Developer/rescript-test/`

## Project Goals

1. Implement classic Conway's Game of Life rules:
   - Any live cell with 2 or 3 neighbors survives
   - Any dead cell with exactly 3 neighbors becomes alive
   - All other live cells die, all other dead cells stay dead

2. Render the grid visually (canvas or DOM)

3. Support controls: Start, Stop, Reset, Step

4. Make it interactive: Click cells to toggle state

## Current Status

- Project scaffolded with Vite + ReScript template
- Initial compilation attempted but had syntax errors
- Agent was working through fixing ReScript v12 syntax issues

## Known Issues / Blockers

1. **ReScript v12 Syntax:** The agent struggled with:
   - Using deprecated ref syntax (`!count`, `count :=`)
   - Attempting JS-style `for` loops (not valid in ReScript)
   - Array.create syntax conflicts with JSX
   - Variant constructor usage

2. **M3 Max MacBook Pro:** May have gone to sleep during agent run. Verify it's awake before spawning new agents.

## Skill Reference

**ALWAYS load and follow** the `rescript-12` skill before writing any ReScript code:

```
.agents/skills/rescript-12/SKILL.md
```

This skill documents:
- Correct ref usage (`.contents`)
- Loop alternatives (while, forEach, reduce)
- v12 migration changes
- Common syntax traps

## Agent Commands

To build the project:
```bash
cd /Users/norm/Developer/rescript-test
rescript watch
```

To run the dev server:
```bash
npm run dev
```

## What Success Looks Like

1. The game renders in the browser
2. Cells evolve according to Conway's rules
3. Controls work (start/stop/reset/step)
4. Clicking cells toggles their state
5. Code compiles without errors
6. Project runs with `npm run dev`
