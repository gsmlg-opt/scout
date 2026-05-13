# Repository Guidelines

## Project Structure & Module Organization

Scout is an Elixir umbrella project. `apps/scout` is shared core code: settings, URL security, fetch structs, retry policy, Markdown helpers, and RabbitMQ helpers. `apps/scout_server` owns job lifecycle, agent registry, RabbitMQ dispatch/consumers, and the public `Scout.Server` API. `apps/scout_agent` owns RabbitMQ job consumption, heartbeat publishing, and the NimblePool-backed Lightpanda executor exposed by `Scout.Agent`. `apps/scout_web` contains the Phoenix 1.8 dashboard and JSON API.

## Build, Test, and Development Commands

- `mix setup` installs umbrella dependencies for all child apps.
- `mix phx.server` starts the Phoenix server on port `6980`.
- `iex -S mix phx.server` starts the server with an interactive Elixir shell.
- `SETTINGS_PATH=/abs/path/settings.yaml mix phx.server` runs with an alternate settings file.
- `mix test` runs all tests across the umbrella.
- `mix test apps/scout/test/scout/security_test.exs:12` runs one test file or line.
- `mix precommit` compiles with warnings as errors, checks unused dependencies, formats code, and runs tests.
- `mix assets.deploy` from `apps/scout_web` builds minified Tailwind/Bun assets and digests them.

## Coding Style & Naming Conventions

Use the root `.formatter.exs`; run `mix format` before handoff. Follow standard Elixir module naming, with files matching modules under `lib/`, such as `Scout.Server.JobManager` in `apps/scout_server/lib/scout/server/job_manager.ex`. Test files should end in `_test.exs`. Prefer public APIs (`Scout.Server.*`, `Scout.Agent.*`) instead of reaching into GenServers directly. For UI, use `phoenix_duskmoon` components and DuskMoon assets; do not add DaisyUI or reintroduce `core_components.ex`.

## Testing Guidelines

Tests use ExUnit and Phoenix test helpers. Core tests are under `apps/scout/test`; server tests under `apps/scout_server/test`; agent tests under `apps/scout_agent/test`; web tests under `apps/scout_web/test`. Add focused tests for URL validation, retry behavior, job lifecycle changes, API responses, agent execution, and LiveView behavior when touched.

## Commit & Pull Request Guidelines

Recent history uses Conventional Commit style, for example `feat(scout): redesign as markdown fetch agent`, `docs: add design document`, and `chore: add .trees/ to gitignore`. Keep commits scoped and imperative. PRs should describe the behavior change, list verification commands run, link related issues, and include screenshots or curl examples for UI/API changes.

## Security & Configuration Tips

Do not weaken SSRF protections in `Scout.Security` without tests. The server-agent pipeline uses RabbitMQ; set `rabbitmq.enabled: true` in `settings.yaml` for real distributed dispatch. Lightpanda must be installed on agent hosts for real fetch execution.
