# Scout Fetch Agent Design Document

## 1. Purpose

Scout is a distributed web fetching system for AI agents.

Scout receives fetch jobs, loads web pages using Lightpanda, converts pages directly into Markdown using Lightpanda’s built-in Markdown output capability, and returns the result.

Scout only performs:

```text
URL -> Lightpanda -> Markdown
```

Scout does not store documents, index content, generate embeddings, or manage knowledge systems.

---

## 2. Scope

### In Scope

Scout provides:

* distributed fetch agents
* RabbitMQ-based job dispatch
* regional fetch workers
* Lightpanda browser execution
* direct Markdown extraction
* retry handling
* timeout handling
* health reporting
* job status reporting

### Out of Scope

Scout does not provide:

* search indexing
* vector databases
* RAG pipelines
* embedding generation
* document persistence
* screenshots
* HTML storage
* browser traces
* memory systems
* knowledge graphs

---

## 3. Architecture

```text
                    ┌────────────────────┐
                    │    Scout Server     │
                    │                    │
                    │ API / Dispatcher    │
                    │ Job Scheduler       │
                    │ Agent Registry      │
                    └─────────┬──────────┘
                              │
                              │ RabbitMQ
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼───────┐   ┌────────▼───────┐
│ Scout Agent EU │   │ Scout Agent US │   │ Scout Agent AS │
│ Lightpanda     │   │ Lightpanda     │   │ Lightpanda     │
│ Markdown Fetch │   │ Markdown Fetch │   │ Markdown Fetch │
└───────┬────────┘   └────────┬───────┘   └────────┬───────┘
        │                     │                    │
        └──────────────┬──────┴────────────┬───────┘
                       │                   │
                 Markdown Result      Status Events
```

---

## 4. Core Principle

Scout Server decides:

```text
what to fetch
where to dispatch
job lifecycle
```

Scout Agents perform:

```text
browser fetch
Markdown extraction
result publishing
```

Agents are stateless execution workers.

---

## 5. Main Components

## 5.1 Scout Server

Responsibilities:

* receive fetch requests
* create jobs
* dispatch jobs via RabbitMQ
* track job status
* track agent health
* receive results
* handle retries

Suggested modules:

```text
Scout.Server.API
Scout.Server.Dispatcher
Scout.Server.JobManager
Scout.Server.AgentRegistry
Scout.Server.ResultHandler
```

---

## 5.2 RabbitMQ

RabbitMQ is the transport layer for jobs and events.

Suggested queues:

```text
scout.fetch.jobs
scout.fetch.results
scout.fetch.failed
scout.agent.heartbeat
```

Optional regional queues:

```text
scout.fetch.jobs.eu
scout.fetch.jobs.us
scout.fetch.jobs.asia
```

RabbitMQ should only carry:

* jobs
* metadata
* Markdown results
* status events

---

## 5.3 Scout Agent

Scout Agent is a Lightpanda-powered execution worker.

Responsibilities:

* consume fetch jobs
* execute Lightpanda fetch
* extract Markdown
* publish result
* report heartbeat

Suggested modules:

```text
Scout.Agent.Application
Scout.Agent.AMQPConsumer
Scout.Agent.Executor
Scout.Agent.Lightpanda
Scout.Agent.Heartbeat
Scout.Agent.Telemetry
```

---

## 6. Fetch Pipeline

Scout uses a single fetch pipeline:

```text
URL
  -> Lightpanda
    -> Render Page
      -> Built-in Markdown Output
        -> Publish Result
```

There is no separate:

* HTML parsing
* Readability extraction
* Markdown conversion layer

Lightpanda is the extraction engine.

---

## 7. Job Payload

Example fetch job:

```json
{
  "job_id": "018f6f7a-8a5d-7b9a-9f1d-1e3f3d92e001",
  "url": "https://example.com/docs/page",
  "timeout_ms": 30000,
  "priority": 5,
  "region_hint": "eu",
  "browser": {
    "wait_until": "network_idle",
    "wait_for": null,
    "javascript": true
  }
}
```

---

## 8. Result Payload

Successful result:

