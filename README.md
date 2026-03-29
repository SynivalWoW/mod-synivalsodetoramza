# Synival's Ode to Ramza

**mod-synival-ode-to-ramza** | AzerothCore WotLK 3.3.5a | CoffingQuest

A combined AzerothCore module containing everything short of a mortgage and a
dental plan. Nine upstream systems merged into one compilable unit, bound
together by a bridge layer, with two extras packages for the parts that have
the audacity to require client-side deployment.

---

## What's Inside

| System | Origin | What It Does |
|---|---|---|
| Paragon Progression & Board | mod-synival-paragon | Paragon XP, prestige resets, 41-board node system, glyph sockets |
| Loot & Item Tiers | mod-synival-paragon | Five-tier rarity scaling, auto-loot, auto-sell, 60 legendary items |
| Random Enchants | mod-synival-paragon | Weighted random enchantment pool applied on loot and craft |
| Buff Command | mod-synival-paragon | `.synbuff <spell_id>` self-buff whitelist system |
| Solo LFG | mod-synival-paragon | Single-player LFG queue with scaled rewards |
| Skip DK | mod-synival-paragon | Skips the Acherus intro chain on Death Knight creation |
| Open World Balance | mod-synival-paragon | Creature HP/damage scales with nearby player count |
| Guild Village | mod-guild-village (BeardBear33) | Guild-owned private zones with upgrades, production, expeditions |
| Guild Village Periodic Reward | original | 3-hour player reward tick: gold, glyph, paragon progress |
| Dungeon Master | mod-dungeon-master (InstanceForge) | Procedural on-demand dungeons with roguelike escalation |
| Guild Sanctuary Bridge | original (gss_guild_dungeon.cpp) | Warden NPC connecting guild villages to Dungeon Master sessions |
| Dungeon Respawn | AnchyDev/DungeonRespawn | In-instance respawn at last recorded position instead of outdoor graveyard |

### Extras (manual deployment, no compilation)
| Package | What It Is |
|---|---|
| `extras/SynParagon_ClientAddon/` | WoW client addon for paragon tier tooltips |
| `extras/SynParagon_DBC_Patch/` | Python patcher for `item_random_suffix` DBC |
| `extras/synparagon_board.lua` | Eluna gossip handler for the Runic Archive NPC |
| `extras/faction-free/` | Full Faction Free deployment: DBCs, SQL, Lua, MPQ, core patch |
| `extras/titles/` | 25 custom CoffingQuest titles: DBC and SQL |

---

## System Breakdown

### Paragon Progression

Players at level 80 accumulate Paragon XP instead of character XP. Each
Paragon Level grants a configurable stat bonus to all primary stats. At the
base cap (default: 200), the bonus reaches the configured ceiling (default:
+100%). Prestige allows players to reset Paragon Level up to 10 times,
unlocking an extended cap (default: 2000) and triggering The Butcher world
event at maximum prestige.

**Board Points** are earned at +1 per Paragon Level gained and a configurable
percent chance per creature kill (default: 5%). Points are spent unlocking
nodes on the Paragon Board.

**Prestige** grants bonus board points per reset, accumulates a permanent stat
multiplier, and is tracked independently of Paragon Level.

### Paragon Board System

41 boards organized in three tiers:
- 1 universal board (all classes)
- 10 class-specific boards (one per WotLK class)
- 30 spec-specific boards (three per class)

**Node types and costs:**

| Type | Cost | Effect |
|---|---|---|
| Start | Free | Entry point, always unlocked, counts for adjacency |
| Normal | 1 pt | Flat stat bonus via `HandleStatModifier(TOTAL_VALUE)` |
| Magic | 2 pts | Flat stat bonus (higher value than Normal) |
| Rare | 3 pts | Percent stat bonus via `HandleStatPercentModifier(TOTAL_PCT)` |
| Socket | 4 pts | Hosts a Glyph; no direct stat bonus |

**Glyphs** amplify all Rare nodes within their Chebyshev radius when socketed.
Removing a glyph returns the item to the player's bags. Glyph bonuses are
applied server-side on equip and removed on unequip.

