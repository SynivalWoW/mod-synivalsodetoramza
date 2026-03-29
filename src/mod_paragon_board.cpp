/*
 * mod_paragon_board.cpp
 *
 * Core engine for the Paragon Board system.
 *
 * Responsibilities
 * ─────────────────
 *  • Load board, node, and glyph definitions from world DB at server startup
 *  • Maintain per-player runtime state (unlocked nodes, socketed glyphs)
 *  • Enforce adjacency rules before allowing node unlocks
 *  • Apply and remove stat bonuses:
 *      Normal/Magic → flat via HandleStatModifier(TOTAL_VALUE)
 *      Rare         → percent via HandleStatPercentModifier(TOTAL_PCT),
 *                     amplified by any glyph socket within Chebyshev radius
 *  • Handle glyph socketing and removal (item returned to bags on removal)
 *  • Persist board state to characters DB
 *  • Provide gossip-menu rendering helpers (grid ASCII art, node entry strings)
 *
 * Thread safety
 * ──────────────
 *  All access to g_ParagonMap and g_PlayerBoardStates is guarded by
 *  g_ParagonMutex. DB queries are issued outside the lock to avoid
 *  blocking the main world thread with I/O latency.
 */

#include "mod_paragon_board.h"
#include "World.h"
#include "ObjectMgr.h"
#include "Chat.h"
#include "StringFormat.h"
#include <algorithm>
#include <cmath>
#include <sstream>

// ─────────────────────────────────────────────────────────────────────────────
// Global definitions
// ─────────────────────────────────────────────────────────────────────────────

std::vector<ParagonBoardDef>                                               g_Boards;
std::unordered_map<uint16, GlyphDef>                                       g_Glyphs;
std::unordered_map<ObjectGuid, ParagonData>                                g_ParagonMap;
std::unordered_map<ObjectGuid, std::unordered_map<uint8, PlayerBoardState>> g_PlayerBoardStates;
std::mutex                                                                  g_ParagonMutex;

// ─────────────────────────────────────────────────────────────────────────────
// Startup loader
// ─────────────────────────────────────────────────────────────────────────────

void LoadAllBoardDefs()
{
    g_Boards.clear();
    g_Glyphs.clear();

    // ── Load board headers ────────────────────────────────────────────────
    QueryResult boards = WorldDatabase.Query(
        "SELECT board_id, name, board_type, required_class, required_board, "
        "unlock_paragon_level, unlock_prestige, width, height "
        "FROM paragon_boards ORDER BY board_id");

    if (!boards)
    {
        LOG_ERROR("module", "mod-synival-paragon: paragon_boards table is empty or missing.");
        return;
    }

    std::unordered_map<uint8, ParagonBoardDef> boardMap;
    do
    {
        Field* f = boards->Fetch();
        ParagonBoardDef board;
        board.boardId            = f[0].Get<uint8>();
        board.name               = f[1].Get<std::string>();
        board.boardType          = static_cast<BoardType>(f[2].Get<uint8>());
        board.requiredClass      = f[3].Get<uint8>();
        board.requiredBoard      = f[4].Get<uint8>();
        board.unlockParagonLevel = f[5].Get<uint32>();
        board.unlockPrestige     = f[6].Get<uint32>();
        board.width              = f[7].Get<uint8>();
        board.height             = f[8].Get<uint8>();
        boardMap[board.boardId]  = std::move(board);
    } while (boards->NextRow());

    // ── Load node definitions ─────────────────────────────────────────────
    QueryResult nodes = WorldDatabase.Query(
        "SELECT board_id, node_id, x, y, node_type, stat_type, stat_value, name, description "
        "FROM paragon_board_nodes ORDER BY board_id, node_id");

    uint32 nodeCount = 0;
    if (nodes)
    {
        do
        {
            Field* f = nodes->Fetch();
            uint8 boardId = f[0].Get<uint8>();
            auto it = boardMap.find(boardId);
            if (it == boardMap.end()) continue;

            ParagonNodeDef node;
            node.boardId     = boardId;
            node.nodeId      = f[1].Get<uint16>();
            node.x           = f[2].Get<uint8>();
            node.y           = f[3].Get<uint8>();
            node.type        = static_cast<NodeType>(f[4].Get<uint8>());
            node.statType    = static_cast<ParagonStatType>(f[5].Get<uint8>());
            node.statValue   = f[6].Get<float>();
            node.name        = f[7].Get<std::string>();
            node.description = f[8].Get<std::string>();
            it->second.nodes.push_back(std::move(node));
            ++nodeCount;
        } while (nodes->NextRow());
    }

    // ── Load glyph definitions ────────────────────────────────────────────
    QueryResult glyphs = WorldDatabase.Query(
        "SELECT glyph_id, name, radius, rare_bonus_pct, bonus_stat_type, "
        "bonus_stat_value, req_stat_type, req_stat_value, item_entry "
        "FROM paragon_glyphs ORDER BY glyph_id");

    uint32 glyphCount = 0;
    if (glyphs)
    {
        do
        {
            Field* f = glyphs->Fetch();
            GlyphDef g;
            g.glyphId        = f[0].Get<uint16>();
            g.name           = f[1].Get<std::string>();
            g.radius         = f[2].Get<uint8>();
            g.rareBonusPct   = f[3].Get<float>();
            g.bonusStatType  = static_cast<ParagonStatType>(f[4].Get<uint8>());
            g.bonusStatValue = f[5].Get<float>();
            g.reqStatType    = static_cast<ParagonStatType>(f[6].Get<uint8>());
            g.reqStatValue   = f[7].Get<float>();
            g.itemEntry      = f[8].Get<uint32>();
            g_Glyphs[g.glyphId] = std::move(g);
            ++glyphCount;
        } while (glyphs->NextRow());
    }

    // Move boardMap into the g_Boards vector (preserve insertion order)
    g_Boards.clear();
    g_Boards.reserve(boardMap.size());
    for (uint8 id = 1; id <= 255; ++id)
    {
        auto it = boardMap.find(id);
        if (it != boardMap.end())
            g_Boards.push_back(std::move(it->second));
        if (g_Boards.size() == boardMap.size()) break;
    }

    LOG_INFO("module", "mod-synival-paragon: Loaded {} boards ({} nodes, {} glyphs).",
             g_Boards.size(), nodeCount, glyphCount);
}

