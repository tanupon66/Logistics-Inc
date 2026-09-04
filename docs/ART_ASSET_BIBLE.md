# Logistics Inc — Art & Asset Bible

**Studio:** TCH Studio  
**Target:** High-detail isometric pixel-art maritime tycoon with a living animated world.  
**Reference quality bar:** Dense, readable, animated isometric management-game visuals. Never ship programmer placeholder art as final-facing art.

---

## 1. Visual Identity

The game world should feel like a handcrafted industrial diorama viewed from an elevated isometric camera.

Core look:
- dark navy / steel-blue UI
- warm brass / gold accents
- weathered industrial materials
- vivid water
- readable silhouettes
- dense but organized scenery
- strong day/night contrast

The game must visually communicate growth: a small 1750 port should look materially different from a 1930 industrial harbor or a 1980 container terminal.

---

## 2. Pixel-Art Rules

### 2.1 Projection
Use a consistent isometric projection for world assets.

Recommended visual grid:
- 2:1 diamond isometric ground grid
- base logical tile: 64x32 px for production-quality world art
- larger structures composed from multiples of the base tile

### 2.2 Pixel discipline
- no accidental anti-aliased edges on pixel sprites
- nearest-neighbor filtering
- consistent light direction
- consistent scale between people, vehicles, buildings and vessels
- no photo-real pasted textures inside the playable world

### 2.3 Lighting
Default light direction: upper-left / north-west visual direction.

Every asset should have:
- lit face
- mid-tone face
- shadow face
- contact shadow

### 2.4 Outline policy
Avoid heavy black outlines around everything. Prefer selective dark edge definition and material contrast.

---

## 3. Era Art Packs

Assets should be grouped by historical era so visual evolution is obvious.

### Era A — 1750–1815
- timber quays
- stone warehouses
- sailing merchant ships
- hand cranes
- carts/horses
- rope yards
- sail lofts
- lantern lighting

### Era B — 1815–1870
- early steamships
- paddle steamers
- coal yards
- rail beginnings
- iron cranes
- larger brick warehouses
- smoke-heavy industry

### Era C — 1870–1914
- steel ships
- major rail terminals
- dry docks
- iron/steel shipyards
- telegraph offices
- steam cranes
- dense industrial city

### Era D — 1914–1945
- motorized trucks
- diesel transition
- larger machine shops
- fuel storage
- electric lighting
- improved docks

### Era E — 1945–1970
- modern cargo ships
- oil terminals
- forklifts
- paved yards
- larger cranes

### Era F — 1970–2000
- container cranes
- container stacks
- Ro-Ro ramps
- dedicated container terminals
- motorway logistics

### Era G — 2000–2035
- mega ships
- automated stacking cranes
- advanced terminals
- dense truck/rail flows
- modern offices

### Era H — 2035+
- alternative fuel bunkering
- autonomous yard vehicles
- electrified cranes
- advanced materials
- futuristic but grounded maritime design

---

## 4. Environment Asset List

### 4.1 Terrain
- deep water
- shallow water
- shoreline
- rocky coast
- mudflat
- grass
- urban ground
- industrial ground
- paved yard
- rail bed

### 4.2 Water overlays
- calm ripple
- wind ripple
- ship wake
- tug wake
- foam at quay
- rain impacts
- storm wave overlay

### 4.3 Roads
- dirt road
- cobbled road
- paved road
- industrial service road
- intersections
- bridge ramps

### 4.4 Rail
- straight
- curve
- junction
- station platform
- freight siding
- crane rail

---

## 5. Port Facility Asset List

Each facility needs at least:
- construction stage sprites
- completed sprite
- selected highlight state
- damaged/under-repair variant when applicable
- night lighting variant/effect

Facilities:
- small quay
- cargo berth
- passenger berth
- pier
- warehouse small/medium/large
- bonded warehouse
- administration office
- customs house
- crew office
- hospital/clinic
- coal depot
- oil/fuel depot
- fresh-water facility
- food/provisions store
- cargo crane
- gantry crane
- rail terminal
- truck yard
- market
- dry dock small/medium/large
- slipway
- shipyard assembly area
- machine shop
- foundry
- engine workshop
- research center

---

## 6. Ship Asset List

Ships need multiple directional frames suitable for world movement.

Minimum world-view directions:
- NE
- SE
- SW
- NW

Production target can expand to 8 directions for smoother navigation.