Node unlocks require adjacency to an already-unlocked node. Board state
persists in `character_paragon_nodes` and `character_paragon_glyphs`.

The board is navigated through the Runic Archive NPC (entry 99996) via an
Eluna gossip handler (`paragon_board.lua`). The C++ layer handles all stat
application; the Lua layer handles all gossip rendering.

### Loot and Item Tiers

All looted items are assigned one of five rarity tiers:

| Tier | Name |
|---|---|
| 1 | Normal |
| 2 | Heroic (SynHeroic) |
| 3 | Mythical |
| 4 | Ascended |
| 5 | Synival's Chosen |

Higher tiers receive proportionally scaled stat bonuses applied on loot.
The system also handles:

> ### ⚡ Automated Resource Collection
> Three fully integrated automation systems handle gathering so players can
> focus on the content rather than the clicking tax that precedes it.
>
> **Auto-Loot** — On creature kill, the corpse is looted automatically and
> distributed to the player without interaction. Gold is split among group
> members within a configurable range. All tier rolls, enchant rolls, and
> auto-sell logic fire exactly as they would on a manual loot.
> Config: `Loot.AutoLootOnKill`, `Loot.AutoLootShareGold`
>
> **Auto-Skin** — After auto-loot clears the corpse, any creature with a
> skinning loot template is automatically skinned by the player. Requires the
> player's Skinning skill to meet the creature's minimum threshold — or
> possession of the Ser Coffington profession bypass spell, which removes the
> skill gate entirely. Skinning XP is awarded normally.
> Config: `Loot.AutoSkin`
>
> **Auto-Gather** — Scans all herb nodes, ore nodes, and chests within a
> configurable radius (default: 30 yards) after each kill and harvests any
> the player has the appropriate skill to collect. Runs the complete normal
> gather flow: skill checks, loot templates, profession XP — no corners cut,
> no shortcuts visible to the server. Players with the Ser Coffington bypass
> skip the skill gate here as well.
> Config: `Loot.AutoGather`, `Loot.AutoGatherRange`

- **Auto-sell** — Grey-quality items are automatically sold when the player
  visits a vendor. A summary of gold earned is printed to chat on
  leaving combat.
- **60 Legendary items** — Six per class, with class-appropriate model IDs
  for WotLK 3.3.5a ICC/T10 gear. Dropped from specific sources and
  purchasable through the Legendary Vendor NPC (entry 99997 range).
- **Paragon Shards** — A currency dropped from elite kills, used at Kadala
  (NPC entry 99998) to gamble for items.
- **Cache of Synival's Treasures** — A daily cache (item 99200) dropping
  shards and quality equipment. Epic and Legendary drop chances are
  independently configurable.
- **Mark of the Ascended** — A consumable (item 99300) granting a permanent
  flat stat bonus beyond the Paragon cap.
- **Hidden Affixes** — A configurable percent chance for looted items to
  receive a hidden secondary enchantment not visible in the tooltip.

### Random Enchants

Weapons and armour receive a random permanent enchantment from a configurable
pool when looted, crafted, or received from quests. The pool is defined in the
world database and weighted per enchantment. Config prefix: `RandomEnchants.*`

### Buff Command

`.synbuff <spell_id>` allows players to self-apply spells from a configurable
whitelist. Administrators may buff any target. Config prefix: `BuffCommand.*`

### Solo LFG

`.synqueue <dungeon>` queues a single player for an LFG dungeon without
requiring a full group. Group-sized rewards are scaled appropriately.
Config prefix: `SoloLFG.*`

### Skip DK Starting Area

On Death Knight creation, players are offered the choice to skip the Acherus
intro quest chain and spawn directly in their faction capital at level 58
with starter gear. Config prefix: `SkipDK.*`

### Open World Balance

Creature health and damage scale based on the number of players within range.
Prevents trivial content becoming trivial at higher Paragon levels when players
group up, and prevents solo content from becoming impossible at lower gear
levels. Config prefix: `AutoBalance.*`

### Guild Village

Guilds purchase a private persistent zone using configurable gold and/or item
costs. The zone is assigned a phase unique to the guild — other players cannot
see or enter it. Inside:

- **Upgrades** — Buildings and NPCs are purchased from a configurable catalog
  using four guild currency materials. Upgrades can require prerequisites.