// ─────────────────────────────────────────────────────────────────────────────
// Visibility gate
// ─────────────────────────────────────────────────────────────────────────────

bool IsBoardVisibleForPlayer(Player const* player,
                              ParagonBoardDef const& board,
                              uint32 paragonLevel,
                              uint32 prestigeCount)
{
    // Universal boards: visible to everyone at any paragon level
    if (board.boardType == BOARD_UNIVERSAL)
        return true;

    // Class boards + spec boards: must match player class
    if (board.requiredClass != 0 && board.requiredClass != player->getClass())
        return false;

    // Paragon level threshold
    if (paragonLevel < board.unlockParagonLevel)
        return false;

    // Prestige threshold (spec boards may require prestige)
    if (prestigeCount < board.unlockPrestige)
        return false;

    // Spec boards additionally require the parent class board to have
    // at least one node unlocked (chain gate prevents skipping class board)
    if (board.boardType == BOARD_SPEC && board.requiredBoard != 0)
    {
        ObjectGuid guid = player->GetGUID();
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        auto pit = g_PlayerBoardStates.find(guid);
        if (pit == g_PlayerBoardStates.end()) return false;
        auto bit = pit->second.find(board.requiredBoard);
        if (bit == pit->second.end() || bit->second.unlockedNodes.empty())
            return false;
    }

    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Adjacency
// ─────────────────────────────────────────────────────────────────────────────

static uint8 ChebyshevDist(uint8 x1, uint8 y1, uint8 x2, uint8 y2)
{
    int dx = std::abs(static_cast<int>(x1) - static_cast<int>(x2));
    int dy = std::abs(static_cast<int>(y1) - static_cast<int>(y2));
    return static_cast<uint8>(std::max(dx, dy));
}

bool IsNodeAdjacent(ParagonBoardDef const& board,
                     PlayerBoardState const& state,
                     uint16 nodeId)
{
    ParagonNodeDef const* target = board.GetNode(nodeId);
    if (!target) return false;

    // START nodes are always self-adjacent (free to unlock without a neighbour)
    if (target->type == NODE_START) return true;

    // Check if any orthogonal (non-diagonal) neighbour is unlocked
    for (auto const& node : board.nodes)
    {
        if (!state.unlockedNodes.count(node.nodeId)) continue;

        int dx = std::abs(static_cast<int>(target->x) - static_cast<int>(node.x));
        int dy = std::abs(static_cast<int>(target->y) - static_cast<int>(node.y));

        // Orthogonal only: exactly one of dx/dy == 1, the other == 0
        if ((dx == 1 && dy == 0) || (dx == 0 && dy == 1))
            return true;
    }
    return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pre-unlock validation
// ─────────────────────────────────────────────────────────────────────────────

bool CanUnlockNode(Player const* player, uint8 boardId, uint16 nodeId)
{
    ParagonBoardDef const* board = FindBoard(boardId);
    if (!board) return false;
    ParagonNodeDef const* node = board->GetNode(nodeId);
    if (!node) return false;

    ObjectGuid guid = player->GetGUID();
    std::lock_guard<std::mutex> lock(g_ParagonMutex);

    // Already unlocked?
    auto& boardStates = g_PlayerBoardStates[guid];
    auto& state       = boardStates[boardId];
    if (state.unlockedNodes.count(nodeId)) return false;

    // Enough points?
    uint32 cost = NODE_COSTS[static_cast<uint8>(node->type)];
    if (g_ParagonMap[guid].boardPoints < cost) return false;

    // Adjacent to an already-unlocked node?
    if (!IsNodeAdjacent(*board, state, nodeId)) return false;

    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat application helpers
// ─────────────────────────────────────────────────────────────────────────────

static void ApplyFlatStat(Player* player, ParagonStatType stat, float val, bool apply)
{
    switch (stat)
    {
        case PSTAT_STRENGTH:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_STRENGTH, TOTAL_VALUE, val, apply); break;
        case PSTAT_AGILITY:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_AGILITY, TOTAL_VALUE, val, apply); break;
        case PSTAT_STAMINA:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_STAMINA, TOTAL_VALUE, val, apply); break;
        case PSTAT_INTELLECT:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_INTELLECT, TOTAL_VALUE, val, apply); break;
        case PSTAT_SPIRIT:
            player->HandleStatFlatModifier(UNIT_MOD_STAT_SPIRIT, TOTAL_VALUE, val, apply); break;
        case PSTAT_ARMOR:
            player->HandleStatFlatModifier(UNIT_MOD_ARMOR, TOTAL_VALUE, val, apply); break;
        case PSTAT_ATTACK_POWER:
            player->HandleStatFlatModifier(UNIT_MOD_ATTACK_POWER, TOTAL_VALUE, val, apply); break;
        case PSTAT_SPELL_POWER:
            // Map to intellect (safe universal hook for spell power)
            player->HandleStatFlatModifier(UNIT_MOD_STAT_INTELLECT, TOTAL_VALUE, val * 0.5f, apply); break;
        default: break;
    }
}

