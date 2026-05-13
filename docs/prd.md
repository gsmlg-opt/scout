# Scout Product Requirements

## Purpose

Scout is a distributed web fetching system for AI agents.

It performs one operation:

```text
URL -> Lightpanda -> Markdown
```

Scout does not store documents, index content, generate embeddings, manage memory systems, or build knowledge graphs.

## In Scope

- Async fetch job API.
- Optional synchronous fetch API.
- RabbitMQ-based job, result, failure, and heartbeat transport.
- Regional Scout agents.
- Lightpanda browser execution.
- Lightpanda native Markdown extraction.
- Retry and timeout handling.
- Agent heartbeat reporting.
- Job status reporting.
- URL security checks for protocol, localhost, and private network targets.

## Out of Scope

- Search indexing.
- Vector databases.
- RAG pipelines.
- Embeddings.
- Document persistence.
- Screenshots.
- HTML storage.
- Browser traces.
- Crawling databases.

## Primary Users

- AI agents that need rendered page Markdown.
- Operators running regional fetch capacity.
- Internal systems that need a narrow fetch boundary without knowledge-system coupling.

## API Requirements

### Submit Fetch Job

```http
POST /api/fetch
```

Request:

```json
{
  "url": "https://example.com/docs/page",
  "region_hint": "eu",
  "timeout_ms": 30000
}
```

Response:

```json
{
  "job_id": "018f6f7a-8a5d-7b9a-9f1d-1e3f3d92e001",
  "status": "queued"
}
```

### Fetch Status

```http
GET /api/fetch/:job_id
```

### Synchronous Fetch

```http
POST /api/fetch/sync
```

## Security Requirements

Scout must reject:

- Non-HTTP/HTTPS URLs.
- Empty or malformed hosts.
- Localhost targets.
- Literal private network IP targets.

Blocked CIDRs:

```text
127.0.0.0/8
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.0.0/16
::1/128
fc00::/7
```

## MVP

Phase 1:

- One Scout Server.
- Local dispatcher for development.
- RabbitMQ publisher/consumer modules.
- One Scout Agent execution path.
- Lightpanda Markdown fetch adapter.
- Heartbeat and job status reporting.

Phase 2:

- Regional agents.
- Retry tuning.
- Dispatch policy by region and capacity.
- Browser pooling.

Phase 3:

- Observability dashboard.
- Domain throttling.
- Adaptive routing.
- Fetch policy configuration.