- **Passive Production** — Production buildings generate currency on a
  configurable cycle. Upgrade ranks reduce cycle time and increase yield.
- **Expeditions** — Guild heroes are dispatched on timed missions that return
  loot and currency based on hero gear vs. mission requirements.
- **Guild Quests** — Daily and weekly quests specific to the village, paying
  out currency or items.
- **Teleporter** — Members save a personal waypoint inside the village.
  `.v tp` / `.v tp back` handle travel and return.
- **PvP Integration** — Kills and battleground victories award guild currency.
- **Rest Zone** — The village phase functions as a rest area.
- **Bot Guard** — Behavioral monitoring for automated farming patterns.
- **GM Tools** — Full GM inspection and manual override commands.

### Guild Village Periodic Reward

Every 3 hours of server uptime, all players currently inside their own guild's
village phase receive a reward bundle — three items rolled independently,
delivered without fanfare or a loading screen.

Players must be **online and inside their village** when the tick fires. There
are no backdated payouts for time spent offline or in the world. The system
tracks the last reward timestamp per character in `character_gv_reward_tracker`.

**The three rewards:**

**1. Gold** — A random amount between the configured minimum and maximum,
in whole gold pieces. Default range: 1–2,000 gold. The floor and ceiling are
independently configurable so you can make the server feel generous or merely
adequate depending on your philosophy.
Config: `GuildVillage.Reward.GoldMin`, `GuildVillage.Reward.GoldMax`

**2. Paragon Glyph** — One glyph item selected at random from the full global
glyph pool (all six glyphs: Tactician, Reinforcement, Elementalist, Brawler,
Phantom, Ironhide). All glyphs carry no class restriction on the item template,
so the random selection is genuinely random rather than quietly weighted by
class. The item is placed directly into the player's bags.

**3. Paragon Points or a full Paragon Level** — Rolled as a single binary
outcome. The default is a 10% chance for a full Paragon Level (one complete
level injected via the standard XP pipeline, with the level-up notification
and stat refresh firing normally) and a 90% chance for a configurable number
of Board Points (default: 3). Both percentages are configurable.
Config: `GuildVillage.Reward.FullLevelChancePct`, `GuildVillage.Reward.BoardPoints`

A chat notification is delivered to the player on each reward tick confirming
the gold amount received.

Config: `GuildVillage.Reward.IntervalSeconds` (default: 10800 — 3 hours)

Chat commands: `.village` (alias `.v`) with subcommands `help`, `info`, `tp`,
`tp back`, `tp set`, `prod`, `exp`, `quest`, `where`.

### Dungeon Master

An NPC-driven procedural dungeon system. Players select a **difficulty tier**
(up to 10 configurable tiers with health, damage, reward, and mob density
multipliers) and a **creature theme** (up to 20 types mapped to AzerothCore
creature type IDs). The system queries the world database for matching
creatures and scales them with layered multipliers:

- Base tier values
- Per-additional-player scaling
- Solo penalty
- Elite chance (default: 20%) with stacked multipliers
- Rare spawn chance (default: 5%)
- Boss placement at furthest spawn points (default: 8× HP, 1.5× damage)

Rewards include base gold, per-mob gold, per-boss gold, item drops with
configurable quality weighting, and an XP multiplier.

**Roguelike Mode** chains clears into an escalating sequence with linear then
exponential difficulty scaling, affix application at configurable tier
thresholds, an optional in-dungeon vendor, and a configurable buff pool.

**Four custom boss encounters** ship with the module:
- **Voltrix the Unbound** — Elemental, multi-phase, Core Burst and Fire
  Missile rotation, Berserk enrage.
- **Thranok the Unyielding** — Warrior-archetype with phased ability rotation.
- **Thalgron the Earthshaker** — Earth-themed area denial mechanics.
- **Thalor the Lifebinder** — Life-drain with healing interruption mechanic.

### Guild Sanctuary Bridge

The Warden of the Vault (NPC entry 501000) spawns in every guild village.
She presents the full Dungeon Master interface restricted to guild members
in their own village. Sessions she launches are tagged with the guild ID.

