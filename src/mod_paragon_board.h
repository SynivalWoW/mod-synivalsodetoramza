#pragma once
/*
 * mod_paragon_board.h
 *
 * Shared type definitions and public API for the Paragon Board engine.
 * Included by both mod_paragon_board.cpp (implementation) and
 * mod_synival_paragon.cpp (gossip, commands, hooks).
 *
 * Architecture summary
 * ─────────────────────
 *  g_Boards          — static board/node definitions loaded from world DB at startup
 *  g_Glyphs          — static glyph definitions loaded from world DB at startup
 *  g_ParagonMap      — per-player ParagonData (paragon level, XP, prestige, board points)
 *  g_PlayerBoardStates — per-player unlocked nodes and socketed glyphs (loaded on login)
 *  g_ParagonMutex    — single mutex protecting both maps; board state always modified
 *                      while holding this lock
 *
 * Stat application model
 * ───────────────────────
 *  NODE_NORMAL / NODE_MAGIC  → flat bonus via HandleStatModifier(TOTAL_VALUE)
 *  NODE_RARE                 → percent bonus via HandleStatPercentModifier(TOTAL_PCT)
 *                              amplified by any glyph whose socket is within Chebyshev
 *                              distance <= glyph.radius
 *  NODE_SOCKET               → no direct stat; hosts a GlyphDef
 *  NODE_START                → no stat; free to own, always counted as unlocked for
 *                              adjacency purposes
 */

#include "Player.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <string>
#include <mutex>

// ─────────────────────────────────────────────────────────────────────────────
// Enumerations
// ─────────────────────────────────────────────────────────────────────────────

enum NodeType : uint8
{
    NODE_NORMAL = 0,
    NODE_MAGIC  = 1,
    NODE_RARE   = 2,
    NODE_SOCKET = 3,
    NODE_START  = 4,
};

// Board-point cost to unlock each node type (START is always free)
static constexpr uint32 NODE_COSTS[5] = { 1, 2, 3, 4, 0 };

enum ParagonStatType : uint8
{
    PSTAT_NONE         = 0,
    PSTAT_STRENGTH     = 1,
    PSTAT_AGILITY      = 2,
    PSTAT_STAMINA      = 3,
    PSTAT_INTELLECT    = 4,
    PSTAT_SPIRIT       = 5,
    PSTAT_ARMOR        = 6,
    PSTAT_CRIT_PCT     = 7,   // converts to rating in application
    PSTAT_HASTE_PCT    = 8,   // converts to rating in application
    PSTAT_SPELL_POWER  = 9,   // applied as intellect for safety
    PSTAT_ATTACK_POWER = 10,
};

enum BoardType : uint8
{
    BOARD_UNIVERSAL = 0,
    BOARD_CLASS     = 1,
    BOARD_SPEC      = 2,
};

// Page-type identifiers used in board gossip action encoding.
// action = (pageType << 24) | (nodeId_12bit << 12) | (secondary_12bit)
// sender = boardId  (0 for non-board-specific pages like BOARD_LIST)
enum BoardGossipPage : uint8
{
    BGA_BOARD_LIST       = 1,
    BGA_BOARD_OVERVIEW   = 2,
    BGA_NODE_LIST        = 3,   // secondary = page offset (0, 10, 20...)
    BGA_NODE_DETAIL      = 4,   // nodeId = target node
    BGA_NODE_UNLOCK      = 5,   // nodeId = target node (confirm + execute)
    BGA_GLYPH_LIST       = 6,
    BGA_GLYPH_DETAIL     = 7,   // nodeId = socket node
    BGA_GLYPH_SOCKET     = 8,   // nodeId = socket node, secondary = glyph_id
    BGA_GLYPH_REMOVE     = 9,   // nodeId = socket node
    BGA_BACK_TO_ARCHIVE  = 10,  // return to Runic Archive main menu
};

// ─────────────────────────────────────────────────────────────────────────────
// Action encoding helpers
// ─────────────────────────────────────────────────────────────────────────────

inline uint32 EncBoardAction(uint8 page, uint16 nodeId = 0, uint16 secondary = 0)
{
    return (uint32(page) << 24) | (uint32(nodeId & 0xFFFu) << 12) | uint32(secondary & 0xFFFu);
}

