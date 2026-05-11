# Xeriscape Designer — Rails API

Stateless Rails API. Orchestrates zone lookup, Claude conversation, and SVG rendering. No database until Phase 3.

## Requirements

- Ruby 3.x (see `.ruby-version`)
- Bundler

## Setup

```bash
bundle install
cp .env.example .env  # add ANTHROPIC_API_KEY
```

## Running

```bash
bin/rails server
```

## Tests

```bash
bin/rails test
```

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Claude API key |

## Endpoint

`POST /api/v1/recommendations`

See [`../docs/API_ARCHITECTURE.md`](../docs/API_ARCHITECTURE.md) for the full request/response contract.
