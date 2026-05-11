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

1. User describes their yard in natural language — dimensions, existing features, spatial relationships
2. Claude interprets the spatial description, asks focused clarifying questions, confirms its layout reading before committing
3. Claude applies xeriscape principles and produces a planting plan with absolute coordinates
4. Output: SVG diagram + plant legend + design summary
5. User tweaks via conversation ("more purple", "add a walkway") → diagram updates

**No structured intake form.** Real yards are not clean rectangles with dropdown fields. A yard description like "37'-8" wide from stairs to ditch, planter 16'-8" x 5' in the right corner, tree 10'-6" from the planter" cannot be captured by a form. Claude is the spatial interpreter.

---

## Build Order

We build in layers, each one usable before the next begins.

| Phase | What | Why |
|---|---|---|
| 1 | Rails API + Next.js frontend (parallel) | Validate the core loop end-to-end — conversational intake, SVG render, visual tweak cycle |
| 2 | MCP server (TypeScript) | Add structured domain tools on top of a working API |
| 3 | Database + persistence | PostgreSQL, designs/plants saved — added once the core loop is proven |

**No database until Phase 3.** Build the useful thing first.

**Why frontend now:** The spatial interpretation model — Claude converting natural language yard descriptions to coordinates — must be validated visually before investing further in the API layer. A working SVG in a browser is the only real proof that the prompt and coordinate model are correct.

**Why Rails before MCP:** The core value loop is "user describes yard → Claude interprets space + recommends plants → SVG renders." Getting that working with Claude's native spatial reasoning first lets us validate the product before adding infrastructure. The MCP layer is additive, not foundational.

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

## Spatial Interpretation Model

Claude serves two roles simultaneously: **spatial interpreter** and **plant recommender**.

When a user describes their yard, Claude must:
1. Parse natural language measurements including feet-inches format (`37'-8"` → `37.67 ft`)
2. Resolve relational measurements (`"tree is 10'-6" from the planter"`) into absolute coordinates
3. Establish a consistent coordinate system: `(0, 0)` at top-left corner, x increases right, y increases down, all values in decimal feet
4. Confirm its spatial interpretation with the user before producing a design — e.g., "I'm placing the planter from x=21 to x=37.67 along the back wall — does that match your yard?"
5. Distinguish existing features (user-provided ground truth) from designed plants (Claude's recommendations)

**Why Claude, not an external tool:** Research into MCP servers and APIs (Mapbox, GIS Operations, ArcGIS, Grasshopper 3D) found that all existing spatial tools assume geographic coordinates — latitude/longitude anchored to the real world. None handle arbitrary local coordinate spaces like a yard. Academic work (HouseLLM, SpatialGrammar) exists but is not deployed as a production API. Claude's native spatial reasoning — guided by a tight prompt — is the correct approach.

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

> **Last completed:** Rails API layer complete — `ZoneLookupService`, `AiRecommendationService`, type structs (`Yard`, `Dimensions`, `YardFeature`), system prompt, and full test coverage. Architecture revised: no structured intake form; Claude is the spatial interpreter. Conversational intake, pure `messages` + `current_design` request contract.
>
> **Next step:** Update `API_ARCHITECTURE.md` with new contract → build `RecommendationsController` + routes → scaffold Next.js frontend → get a full request → SVG response rendering in the browser. Spatial interpretation must be validated visually before further API investment.