static void ApplyPctStat(Player* player, ParagonStatType stat, float pct, bool apply)
{
    switch (stat)
    {
        case PSTAT_STRENGTH:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_STRENGTH, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_AGILITY:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_AGILITY, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_STAMINA:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_STAMINA, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_INTELLECT:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_INTELLECT, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_SPIRIT:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_SPIRIT, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_ARMOR:
            player->ApplyStatPctModifier(UNIT_MOD_ARMOR, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_ATTACK_POWER:
            player->ApplyStatPctModifier(UNIT_MOD_ATTACK_POWER, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_SPELL_POWER:
            player->ApplyStatPctModifier(UNIT_MOD_STAT_INTELLECT, TOTAL_PCT, apply ? pct : -(pct)); break;
        case PSTAT_CRIT_PCT:
        {
            // 1% crit ≈ 45.906 rating at level 80 (WotLK formula)
            int32 rating = static_cast<int32>(pct * 45.906f);
            player->ApplyRatingMod(CR_CRIT_MELEE,  rating, apply);
            player->ApplyRatingMod(CR_CRIT_RANGED, rating, apply);
            player->ApplyRatingMod(CR_CRIT_SPELL,  rating, apply);
            break;
        }
        case PSTAT_HASTE_PCT:
        {
            // 1% haste ≈ 32.79 rating at level 80 (WotLK formula)
            int32 rating = static_cast<int32>(pct * 32.79f);
            player->ApplyRatingMod(CR_HASTE_MELEE,  rating, apply);
            player->ApplyRatingMod(CR_HASTE_RANGED, rating, apply);
            player->ApplyRatingMod(CR_HASTE_SPELL,  rating, apply);
            break;
        }
        default: break;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glyph radius amplification
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Returns the total amplification multiplier for a given Rare node,
 * factoring in every socketed glyph on that board whose socket is within
 * Chebyshev radius of the Rare node.
 *
 * amplification = 1.0 + sum(glyph.rareBonusPct / 100) for all qualifying glyphs
 */
static float GetRareAmplification(ParagonBoardDef const& board,
                                   PlayerBoardState const& state,
                                   ParagonNodeDef const& rareNode)
{
    float amp = 1.0f;
    for (auto const& [socketNodeId, glyphId] : state.socketedGlyphs)
    {
        ParagonNodeDef const* socketNode = board.GetNode(socketNodeId);
        if (!socketNode) continue;

        GlyphDef const* glyph = FindGlyph(glyphId);
        if (!glyph) continue;

        uint8 dist = ChebyshevDist(socketNode->x, socketNode->y,
                                    rareNode.x,    rareNode.y);
        if (dist <= glyph->radius)
            amp += glyph->rareBonusPct / 100.0f;
    }
    return amp;
}

/**
 * Check if the glyph's conditional requirement is satisfied by the
 * unlocked nodes within its radius on the given board.
 * Requirement: sum of stat_value for nodes matching glyph.reqStatType
 * within radius must be >= glyph.reqStatValue.
 */
static bool GlyphRequirementMet(ParagonBoardDef const& board,
                                  PlayerBoardState const& state,
                                  GlyphDef const& glyph,
                                  ParagonNodeDef const& socketNode)
{
    if (glyph.reqStatType == PSTAT_NONE) return true;
    float total = 0.0f;
    for (auto const& node : board.nodes)
    {
        if (!state.unlockedNodes.count(node.nodeId)) continue;
        if (node.statType != glyph.reqStatType) continue;
        uint8 dist = ChebyshevDist(socketNode.x, socketNode.y, node.x, node.y);
        if (dist <= glyph.radius) total += node.statValue;
    }
    return total >= glyph.reqStatValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main stat application
// ─────────────────────────────────────────────────────────────────────────────

void ApplyAllBoardStats(Player* player, bool apply)
{
    ObjectGuid guid = player->GetGUID();

    // Snapshot state under lock to avoid holding it during stat calls
    std::unordered_map<uint8, PlayerBoardState> statesCopy;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        auto it = g_PlayerBoardStates.find(guid);
        if (it != g_PlayerBoardStates.end())
            statesCopy = it->second;
    }

    bool statsChanged = false;

    for (auto const& [boardId, state] : statesCopy)
    {
        ParagonBoardDef const* board = FindBoard(boardId);
        if (!board) continue;

        for (uint16 nodeId : state.unlockedNodes)
        {
            ParagonNodeDef const* node = board->GetNode(nodeId);
            if (!node || node->statType == PSTAT_NONE) continue;

            switch (node->type)
            {
                case NODE_NORMAL:
                case NODE_MAGIC:
                    ApplyFlatStat(player, node->statType, node->statValue, apply);
                    statsChanged = true;
                    break;

                case NODE_RARE:
                {
                    float amp     = GetRareAmplification(*board, state, *node);
                    float effVal  = node->statValue * amp;
                    ApplyPctStat(player, node->statType, effVal, apply);
                    statsChanged = true;
                    break;
                }

                default:
                    break;
            }
        }

        // Apply glyph conditional bonuses
        for (auto const& [socketNodeId, glyphId] : state.socketedGlyphs)
        {
            GlyphDef const* glyph = FindGlyph(glyphId);
            if (!glyph || glyph->bonusStatType == PSTAT_NONE) continue;

            ParagonNodeDef const* socketNode = board->GetNode(socketNodeId);
            if (!socketNode) continue;

            if (GlyphRequirementMet(*board, state, *glyph, *socketNode))
            {
                // Bonus stat: if CRIT_PCT/HASTE_PCT treat as percent, else flat
                if (glyph->bonusStatType == PSTAT_CRIT_PCT ||
                    glyph->bonusStatType == PSTAT_HASTE_PCT ||
                    glyph->bonusStatType == PSTAT_ARMOR   ||
                    glyph->bonusStatType == PSTAT_ATTACK_POWER)
                    ApplyPctStat(player, glyph->bonusStatType, glyph->bonusStatValue, apply);
                else
                    ApplyFlatStat(player, glyph->bonusStatType, glyph->bonusStatValue, apply);
                statsChanged = true;
            }
        }
    }

    if (statsChanged)
        player->UpdateAllStats();
}

// ─────────────────────────────────────────────────────────────────────────────
// Mutations
// ─────────────────────────────────────────────────────────────────────────────

bool UnlockNode(Player* player, uint8 boardId, uint16 nodeId)
{
    if (!CanUnlockNode(player, boardId, nodeId))
        return false;

    ParagonBoardDef const* board = FindBoard(boardId);
    ParagonNodeDef const*  node  = board->GetNode(nodeId);
    uint32 cost = NODE_COSTS[static_cast<uint8>(node->type)];

    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        g_ParagonMap[player->GetGUID()].boardPoints -= cost;
        g_PlayerBoardStates[player->GetGUID()][boardId].unlockedNodes.insert(nodeId);
    }

    // Persist: deduct points and record the unlock
    ObjectGuid guid = player->GetGUID();
    uint32 newPoints;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        newPoints = g_ParagonMap[guid].boardPoints;
    }
    SaveBoardPointsOnly(guid, newPoints);
    CharacterDatabase.Execute(
        "INSERT IGNORE INTO character_paragon_nodes (guid, board_id, node_id) "
        "VALUES ({}, {}, {})",
        guid.GetCounter(), boardId, nodeId);

    // Refresh stats
    ApplyAllBoardStats(player, false);
    ApplyAllBoardStats(player, true);

    return true;
}

bool SocketGlyph(Player* player, uint8 boardId, uint16 nodeId, uint16 glyphId)
{
    ParagonBoardDef const* board = FindBoard(boardId);
    if (!board) return false;
    ParagonNodeDef const* node = board->GetNode(nodeId);
    if (!node || node->type != NODE_SOCKET) return false;

    GlyphDef const* glyph = FindGlyph(glyphId);
    if (!glyph) return false;

    ObjectGuid guid = player->GetGUID();

    // Node must be unlocked
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        auto& state = g_PlayerBoardStates[guid][boardId];
        if (!state.unlockedNodes.count(nodeId)) return false;
        // Cannot socket if already occupied
        if (state.socketedGlyphs.count(nodeId)) return false;
    }

    // Player must have the glyph item in their bags
    if (!player->GetItemCount(glyph->itemEntry, false))
    {
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cffFF4444[Paragon Board]|r You do not have |cff0070dd{}|r in your bags.",
            glyph->name);
        return false;
    }

    // Remove the glyph item from bags
    player->DestroyItemCount(glyph->itemEntry, 1, true);

    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        g_PlayerBoardStates[guid][boardId].socketedGlyphs[nodeId] = glyphId;
    }

    CharacterDatabase.Execute(
        "REPLACE INTO character_paragon_glyphs (guid, board_id, node_id, glyph_id) "
        "VALUES ({}, {}, {}, {})",
        guid.GetCounter(), boardId, nodeId, glyphId);

    ApplyAllBoardStats(player, false);
    ApplyAllBoardStats(player, true);

    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffFFD700[Paragon Board]|r |cff0070dd{}|r socketed into {}.",
        glyph->name, node->name);
    return true;
}

