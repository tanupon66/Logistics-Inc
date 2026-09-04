# Logistics Inc — Game Design Document

**Studio:** TCH Studio  
**Working Genre:** Isometric Pixel-Art Maritime Tycoon / Living Logistics Simulation  
**Engine:** Godot 4.x  
**Primary Platform:** Android landscape, with architecture prepared for desktop/tablet  
**Core Fantasy:** Start with almost nothing, rent access to maritime infrastructure, build a shipping company, vertically integrate into ports and shipyards, and eventually control a global maritime-industrial empire across historical eras.

---

## 1. Non-Negotiable Design Pillars

### 1.1 A living world, not a menu game
The main gameplay screen is a persistent animated world. Menus are overlays around the simulation, never the game itself.

The player should constantly see activity: ships maneuvering, tugboats assisting, cranes working, cargo moving, workers walking, trains arriving, trucks queueing, smoke stacks operating, lights switching on, weather changing, tides/water animating, and construction progressing.

### 1.2 Freedom of management
The player is never forced into one business model. Viable paths include:
- charter-first shipping company
- owned-fleet carrier
- port operator
- warehouse/terminal operator
- ship repair company
- shipbuilder
- R&D-led technology company
- logistics conglomerate
- acquisition-focused holding company

### 1.3 Rent before ownership
Most infrastructure can be rented/leased before it can be owned.

Examples:
- vessel charter
- office lease
- berth lease
- warehouse lease
- repair slot rental
- crane rental
- shipyard build slot rental
- fuel/supply contracts

Ownership brings long-term savings and new revenue streams, but also maintenance, staffing, debt and operational risk.

### 1.4 Vertical integration is visible
Progression is not just `Level +1`.

The world changes visually as the player grows:

`Charter ship -> Own ship -> Fleet -> Warehouse -> Berth rights -> Terminal -> Shipyard -> Dry dock -> Build ships -> Sell ships -> Tender contracts -> Global industrial group`

### 1.5 Historical progression changes gameplay
The game begins in an early commercial maritime era and advances through technological transitions.

Target eras:
1. 1750–1815 — Late Age of Sail
2. 1815–1870 — Steam Transition
3. 1870–1914 — Steel & Industrial Shipping
4. 1914–1945 — Mechanization & Regulation
5. 1945–1970 — Diesel & Global Trade
6. 1970–2000 — Containerization
7. 2000–2035 — Mega Ports & Digital Logistics
8. 2035+ — Automation, alternative fuels, advanced materials

Each era changes ship types, port facilities, labor, regulations, cargo handling, fuel supply and economics.

---

## 2. Player Start

Recommended default start: **Liverpool, 1750**.

The player starts with:
- small company office lease
- one leased berth right or service agreement
- modest cash
- no shipyard
- no owned vessel by default
- access to charter market
- access to public port services

The player can immediately:
- charter a ship
- inspect freight contracts
- hire a captain and crew
- buy provisions
- accept cargo
- send a voyage

The first meaningful decision is whether to grow through rented capacity or save toward owned assets.

---

## 3. Core Gameplay Loop

### 3.1 Pre-voyage
1. Choose or charter vessel
2. Select contract/cargo
3. Assign captain/officers/crew
4. Load provisions
5. Choose route and risk tolerance
6. Choose insurance / standing orders
7. Depart

### 3.2 Voyage simulation
Voyages run continuously on the world map.

Possible events:
- storm
- fog
- disease
- injury
- food shortage
- fresh-water shortage
- engine/rigging damage
- hull damage
- cargo damage
- labor dispute
- mutiny risk
- piracy
- port closure
- customs delay
- fuel shortage
- navigation error

A skilled captain can resolve minor events according to standing orders. A weak/no captain creates more direct player intervention.

### 3.3 Arrival
On arrival:
- berth queue
- unload cargo
- customs/fees
- repair check
- supply refill
- crew morale/rest
- contract payout
- reputation adjustment

### 3.4 Reinvestment
Profits are reinvested into:
- ships
- port rights
- warehouses
- terminal equipment
- shipyards
- staff
- R&D
- acquisitions

---

## 4. Living Port Simulation

The port is a real simulation space, not a background.

### 4.1 Visible traffic
- cargo vessels
- passenger vessels
- tugs
- barges
- pilot boats
- fishing vessels
- yard service craft
- trucks
- rail freight
- workers

