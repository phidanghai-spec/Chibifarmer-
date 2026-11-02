# 🎮 Full Game Studio Agent Roster (49 Roles)

Adapted from **Claude Code Game Studios** for Antigravity & Godot Engine.
Each agent owns a specific domain with defined responsibilities and quality gates.

---

## 🏛️ Tier 1 — Directors (Strategic Vision & Scope)

| Agent | Domain & Purpose | Key Responsibilities |
| :--- | :--- | :--- |
| **`creative-director`** | Core Game Vision | Guards high-level concept, emotional tone, aesthetic cohesion, and core gameplay pillar alignment. Resolves creative conflicts. |
| **`technical-director`** | Engineering Vision | Sets architectural principles, tech stack choices, performance budgets (draw calls, memory, target 60 FPS), and engine constraints. |
| **`producer`** | Scope & Schedule | Manages milestone tracking, sprint planning, feature cuts, scope-creep prevention, and dependency roadmaps. |

---

## 🎖️ Tier 2 — Department Leads (Domain Ownership)

| Agent | Domain & Purpose | Key Responsibilities |
| :--- | :--- | :--- |
| **`game-designer`** | Gameplay Systems & GDD | Owns the Game Design Document, core interaction loops, player agency, progression mechanics, and rule sets. |
| **`lead-programmer`** | Code Standards & Architecture | Enforces GDScript 2.0 static typing, decoupled signal architecture, Autoload design, node lifecycle, and PR approvals. |
| **`art-director`** | Visual Identity & Style Bible | Establishes the 2.5D Chibi Cozy aesthetic, color palette harmony, sprite resolution standards, and UI styling. |
| **`audio-director`** | Soundscapes & Music | Curates cozy background music, spatial audio cues, audio bus mixing, and sound design cohesion. |
| **`narrative-director`** | Story & World Context | Establishes lore, environmental storytelling, quest narrative arcs, and NPC personality profiles. |
| **`qa-lead`** | Quality Assurance Strategy | Defines test suites, acceptance criteria, regression test plans, and release sign-off checklists. |
| **`release-manager`** | Build & Deployment | Oversees export presets, headless compilation validation, package distribution, and patch notes. |
| **`localization-lead`** | Multilingual Systems | Manages text translation keys, font glyph support, cultural adaptation, and RTL/LTR layout safety. |

---

## 🛠️ Tier 3 — Specialists (Hands-on Execution)

### A. Programming & Godot Specialists
- **`godot-gdscript-specialist`**: Expert in GDScript 2.0 Static Typing, `@onready`, custom classes (`class_name`), lambda callables, and signal decoupling without memory leaks.
- **`godot-specialist`**: Godot 4 scene tree architecture, Node composition, Resource workflows, TileMap/TileSet, and AStarGrid2D.
- **`gameplay-programmer`**: Player input handling, drag-and-swipe mechanics, crop timers, entity state machines, and inventory interactions.
- **`engine-programmer`**: Custom physics layers, tick timers, save serialization (`user://`), and engine performance tweaks.
- **`ai-programmer`**: Visitor NPC pathfinding, behavior trees, wandering critters (rabbits, ducks, birds), and pet navigation.
- **`ui-programmer`**: Responsive HUD layouts, modal popups, CanvasLayer ordering, and `mouse_filter` event dispatching.
- **`godot-shader-specialist`**: 2D water ripples, outline shaders, seasonal tints, wind sway, and dissolve transitions.
- **`tools-programmer`**: Asset slicing tools (`tools/chibi_asset_forge.py`), SFX generators, and automated test runners.
- **`network-programmer`**: Multi-client sync, packet serialization, latency compensation (for online expansions).

### B. Design & Balance Specialists
- **`economy-designer`**: Item pricing, crop growth durations, crafting recipes, storage capacities, drop rates, and gold/XP progression curves.
- **`systems-designer`**: Multi-system interplay (e.g. Farming $\to$ Animal Pens $\to$ Roadside Shop $\to$ Steamboat $\to$ Zoo).
- **`level-designer`**: Farm plot layout, road network, natural obstacles, expansion zones, and scenic points of interest.
- **`ux-designer`**: Control ergonomics, click radii, tooltip delays, tactile feedback, and drag-and-drop thresholds.
- **`accessibility-specialist`**: High-contrast modes, scalable fonts, colorblind-safe palettes, and one-finger touch controls.
- **`live-ops-designer`**: Daily newspaper events, seasonal festivals, limited-time truck orders, and visitor bonuses.
- **`world-builder`**: Biome design, natural landmarks, river flow paths, and seasonal landscape transitions.

### C. Art, Audio & Narrative Specialists
- **`technical-artist`**: Sprite atlas optimization, corner BFS background removal, 1px de-fringing, and 60 FPS procedural animations (Idle Breathing, Walk Bounce).
- **`sound-designer`**: Procedural sound generation, Foley synthesis, crop harvesting pops, animal barks, and water splashes.
- **`writer`**: Quest dialogues, NPC speech bubbles, daily newspaper articles, and item descriptions.
- **`prototyper`**: Rapid mechanic testing, graybox iterations, and gameplay feel experiments.

### D. QA, DevOps & Operations
- **`qa-tester`**: Headless CLI test execution, visual regression screenshot comparisons, edge-case boundary testing.
- **`performance-analyst`**: Frame-time profiling, memory leak detection, draw call budgeting, and mobile battery optimization.
- **`devops-engineer`**: CI/CD export pipelines, automated screenshot captures, and versioning scripts.
- **`security-engineer`**: Save file validation, anti-cheat checks for local storage, and input sanitization.
- **`analytics-engineer`**: Player telemetry tracking, session length metrics, and churn-point identification.
- **`community-manager`**: Player feedback triage, patch notes communication, and community bug reporting.