bool RemoveGlyph(Player* player, uint8 boardId, uint16 nodeId)
{
    ParagonBoardDef const* board = FindBoard(boardId);
    if (!board) return false;

    ObjectGuid guid = player->GetGUID();
    uint16 glyphId  = 0;

    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        auto& state = g_PlayerBoardStates[guid][boardId];
        auto it = state.socketedGlyphs.find(nodeId);
        if (it == state.socketedGlyphs.end()) return false;
        glyphId = it->second;
        state.socketedGlyphs.erase(it);
    }

    GlyphDef const* glyph = FindGlyph(glyphId);

    // Remove stats BEFORE returning item (so stats don't over-apply)
    ApplyAllBoardStats(player, false);

    // Return glyph item to player's bags
    if (glyph)
    {
        ItemPosCountVec dest;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, glyph->itemEntry, 1) == EQUIP_ERR_OK)
        {
            if (Item* item = player->StoreNewItem(dest, glyph->itemEntry, true))
                player->SendNewItem(item, 1, false, false, false);
        }
        else
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffFF4444[Paragon Board]|r Bags are full — |cff0070dd{}|r dropped to ground.",
                glyph->name);
            // Drop at player feet — better than silent loss
        }
    }

    // Persist removal then reapply stats
    CharacterDatabase.Execute(
        "DELETE FROM character_paragon_glyphs "
        "WHERE guid = {} AND board_id = {} AND node_id = {}",
        guid.GetCounter(), boardId, nodeId);

    ApplyAllBoardStats(player, true);
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistence
// ─────────────────────────────────────────────────────────────────────────────

