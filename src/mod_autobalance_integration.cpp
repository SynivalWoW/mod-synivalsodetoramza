/*
 * mod_autobalance_integration.cpp
 *
 * Open World Balance (OWB) — Part 2 only.
 *
 * ════════════════════════════════════════════════════════════════════════════
 * INSTANCE AUTOBALANCE
 * ════════════════════════════════════════════════════════════════════════════
 *
 * Dungeon and raid instance scaling is handled entirely by the standalone
 * mod-autobalance module. This file no longer registers any AutoBalance_*
 * scripts to avoid duplicate registration (which caused the startup assertion
 * "Duplicate blank sub-command" from AutoBalance_CommandScript).
 *
 * Keep mod-autobalance installed as a separate module for dungeon scaling.
 *
 * ════════════════════════════════════════════════════════════════════════════
 * PART 2 — OPEN WORLD BALANCE (SynivalOWB_* scripts)
 * ════════════════════════════════════════════════════════════════════════════
 *
 * AutoBalance only scales dungeon/raid instances (IsDungeon() == true).
 * This integration adds player-count-driven HP/damage/mana scaling for
 * open-world creatures on four continent maps:
 *
 *   Map 0   Eastern Kingdoms
 *   Map 1   Kalimdor
 *   Map 530 Outland
 *   Map 571 Northrend
 *
 * Design
 * ──────
 * Open world maps have no per-instance player list; scaling is based on
 * the count of players within OWB.ScaleRadius yards of the creature.
 * The same sigmoid formula used by AutoBalance is applied:
 *
 *   sigmoid(x) = 1 / (1 + exp(-10 * (x/refGroup - inflectionPoint)))
 *   multiplier = floor + (ceiling - floor) * sigmoid(nearbyPlayers)
 *
 * Baseline stats (max HP, mana pool) are captured in OWBCreatureData on
 * first spawn. All subsequent scaling is applied relative to these baselines
 * so repeated calls are idempotent. Damage multipliers are applied via
 * UnitScript hooks (same mechanism as AutoBalance instance damage scaling)
 * rather than directly modifying UNIT_FIELD_MINDAMAGE, which would require
 * calling SelectLevel() and resetting HP.
 *
 * Exclusions
 * ──────────
 *   World bosses (rank CREATURE_ELITE_WORLDBOSS)  — scaling incoherent
 *   Pets, summons, vehicles, totems, civilians    — not combat mobs
 *   Friendly faction NPCs                         — guards, vendors, etc.
 *   Dead creatures                                — stats irrelevant until respawn
 *
 * Performance
 * ───────────
 * OWB_CountNearbyPlayers() iterates Map::GetPlayers() which is O(map_players).
 * The result is cached in OWBCreatureData::lastNearbyPlayers; the sigmoid is
 * only recomputed when the nearby player count changes, reducing per-tick
 * math to a single uint32 comparison in the common case.
 *
 * Configuration keys (OWB.* prefix, loaded in OWBConfig::Load())
 * ──────────────────────────────────────────────────────────────
 *   OWB.Enable                 = 1
 *   OWB.EnableEasternKingdoms  = 1   (map 0)
 *   OWB.EnableKalimdor         = 1   (map 1)
 *   OWB.EnableOutland          = 1   (map 530)
 *   OWB.EnableNorthrend        = 1   (map 571)
 *   OWB.ScaleRadius            = 150.0
 *   OWB.ReferenceGroupSize     = 5
 *   OWB.InflectionPoint        = 0.5
 *   OWB.CurveFloor             = 0.40
 *   OWB.CurveCeiling           = 1.0
 *   OWB.MinHPModifier          = 0.15
 *   OWB.MinDamageModifier      = 0.10
 *   OWB.StatModifier_Health    = 1.0
 *   OWB.StatModifier_Damage    = 1.0
 *   OWB.StatModifier_Mana      = 1.0
 *   OWB.Announcement           = 1
 *
 * AzerothCore Doxygen references:
 *   AllCreatureScript::OnCreatureAddWorld / OnAllCreatureUpdate
 *   UnitScript::ModifyMeleeDamage / ModifySpellDamageTaken
 *   UnitScript::ModifyPeriodicDamageAurasTick
 *   AllMapScript::OnPlayerEnterAll (ALLMAPHOOK_ON_PLAYER_ENTER_ALL)
 *   WorldScript::OnBeforeConfigLoad
 *   Creature::CustomData::GetDefault<T>
 *   Creature::SetMaxHealth / SetHealth / GetMaxHealth / GetHealth
 *   Creature::SetMaxPower / GetMaxPower (POWER_MANA)
 *   Creature::IsPet / IsSummon / IsVehicle / isTotem / IsCivilian / IsAlive
 *   CreatureTemplate::rank (CREATURE_ELITE_WORLDBOSS)
 *   Map::GetPlayers — MapRefManager containing all players on the map
 *   Map::GetId      — numeric map ID (0, 1, 530, 571)
 *   sConfigMgr->GetOption<T>
 */

