# Logistics Inc — Technical Architecture

**Engine:** Godot 4.x  
**Primary target:** Android landscape  
**Secondary target:** Windows/Linux desktop  
**Principle:** Simulation logic must be independent from presentation so the world can scale without UI code becoming the game.

---

## 1. Architecture Goals

1. Living world simulation continues while management panels are open.
2. World objects represent real simulation state where practical.
3. Systems are data-driven and testable independently.
4. Save files are versioned and migratable.
5. Art/assets can be replaced without rewriting game logic.
6. Mobile performance is budgeted from the start.

---

## 2. High-Level Layering

```text
Presentation Layer
  UI / Camera / Animation / FX / Audio
          |
Simulation Facade / Event Bus
          |
Core Simulation Systems
  Time / Economy / Ports / Fleet / Voyages / Personnel
  Contracts / Shipyard / Research / AI / Events / Finance
          |
Data Layer
  Static databases / runtime state / save system
```

UI never directly owns authoritative economy/fleet state.

---

## 3. Recommended Godot Project Structure

```text
res://
  scenes/
    boot/
    menu/
    world/
    port/
    ui/
    entities/
      ships/
      vehicles/
      facilities/
      workers/
  scripts/
    core/
      game_state.gd
      event_bus.gd
      time_system.gd
      save_system.gd
    simulation/
      economy_system.gd
      port_system.gd
      fleet_system.gd
      voyage_system.gd
      contract_system.gd
      personnel_system.gd
      shipyard_system.gd
      research_system.gd
      finance_system.gd
      event_system.gd
      competitor_system.gd
      market_system.gd
    presentation/
      port_world_controller.gd
      world_map_controller.gd
      camera_controller.gd
      animation_router.gd
    ui/
      hud_controller.gd
      context_panel_controller.gd
      build_toolbar_controller.gd
  data/
    eras/
    ports/
    ships/
    cargo/
    technologies/
    people/
    contracts/
    events/
  assets/
    art/
    ui/
    audio/
```

---

## 4. Core Singletons / Autoloads

### GameState
Authoritative runtime company/world state.

### EventBus
Signals between systems and presentation.

Example events:
- day_advanced
- contract_accepted
- vessel_departed
- vessel_arrived
- cargo_loaded
- facility_started
- facility_completed
- shipyard_job_started
- research_completed
- finance_changed
- world_event_started

### SaveSystem
Serializes/deserializes versioned state.

### Database
Loads immutable data definitions.

---

## 5. Time System

Simulation speeds:
- paused
- 1x
- 2x
- 4x
- optional faster speeds for world-map time

Use discrete simulation ticks rather than frame-dependent economics.

Recommended:
- visual animation: every frame
- lightweight movement: every frame / physics tick
- economy/logistics: hourly/day ticks depending on system
- strategic AI: daily/weekly ticks

---

## 6. Entity Model

Every persistent simulation entity uses a stable ID.

Examples:
- `port_liverpool`
- `company_player`
- `ship_000012`
- `facility_000104`
- `person_000455`
- `contract_001280`

Visual nodes may be destroyed/recreated without losing simulation state.

---

## 7. Port Runtime Model

PortState:
- id
- owner/government
- region
- local economy
- berth slots
- warehouse slots
- facilities
- congestion
- workforce
- relationships
- service prices
- active vessel calls

FacilityState:
- id
- definition_id
- owner_company
- grid_position
- orientation
- construction_stage
- condition
- staffing
- active_job

---

## 8. World Representation

### Port Scene
Detailed isometric local simulation.

Use:
- isometric tile/grid coordinates
- navigation lanes for ships
- spline/waypoint networks for road/rail
- object pooling for workers, vehicles and ambient craft

### World Map
Strategic representation.

Voyaging ships should not carry the full local port scene. They exist as strategic voyage entities and render as simplified moving world-map sprites.

---

## 9. Fleet / Voyage Separation

ShipState stores vessel condition and configuration.