### 4.2 Traffic logic
Every moving object should have an economic purpose when possible.

Examples:
- truck leaves warehouse after cargo unload
- train arrives for export demand
- tug appears because large ship requests berth assistance
- crane operation corresponds to cargo handling progress
- shipyard workers appear when a build/repair job is active

### 4.3 Day/night/weather
World state affects visibility and productivity.

Weather states:
- clear
- overcast
- rain
- storm
- fog
- snow where geographically appropriate

Night adds:
- dock lights
- building windows
- navigation lights
- reduced/changed labor efficiency depending on era and technology

---

## 5. Port System

Ports are independent economic nodes with:
- ownership/governance
- access rules
- tariffs/fees
- berth capacity
- cargo specialization
- warehouse capacity
- local workforce
- fuel/supply availability
- repair services
- shipyard capability
- congestion
- reputation
- political/commercial relationships

### 5.1 Access models
- public access
- berth agreement
- service contract
- warehouse lease
- land lease
- terminal concession
- exclusive concession

### 5.2 Facilities
- quay/berth
- pier
- warehouse
- bonded warehouse
- coal depot
- fuel depot
- water station
- provisions market
- crane
- rail terminal
- truck yard
- customs house
- administration office
- crew center
- hospital/clinic
- dry dock
- slipway
- shipyard
- machine shop
- foundry
- engine works
- research center

---

## 6. Construction & Expansion

Construction is placed into the port world.

The player selects a facility, sees a footprint/ghost, chooses a valid area and confirms construction.

Construction has:
- material requirements
- workforce requirement
- build time
- cost
- disruption footprint

Visual phases:
1. ground preparation
2. foundation
3. frame
4. equipment installation
5. final operational state

No instant visual `Level Up` for major facilities.

---

## 7. Fleet System

Each vessel has persistent identity.

Core attributes:
- vessel ID
- name
- class
- launch year
- hull material
- propulsion
- speed
- cargo capacity
- range
- fuel type
- fuel capacity
- condition
- reliability
- crew requirement
- maintenance interval
- insurance value
- class/certification
- upgrade slots

Possible vessel categories across eras:
- sailing merchantman
- packet ship
- steam cargo ship
- bulk carrier
- tanker
- container ship
- LNG carrier
- Ro-Ro
- ferry
- tugboat
- offshore support vessel
- heavy lift vessel
- car carrier
- reefer

---

## 8. Crew & Personnel

Key personnel are persistent characters:
- captain
- chief officer
- chief engineer
- yard manager
- naval architect
- research lead
- finance director
- port manager

Character attributes:
- age
- salary
- contract
- experience
- loyalty
- morale
- reputation
- specialization
- traits

Examples of traits:
- excellent navigator
- cautious
- aggressive schedule keeper
- crew favorite
- poor disciplinarian
- innovative engineer
- unreliable
- politically connected

AI competitors can poach talent. The player can counter-offer or recruit from rivals.

---

## 9. Shipyard System

Before owning a yard, the player uses third-party yards.

Third-party service includes:
- repair queue
- retrofit quote
- scheduled dry dock
- emergency repair
- build contract

Owned shipyard unlocks:
- priority repair of own fleet
- external repair customers
- ship upgrades
- ship construction
- design ownership
- ship sales
- tenders

### 9.1 Yard capacity
Resources:
- dry docks
- slipways
- cranes
- workforce
- machine shops
- material inventory
- engineering capacity

### 9.2 Ship construction
Build phases are visible:
1. keel/structural start
2. hull frame
3. hull completion
4. machinery installation
5. superstructure
6. outfitting
7. sea trials
8. delivery

---

## 10. Ship Design

Player-created ship classes become long-term company assets.

Design dimensions:
- hull form
- material
- length/beam/draft
- propulsion
- engine power
- cargo layout
- crew accommodations
- safety systems
- range
- speed
- reliability
- production cost

Trade-offs are mandatory:
- more speed -> higher fuel use / machinery cost
- more cargo -> less machinery/crew space
- stronger hull -> higher weight/cost
- lower build cost -> potentially lower reliability/class rating

---

## 11. Classification & Regulation

Ships must meet appropriate standards for their era.

Possible checks:
- hull strength
- stability
- machinery
- steering
- fire safety
- lifesaving systems
- emissions
- crew/safety regulations

