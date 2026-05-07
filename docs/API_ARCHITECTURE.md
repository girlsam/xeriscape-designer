# API Architecture

## Endpoint

`POST /api/v1/recommendations`

**Input:**
- `zip_code` — used for zone lookup and climate context
- `width_ft`, `length_ft` — yard dimensions
- `sun_exposure` — full sun / partial shade / full shade
- `style` — naturalistic, formal, desert modern, etc.
- `existing_elements` (optional) — array of trees, beds, paths, hardscaping

**Output:**
- Zone info (zone number, temp range, climate summary)
- Plant recommendations — each with name, why it was chosen, placement rationale, water zone
- Design principles specific to the yard's context
- Layout suggestions (where to group plants, water zones, focal points)

---

## Services

**`ZoneLookupService`**
Calls phzmapi.org with the zip code. Returns USDA zone, temp range, and climate context. Keeps the zone lookup isolated and easy to swap.

**`AIRecommendationService`**
Owns the prompt. Takes zone data + yard context, calls the AI provider, returns structured JSON recommendations. This is where the prompt engineering lives.

**`RecommendationsController`**
Thin orchestration layer — calls the two services, merges results, renders the response. No business logic here.

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
api/                        # Rails API mode app
  app/
    controllers/
      api/
        v1/
          recommendations_controller.rb
    services/
      zone_lookup_service.rb
      ai_recommendation_service.rb
  config/
    routes.rb
```

---

## Status

> **Next step:** Confirm Rails is installed, scaffold `api/` with `rails new api --api`, set up versioned routes, stub the endpoint, then build services one at a time starting with `ZoneLookupService`.
