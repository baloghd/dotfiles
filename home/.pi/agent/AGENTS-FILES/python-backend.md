# Python backend service guidelines

Use this in a project that has an HTTP API and persistence. Drop it into the
project's `AGENTS.md` (or include it from there) for FastAPI + DDD-style
services. For scripts, CLIs, libraries, or anything without an HTTP layer,
ignore this file — the global `AGENTS.md` covers you.

## Layering

Dependencies flow one way:

```
HTTP/API
   ↓
Application Services
   ↓
Domain
   ↓
Repositories
   ↓
Infrastructure
```

Lower layers never import higher layers. In particular:
- Services never import FastAPI.
- Repositories never import FastAPI.
- Domain models never depend on infrastructure (ORM, transport, config).

## FastAPI routers

Routers translate HTTP into service calls and back. Routers:
- validate input (Pydantic schemas)
- call services
- map domain exceptions to HTTP responses
- return responses

Routers must not:
- contain business logic
- execute SQL
- manipulate ORM sessions
- implement workflows

Keep routers thin. If a router grows past the point where it's hard to read,
the logic belongs in a service.

## Services

Business rules live here. Services:
- orchestrate use cases
- call repositories
- enforce business rules
- raise domain-specific exceptions

Services should be framework independent — no FastAPI, no SQLAlchemy.
Tests should be able to call them with hand-rolled fakes.

## Repositories

Repositories encapsulate persistence. They:
- own the ORM session for their unit of work
- return domain objects or DTOs (not ORM rows leaking out)
- expose intent-shaped methods (`get_active_user`,
  `list_orders_for_customer`) — not generic `find_by_id` wrappers

No business logic in repositories. No HTTP concerns. Domain code talks to
repositories through `Protocol` interfaces declared in the domain layer.

## Models

Keep three separate concerns:
- ORM models — persistence shape.
- API schemas (Pydantic) — transport shape.
- Domain models — behaviour and invariants.

Don't combine these into one class hierarchy. Map between them at the
boundary (routers for API, repositories for persistence).

## Errors

Raise domain-specific exceptions (e.g. `UserNotFound`, `InsufficientFunds`).
Translate them to HTTP inside routers via exception handlers — never
`raise HTTPException` outside the API layer.

## Testing

- Unit tests cover services with in-memory fakes for repositories.
- Integration tests cover repositories against a real database
  (testcontainers or sqlite-in-memory).
- HTTP tests exist for routers only when the routing logic is
  non-trivial; otherwise service tests suffice.
- Don't mock the business rules you're trying to test — mock
  infrastructure.

## Configuration

Configuration lives in one place (typically `pydantic-settings` or a typed
`Settings` object). Inject it into services and repositories. Don't read
`os.getenv` across the codebase.

## Dependencies

Prefer constructor injection. Pass the database session, repository
implementations, settings, and clients explicitly. Avoid globals and
service locators — they make testing painful.

## Logging

Structured logging only (`structlog` or stdlib `logging` with JSON
formatter). Log at the service boundary, not inside repositories. Never
log secrets, tokens, or PII.

## When modifying existing code

- Improve nearby code instead of matching poor patterns.
- Extract helpers when duplication appears.
- Split a router or service that has grown hard to read — but only when
  it actually hurts.
- Leave the codebase cleaner than you found it.

## Before finishing

Ask:
- Does this belong in this layer?
- Is there business logic inside a router?
- Is this dependency pointing the correct direction?
- Is there unnecessary coupling to FastAPI or the ORM outside the API
  or persistence layer?
