# API Architecture

## Endpoint

`POST /api/v1/recommendations`

Multi-turn and stateless. The client sends the full message history each turn. Claude guides the user through describing their yard spatially, confirms its interpretation, then produces a design. Subsequent turns allow conversational refinement ("more purple", "add a walkway toward the back").

---

## Interaction Model

There are two distinct phases:

**Phase 1 — Spatial intake and initial design**
Claude gathers everything conversationally: zip code, yard description, existing features, sun exposure, style. No form. The user describes their yard in natural language (e.g. "37'-8" wide from stairs to ditch, planter 16'-8" x 5' in the right corner, tree 10'-6" from the planter"). Claude asks focused clarifying questions, confirms its spatial interpretation before locking in coordinates, then produces a first design.

**Phase 2 — Refinement**
Once a design exists, the user tweaks it conversationally. The `current_design` field carries the last design JSON as a separate field — it is not part of the message history. This keeps the history lean (no multi-KB JSON blobs in every request) while giving Claude full context to refine from.

---

## Request

```json
{
  "current_design": null,
  "messages": [
    { "role": "user", "content": "..." },
    { "role": "assistant", "content": "..." }
  ]
}
```

- `messages` — full conversation history, role + content pairs. `<design>` blocks are stripped from assistant messages before resending — Claude's prior design is passed via `current_design`, not embedded in history.
- `current_design` — `null` on the first call (initial design mode); the last design JSON object on refinement turns. Rails injects this into the system prompt so Claude knows what it previously produced.

**No structured yard fields on the request.** Zip code, dimensions, sun exposure, style, and existing features are all gathered by Claude through conversation. The design block is the authoritative structured output once Claude has enough context.

---

## Response

```json
{
  "message": "Claude's conversational response",
  "design": { ... },
  "svg": "<svg>...</svg>",
  "legend": [ ... ]
}
```

- `message` — always present. Claude's conversational text with the `<design>` block stripped.
- `design` — present once Claude has produced a plan; `null` during early intake turns.
- `svg` — present when `design` is present. Rendered by `SvgRenderService` from the design JSON.
- `legend` — present when `design` is present. Derived from `design.plants`.

---

## Design JSON Schema

The `<design>` block Claude produces and Rails parses:

```json
{
  "yard": {
    "boundary": [
      { "x": 0, "y": 0 },
      { "x": 37.67, "y": 0 },
      { "x": 37.67, "y": 24 },
      { "x": 0, "y": 24 }
    ],
    "unit": "ft",
    "existing_features": [
      { "type": "planter", "label": "Planter", "x": 21, "y": 19, "width": 16.67, "height": 5 },
      { "type": "tree", "label": "Existing tree", "x": 31, "y": 8.5, "radius_ft": 3 }
    ]
  },
  "plants": [
    {
      "letter": "A",
      "common_name": "Gro-Low Fragrant Sumac",
      "scientific_name": "Rhus aromatica",
      "plant_type": "shrub",
      "color": "#8B4513",
      "mature_spread_ft": 8,
      "quantity": 3,
      "positions": [{ "x": 4, "y": 6 }, { "x": 8, "y": 6 }, { "x": 12, "y": 6 }]
    }
  ]
}
```

**Coordinate system:** `(0, 0)` at top-left corner of the yard. x increases right, y increases down. All values in decimal feet. Claude converts feet-inches (`37'-8"` → `37.67`) and resolves relational measurements (`"10'-6" from the planter"`) into absolute coordinates.

**Semantic distinction:**
- `existing_features` — ground truth provided by the user. Claude designs around these; it does not move or remove them.
- `plants` — Claude's recommendations. The design artifact.

**`features` (hardscape Claude recommends) is reserved for a future iteration.** If a user asks for a walkway, Claude describes it in the `message` field but does not yet emit it in the design block. The schema is forward-compatible — a `features` array will be added alongside `plants` when SVG rendering supports it.

---

## Services

**`ZoneLookupService`**
Calls phzmapi.org with the zip code once Claude has gathered it. Returns USDA zone and temp range. Zone data is injected into the system prompt for all subsequent turns.

**`AiRecommendationService`**
Owns the prompt. Takes `current_design` + message history, calls Claude, returns conversational response + structured design JSON. Two prompt modes:
- Initial design: Claude has no `current_design`; gathers context and produces first plan.
- Refinement: `current_design` injected into system prompt; Claude modifies it per the user's request.

**`SvgRenderService`**
Takes the design JSON and renders an SVG string: yard boundary polygon, existing features, plant circles at specified positions with letter labels, legend. Pure rendering — no AI.

**`RecommendationsController`**
Thin orchestration: parse params → call services → merge results → render JSON. No business logic here.

---

## Prompt Engineering

The prompt is a first-class concern. Key responsibilities beyond plant expertise:

**Spatial interpretation**
- Parse feet-inches format: `37'-8"` → `37.67 ft`
- Resolve relational measurements into absolute coordinates using the established coordinate system
- Set `(0, 0)` at top-left, x right, y down, all values in decimal feet
- Confirm spatial reading with the user before producing a `<design>` block: "I'm placing the planter from x=21 to x=37.67 along the back — does that match?"

**Conversation discipline**
- Ask one clarifying question at a time, not a list
- Do not produce a `<design>` block until spatial layout is confirmed and plant context (sun, style, zone) is sufficient
- On refinement turns, modify `current_design` in response to the user's request; do not start from scratch

**Output structure**
- Emit `<design>` block only when ready; strip it from message text (the `message` field is the design block stripped)
- Positions in absolute decimal feet from `(0, 0)`; `positions.length` must equal `quantity`

---

## Directory Structure

```
api/
  app/
    controllers/
      api/
        v1/
          recommendations_controller.rb
    services/
      zone_lookup_service.rb
      ai_recommendation_service.rb
      svg_render_service.rb
    prompts/
      xeriscape_designer.txt
    types/
      yard.rb
      dimensions.rb
      yard_feature.rb
  config/
    routes.rb
```

---

## Status

> **Services built:** `ZoneLookupService`, `AiRecommendationService`, type structs, system prompt, tests.
>
> **Not yet built:** `RecommendationsController`, routes, `SvgRenderService`, Next.js frontend.
>
> **Next step:** Build controller + routes → scaffold Next.js frontend → validate spatial interpretation visually in the browser.
