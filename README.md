# Scout

Scout is a distributed Markdown fetch system for AI agents. It accepts URL fetch jobs, dispatches them to Scout agents, renders pages with Lightpanda, and returns Lightpanda's native Markdown output.

Scout intentionally does not index, persist documents, generate embeddings, or manage RAG state.

## Project Structure

- `apps/scout` — fetch job lifecycle, settings (YAML GenServer), dispatch (local + RabbitMQ), Lightpanda execution, retry policy, URL security, heartbeat.
- `apps/scout_web` — Phoenix 1.8 API and LiveView dashboard.
- `settings.yaml` — runtime settings for RabbitMQ queues, fetch policy, agent capacity, Lightpanda path, and URL security.
- `docs/design.md` — design document.

## Requirements

- Elixir 1.15 or newer
- Erlang/OTP compatible with your Elixir version
- Mix
- Lightpanda on agent hosts for real fetch execution
- RabbitMQ for distributed server/agent deployment

The default development mode uses a local dispatcher, so RabbitMQ is not required for local UI/API smoke tests.

## Setup

Install dependencies from the umbrella root:

```sh
mix setup
```

The default runtime settings file is `settings.yaml` in the project root. To use another settings file:

```sh
SETTINGS_PATH=/absolute/path/to/settings.yaml mix phx.server
```

## Run

Start the Phoenix server:

```sh
mix phx.server
```

By default, the app listens on port `6980`:

- Dashboard: http://localhost:6980
- API: http://localhost:6980/api/fetch

## API

Submit an async fetch job:

```sh
curl -X POST http://localhost:6980/api/fetch \
  -H 'content-type: application/json' \
  -d '{"url":"https://example.com/docs/page","region_hint":"eu","timeout_ms":30000}'
```

Check job status:

```sh
curl http://localhost:6980/api/fetch/JOB_ID
```

Run a synchronous fetch:

```sh
curl -X POST http://localhost:6980/api/fetch/sync \
  -H 'content-type: application/json' \
  -d '{"url":"https://example.com/docs/page"}'
```

## Runtime Modes

Local dispatch is the default:

```elixir
config :scout, :dispatch_mode, :local
```

RabbitMQ dispatch:

```elixir
config :scout, :dispatch_mode, :rabbitmq
config :scout, :agent_enabled, true
```

RabbitMQ queue names, regional queues, retry policy, agent capacity, and Lightpanda path are configured in `settings.yaml`.

## Development

Run tests:

```sh
mix test
```

Run the project precommit checks before handoff:

```sh
mix precommit
```

The precommit alias compiles with warnings as errors, checks unused dependencies, formats code, and runs tests.
