# API Architecture

## Endpoint

`POST /api/v1/recommendations`

Multi-turn and stateless — the client sends the full message history each turn. Claude guides the user through providing context, confirms understanding, then produces a design. Subsequent turns allow tweaks ("more purple", "fewer shrubs").

**Input:**
- `messages` — full conversation history (role + content pairs)
- `zip_code` — provided on first turn, used for zone lookup
- `width_ft`, `length_ft` — yard dimensions
- `sun_exposure` — full sun / partial shade / full shade
- `style` — naturalistic, formal, desert modern, etc.
- `existing_elements` (optional) — array of trees, beds, paths, hardscaping

**Output:**
- `message` — Claude's conversational response
- `design` (once ready) — structured JSON plant layout (see below)
- `svg` (once ready) — rendered SVG diagram as a string
- `legend` — plant list with letter key, name, size, quantity
- `summary` — short design description paragraph

**Design JSON shape:**
```json
{
  "yard": { "width_ft": 20, "length_ft": 30 },
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

---

## Services

**`ZoneLookupService`**
Calls phzmapi.org with the zip code. Returns USDA zone, temp range, and climate context. Keeps the zone lookup isolated and easy to swap.

**`AIRecommendationService`**
Owns the prompt. Takes zone data + yard context + message history, calls Claude, returns conversational response + structured design JSON. This is where the prompt engineering lives.

**`SvgRenderService`**
Takes the design JSON and renders it to an SVG string — grid, scaled plant shapes, letter labels, legend, design summary. Pure rendering, no AI.

**`RecommendationsController`**
Thin orchestration layer — calls services in order, merges results, renders the response. No business logic here.

---

## Prompt Engineering

The prompt is a first-class concern of this project, not an afterthought.

**System prompt goals:**
- Establish Claude as a xeriscape expert who prioritizes water efficiency, native plants, and regional appropriateness
- Constrain output to a structured JSON format so the frontend can render it reliably
- Set tone: practical and specific, not generic ("plant drought-tolerant species")

**Context injection:**
Zone data and yard details are injected into the user turn in a clean, labeled format so Claude has unambiguous inputs to reason from.

**Chain of thought:**
Claude is asked to reason about the yard before making recommendations — water zones, sun patterns, existing elements, desired style. Recommendations follow from the reasoning, making the output explainable.

**Output structure:**
```json
{
  "zone": { "number": "7b", "temp_range": "5–10°F", "summary": "..." },
  "reasoning": "...",
  "plants": [
    {
      "common_name": "...",
      "scientific_name": "...",
      "why": "...",
      "placement": "...",
      "water_need": "low | moderate",
      "mature_size": "..."
    }
  ],
  "design_principles": ["...", "..."],
  "layout_notes": "..."
}
```

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
  config/
    routes.rb
```

---

## Status

> **Next step:** Build `ZoneLookupService` → `AIRecommendationService` (first prompt draft) → `SvgRenderService`. Get a full request → SVG response working end to end before polishing any layer.