#include "ScriptMgr.h"
#include "Config.h"
#include "Chat.h"
#include "Creature.h"
#include "DataMap.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "SharedDefines.h"
#include "SpellInfo.h"
#include "Unit.h"
#include "World.h"

// ── AutoBalance module headers removed ───────────────────────────────────────
// Part 1 (instance autobalance) is now handled entirely by the standalone
// mod-autobalance module. We only keep Part 2 (Open World Balance) which
// has no dependency on AutoBalance internals.
// Removing these headers eliminates the AutoBalance_CommandScript duplicate
// registration that caused the startup assertion failure.

#include <cmath>
#include <climits>

// ─────────────────────────────────────────────────────────────────────────────
// PART 2 — Open World Balance
// ─────────────────────────────────────────────────────────────────────────────

// ── Config struct ─────────────────────────────────────────────────────────

struct OWBConfig
{
    bool   Enable                 = true;
    bool   EnableEasternKingdoms  = true;
    bool   EnableKalimdor         = true;
    bool   EnableOutland          = true;
    bool   EnableNorthrend        = true;

    float  ScaleRadius            = 150.0f;
    uint32 ReferenceGroupSize     = 5;

    float  InflectionPoint        = 0.5f;
    float  CurveFloor             = 0.40f;
    float  CurveCeiling           = 1.0f;

    float  MinHPModifier          = 0.15f;
    float  MinDamageModifier      = 0.10f;

    float  StatModifier_Health    = 1.0f;
    float  StatModifier_Damage    = 1.0f;
    float  StatModifier_Mana      = 1.0f;

    bool   Announcement           = true;

    void Load()
    {
        Enable                = sConfigMgr->GetOption<bool>  ("OWB.Enable",                   true);
        EnableEasternKingdoms = sConfigMgr->GetOption<bool>  ("OWB.EnableEasternKingdoms",     true);
        EnableKalimdor        = sConfigMgr->GetOption<bool>  ("OWB.EnableKalimdor",            true);
        EnableOutland         = sConfigMgr->GetOption<bool>  ("OWB.EnableOutland",             true);
        EnableNorthrend       = sConfigMgr->GetOption<bool>  ("OWB.EnableNorthrend",           true);

        ScaleRadius           = sConfigMgr->GetOption<float> ("OWB.ScaleRadius",               150.0f);
        ReferenceGroupSize    = sConfigMgr->GetOption<uint32>("OWB.ReferenceGroupSize",         5);
        if (ReferenceGroupSize == 0) ReferenceGroupSize = 5;

        InflectionPoint       = sConfigMgr->GetOption<float> ("OWB.InflectionPoint",           0.5f);
        CurveFloor            = sConfigMgr->GetOption<float> ("OWB.CurveFloor",                0.40f);
        CurveCeiling          = sConfigMgr->GetOption<float> ("OWB.CurveCeiling",              1.0f);

        MinHPModifier         = sConfigMgr->GetOption<float> ("OWB.MinHPModifier",             0.15f);
        MinDamageModifier     = sConfigMgr->GetOption<float> ("OWB.MinDamageModifier",         0.10f);

        StatModifier_Health   = sConfigMgr->GetOption<float> ("OWB.StatModifier_Health",       1.0f);
        StatModifier_Damage   = sConfigMgr->GetOption<float> ("OWB.StatModifier_Damage",       1.0f);
        StatModifier_Mana     = sConfigMgr->GetOption<float> ("OWB.StatModifier_Mana",         1.0f);

        Announcement          = sConfigMgr->GetOption<bool>  ("OWB.Announcement",              true);

        LOG_INFO("module.AutoBalance",
            "mod-synival OWB: {} | Radius={:.0f}y Ref={} IP={:.2f} [{:.2f}-{:.2f}]",
            Enable ? "ENABLED" : "DISABLED",
            ScaleRadius, ReferenceGroupSize,
            InflectionPoint, CurveFloor, CurveCeiling);
    }
};