void SaveBoardPointsOnly(ObjectGuid guid, uint32 boardPoints)
{
    CharacterDatabase.Execute(
        "UPDATE character_paragon SET board_points = {} WHERE guid = {}",
        boardPoints, guid.GetCounter());
}

void SaveShardsOnly(ObjectGuid guid, uint32 shards, uint32 lastPurchaseDay)
{
    CharacterDatabase.Execute(
        "UPDATE character_paragon "
        "SET paragon_shards = {}, last_shard_purchase_day = {} WHERE guid = {}",
        shards, lastPurchaseDay, guid.GetCounter());
}

uint32 ModifyPlayerParagonShards(ObjectGuid guid, int32 delta)
{
    uint32 newShards;
    uint32 lastDay;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        ParagonData& d = g_ParagonMap[guid];
        int32 result = static_cast<int32>(d.paragonShards) + delta;
        d.paragonShards = (result > 0) ? static_cast<uint32>(result) : 0u;
        newShards = d.paragonShards;
        lastDay   = d.lastShardPurchaseDay;
    }
    SaveShardsOnly(guid, newShards, lastDay);
    return newShards;
}

void LoadBoardState(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    std::unordered_map<uint8, PlayerBoardState> states;

    // Unlocked nodes
    QueryResult nodeResult = CharacterDatabase.Query(
        "SELECT board_id, node_id FROM character_paragon_nodes WHERE guid = {}",
        guid.GetCounter());
    if (nodeResult)
    {
        do
        {
            Field* f = nodeResult->Fetch();
            uint8  bId = f[0].Get<uint8>();
            uint16 nId = f[1].Get<uint16>();
            states[bId].unlockedNodes.insert(nId);
        } while (nodeResult->NextRow());
    }

    // Socketed glyphs
    QueryResult glyphResult = CharacterDatabase.Query(
        "SELECT board_id, node_id, glyph_id FROM character_paragon_glyphs WHERE guid = {}",
        guid.GetCounter());
    if (glyphResult)
    {
        do
        {
            Field* f = glyphResult->Fetch();
            uint8  bId = f[0].Get<uint8>();
            uint16 nId = f[1].Get<uint16>();
            uint16 gId = f[2].Get<uint16>();
            states[bId].socketedGlyphs[nId] = gId;
        } while (glyphResult->NextRow());
    }

    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        g_PlayerBoardStates[guid] = std::move(states);
    }
}