VoyageState stores temporary travel state:
- vessel_id
- origin
- destination
- route
- departure time
- ETA
- cargo
- supplies
- risk
- current event

This avoids mixing ship ownership with active route state.

---

## 10. Economy System

Economy runs from supply/demand state per port and cargo type.

At minimum:

```text
local_price = base_price * demand_factor / supply_factor
freight_rate = distance * cargo_rate * risk_multiplier * market_multiplier
```

Later add:
- seasonal effects
- shocks
- storage costs
- congestion
- competition
- contract premiums

Economy calculations should be deterministic from state + random seed where possible.

---

## 11. Construction System

Construction is a simulation job linked to a world facility placeholder.

ConstructionJob:
- facility_id
- start_time
- completion_time
- required_materials
- assigned_workers
- current_stage

Visual stages are presentation outputs driven by progress thresholds.

---

## 12. Shipyard System

Shipyard jobs share a common queue model:
- repair
- retrofit
- new build
- external customer job

ShipyardJob:
- job_id
- yard_id
- dock/slot
- customer_company
- vessel/design
- progress
- quality_target
- deadline
- cost
- penalty

Visible shipyard animation reads job phase from simulation state.

---

## 13. Personnel System

Persistent named characters use structured traits and skills.

PersonnelState:
- person_id
- employer
- role
- age
- salary
- contract_end
- loyalty
- morale
- skills
- traits

Crew mass labor can be aggregated while key officers remain individual characters.

---

## 14. AI Competitor System

Use utility-based strategic decisions instead of scripting one fixed behavior.

AI evaluates opportunities:
- route profitability
- vessel purchase/charter
- facility investment
- research investment
- tender bid
- personnel recruitment
- debt pressure

Each AI company has a personality profile:
- conservative
- expansionist
- technology-led
- low-cost carrier
- shipbuilder-focused
- port-focused

---

## 15. Event System

Data-driven events stored as definitions.

Event fields:
- id
- trigger conditions
- era range
- geographic scope
- probability/weight
- choices
- effects
- follow-up events

Choices modify actual simulation state, not only text.

---

## 16. UI Architecture

UI is composed of persistent HUD + contextual panels.

Never recreate all game state inside UI controls.

UI receives updates via EventBus and queries GameState through typed accessors.

Routine actions should remain non-modal.

Modal dialogs reserved for:
- important voyage event
- confirmation of irreversible action
- tender submission
- major world event

---

## 17. Rendering / Mobile Performance Budget

Target: smooth gameplay on mid-range Android devices.

Strategies:
- object pooling
- viewport culling
- simplified off-screen simulation
- sprite atlas use
- limited shader complexity
- batch-friendly assets
- lower animation update frequency for distant ambient actors

Avoid thousands of individual process callbacks. Use managers/batched updates.

---

## 18. Save Schema

Example top-level structure:

```json
{
  "save_version": 1,
  "world": {},
  "player_company": {},
  "companies": {},
  "ports": {},
  "ships": {},
  "people": {},
  "contracts": {},
  "voyages": {},
  "research": {},
  "events": {},
  "random_seed": 12345
}
```

Save migration functions must be added before changing released schemas.

---

## 19. Data Files

Static content should be editable without code changes.

Example data definitions:
- cargo JSON/resources
- ship class definitions
- technology definitions
- port definitions
- event definitions
- era unlock tables

This is necessary for balancing and historical expansion.

---

## 20. Production Refactor Plan

The current prototype contains too much logic in large scripts. Production refactor should occur incrementally.

Order:
1. Create GameState + EventBus + TimeSystem
2. Move port/fleet/contracts state out of `app.gd`
3. Create PortWorldController with camera + selection
4. Build construction job model
5. Build vessel/voyage state model
6. Build world map route model
7. Add save schema v1
8. Add data definitions
9. Add competitor AI only after player economy loop is stable

The playable build should remain buildable at every milestone.