```json
{
  "job_id": "018f6f7a-8a5d-7b9a-9f1d-1e3f3d92e001",
  "ok": true,
  "url": "https://example.com/docs/page",
  "final_url": "https://example.com/docs/page",
  "title": "Example Documentation",
  "markdown": "# Example Documentation\n\nThis is the page content...",
  "status_code": 200,
  "agent_id": "eu-agent-1",
  "duration_ms": 1240,
  "word_count": 850
}
```

Failure result:

```json
{
  "job_id": "018f6f7a-8a5d-7b9a-9f1d-1e3f3d92e001",
  "ok": false,
  "url": "https://example.com/docs/page",
  "error": {
    "type": "timeout",
    "message": "Fetch timed out after 30000ms",
    "retryable": true
  },
  "agent_id": "eu-agent-1"
}
```

---

## 9. Execution Flow

```text
1. Consume job from RabbitMQ
2. Launch Lightpanda page
3. Navigate to URL
4. Wait for page readiness
5. Request Markdown output
6. Publish result
7. Ack RabbitMQ message
```

Failure flow:

```text
1. Capture failure
2. Classify retryability
3. Publish failure event
4. Ack or reject message
```

---

## 10. Retry Policy

Retries are managed centrally by Scout Server.

Retryable failures:

```text
timeout
temporary network failure
429
502
503
browser crash
```

Non-retryable failures:

```text
invalid URL
unsupported protocol
404
robots denied
content too large
```

Suggested retry policy:

```text
max_attempts: 3
backoff: exponential
jitter: true
```

---

## 11. Lightpanda Pool

Each agent should maintain a reusable Lightpanda pool.

Example:

```text
browser_instances: 2-4
page_concurrency: 16-32
```

The agent should avoid launching a fresh browser for every job.

Recommended architecture:

```text
Agent
  -> Browser Pool
    -> Reusable Browser Sessions
      -> Temporary Pages/Tabs
```

---

## 12. Heartbeat

Agents publish periodic heartbeat events.

Example:

```json
{
  "agent_id": "eu-agent-1",
  "region": "eu",
  "status": "healthy",
  "running_jobs": 4,
  "capacity": 32,
  "version": "0.1.0",
  "timestamp": "2026-05-13T13:00:00Z"
}
```

Server uses heartbeat for:

* health monitoring
* routing
* load balancing
* capacity awareness

---

## 13. Dispatch Policy

Server dispatches jobs based on:

```text
region_hint
agent health
current load
available capacity
recent failure rate
```

Suggested strategy:

```text
1. Prefer requested region
2. Prefer healthy agents
3. Prefer lowest running_jobs
4. Prefer highest available capacity
```

---

## 14. API Design

## Submit Fetch Job

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

---

## Fetch Status

```http
GET /api/fetch/:job_id
```

Response:

```json
{
  "job_id": "...",
  "status": "completed"
}
```

---

## Synchronous Fetch

Optional API:

```http
POST /api/fetch/sync
```

Response:

```json
{
  "ok": true,
  "markdown": "...",
  "metadata": {}
}
```

---

## 15. Telemetry

Scout should expose metrics for:

```text
job queued
job completed
job failed
fetch duration
browser duration
timeout rate
success rate
queue depth
agent load
```

Events:

```text
fetch.started
fetch.completed
fetch.failed
agent.heartbeat
```

---

## 16. Security

Scout must enforce:

* HTTP/HTTPS only
* redirect limits
* timeout limits
* max page size
* private network blocking
* localhost blocking
* SSRF protection

Blocked targets:

```text
127.0.0.0/8
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
169.254.0.0/16
::1
fc00::/7
```

---

## 17. MVP Plan

### Phase 1

* RabbitMQ integration
* one Scout Server
* one Scout Agent
* Lightpanda Markdown fetch
* result publishing
* heartbeat

### Phase 2

* regional agents
* retry handling
* dispatch policy
* concurrency limits
* browser pooling

### Phase 3

* observability dashboard
* domain throttling
* adaptive routing
* fetch policy configuration

---

## 18. Final Boundary

Scout is intentionally narrow in scope.

Input:

```text
URL
fetch options
```

Output:

```text
Markdown
metadata
success/failure
```

Scout is not a search engine, storage system, crawler database, or RAG platform.

It is:

> A distributed Lightpanda-powered Markdown fetching system for AI agents.