static OWBConfig g_OWBCfg;

// ── Per-creature scaling data ─────────────────────────────────────────────

class OWBCreatureData : public DataMap::Base
{
public:
    OWBCreatureData() {}

    bool    initialized        = false;
    uint32  baseMaxHealth      = 0;
    int32   baseMaxMana        = 0;
    float   currentMultiplier  = 1.0f;
    uint32  lastNearbyPlayers  = UINT32_MAX; // sentinel — forces first-pass
};

// ── Static helpers ────────────────────────────────────────────────────────

static bool OWB_MapEnabled(uint32 mapId)
{
    if (!g_OWBCfg.Enable) return false;
    switch (mapId)
    {
        case 0:   return g_OWBCfg.EnableEasternKingdoms;
        case 1:   return g_OWBCfg.EnableKalimdor;
        case 530: return g_OWBCfg.EnableOutland;
        case 571: return g_OWBCfg.EnableNorthrend;
        default:  return false;
    }
}

static bool OWB_SkipCreature(Creature* c)
{
    if (!c || !c->IsAlive())                            return true;
    if (c->IsPet())                                     return true;
    if (c->IsSummon())                                  return true;
    if (c->IsVehicle())                                 return true;
    if (c->IsTotem())                                   return true;
    if (c->IsCivilian())                                return true;
    if (c->GetCreatureTemplate()->rank
        == CREATURE_ELITE_WORLDBOSS)                    return true;
    // IsCreatedByPlayer covers non-combat pets and tameables without relying on
    // type_flags constants whose names vary across AzerothCore builds.
    // IsPet() + IsSummon() above already handle the common cases; this catches
    // the remainder (e.g. player-owned critters, non-combat companions).
    if (c->IsCreatedByPlayer())                         return true;
    return false;
}

/**
 * @brief Sigmoid multiplier matching AutoBalance's inflection-point formula.
 *
 * multiplier = floor + (ceiling - floor) / (1 + exp(-10*(x - IP)))
 * where x = nearbyPlayers / referenceGroupSize
 */
static float OWB_Multiplier(uint32 nearbyPlayers)
{
    if (nearbyPlayers == 0) return g_OWBCfg.CurveFloor;

    float x   = static_cast<float>(nearbyPlayers)
                / static_cast<float>(g_OWBCfg.ReferenceGroupSize);
    float sig = 1.0f / (1.0f + std::exp(-10.0f * (x - g_OWBCfg.InflectionPoint)));
    float m   = g_OWBCfg.CurveFloor + (g_OWBCfg.CurveCeiling - g_OWBCfg.CurveFloor) * sig;

    if (m < g_OWBCfg.CurveFloor)   m = g_OWBCfg.CurveFloor;
    if (m > g_OWBCfg.CurveCeiling) m = g_OWBCfg.CurveCeiling;
    return m;
}

static uint32 OWB_NearbyPlayers(Creature* creature)
{
    Map* map = creature->GetMap();
    if (!map) return 0;

    uint32 count = 0;
    float  radius = g_OWBCfg.ScaleRadius;

    Map::PlayerList const& plist = map->GetPlayers();
    for (auto itr = plist.begin(); itr != plist.end(); ++itr)
    {
        Player* p = itr->GetSource();
        if (!p || p->IsGameMaster() || !p->IsAlive() || p->IsBeingTeleported())
            continue;
        if (creature->GetDistance(p) <= radius)
            ++count;
    }
    return count;
}

/**
 * @brief Apply the open-world HP/mana multiplier.
 *
 * HP is scaled by hpMult; the current HP/MaxHP ratio is preserved
 * so a creature at 80% health stays at 80% after rescaling.
 * Damage multipliers are stored in OWBCreatureData::currentMultiplier
 * and applied via the UnitScript intercept hooks below.
 */
