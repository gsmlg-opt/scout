# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- **Setup Dependencies:** `mix setup`
- **Start Development Server:** `mix phx.server` (or `iex -S mix phx.server` for an interactive shell)
- **Run All Tests:** `mix test`
- **Run a Specific Test:** `mix test path/to/file_test.exs` or `mix test path/to/file_test.exs:123` (to run a specific line)
- **Pre-commit Check (Compile, Format, Test):** `mix precommit` (Use this alias when you are done with all changes to catch warnings and run tests)
- Default port is **6980** (override with `PORT`). Settings path overridable with `SETTINGS_PATH`.

## Architecture & Structure

SearchAggregator is an **Elixir umbrella project** — a Phoenix 1.8 metasearch application that queries multiple external search engines in parallel and aggregates results. It provides both an interactive LiveView UI and a JSON API. **No database is required** — everything runs in memory from `settings.yaml`.

### Umbrella Apps

- **`apps/search_aggregator`** — Core search orchestration: `Settings` GenServer (YAML loader), engine behaviour, HTTP dispatch, result normalization/deduplication.
- **`apps/search_aggregator_web`** — Phoenix 1.8 web layer: LiveView (`SearchLive`) at `/`, JSON API controller at `/search`.

### Search Lifecycle

There are two search modes:

1. **Async (`Search.start/3`)** — Used by the LiveView. Fires parallel `Task` processes (one per engine), each sends `{:search_engine_result, ref, result}` back to the caller. Results stream in progressively as engines respond.
2. **Sync (`Search.search/2`)** — Used by the JSON API. Waits for all engines to complete, then returns the merged result list.

Both modes go through:
- `Search.normalize_options/2` — resolves category, limit, engine_names, language defaults from settings.
- `Search.enabled_engines/2` — filters by `disabled` flag, engine registration, category, and user-selected engines.
- `Search.run_engine/4` — dispatches to the engine module (http mode → `module.search/3`; browser mode → `BrowserSimulator` placeholder).
- `Search.merge_results/3` — deduplicates by normalized URL, boosts score for duplicates, sorts by score, truncates to limit.

### Core Modules

- **`SearchAggregator.Settings`** — GenServer that loads `settings.yaml` at startup, merges with defaults, normalizes engine configs. Call `Settings.get/0` anywhere; `Settings.reload!/0` for hot reload.
- **`SearchAggregator.Search.Engine`** — Behaviour with `@callback search(binary(), map(), map()) :: {:ok, [Result.t()]} | {:error, term()}`.
- **`SearchAggregator.Search.Result`** — Struct: `:title`, `:url`, `:engine`, `:content`, `:source`, `:score`, `:published_at`.
- **`SearchAggregator.Search.HTTP`** — Thin wrapper over `Req` that auto-decodes JSON responses.
- **`SearchAggregator.Search.BrowserSimulator`** — Placeholder for future Playwright-based browser engine mode.
- **`SearchAggregator.Search.QueryParams`** — Parses URL query params into normalized opts and serializes opts back to query string for `push_patch`.

### Supervision Tree

```
SearchAggregator.Supervisor (one_for_one)
  ├── Task.Supervisor (SearchAggregator.TaskSupervisor)
  ├── SearchAggregator.Settings (GenServer)
  ├── DNSCluster
  └── Phoenix.PubSub (SearchAggregator.PubSub)
```

## Project Guidelines

## UI Library

This project uses the DuskMoon UI system:

- **`phoenix_duskmoon`** — Phoenix LiveView UI component library (primary web UI)
- **`@duskmoon-dev/core`** — Core Tailwind CSS plugin and utilities
- **`@duskmoon-dev/css-art`** — CSS art utilities
- **`@duskmoon-dev/elements`** — Base web components
- **`@duskmoon-dev/art-elements`** — Art/decorative web components

Do NOT use DaisyUI or other CSS component libraries. Do NOT use `core_components.ex` — use `phoenix_duskmoon` components instead.
Use `@duskmoon-dev/core/plugin` as the Tailwind CSS plugin.

### Reporting issues or feature requests

If you encounter missing features, bugs, or need functionality not yet available in any DuskMoon package, open a GitHub issue in the appropriate repository with the label `internal request`:

- **`phoenix_duskmoon`** — https://github.com/gsmlg-dev/phoenix_duskmoon/issues
- **`@duskmoon-dev/core`** — https://github.com/gsmlg-dev/duskmoon-dev/issues
- **`@duskmoon-dev/css-art`** — https://github.com/gsmlg-dev/duskmoon-dev/issues
- **`@duskmoon-dev/elements`** — https://github.com/gsmlg-dev/duskmoon-dev/issues
- **`@duskmoon-dev/art-elements`** — https://github.com/gsmlg-dev/duskmoon-dev/issues

### Elixir Best Practices
- **HTTP Client:** Use the included `Req` library for HTTP requests. **Avoid** `:httpoison`, `:tesla`, and `:httpc`.
- **List Access:** Do not use index-based access syntax on lists (e.g., `mylist[i]` is invalid). Always use `Enum.at(mylist, i)`.
- **Variable Binding:** Elixir variables are immutable. For block expressions (`if`, `case`, `cond`), you must bind the *result* of the expression to a variable rather than rebinding inside the block.

### Phoenix v1.8 Conventions
- **LiveView Layouts:** Always begin LiveView templates with `<Layouts.app flash={@flash} ...>` to wrap all inner content.
- **Current Scope Assign:** If you see `current_scope` assign errors, move the routes to the proper `live_session` and pass `current_scope`.
- **Flash Messages:** Use DuskMoon flash components through `Layouts`; do not call legacy `<.flash_group>`.
- **UI Components:** Use `phoenix_duskmoon` components and helpers. Do not reintroduce `core_components.ex`.