inline void DecBoardAction(uint32 action, uint8& page, uint16& nodeId, uint16& secondary)
{
    page      = uint8(action >> 24);
    nodeId    = uint16((action >> 12) & 0xFFFu);
    secondary = uint16(action & 0xFFFu);
}

inline bool IsBoardAction(uint32 action)
{
    return (action >> 24) >= uint32(BGA_BOARD_LIST);
}

// ─────────────────────────────────────────────────────────────────────────────
// Static data structures (loaded from world DB at startup)
// ─────────────────────────────────────────────────────────────────────────────

struct ParagonNodeDef
{
    uint16          nodeId      = 0;
    uint8           boardId     = 0;
    uint8           x           = 0;
    uint8           y           = 0;
    NodeType        type        = NODE_NORMAL;
    ParagonStatType statType    = PSTAT_NONE;
    float           statValue   = 0.0f;
    std::string     name;
    std::string     description;
};

struct ParagonBoardDef
{
    uint8       boardId            = 0;
    std::string name;
    BoardType   boardType          = BOARD_UNIVERSAL;
    uint8       requiredClass      = 0;   // 0 = any class
    uint8       requiredBoard      = 0;   // 0 = none; else boardId whose state must be non-empty
    uint32      unlockParagonLevel = 0;
    uint32      unlockPrestige     = 0;
    uint8       width              = 7;
    uint8       height             = 7;
    std::vector<ParagonNodeDef> nodes;

    ParagonNodeDef const* GetNode(uint16 nodeId) const
    {
        for (auto const& n : nodes)
            if (n.nodeId == nodeId) return &n;
        return nullptr;
    }
};

struct GlyphDef
{
    uint16          glyphId         = 0;
    std::string     name;
    uint8           radius          = 2;
    float           rareBonusPct    = 50.0f;   // % amplification to Rare nodes in radius
    ParagonStatType bonusStatType   = PSTAT_NONE;
    float           bonusStatValue  = 0.0f;    // conditional bonus stat value
    ParagonStatType reqStatType     = PSTAT_NONE;
    float           reqStatValue    = 0.0f;    // flat stat total needed in radius to trigger bonus
    uint32          itemEntry       = 0;
};

// ─────────────────────────────────────────────────────────────────────────────
// Per-player runtime state
// ─────────────────────────────────────────────────────────────────────────────

struct PlayerBoardState
{
    std::unordered_set<uint16>          unlockedNodes;  // set of node_ids
    std::unordered_map<uint16, uint16>  socketedGlyphs; // socket node_id → glyph_id
};

struct ParagonData
{
    // ── Core progression fields (persisted) ───────────────────────────────
    uint32 paragonLevel         = 0;
    uint32 paragonXP            = 0;
    uint32 prestigeCount        = 0;
    uint32 lastCacheDay         = 0;
    bool   markUsed             = false;

    // ── Stat tracking (runtime only, not persisted) ────────────────────────
    uint32 appliedStatLevel     = 0;
    bool   appliedMark          = false;

    // ── Board system (persisted) ───────────────────────────────────────────
    uint32 boardPoints          = 0;

    // ── Paragon Shard currency (persisted) ────────────────────────────────
    // paragonShards       = current shard balance
    // lastShardPurchaseDay = Unix day of last Kadala bundle purchase;
    //                        enforces per-player 24hr restock window in C++
    uint32 paragonShards        = 0;
    uint32 lastShardPurchaseDay = 0;
};

// ─────────────────────────────────────────────────────────────────────────────
// Global registries — defined in mod_paragon_board.cpp
// ─────────────────────────────────────────────────────────────────────────────

extern std::vector<ParagonBoardDef>                                         g_Boards;
extern std::unordered_map<uint16, GlyphDef>                                 g_Glyphs;
extern std::unordered_map<ObjectGuid, ParagonData>                          g_ParagonMap;
extern std::unordered_map<ObjectGuid, std::unordered_map<uint8, PlayerBoardState>> g_PlayerBoardStates;
extern std::mutex                                                            g_ParagonMutex;

// ─────────────────────────────────────────────────────────────────────────────
// Public API — implemented in mod_paragon_board.cpp
// ─────────────────────────────────────────────────────────────────────────────

// Startup — called from WorldScript::OnBeforeConfigLoad
void LoadAllBoardDefs();