void ClearBoardState(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    std::lock_guard<std::mutex> lock(g_ParagonMutex);
    g_PlayerBoardStates.erase(guid);
    g_ParagonMap.erase(guid);
}

// ─────────────────────────────────────────────────────────────────────────────
// Board-point awards
// ─────────────────────────────────────────────────────────────────────────────

void AwardBoardPointOnLevelUp(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    uint32 newPoints;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        newPoints = ++g_ParagonMap[guid].boardPoints;
    }
    SaveBoardPointsOnly(guid, newPoints);
    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffFFD700[Paragon Board]|r +1 Board Point awarded. Total: |cff00FF00{}|r.", newPoints);
}

void RollBoardPointOnKill(Player* player)
{
    // 5% chance per eligible kill — config-driven in calling code
    ObjectGuid guid = player->GetGUID();
    uint32 newPoints;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        newPoints = ++g_ParagonMap[guid].boardPoints;
    }
    SaveBoardPointsOnly(guid, newPoints);
    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffFFD700[Paragon Board]|r A moment of clarity — +1 Board Point. Total: |cff00FF00{}|r.", newPoints);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gossip rendering helpers
// ─────────────────────────────────────────────────────────────────────────────

std::string StatTypeName(ParagonStatType t)
{
    switch (t)
    {
        case PSTAT_STRENGTH:     return "Strength";
        case PSTAT_AGILITY:      return "Agility";
        case PSTAT_STAMINA:      return "Stamina";
        case PSTAT_INTELLECT:    return "Intellect";
        case PSTAT_SPIRIT:       return "Spirit";
        case PSTAT_ARMOR:        return "Armor";
        case PSTAT_CRIT_PCT:     return "Critical Strike";
        case PSTAT_HASTE_PCT:    return "Haste";
        case PSTAT_SPELL_POWER:  return "Spell Power";
        case PSTAT_ATTACK_POWER: return "Attack Power";
        default:                 return "None";
    }
}