On confirmed completion, each participant receives configurable Material1
and Material2 currency. Per-guild aggregate statistics and a 50-entry run
log are maintained in the characters database.

Config keys (read by the C++ source, must remain as written):
`GuildSanctuary.WardenEntry`, `GuildSanctuary.Reward.ClearMat1`,
`GuildSanctuary.Reward.ClearMat2`, `GuildSanctuary.ShowGuildRecords`

### Dungeon Respawn

When a player dies in a dungeon or raid and releases their ghost, instead of
being sent to the nearest outdoor graveyard, they are resurrected at their last
recorded in-instance coordinates at a configurable health percentage
(default: 50%). Position is tracked per-player on every map transition and
persists across restarts via `dungeonrespawn_playerinfo`.

**Disabled by default.** Enable with `DungeonRespawn.Enable = 1`.

---

## Compilation

Drop the `mod-synival-ode-to-ramza/` folder into your AzerothCore `modules/`
directory and compile normally. `CollectSourceFiles` auto-discovers all `.cpp`
files in `src/` and its subdirectories, so no manual CMakeLists maintenance
is required when adding files.

The module entry point is `Addmod_synival_ode_to_ramzaScripts()` in
`src/loader.cpp`, derived from the folder name as AzerothCore requires.

---

## SQL Deployment

Run all SQL files against the appropriate database before starting the
worldserver. All `CREATE TABLE` statements use `IF NOT EXISTS`. All inserts
use `INSERT IGNORE` or `ON DUPLICATE KEY UPDATE` where applicable — safe to
re-run.

### acore_characters

| File | Description |
|---|---|
| `data/sql/characters/paragon_characters.sql` | Paragon level, board nodes, glyphs |
| `data/sql/characters/gss_characters.sql` | Guild village per-character state |
| `data/sql/characters/gss_dungeon_master_characters.sql` | DM session and roguelike state |
| `data/sql/characters/gss_dungeonrespawn_characters.sql` | Dungeon respawn position tracking |
| `data/sql/characters/gss_village_reward_tracker.sql` | 3-hour village reward timestamps per character |
| `data/sql/characters/base/01_grant_world_flight.sql` | Grants old-world flying to eligible characters |

### acore_world

| File | Description |
|---|---|
| `data/sql/world/paragon_world.sql` | Runic Archive, Kadala, Butcher NPCs; board/node definitions |
| `data/sql/world/loot_world.sql` | Loot tier tables, legendary item entries |
| `data/sql/world/endgame_sets.sql` | Legendary class set definitions |
| `data/sql/world/coffington_world.sql` | Ser Coffington NPC (profession and riding trainer) |
| `data/sql/world/random_enchants_world.sql` | Random enchantment pool |
| `data/sql/world/reagent_removal.sql` | Removes reagent requirements for relevant spells |
| `data/sql/world/cache_item_patch.sql` | Cache of Synival's Treasures item entry |
| `data/sql/world/legendary_display_id_patch.sql` | Corrects display IDs for legendary items |
| `data/sql/world/missing_spec_boards.sql` | Populates spec board node data (boards 12–17) |
| `data/sql/world/patch_item_random_suffix.sql` | item_random_suffix_dbc entries for tier suffixes |
| `data/sql/world/scriptname_patch.sql` | Corrects creature_template scriptnames |
| `data/sql/world/synparagon_config.sql` | Synival paragon config table seed |
| `data/sql/world/gss_world.sql` | Warden of the Vault NPC template and spawn |
| `data/sql/world/base/01_world_flight_spell.sql` | Old-world flying spell entry in spell_dbc |

### customs database (run in order 001–027)

`data/sql/customs/base/` — Full guild village schema. Run these in ascending
numerical order. All 27 files must be present before starting the server.

### Extras SQL (manual — run when deploying those features)

| File | Database | Description |
|---|---|---|
| `extras/faction-free/sql/EntryChecker_RUN_FIRST.sql` | acore_world | Check for GUID/entry conflicts before applying Faction Free |
| `extras/faction-free/sql/FactionFree.sql` | acore_world | Full faction-free world patch |
| `extras/titles/coffingquest_custom_titles.sql` | acore_world | 25 custom title inserts |

