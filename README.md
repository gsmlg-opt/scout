# SearchAggregator

SearchAggregator is a self-hosted metasearch application built with Elixir and Phoenix. It is structured as an umbrella project with a core search application and a Phoenix web application.

The project follows a SearXNG-style model: runtime behavior is driven by `settings.yaml`, enabled engines are queried in parallel, results are normalized and deduplicated, and engine failures degrade gracefully instead of failing the whole search.

## Project Structure

- `apps/search_aggregator` - core search orchestration, YAML settings loader, engine behavior, result normalization, and HTTP/browser dispatch.
- `apps/search_aggregator_web` - Phoenix 1.8 web layer with LiveView UI and JSON API.
- `settings.yaml` - runtime configuration for general settings, UI settings, engine list, timeouts, categories, and browser simulation options.
- `docs/prd.md` - product requirements.
- `docs/tdd.md` - technical design.

## Requirements

- Elixir 1.15 or newer
- Erlang/OTP compatible with your Elixir version
- Mix

No database is required for the current app. Results and settings are loaded in memory.

## Setup

Install dependencies from the umbrella root:

```sh
mix setup
```

The default runtime settings file is `settings.yaml` in the project root. To use another settings file, set `SETTINGS_PATH`:

```sh
SETTINGS_PATH=/absolute/path/to/settings.yaml mix phx.server
```

## Run

Start the Phoenix server:

```sh
mix phx.server
```

Or run it inside IEx:

```sh
iex -S mix phx.server
```

By default, the app listens on port `6980`:

- Web UI: http://localhost:6980
- JSON API: http://localhost:6980/search?q=phoenix

You can override the port with `PORT`:

```sh
PORT=4000 mix phx.server
```

## Configuration

Edit `settings.yaml` to configure:

- `general` - instance name, default locale, request timeout, contact URL.
- `search` - default result limit, max result limit, autocomplete, safe search.
- `ui` - theme, default category, category tab mappings.
- `browser_simulator` - browser simulation toggle, pool size, exported browser data path.
- `engines` - configured engines, shortcuts, categories, request mode, timeout, and base URLs.

Enabled engines currently include:

- Wikipedia
- Hacker News
- Stack Overflow

Configuration is loaded at runtime on application start. Restart the server after changing `settings.yaml`.

## JSON API

Search with:

```sh
curl 'http://localhost:6980/search?q=elixir&category=tech&limit=8'
```

Supported query parameters:

- `q` - required search query.
- `category` or `categories` - category to search, such as `general`, `tech`, or `all`.
- `limit` or `count` - result limit, capped by `search.max_limit`.
- `engines` - comma-separated engine names, such as `wikipedia,hacker_news`.
- `language` - locale/language value passed through request options.

The API returns the normalized result list plus per-engine status metadata.

## Development

Run the test suite:

```sh
mix test
```

Run the project precommit checks before handing off changes:

```sh
mix precommit
```

The precommit alias compiles with warnings as errors, checks unused dependencies, formats code, and runs tests.

## Adding Engines

1. Add an engine module under `apps/search_aggregator/lib/search_aggregator/search/engines/`.
2. Implement the existing engine search contract used by the current engine modules.
3. Register the engine in `SearchAggregator.Search`.
4. Add the engine configuration to `settings.yaml`.

Use `Req` for HTTP requests. Do not add another HTTP client unless there is a specific requirement.
