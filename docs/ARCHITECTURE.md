# Xeriscape Yard Designer — Architecture

> **For future Claude sessions:** Read this fully before doing anything. The Status section tells you exactly where to pick up.

---

## Project Goal

A web app that helps users design a xeriscaped yard. It should feel like a smart design assistant — not just a drag-and-drop tool, but something that knows what it's doing.

**Portfolio goals:** Public GitHub repo showcasing AI integration (Claude API tool use, MCP) and full-stack engineering (Rails API + Next.js frontend).

---

## MVP Output

A top-down yard planting plan rendered as an SVG image, matching the style of professional xeriscape design handouts:

- **Grid-based yard diagram** — yard boundary drawn to scale on a grid
- **Plant shapes scaled to mature size** — each plant type gets a distinct shape (trees = cloud blobs, shrubs = diamonds/pentagons, perennials = starbursts, groundcovers = squares) and a unique color + letter label
- **Landscape design principles applied** — odd-number groupings, layering by mature height, water zones, sun/shade placement, companion planting
- **Plant legend** — letter key, common name, variety, mature dimensions, quantity per plant type
- **Design summary** — short paragraph describing the design intent

User can request tweaks conversationally ("more purple", "fewer shrubs", "move the oak") and the diagram re-renders from updated Claude output.

---

## Core Features

1. Enter zip code → USDA hardiness zone lookup
2. Provide yard dimensions and shape
3. Describe existing elements (trees, beds, paths, hardscaping)
4. Describe style preferences (sun, color palette, formality)
5. AI applies xeriscape principles and produces a planting plan
6. Output: SVG diagram + plant legend + design summary
7. User tweaks via conversation → diagram updates

---

## Build Order

We build in layers, each one usable before the next begins.

| Phase | What | Why |
|---|---|---|
| 1 | Rails API (stateless, no DB) | Get Claude talking first — zip + context in, plant recommendations out |
| 2 | MCP server (TypeScript) | Add structured domain tools on top of a working API |
| 3 | Next.js frontend | UI on top of a working API |
| 4 | Database + persistence | PostgreSQL, designs/plants saved — added once the core loop is proven |

**No database until Phase 4.** Build the useful thing first.

**Why Rails before MCP:** The core value loop is "user provides context → Claude recommends plants." Getting that working with Claude's native knowledge first lets us validate the product before adding infrastructure. The MCP layer is additive, not foundational.

---

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Backend | Rails API mode | Stateless to start; DB added in Phase 4 |
| MCP server | TypeScript (`@modelcontextprotocol/sdk`) | Domain knowledge layer — added in Phase 2 |
| Frontend | Next.js (TypeScript/React) | Vercel free tier |
| SVG rendering | Ruby (`victor` gem or similar) | Server-side: Claude JSON → SVG diagram |
| Database | PostgreSQL | Render or Railway — Phase 4 only |
| AI | Claude API via Rails | Tool use, optionally backed by MCP server |
| Zone lookup | phzmapi.org | Free REST API: zip → USDA zone |
| Plant data | Claude's knowledge (Phase 1), MCP tools (Phase 2) | No external plant API needed |
| File storage | Active Storage + S3/Supabase | Inspiration image uploads — post-MVP |
| Auth | Not in MVP | Nullable `user_id` on `Design` keeps the door open |

**Hosting:**
- Frontend: Vercel (free)
- Rails API: Render or Railway (cheap/free tier)

---

## MCP Server — Tools (Phase 2)

The MCP server is the AI's structured domain knowledge layer. Claude calls these tools to ground recommendations in defined data rather than relying solely on training knowledge. This pattern makes most sense when you own the data — e.g., a plant retailer constraining Claude to their actual inventory.

For this project, MCP is included deliberately to demonstrate the pattern, not because it's strictly required at MVP scale.

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

> **Last completed:** Rails API scaffolded in `api/`. Versioned routes stubbed. Architecture revised — output is an SVG planting plan (not a frontend canvas). Claude produces structured JSON; Rails renders it to SVG. Conversation is multi-turn, stateless (client sends full message history each turn).
>
> **Next step:** Build `ZoneLookupService` (phzmapi.org), then `AIRecommendationService` with the first prompt draft, then `SvgRenderService`. Get a full request → SVG response working end to end before polishing any layer.