static void OWB_Apply(Creature* creature, OWBCreatureData* d, float mult)
{
    float hpMult   = std::max(mult * g_OWBCfg.StatModifier_Health, g_OWBCfg.MinHPModifier);
    float manaMult = std::max(mult * g_OWBCfg.StatModifier_Mana,   0.01f);

    // ── HP ────────────────────────────────────────────────────────────────
    uint32 newMaxHP = static_cast<uint32>(static_cast<float>(d->baseMaxHealth) * hpMult);
    if (newMaxHP < 1) newMaxHP = 1;

    uint32 oldMax = creature->GetMaxHealth();
    uint32 oldHP  = creature->GetHealth();

    creature->SetMaxHealth(newMaxHP);

    // Preserve HP fraction
    if (oldMax > 0)
    {
        uint32 newHP = static_cast<uint32>(
            (static_cast<float>(oldHP) / static_cast<float>(oldMax)) * static_cast<float>(newMaxHP));
        creature->SetHealth(newHP < 1 ? 1 : newHP);
    }
    else
    {
        creature->SetFullHealth();
    }

    // ── Mana ──────────────────────────────────────────────────────────────
    if (d->baseMaxMana > 0)
    {
        int32 newMana = static_cast<int32>(static_cast<float>(d->baseMaxMana) * manaMult);
        creature->SetMaxPower(POWER_MANA, newMana > 0 ? newMana : 1);
    }

    // Store for damage intercept hooks
    d->currentMultiplier = mult;
}

// ── WorldScript ───────────────────────────────────────────────────────────

class SynivalOWBWorldScript : public WorldScript
{
public:
    SynivalOWBWorldScript() : WorldScript("SynivalOWBWorldScript") {}

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        g_OWBCfg.Load();
    }
};

// ── AllCreatureScript ─────────────────────────────────────────────────────

class SynivalOWBAllCreatureScript : public AllCreatureScript
{
public:
    SynivalOWBAllCreatureScript()
        : AllCreatureScript("SynivalOWBAllCreatureScript") {}

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!g_OWBCfg.Enable) return;
        if (!creature || !creature->GetMap()) return;
        if (!OWB_MapEnabled(creature->GetMap()->GetId())) return;
        if (OWB_SkipCreature(creature)) return;

        OWBCreatureData* d =
            creature->CustomData.GetDefault<OWBCreatureData>("OWBCreatureData");

        if (!d->initialized)
        {
            d->baseMaxHealth      = creature->GetMaxHealth();
            d->baseMaxMana        = creature->GetMaxPower(POWER_MANA);
            d->currentMultiplier  = 1.0f;
            d->lastNearbyPlayers  = UINT32_MAX;
            d->initialized        = true;
        }
    }

    /**
     * @brief Per-tick update — rescale only when nearby player count changes.
     *
     * The early-exit on count == lastNearbyPlayers means the sigmoid is
     * computed at most once per player enter/leave event, not every tick.
     */
    void OnAllCreatureUpdate(Creature* creature, uint32 /*diff*/) override
    {
        if (!g_OWBCfg.Enable) return;
        if (!creature || !creature->GetMap()) return;
        if (!OWB_MapEnabled(creature->GetMap()->GetId())) return;
        if (OWB_SkipCreature(creature)) return;

        OWBCreatureData* d =
            creature->CustomData.GetDefault<OWBCreatureData>("OWBCreatureData");

        // Lazy-init for creatures that were in the world before the module loaded
        if (!d->initialized)
        {
            d->baseMaxHealth      = creature->GetMaxHealth();
            d->baseMaxMana        = creature->GetMaxPower(POWER_MANA);
            d->currentMultiplier  = 1.0f;
            d->lastNearbyPlayers  = UINT32_MAX;
            d->initialized        = true;
        }

        uint32 nearby = OWB_NearbyPlayers(creature);
        if (nearby == d->lastNearbyPlayers) return; // no change — skip

        d->lastNearbyPlayers = nearby;
        float mult = OWB_Multiplier(nearby);
        OWB_Apply(creature, d, mult);

        LOG_DEBUG("module.AutoBalance",
            "SynivalOWB: {} lvl={} map={} nearby={} mult={:.3f} hp={}/{}",
            creature->GetName(), creature->GetLevel(),
            creature->GetMap()->GetId(),
            nearby, mult,
            creature->GetHealth(), creature->GetMaxHealth());
    }
};

// ── UnitScript — damage intercept ─────────────────────────────────────────

class SynivalOWBUnitScript : public UnitScript
{
public:
    SynivalOWBUnitScript() : UnitScript("SynivalOWBUnitScript") {}

    void ModifyMeleeDamage(Unit* /*target*/, Unit* source, uint32& amount) override
    {
        if (!g_OWBCfg.Enable) return;
        Creature* c = source ? source->ToCreature() : nullptr;
        if (!c || !c->GetMap()) return;
        if (!OWB_MapEnabled(c->GetMap()->GetId())) return;
        if (OWB_SkipCreature(c)) return;

        OWBCreatureData* d = c->CustomData.GetDefault<OWBCreatureData>("OWBCreatureData");
        if (!d->initialized) return;

        float dm = std::max(d->currentMultiplier * g_OWBCfg.StatModifier_Damage,
                            g_OWBCfg.MinDamageModifier);
        amount = static_cast<uint32>(static_cast<float>(amount) * dm);
    }

