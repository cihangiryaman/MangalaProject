# Copilot Instructions

## Repository baseline
- Treat `cse2260_project1.pdf` as the source of truth for functional rules and output expectations.
- Consider the photos in the `cse2260_project1.pdf` too.
- There is no existing `README.md`, `CONTRIBUTING.md`, or other assistant-specific rule file in the repository yet.

## Build, test, and lint commands
- No build, test, or lint tooling is currently defined in this repository.
- There is no detectable Haskell project scaffold yet (no `*.cabal`, `stack.yaml`, `package.yaml`, test suite, or lint config).
- After scaffolding is added, document:
  - full build command,
  - full test command,
  - single-test command (for one test case/module),
  - lint command.

## MCP configuration in this repository
- Repo-level MCP config is stored in `.vscode/mcp.json`.
- The configured server is `github` via `https://api.githubcopilot.com/mcp/`.
- Use this config for repository-aware Copilot agent workflows in IDEs that support `.vscode/mcp.json`.

## Assignment implementation target
- Build a **fully runnable and compilable Haskell CLI program** for Modified Mangala.
- No GUI. All interaction must be terminal input/output.
- Keep a clear split between:
  - **Pure game logic**: board model, move execution, sowing, capture, extra turn, endgame.
  - **Console I/O**: prompts, safe input parsing, board rendering, winner output.

## Core game model requirements
- 2 players.
- Total 48 stones.
- Each player has:
  - 6 holes,
  - 1 store/box.
- Initial state: each hole has 4 stones.
- Preserve assignment orientation/indexing exactly:
  - Player 1 is bottom row,
  - Player 2 is top row,
  - hole indices must not be remapped in a way that conflicts with the PDF.

## Rule requirements (must be implemented exactly)
- Ask user which player starts when program begins.
- On a turn, player selects one of their own holes (1..6) and takes all stones from that hole.
- If selected hole has **more than 1 stone**:
  - put one stone back into the selected hole,
  - sow remaining stones one-by-one to the right starting from the next hole,
  - continue wrapping and sowing across opponent holes as needed.
- If selected hole has **exactly 1 stone**:
  - move that single stone to the immediate right adjacent hole,
  - then turn passes to opponent.
- If last stone lands in current player's own store, current player gets one extra turn.
- Capture rule:
  - if last stone lands in an empty hole on current player's side,
  - and opposite opponent hole is non-empty,
  - move both the last stone and all stones from opposite hole into current player's store.
- Game end:
  - when one player's side holes are all empty, game ends.
  - transfer all stones remaining on the other side to the store of the player whose side became empty (as stated in assignment text).

## Input and robustness requirements
- At startup, read first player from user input.
- On each turn, ask current player for hole number (1..6).
- Invalid inputs must not crash the program.
- Force retry on:
  - values outside 1..6,
  - selecting an empty hole,
  - selecting a hole that is not valid for current player,
  - non-numeric input.
- Prefer safe parsing (`Text.Read.readMaybe`) instead of unsafe `read`.

## Board rendering requirements
- Print board after every move and at game end.
- Render clearly in terminal with:
  - Player 2 row on top,
  - Player 1 row on bottom,
  - both stores clearly visible,
  - hole numbering clear from player perspective.

## Code organization requirements
- Use a sensible data model (for example, `Board` and `Player` types).
- Keep game loop clean.
- Keep sowing logic in separate helper functions.
- Keep endgame detection and winner calculation in separate functions.
- Include a working `main`.
- Favor readable, well-structured code with useful comments on non-obvious logic.
- Prefer only standard Haskell libraries when possible.

## Response format requirements (when asked to output solution code)
- Provide in this order:
  1) a short solution summary,
  2) one complete Haskell code block,
  3) compile and run commands,
  4) short explanation of what key functions do.
- If any rule is ambiguous, choose the most reasonable interpretation and state that choice in the summary.
