# Repository Guidelines

## Project Structure & Module Organization

Scout is an Elixir umbrella project with two apps. `apps/scout` contains the core fetch pipeline: settings, URL security, job lifecycle, dispatch, RabbitMQ integration, Lightpanda execution, retry logic, and agent heartbeat code. `apps/scout_web` contains the Phoenix 1.8 web layer, including the LiveView dashboard, JSON API controllers, layouts, static assets, gettext files, and web tests. Shared runtime configuration lives in `config/`; root `settings.yaml` controls queues, fetch policy, agent capacity, Lightpanda path, and URL security. Design notes live in `docs/`.

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

Use the root `.formatter.exs`; run `mix format` before handoff. Follow standard Elixir module naming, with files matching modules under `lib/`, such as `Scout.Server.JobManager` in `apps/scout/lib/scout/server/job_manager.ex`. Test files should end in `_test.exs`. Prefer existing OTP boundaries and public APIs (`Scout.submit_fetch/1`, `Scout.get_fetch/1`) instead of reaching into GenServers directly. For UI, use `phoenix_duskmoon` components and DuskMoon assets; do not add DaisyUI or reintroduce `core_components.ex`.

## Testing Guidelines

Tests use ExUnit and Phoenix test helpers. Core tests are under `apps/scout/test`; web/controller/LiveView tests are under `apps/scout_web/test`. Add focused tests for URL validation, retry behavior, job lifecycle changes, API responses, and LiveView behavior when touched. Use fixtures from `test/support/fixtures/` where possible.

## Commit & Pull Request Guidelines

Recent history uses Conventional Commit style, for example `feat(scout): redesign as markdown fetch agent`, `docs: add design document`, and `chore: add .trees/ to gitignore`. Keep commits scoped and imperative. PRs should describe the behavior change, list verification commands run, link related issues, and include screenshots or curl examples for UI/API changes.

## Security & Configuration Tips

Do not weaken SSRF protections in `Scout.Security` without tests. Local mode does not require RabbitMQ; distributed mode depends on RabbitMQ settings and `config :scout, :agent_enabled`. Lightpanda must be installed on agent hosts for real fetch execution.