    void ModifySpellDamageTaken(Unit* /*target*/, Unit* source,
                                 int32& amount, SpellInfo const* /*spellInfo*/) override
    {
        if (!g_OWBCfg.Enable) return;
        if (amount <= 0) return;
        Creature* c = source ? source->ToCreature() : nullptr;
        if (!c || !c->GetMap()) return;
        if (!OWB_MapEnabled(c->GetMap()->GetId())) return;
        if (OWB_SkipCreature(c)) return;

        OWBCreatureData* d = c->CustomData.GetDefault<OWBCreatureData>("OWBCreatureData");
        if (!d->initialized) return;

        float dm = std::max(d->currentMultiplier * g_OWBCfg.StatModifier_Damage,
                            g_OWBCfg.MinDamageModifier);
        amount = static_cast<int32>(static_cast<float>(amount) * dm);
    }

    void ModifyPeriodicDamageAurasTick(Unit* /*target*/, Unit* source,
                                        uint32& amount, SpellInfo const* /*spellInfo*/) override
    {
        if (!g_OWBCfg.Enable) return;
        Creature* c = source ? source->ToCreature() : nullptr;
        if (!c || !c->GetMap()) return;
        if (!OWB_MapEnabled(c->GetMap()->GetId())) return;
        if (OWB_SkipCreature(c)) return;

        OWBCreatureData* d = c->CustomData.GetDefault<OWBCreatureData>("OWBCreatureData");
        if (!d->initialized) return;

        float dm = std::max(d->currentMultiplier * g_OWBCfg.StatModifier_Damage,
                            g_OWBCfg.MinDamageModifier);
        amount = static_cast<uint32>(static_cast<float>(amount) * dm);
    }
};

// ── AllMapScript — area entry announcement ────────────────────────────────
//
// PlayerScript::OnMapChanged does not exist in AzerothCore 3.3.5a.
// The correct hook for player map transitions is AllMapScript::OnPlayerEnterAll,
// which fires after the player is fully placed on the new map.

class SynivalOWBAllMapScript : public AllMapScript
{
public:
    SynivalOWBAllMapScript()
        : AllMapScript("SynivalOWBAllMapScript",
            { ALLMAPHOOK_ON_PLAYER_ENTER_ALL })
    {}

    void OnPlayerEnterAll(Map* map, Player* player) override
    {
        if (!g_OWBCfg.Enable || !g_OWBCfg.Announcement) return;
        if (!map || !player) return;
        if (!OWB_MapEnabled(map->GetId())) return;
        if (player->IsGameMaster()) return;

        // Count nearby players (including this player who just arrived)
        uint32 count = 0;
        Map::PlayerList const& plist = map->GetPlayers();
        for (auto itr = plist.begin(); itr != plist.end(); ++itr)
        {
            Player* p = itr->GetSource();
            if (!p || p->IsGameMaster() || !p->IsAlive() || p->IsBeingTeleported())
                continue;
            if (player->GetDistance(p) <= g_OWBCfg.ScaleRadius)
                ++count;
        }

        float mult = OWB_Multiplier(count);

        // Always announce so players can see both solo (reduced) and group (full) strength.
        // Build the message with StringFormat first — the em-dash UTF-8 bytes confuse
        // printf-style PSendSysMessage, causing literal %u/%.0f in chat.
        std::string msg = Acore::StringFormat(
            "|cff00CCFF[Open World Balance]|r {} nearby player(s) — creatures at |cffFFD700{:.0f}%|r strength.",
            count,
            mult * 100.0f);
        ChatHandler(player->GetSession()).SendSysMessage(msg.c_str());
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Script Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_autobalance()
{
    // Part 1 (AutoBalance instance scaling) is registered by the standalone
    // mod-autobalance module. Registering those scripts here too caused the
    // "Duplicate blank sub-command" assertion from AutoBalance_CommandScript
    // being registered twice. They are intentionally omitted here.

    // Part 2: Open World Balance (EK / Kalimdor / Outland / Northrend)
    // These are our own scripts with no mod-autobalance dependency.
    new SynivalOWBWorldScript();
    new SynivalOWBAllCreatureScript();
    new SynivalOWBUnitScript();
    new SynivalOWBAllMapScript();
}
