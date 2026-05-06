# Xeriscape Yard Designer — Architecture

> **For future Claude sessions:** Read this fully before doing anything. The Status section tells you exactly where to pick up.

---

## Project Goal

A web app that helps users design a xeriscaped yard. It should feel like a smart design assistant — not just a drag-and-drop tool, but something that knows what it's doing.

**Portfolio goals:** Public GitHub repo showcasing AI integration (MCP, Claude tool use) and full-stack engineering (Rails API + Next.js frontend).

---

## Core Features

1. Enter a zip code → get USDA hardiness zone + region-appropriate plant recommendations
2. Input yard dimensions to define the canvas
3. Place existing elements (trees, beds, paths, hardscaping)
4. Upload inspiration images or paste links to convey desired style
5. AI recommends plants and layout using xeriscape best practices
6. User can adjust recommendations freely
7. Final output: 2D top-down plan + plant list

---

## Build Order

We build in layers, each one usable before the next begins.

| Phase | What | Why |
|---|---|---|
| 1 | MCP server (TypeScript) | Domain knowledge layer — zones, plants, design principles as Claude tools |
| 2 | Rails API (stateless, no DB) | Orchestration: takes user input, calls Claude with MCP tools, returns recommendations |
| 3 | Next.js frontend | UI on top of a working API |
| 4 | Database + persistence | PostgreSQL, designs/plants saved — added once the core loop is proven |

**No database until Phase 4.** Build the useful thing first.

---

## Stack

| Layer | Choice | Notes |
|---|---|---|
| MCP server | TypeScript (`@modelcontextprotocol/sdk`) | First thing built |
| Backend | Rails API mode | Stateless to start; DB added in Phase 4 |
| Frontend | Next.js (TypeScript/React) | Vercel free tier |
| Canvas | react-konva or Fabric.js | 2D top-down yard designer |
| Database | PostgreSQL | Render or Railway — Phase 4 only |
| AI | Claude API via Rails | Tool use against the MCP server |
| Zone lookup | phzmapi.org | Free REST API: zip → USDA zone |
| Plant data | Claude's knowledge via MCP tools | No external plant API or seeded DB needed initially |
| File storage | Active Storage + S3/Supabase | Inspiration image uploads — post-MVP |
| Auth | Not in MVP | Nullable `user_id` on `Design` keeps the door open |

**Hosting:**
- Frontend: Vercel (free)
- Rails API: Render or Railway (cheap/free tier)

---

## MCP Server — Tools

The MCP server is the AI's domain knowledge layer. Claude calls these tools instead of relying on its training data for facts.

| Tool | Input | Output |
|---|---|---|
| `lookup_zone` | `zip_code` | USDA zone, temp range, climate context |
| `search_plants` | `zone, water_need, sun, plant_type, limit` | Filtered plant list with care details |
| `get_companion_plants` | `plant_name` | Plants that pair well with it |
| `get_design_principles` | `zone, style, lot_size_sqft` | Xeriscape best practices for the context |

---

## Architecture Diagram

```
┌─────────────────────┐         ┌──────────────────────┐
│   Next.js (Vercel)  │ ──────▶ │   Rails API (Render) │
│   TypeScript/React  │         │   (stateless to start)│
│   react-konva       │         │   Claude API calls    │
└─────────────────────┘         └──────────┬───────────┘
                                           │ tool use
                                ┌──────────▼───────────┐
                                │   MCP Server (TS)    │
                                │   lookup_zone        │
                                │   search_plants      │
                                │   get_companions     │
                                │   design_principles  │
                                └──────────────────────┘
```

---

## Data Model (Phase 4 — when DB is added)

### Key decisions

- `DesignElement` = existing physical features in the yard (user-entered ground truth)
- `DesignPlant` = AI-recommended / user-placed plants (the design output)
- AI populates `DesignPlant` records with positions; it never mutates `DesignElement` records
- No external plant API — MCP server + Claude knowledge is sufficient to start

### Models

**`Design`** — `name`, `width_ft`, `length_ft`, `zip_code`, `zone` (cached from lookup), `user_id` (nullable)
- `belongs_to :user, optional: true`
- `has_many :design_elements`
- `has_many :design_plants`
- `has_many :plants, through: :design_plants`
- `has_many :inspiration_items`

**`DesignElement`** — `element_type` (enum: tree/bed/path/hardscape/structure), `label`, `x`, `y`, `width`, `height`, `rotation`
- `belongs_to :design`

**`Plant`** — `common_name`, `scientific_name`, `zone_min`, `zone_max`, `water_need`, `mature_height_ft`, `mature_spread_ft`, `bloom_season`, `bloom_color`, `plant_type`, `sun_requirement`, `native_regions`
- `has_many :design_plants`
- `has_many :designs, through: :design_plants`

**`DesignPlant`** *(join: plants placed in a design)* — `x`, `y`, `quantity`, `notes`
- `belongs_to :design`
- `belongs_to :plant`

**`InspirationItem`** — `item_type` (enum: image/url), `url`, `caption`, `image` (Active Storage attachment)
- `belongs_to :design`

**`User`** *(future)* — `email`, `password_digest`
- `has_many :designs`

---

## Status

> **Last completed:** Git repo initialized. MCP server scaffolded — `package.json`, `tsconfig.json`, `src/tools/` and `src/data/` directories in place. Architecture doc written and agreed on. Old planning doc at `../xeriscape-architecture.md` marked superseded.
>
> **Next step:** `npm install` in `mcp-server/`, then write the first tool (`lookup_zone`).
