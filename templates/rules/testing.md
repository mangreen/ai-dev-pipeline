# Testing rules

## Pyramid

| Layer | Share | Scope |
| --- | --- | --- |
| Unit | ~70% | Domain logic and use cases. Mock all I/O. Runs in memory, milliseconds. |
| Integration | ~20% | Adapters (repositories, API clients, controllers). Real lightweight infrastructure (Testcontainers or in-memory DB). |
| End to end | ~10% | Critical happy paths only, against a deployed staging environment, in a separate CI job. |

## Quality

- Arrange / Act / Assert in every test.
- Name: `should_<expected_behavior>_when_<trigger_condition>`.
- Mutation mindset: a test must fail if a logical operator is changed (`>` to `>=`).
- Concurrency: for inventory, wallet or idempotency logic, an integration test must fire about
  10 simultaneous requests and assert that exactly one succeeds and the rest get a conflict error.
- Never weaken, skip or delete a failing test to get green. Fix the code.

## Gate

- At least 80% coverage on domain and application code. CI fails below it.