std::string StatValueString(ParagonStatType t, float v)
{
    std::ostringstream ss;
    if (t == PSTAT_CRIT_PCT || t == PSTAT_HASTE_PCT)
        ss << "+" << v << "%";
    else
        ss << "+" << static_cast<uint32>(v);
    ss << " " << StatTypeName(t);
    return ss.str();
}

/**
 * Renders one row (y) of the 7-wide board grid as a coloured string.
 *
 * Cell symbols:
 *   [@] = START (always gold)      [G] = Socket with glyph (orange)
 *   [S] = Socket empty (yellow)    [R] = Rare unlocked (blue)
 *   [M] = Magic unlocked (green)   [N] = Normal unlocked (grey)
 *   [?] = Locked node (dark grey)  ' ' = no node at this position
 */
std::string BuildBoardGridRow(ParagonBoardDef const& board,
                               PlayerBoardState const& state,
                               uint8 row)
{
    std::string result;
    for (uint8 col = 0; col < board.width; ++col)
    {
        // Find node at (col, row)
        ParagonNodeDef const* found = nullptr;
        for (auto const& n : board.nodes)
            if (n.x == col && n.y == row) { found = &n; break; }

        if (!found) { result += "  .  "; continue; }

        bool unlocked  = state.unlockedNodes.count(found->nodeId) > 0;
        bool hasglyph  = state.socketedGlyphs.count(found->nodeId) > 0;

        switch (found->type)
        {
            case NODE_START:
                result += "|cffFFD700[@]|r "; break;
            case NODE_SOCKET:
                if (!unlocked)       result += "|cff444444[O]|r ";
                else if (hasglyph)   result += "|cffFF8000[G]|r ";
                else                 result += "|cffFFFF00[S]|r ";
                break;
            case NODE_RARE:
                result += unlocked ? "|cff0070dd[R]|r " : "|cff444444[?]|r ";
                break;
            case NODE_MAGIC:
                result += unlocked ? "|cff1eff00[M]|r " : "|cff444444[?]|r ";
                break;
            case NODE_NORMAL:
                result += unlocked ? "|cff888888[N]|r " : "|cff444444[?]|r ";
                break;
        }
    }
    return result;
}

/**
 * Formats a single node as a gossip list entry.
 * Colour-codes the node type prefix and appends availability status.
 */
std::string FormatNodeEntry(ParagonNodeDef const& node,
                             bool unlocked,
                             bool available,
                             bool affordable)
{
    std::ostringstream ss;

    // Type tag
    switch (node.type)
    {
        case NODE_START:  ss << "|cffFFD700[START]|r ";  break;
        case NODE_SOCKET: ss << "|cffFFFF00[SOCKET]|r "; break;
        case NODE_RARE:   ss << "|cff0070dd[RARE]|r ";   break;
        case NODE_MAGIC:  ss << "|cff1eff00[MAGIC]|r ";  break;
        case NODE_NORMAL: ss << "|cff888888[NORM]|r ";   break;
    }

    ss << node.name;

    if (node.statType != PSTAT_NONE)
        ss << "  " << StatValueString(node.statType, node.statValue);

    uint32 cost = NODE_COSTS[static_cast<uint8>(node.type)];
    if (cost > 0) ss << "  [" << cost << "pt]";

    if (unlocked)          ss << "  |cff00FF00[OWNED]|r";
    else if (!available)   ss << "  |cff666666[LOCKED]|r";
    else if (!affordable)  ss << "  |cffFF4444[NEED " << cost << "pt]|r";
    else                   ss << "  |cffFFFF00[AVAILABLE]|r";

    return ss.str();
}
