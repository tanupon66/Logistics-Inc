# Logistics Inc — Production Roadmap

This roadmap converts the current prototype into the full TCH Studio game defined by the GDD and Art Bible.

## v0.5 — Foundation Rebuild
Goal: stop treating the game as a large UI script.

Deliverables:
- GameState singleton
- EventBus
- TimeSystem
- Save schema v1
- port/fleet/contract data models
- persistent camera pan/zoom
- proper isometric grid
- first production 1750 port district
- animated water, smoke, flags, birds
- moving ship + cart actors using real route state

Exit condition: watching the port without opening menus already feels alive.

## v0.6 — Shipping Company Loop
Goal: complete the charter-to-owned-ship loop.

Deliverables:
- charter market
- buy/sell ship
- hire captain + basic crew
- provision loading
- freight contracts
- departure/arrival
- voyage state
- world-map route movement
- voyage events
- repair at external yard
- berth/warehouse lease

Exit condition: player can start with no owned ship and build a profitable shipping company.

## v0.7 — Port Building
Goal: turn the port into a genuine buildable management space.

Deliverables:
- build mode
- placement grid
- construction ghost
- roads/quays/warehouses
- cargo berth
- warehouse operations
- visual construction stages
- truck/cart flows tied to cargo
- port congestion
- facility maintenance/staffing

Exit condition: player expansion visibly changes the working port.

## v0.8 — Shipyard & Industry
Goal: enable vertical integration.

Deliverables:
- external yard service market
- owned shipyard
- dry dock
- repair queues
- retrofit
- visible hull construction
- ship design v1
- build for own fleet
- build for sale
- customer shipbuilding contracts
- shipyard workforce/capacity

Exit condition: a player can become a shipbuilder without focusing on freight shipping.

## v0.9 — Global Competition
Goal: make the world respond to the player.

Deliverables:
- multiple regions/ports
- dynamic cargo supply/demand
- competitor companies
- competitor routes/fleets
- personnel market/poaching
- tenders
- port agreements/concessions
- company acquisitions
- R&D web
- historical events

Exit condition: the player competes for cargo, people, infrastructure and technology.

## v0.10 — Historical Eras
Goal: meaningful technological progression.

Deliverables:
- 1750 baseline art/data
- steam transition
- steel/industrial era
- diesel era
- containerization
- modern era
- regulations by era
- facility replacement/retrofit pressure
- era-specific port visuals

Exit condition: a long-running company visibly and mechanically evolves through time.

## v0.11 — Content & Polish
Goal: expand breadth while improving quality.

Deliverables:
- larger ship roster
- more cargo types
- more ports
- more events
- weather system
- day/night lighting
- audio mix
- settings/accessibility
- tutorial/onboarding
- economy balancing
- Android performance pass

## v0.12 — Beta
Goal: long-session reliability.

Deliverables:
- save migration tests
- crash/error logging strategy
- economy exploit fixes
- long-run AI tests
- touch UX pass
- loading/performance optimization
- regression test checklist

## v1.0 — Full Release Definition
The full game must support:
- charter-first start
- owned fleets
- living animated port
- buildable infrastructure
- ship repair and construction
- ship sales/tenders
- personnel and captains
- supplies and voyage decisions
- research and historical progression
- global trade routes
- dynamic economy
- AI competitors
- port rights/concessions
- save/load stability
- production-quality isometric pixel art
- TCH Studio branding, icon, splash, music and environmental audio

## Development Rule
No milestone is considered complete merely because a button changes a number. Every major economic system should have a visible representation in the world whenever practical.