---

## Extras Deployment

### SynParagon Client Addon (`extras/SynParagon_ClientAddon/`)

A WoW 3.3.5a client addon that injects colored tier label lines into item
tooltips using `HookScript("OnTooltipSetItem")`. Copy the `SynParagon/`
folder into your WoW client's `Interface/AddOns/` directory and enable it
at the character select screen.

### DBC Patcher (`extras/SynParagon_DBC_Patch/`)

`patch_item_random_suffix.py` — A Python script that patches
`item_random_suffix.dbc` with the tier suffix names. Reads the field count
from the DBC header dynamically (the server's file has 29 fields, not the
commonly assumed 21). Run against your server's DBC copy before restarting.

Tier suffix names: **SynHeroic**, **Mythical**, **Ascended**,
**Synival's Chosen**

### Synparagon Board Lua (`extras/synparagon_board.lua`)

The Eluna gossip handler for NPC 99996 (Runic Archive). Drop into your
`lua_scripts/` directory. The C++ `npc_runic_archive` CreatureScript gossip
handler has been removed — this Lua file is the sole gossip renderer for
that NPC. C++ retains all stat application logic.

A copy is also at the module root as `paragon_board.lua` — both are identical.
Use whichever your file management religion demands.

### Faction Free (`extras/faction-free/`)

Removes the player-to-NPC faction barrier entirely. Requires five separate
deployment steps:

**Step 1 — SQL against acore_world**
Run `EntryChecker_RUN_FIRST.sql` to verify no GUID or entry conflicts exist.
Then run `FactionFree.sql`. This patches quest availability, tavern faction,
player languages, NPC text language IDs, item faction restrictions, and
hundreds of creature faction assignments.

**Step 2 — Server DBC replacement**
Replace in your worldserver data directory:
- `Achievement.dbc`
- `Faction.dbc`
- `FactionTemplate.dbc`

Back up the originals. These are full replacements, not additive patches. If
you have custom factions or achievements already in these files, you will need
to merge the changes manually.

**Step 3 — Core source patch (requires recompile)**
`extras/faction-free/PlayerUpdates.cpp` →
`<AzerothCore>/src/server/game/Entities/Player/PlayerUpdates.cpp`

This removes the automatic PVP flag applied when a player enters an opposing
faction's city zone. Back up the original and recompile.

**Step 4 — Eluna Lua scripts → `lua_scripts/`**
- `FactionFreeTeleports_Goblin.lua` (NPC entry 500000)
- `FactionFreeTeleports_Gnome.lua` (NPC entry 500001)

These drive the gossip menus for the cross-faction teleport network covering
all capital cities, dungeon entrances, and raid entrances across all
continents.

**Step 5 — Client MPQ**
`extras/faction-free/client/Patch-F.mpq` → `<WoW Client>/Data/`

Rename to the next unused letter if `Patch-F` is already in use. Contains
the client-side DBC changes mirroring the server-side replacements.

### Custom Titles (`extras/titles/`)

25 custom CoffingQuest titles. Granted manually with `.title add <bit_index>`.
Not awarded automatically by any system in this module.

**Step 1 — Client DBC**
Add `CharTitles.dbc` to your custom client patch MPQ.

**Step 2 — SQL against acore_world**
```sql
SOURCE extras/titles/coffingquest_custom_titles.sql;
```

| Bit | Title |
|---|---|
| 9139 | %s, Founder of CoffingQuest |
| 9140 | %s, Contributor to CoffingQuest |
| 9141 | %s, Dreamer of the Void |
| 9142 | Herald of the Black Empire %s |
| 9143 | %s the Unknowable |
| 9144 | %s, Keeper of Forbidden Lore |
| 9145 | Twilight's Hammer %s |
| 9146 | %s, Scion of the Titan-Forged |
| 9147 | Lord/Lady of the Burning Legion %s |
| 9148 | %s, Breaker of the Legion's Chain |
| 9149 | Kirin Tor Archmage %s |
| 9150 | %s, Veteran of the War of Ancients |
| 9151 | Champion of Karazhan %s |
| 9152 | %s, Keeper of the Dark Portal |
| 9153 | Warchief %s |
| 9154 | %s, Chosen of the Aspects |
| 9155 | Arch-Druid %s |
| 9156 | %s, Guardian of Tirisfal |
| 9157 | %s, Bane of the Black Empire |
| 9158 | %s the Forsaken |
| 9159 | %s the Deathless |
| 9160 | %s, Liberator of Outland |
| 9161 | Fel-Sworn %s |
| 9162 | %s, the Nightmare's End |
| 9163 | %s of the Highmountain |

