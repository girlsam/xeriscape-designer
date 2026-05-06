# Xeriscape Yard Designer

An AI-assisted web app for designing drought-tolerant yards. Provide your zip code and yard details — get back plant recommendations and a 2D layout plan tailored to your climate zone.

## What it does

1. Enter a zip code → USDA hardiness zone lookup
2. Describe your yard (dimensions, existing trees, beds, paths)
3. Claude recommends xeriscape-appropriate plants and layout
4. Adjust the design on an interactive 2D canvas
5. Export a plant list and top-down yard plan

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | Next.js (TypeScript/React), react-konva |
| Backend | Rails API mode (Ruby) |
| AI | Claude API — tool use for structured recommendations |
| MCP server | TypeScript (`@modelcontextprotocol/sdk`) |
| Database | PostgreSQL (Phase 4) |
| Hosting | Vercel (frontend), Render (API) |

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full build plan, data model, and design decisions.

### On the MCP server

This project includes a Model Context Protocol (MCP) server as a deliberate portfolio choice — it demonstrates the pattern of grounding Claude's recommendations in structured, controlled domain data rather than relying solely on training knowledge.

In production, this pattern is most valuable when you own the data: for example, a plant retailer using MCP to constrain Claude to their actual inventory. For this project, Claude's native plant knowledge is sufficient at MVP scale — the MCP layer is additive, not foundational, and is introduced in Phase 2 after the core recommendation loop is working.

## Build order

| Phase | What |
|---|---|
| 1 | Rails API — Claude integration, recommendations endpoint |
| 2 | MCP server — structured domain tools layered on top |
| 3 | Next.js frontend — canvas UI |
| 4 | PostgreSQL — saved designs and persistence |
