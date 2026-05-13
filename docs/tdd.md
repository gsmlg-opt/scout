# Scout Technical Design

## Architecture

Scout is an umbrella Phoenix project with two OTP applications:

- `:scout` owns job lifecycle, dispatch, agent execution, settings, RabbitMQ, and telemetry boundaries.
- `:scout_web` owns the HTTP API and LiveView dashboard.

Runtime flow:

```text
Client
  -> ScoutWeb.FetchController
  -> Scout.Server.JobManager
  -> Scout.Server.Dispatcher
  -> Scout.Agent.Executor
  -> Scout.Agent.Lightpanda
  -> Markdown result
  -> Scout.Server.ResultHandler
```

Distributed flow:

```text
Scout Server
  -> RabbitMQ job queue
  -> Scout Agent AMQP consumer
  -> Lightpanda fetch --dump markdown
  -> RabbitMQ result or failed queue
```

## Core Modules

- `Scout.Fetch.Job` normalizes and validates fetch job payloads.
- `Scout.Fetch.Result` defines success and failure result payloads.
- `Scout.Fetch.RetryPolicy` owns retryability and backoff calculation.
- `Scout.Security` rejects unsupported protocols, localhost, and private literal IP targets.
- `Scout.Server.JobManager` tracks in-memory job status and owns server-side retry scheduling.
- `Scout.Server.Dispatcher` selects local or RabbitMQ dispatch.
- `Scout.Server.RabbitMQ` publishes jobs, results, failures, and heartbeats.
- `Scout.Server.AgentRegistry` tracks heartbeat state.
- `Scout.Agent.Executor` runs one job.
- `Scout.Agent.Lightpanda.CLI` shells out to `lightpanda fetch --dump markdown`.
- `Scout.Agent.AMQPConsumer` consumes distributed jobs.
- `Scout.Agent.Heartbeat` publishes capacity and health.

## Runtime State

Scout keeps only operational state in memory:

- job status
- result payload for completed or failed jobs
- recent agent heartbeats

It does not persist fetched documents.

## Configuration

`settings.yaml` is loaded at runtime through `Scout.Settings`.

Important sections:

- `rabbitmq` - queue names, regional queues, connection URL.
- `fetch` - timeout, retry, and browser readiness options.
- `agent` - id, region, heartbeat interval, capacity, Lightpanda path.
- `security` - allowed schemes, redirect limit, blocked CIDRs.

## Lightpanda

The CLI adapter uses native Markdown output:

```text
lightpanda fetch --dump markdown URL
```

`browser.wait_until: network_idle` maps to Lightpanda's `--wait-until networkidle`.

## Retry

Retries are centralized in `Scout.Server.JobManager`.

Retryable errors:

```text
timeout
temporary_network_failure
429
502
503
browser_crash
browser_unavailable
command_failed
```

Non-retryable errors include invalid URLs, unsupported protocols, blocked targets, 404, robots denial, and oversized content.

## Testing

Tests use a fake Lightpanda adapter and do not require RabbitMQ or a Lightpanda binary.

Run:

```sh
mix precommit
```