---

## Configuration

All configuration lives in `conf/mod_synival_ode_to_ramza.conf.dist`. Copy
it to your worldserver config directory and remove the `.dist` suffix.

The file has five sections:

| Section | Prefix | Covers |
|---|---|---|
| 1 — Guild Village | `GuildVillage.*` | Village cost, spawn location, production, expeditions, currency caps |
| 2 — Dungeon Master | `DungeonMaster.*` | Difficulty tiers, creature themes, scaling, rewards, roguelike |
| 3 — Guild Sanctuary Bridge | `GuildSanctuary.*` | Warden entry, clear rewards, guild records page |
| 4 — Guild Village Periodic Reward | `GuildVillage.Reward.*` | Interval, gold range, board points, full level chance |
| 5 — Dungeon Respawn | `DungeonRespawn.*` | Enable/disable, respawn health percentage |
| 6 — Paragon & Loot | `Paragon.*` `Loot.*` `RandomEnchants.*` etc. | All paragon and loot subsystem settings |

---

## Entry and GUID Ranges

| System | Table | Range |
|---|---|---|
| Paragon NPCs (Runic Archive, Kadala, Butcher) | creature_template | 99996–99998 |
| Paragon items (Mark, Cache, Legendary base) | item_template | 99200–99300+ |
| Faction Free NPCs | creature_template | 500000–500001 |
| Faction Free objects | gameobject_template | 500000–500004 |
| Faction Free text | broadcast_text / npc_text | 500000–500003 |
| Faction Free creature spawns | creature (GUID) | 5000000–5000019 |
| Faction Free object spawns | gameobject (GUID) | 5000000–5000049 |
| Warden of the Vault | creature_template | 501000 |
| Guild Sanctuary reserved NPCs | creature_template | 501001–501099 |
| Gossip action IDs (Guild Sanctuary) | runtime | 20001–21201 |
| Custom titles | char_titles_dbc ID | 178–202 |
| Custom title bit indices | char_titles_dbc | 9139–9163 |

---

## Credits

### Module Authors & Origins

| System | Author / Origin |
|---|---|
| mod-guild-village | BeardBear33 |
| mod-dungeon-master | InstanceForge |
| Guild Sanctuary Bridge | Synival / CoffingQuest |
| DungeonRespawn | AnchyDev — https://github.com/AnchyDev/DungeonRespawn |
| Faction Free | gitdalisar — https://github.com/gitdalisar/mod-Faction-Free |
| lua-paragon-anniversary (OtR Lua architecture reference) | iThorgrim |
| Random Enchants | Origin: AzerothCore/mod-random-enchants — https://github.com/azerothcore/mod-random-enchants |
| Buff Command | Origin: AzerothCore/mod-buff-command — https://github.com/azerothcore/mod-buff-command |
| Skip DK Starting Area | Origin: AzerothCore/mod-skip-dk-starting-area — https://github.com/azerothcore/mod-skip-dk-starting-area |
| Open World Balance | Inspired by AnchyDev — https://github.com/AnchyDev/DungeonRespawn |

### Design Inspiration

| System | Inspiration |
|---|---|
| Paragon Progression & Board | Inspired by the Paragon Board system in **Diablo 4** (Blizzard Entertainment) |
| Loot & Item Tiers | Conceptualized by **Dark (Gaedrin)** and **Griggith** |

### Special Thanks

**RamzaBeouvle** — For keeping CoffingQuest operational when it mattered,
for teaching the skills needed to properly navigate AzerothCore's source code,
and for providing the inspiration to learn more and grow CoffingQuest into
what it is today. This module exists in part because of that foundation.

---

## License

AGPL v3. See upstream module licenses for their respective terms.