Failure can require:
- redesign
- reinforcement
- delay
- retrofit
- operating restriction

Historical regulation events can make older ships non-compliant.

---

## 12. Contract System

Contract categories:
- spot freight
- recurring freight
- mail/passenger contracts in applicable eras
- government civil transport
- industrial logistics
- port service agreements
- ship repair orders
- shipbuilding orders
- long-term supply contracts

Contract scoring may consider:
- price
- delivery time
- reliability
- reputation
- technology
- relationship
- risk

---

## 13. Tender System

Large customers issue tenders for ships/infrastructure.

Tender fields:
- vessel type
- quantity
- capacity
- speed
- range
- quality requirement
- delivery deadline
- payment schedule
- penalty clauses

AI competitors submit bids. Cheapest bid does not automatically win.

---

## 14. Research & Technology

R&D is a technology web, not a single linear tree.

Categories:
- hull/materials
- propulsion
- navigation
- communications
- cargo handling
- shipyard production
- safety
- energy/fuel
- automation
- logistics/operations

Technology acquisition methods:
- internal research
- license technology
- hire expert
- joint venture
- acquire company
- purchase patent

---

## 15. Economy

Every port has local market conditions.

Cargo examples:
- grain
- timber
- coal
- iron ore
- steel
- textiles
- machinery
- tea
- coffee
- rubber
- oil
- chemicals
- refrigerated food
- containers

Variables:
- local supply
- local demand
- regional price
- freight rate
- route risk
- congestion
- fuel price
- labor cost

The goal is a simulated economy where routes can become unprofitable and new opportunities emerge.

---

## 16. Competitor AI

Competitors operate under the same broad economic rules as the player.

They can:
- charter/buy ships
- run routes
- bid on tenders
- lease port facilities
- build terminals
- build shipyards
- research technology
- hire/poach personnel
- borrow money
- fail financially
- merge/acquire

AI does not receive infinite hidden money as a normal rule.

---

## 17. Company Finance

Track:
- cash
- operating revenue
- port revenue
- yard revenue
- maintenance
- payroll
- fuel
- provisions
- lease costs
- debt
- interest
- insurance
- taxes/fees
- capital expenditure

Financing options:
- retained earnings
- bank loan
- bonds in later eras
- investors/share issuance if enabled
- asset sale
- sale-and-leaseback

---

## 18. World & Historical Events

World events should materially affect gameplay.

Examples:
- canal opening
- war/embargo
- recession/depression
- fuel shock
- labor strike
- regulation change
- new propulsion technology
- containerization
- communications breakthroughs
- global trade boom

History provides the baseline, but simulation outcomes can diverge.

---

## 19. UI Philosophy

The world occupies most of the screen.

### Top HUD
- cash
- current profit/loss
- date/time
- time controls
- reputation
- notifications

### Left navigation
- Port
- Fleet
- Contracts
- Shipyard
- Research
- Personnel
- Finance
- World

### Right contextual inspector
Shows only information for the selected object/facility/ship.

### Bottom action bar
Contextual actions such as:
- Build
- Repair
- Route
- Hire
- Upgrade
- Supply
- Manage

### Rule
Avoid full-screen popups for routine operations. Use side panels, bottom drawers and in-world selection.

---

## 20. Mobile Interaction

Landscape-first.

Controls:
- one-finger drag: camera pan
- pinch: zoom
- tap: select
- long press: contextual quick menu
- two-finger tap or UI button: cancel/close

Touch targets must remain readable without destroying the world view.

---

## 21. Save System

Versioned save schema.

Save must contain:
- world time
- economy state
- company state
- ports
- facilities
- fleet
- people
- routes
- contracts
- research
- competitor state
- random seed

Backward migration is required once public testing begins.

---

## 22. Definition of the Full Game

The game reaches 1.0 when the player can:
- start with rented capacity
- run profitable voyages
- hire crew and captains
- buy and maintain a fleet
- lease and own port infrastructure
- construct visible port facilities
- own and operate shipyards
- design/build/repair/sell ships
- bid on external tenders
- research technologies across multiple eras
- compete against functioning AI companies
- operate on a global world map
- experience dynamic economic/weather/historical events
- save/load long-running companies reliably
- play with a living animated pixel-art world rather than menu-only management