Each major ship class needs:
- clean sprite
- damaged variant
- selected glow/outline mask
- wake anchor points
- smoke stack anchor points where applicable
- navigation light anchors

Initial playable classes:
1. sailing merchantman
2. coastal trader
3. packet ship
4. early steam cargo ship
5. steam freighter
6. tugboat
7. tanker
8. bulk carrier
9. container ship
10. ferry

---

## 7. Vehicle & Character Asset List

### Vehicles
- horse cart
- cargo wagon
- steam locomotive
- freight railcar
- early truck
- modern truck
- yard tractor
- forklift
- service van

### Characters
World-scale silhouettes/animations:
- dock worker
- sailor
- officer
- engineer
- clerk
- crane operator

Character portraits:
- captain variants
- engineer variants
- researcher variants
- port manager variants

---

## 8. Animation Library

### 8.1 Ambient loop animations
- water shimmer
- waves
- smoke puffs
- chimney smoke
- flags
- birds
- rotating beacons
- lighthouse beam

### 8.2 Logistics animations
- crane boom move
- crane hook descend
- cargo load/unload
- container transfer
- warehouse door open/close
- truck arrive/depart
- train arrive/depart
- tug docking assist

### 8.3 Shipyard animations
- sparks/welding
- crane lifting hull section
- workers moving
- scaffolding changes
- hull construction stage transitions
- dry dock flooding/draining

### 8.4 Weather
- rain
- heavy rain
- fog layer
- snow
- lightning flash
- storm wave intensity

### 8.5 UI micro-animation
- panel slide
- notification pulse
- button press
- progress completion
- cash change tick
- research completion

---

## 9. Camera & Presentation

Camera must make the world feel large.

Required:
- smooth pan
- pinch zoom on mobile
- min/max zoom limits
- focus selected object
- optional edge pan for desktop

The playable world should remain visible behind most management UI.

---

## 10. UI Asset System

UI should use reusable 9-slice panels and iconography rather than unique painted screenshots.

Core UI palette:
- background: dark navy
- border/accent: brass/gold
- positive: green
- warning: amber
- danger: red
- selected: cyan/blue highlight

Icon set:
- port
- fleet
- contracts
- shipyard
- research
- personnel
- finance
- world
- build
- repair
- route
- hire
- upgrade
- supply
- manage
- pause/play/speed
- notification/mail

---

## 11. Main Menu Art

Main menu should be a living scene, not a static poster.

Layers:
1. distant city
2. rail/factory layer
3. shipyard layer
4. water layer
5. moving ships/tugs
6. smoke/lighting FX
7. logo/UI

Loop length target: 20–40 seconds before repetition becomes obvious.

---

## 12. Port Scene Composition

A medium port scene should visually include:
- active water area
- at least 2–4 moving vessels
- one active berth
- one warehouse cluster
- one road freight stream
- one rail line or equivalent historical logistics path
- visible industrial background
- space for future expansion

A mature port should feel crowded but readable, with clear functional districts.

---

## 13. Asset Folder Structure

Recommended:

```text
assets/
  art/
    world/
      terrain/
      water/
      roads/
      rail/
    buildings/
      era_1750/
      era_1850/
      era_1900/
      era_1950/
      era_2000/
    ships/
    vehicles/
    characters/
    fx/
  ui/
    icons/
    panels/
    portraits/
  audio/
    music/
    ambience/
    sfx/
```

---

## 14. Asset Production Priority

### Priority 0 — Needed for the next playable build
- 1750 water tiles
- 1750 quay tiles
- small warehouse
- office
- basic berth
- 2 sailing merchant vessels
- 1 tug/service boat equivalent suitable for era
- dock worker sprites
- cart sprites
- crane sprites
- animated water/wake
- smoke/flag/birds
- UI icon pack

### Priority 1
- shipyard small
- dry dock small
- coal/fuel transition assets
- rail assets
- early steamship

### Priority 2
- industrial expansion pack
- world map port icons
- character portraits
- weather FX

---

## 15. Quality Gate

An art build is rejected if:
- the port is primarily a static background
- moving objects are decorative but disconnected from logistics
- structures use inconsistent perspective
- pixel scale is inconsistent
- UI covers most of the world
- programmer primitives/shapes dominate the final look
- major construction has no visual progression
- the scene feels empty when time is running

The visual goal is always: **the player should enjoy watching the port operate even before pressing a button.**