// Visibility gate — checks class, paragon level, required board chain
bool IsBoardVisibleForPlayer(Player const* player,
                             ParagonBoardDef const& board,
                             uint32 paragonLevel,
                             uint32 prestigeCount);

// Adjacency — returns true if any orthogonal neighbour of nodeId is unlocked
// (or if nodeId is NODE_START, which is always considered adjacent)
bool IsNodeAdjacent(ParagonBoardDef const& board,
                    PlayerBoardState const& state,
                    uint16 nodeId);

// Returns true when the node can be purchased (adjacent, affordable, not owned)
bool CanUnlockNode(Player const* player, uint8 boardId, uint16 nodeId);

// Mutations — each acquires g_ParagonMutex internally and persists to DB
bool UnlockNode (Player* player, uint8 boardId, uint16 nodeId);
bool SocketGlyph(Player* player, uint8 boardId, uint16 nodeId, uint16 glyphId);
bool RemoveGlyph(Player* player, uint8 boardId, uint16 nodeId);

// Stat application — call with apply=false then apply=true to refresh
// Handles flat (Normal/Magic), percent (Rare), and glyph radius amplification
void ApplyAllBoardStats(Player* player, bool apply);

// Persistence
void SaveBoardPointsOnly(ObjectGuid guid, uint32 boardPoints);
void LoadBoardState(Player* player);   // reads character_paragon_nodes/glyphs
void ClearBoardState(Player* player);  // called on logout — removes runtime state only

// Gossip rendering helpers
std::string BuildBoardGridRow(ParagonBoardDef const& board,
                               PlayerBoardState const& state,
                               uint8 row);

std::string FormatNodeEntry(ParagonNodeDef const& node,
                             bool unlocked,
                             bool available,
                             bool affordable);

std::string StatTypeName(ParagonStatType t);
std::string StatValueString(ParagonStatType t, float v);

// Board-point award helpers (called from PlayerScript hooks)
void AwardBoardPointOnLevelUp(Player* player);
void RollBoardPointOnKill(Player* player);   // 5% chance per kill

// ─────────────────────────────────────────────────────────────────────────────
// Inline lookup helpers used in both translation units
// ─────────────────────────────────────────────────────────────────────────────

inline ParagonBoardDef const* FindBoard(uint8 boardId)
{
    for (auto const& b : g_Boards)
        if (b.boardId == boardId) return &b;
    return nullptr;
}

inline GlyphDef const* FindGlyph(uint16 glyphId)
{
    auto it = g_Glyphs.find(glyphId);
    return (it != g_Glyphs.end()) ? &it->second : nullptr;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cross-module helpers
// Called by mod_synival_loot.cpp to read paragon progression without
// exposing g_ParagonMap directly.  Lock is held internally.
// ─────────────────────────────────────────────────────────────────────────────

inline uint32 GetPlayerParagonLevel(ObjectGuid guid)
{
    std::lock_guard<std::mutex> lock(g_ParagonMutex);
    auto it = g_ParagonMap.find(guid);
    return (it != g_ParagonMap.end()) ? it->second.paragonLevel : 0u;
}

inline uint32 GetPlayerParagonShards(ObjectGuid guid)
{
    std::lock_guard<std::mutex> lock(g_ParagonMutex);
    auto it = g_ParagonMap.find(guid);
    return (it != g_ParagonMap.end()) ? it->second.paragonShards : 0u;
}

// Modifies the shard balance and flushes to DB.
// delta may be negative (spending) — clamped to 0.
// Returns the new balance.
uint32 ModifyPlayerParagonShards(ObjectGuid guid, int32 delta);

// Persist shard fields only (cheaper than a full SavePlayerData call)
void SaveShardsOnly(ObjectGuid guid, uint32 shards, uint32 lastPurchaseDay);

// ─────────────────────────────────────────────────────────────────────────────
// Village Periodic Reward bridge
// Defined in mod_synival_paragon.cpp (same TU as static helpers).
// Called by guild_village_periodic_reward.cpp.
//
// OtR_GrantParagonProgress — awards either a full Paragon Level or a given
// number of Board Points to the player, depending on the roll.
//   fullLevel   true  → inject XPPerParagonLevel XP, fire level-up handling
//               false → add boardPoints to the player's pool
// ─────────────────────────────────────────────────────────────────────────────
void OtR_GrantParagonProgress(Player* player, bool fullLevel, uint32 boardPoints);
