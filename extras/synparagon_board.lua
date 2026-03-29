-- =============================================================================
-- synparagon_board.lua  (v3 — standalone, no C++ gossip dependency)
-- Synival Paragon Board — mod-ale (Eluna) server-side gossip handler
-- =============================================================================
--
-- DROP into your Lua scripts folder, e.g.:
--   C:\builds\CoffingQuest\bin\RelWithDebInfo\lua_scripts\
--
-- This script is the SOLE gossip handler for NPC 99996 (Runic Archive).
-- The C++ npc_runic_archive CreatureScript has been removed. All gossip
-- rendering lives here. C++ retains all game logic:
--   • Paragon XP accumulation (PlayerScript hooks)
--   • Stat bonus application (RefreshStatBonus / ApplyAllBoardStats)
--   • Glyph stat amplification (applied server-side on equip)
--   • Prestige (AttemptPrestige — triggered by .paragon set prestige command
--     or directly from this Lua via CharDBExecute + player:CastSpell)
--
-- Sources:
--   Eluna API: https://azerothcore.github.io/eluna/
--   mod-ale:   https://github.com/azerothcore/mod-eluna
--   Gossip event IDs: CREATURE_EVENT_ON_GOSSIP_HELLO=1, ON_GOSSIP_SELECT=2
-- =============================================================================

-- ── NPC / text IDs ────────────────────────────────────────────────────────────
local NPC_ENTRY   = 99996
local NPC_TEXT_ID = 99996

-- ── Gossip page limits ────────────────────────────────────────────────────────
local NODES_PER_PAGE = 8

-- ── Action IDs — non-board archive pages ─────────────────────────────────────
-- Must NOT collide with IsBoardAction() range (page*16777216, page >= 1).
-- All values below are < 16777216 so IsBoardAction returns false for them.
local ACT_STATUS          = 1
local ACT_SCALING         = 2
local ACT_PRESTIGE_INFO   = 3
local ACT_PRESTIGE_CONFIRM= 4
local ACT_PRESTIGE_DO     = 5
local ACT_ADMIN_PANEL     = 10
local ACT_ADMIN_GIVEPOINTS= 11
local ACT_ADMIN_SETLEVEL50= 12
local ACT_ADMIN_RESETBOARD= 13
local ACT_ADMIN_RESETPRES = 14
local ACT_ADMIN_GRANTCACHE= 15
local ACT_BACK            = 98
local ACT_CLOSE           = 99

-- ── BoardGossipAction page types (must match C++ enum in mod_paragon_board.h) ─
local BGA_BOARD_LIST      = 1
local BGA_BOARD_OVERVIEW  = 2
local BGA_NODE_LIST       = 3
local BGA_NODE_DETAIL     = 4
local BGA_NODE_UNLOCK     = 5
local BGA_GLYPH_LIST      = 6
local BGA_GLYPH_DETAIL    = 7
local BGA_GLYPH_SOCKET    = 8
local BGA_GLYPH_REMOVE    = 9
local BGA_BACK_TO_ARCHIVE = 10

-- ── Node type costs (Normal=1 Magic=2 Rare=3 Socket=4 Start=free) ────────────
local NODE_COSTS = { [0]=1, [1]=2, [2]=3, [3]=4, [4]=0 }

local NODE_TYPE_NAME = {
    [0]="Normal", [1]="Magic", [2]="Rare", [3]="Socket", [4]="Start"
}

local STAT_NAME = {
    [0]="—",          [1]="Strength",    [2]="Agility",
    [3]="Stamina",    [4]="Intellect",   [5]="Spirit",
    [6]="Armor",      [7]="Crit Strike", [8]="Haste",
    [9]="Spell Power",[10]="Attack Power"
}

-- ── Gossip icons ──────────────────────────────────────────────────────────────
local ICON_CHAT      = 0
local ICON_VENDOR    = 1
local ICON_TAXI      = 2
local ICON_TRAINER   = 3
local ICON_INTERACT1 = 4
local ICON_MONEY     = 5
local ICON_BATTLE    = 9

-- ── Class data ────────────────────────────────────────────────────────────────
local CLASS_DATA = {
    [1]  = { name="Warrior",      color="C69B3A" },
    [2]  = { name="Paladin",      color="F48CBA" },
    [3]  = { name="Hunter",       color="AAD372" },
    [4]  = { name="Rogue",        color="FFF468" },
    [5]  = { name="Priest",       color="FFFFFF" },
    [6]  = { name="Death Knight", color="C41E3A" },
    [7]  = { name="Shaman",       color="0070DD" },
    [8]  = { name="Mage",         color="3FC7EB" },
    [9]  = { name="Warlock",      color="8788EE" },
    [11] = { name="Druid",        color="FF7C0A" },
}

-- ── Server config (loaded live from synparagon_config world DB table) ─────────
-- C++ OnBeforeConfigLoad writes all active config values to this table on every
-- server start and reload. Lua reads it once on first NPC interaction and caches
-- the result for the session. This means Paragon.BaseCap, StatBonusCap, etc.
-- always reflect the current .conf file without any hardcoded fallback drift.

local CFG = nil   -- populated by LoadCFG() on first use

local CFG_DEFAULTS = {
    BaseCap               = 200,
    ExtendedCap           = 2000,
    MaxPrestige           = 10,
    StatBonusPerLevel     = 0.5,
    StatBonusCap          = 100.0,
    MarkBonusPercent      = 15.0,
    XPPerLevel            = 1500000,
    PrestigeBoardPtBonus  = 5,
    BoardPointKillChance  = 5,
    HiddenAffixChance     = 15,
    PrestigeAchievId      = 2139,
    ItemCacheEntry        = 99200,
}

local function LoadCFG()
    local cfg = {}
    -- Copy defaults first so any missing key falls back gracefully
    for k, v in pairs(CFG_DEFAULTS) do cfg[k] = v end

    local q = WorldDBQuery("SELECT cfg_key, cfg_value FROM synparagon_config")
    if q then
        repeat
            local k = q:GetString(0)
            local v = q:GetString(1)
            -- Integer keys
            if k == "BaseCap" or k == "ExtendedCap" or k == "MaxPrestige"
            or k == "XPPerLevel" or k == "PrestigeBoardPtBonus"
            or k == "BoardPointKillChance" or k == "HiddenAffixChance"
            or k == "PrestigeAchievId" or k == "ItemCacheEntry" then
                cfg[k] = tonumber(v) or CFG_DEFAULTS[k]
            else
                -- Float keys
                cfg[k] = tonumber(v) or CFG_DEFAULTS[k]
            end
        until not q:NextRow()
    end

    return cfg
end

-- Returns the cached config, loading it on first call.
local function GetCFG()
    if not CFG then CFG = LoadCFG() end
    return CFG
end

-- ── Helper: current paragon cap given prestige rank ───────────────────────────
local function GetCurrentCap(prestige)
    if prestige >= GetCFG().MaxPrestige then
        return GetCFG().ExtendedCap
    end
    return GetCFG().BaseCap
end

-- ── Helper: class info with safe fallback ────────────────────────────────────
local function GetClassInfo(player)
    local id = player:GetClass()
    return CLASS_DATA[id] or { name="Adventurer", color="FFD700" }
end

-- ── Helper: wrap text in class color ─────────────────────────────────────────
local function ClassColor(cd, text)
    return "|cff"..cd.color..text.."|r"
end

-- ── Action encoding / decoding (mirrors C++ EncBoardAction/DecBoardAction) ────
local function EncAction(page, nodeId, secondary)
    nodeId    = nodeId    or 0
    secondary = secondary or 0
    return (page * 16777216) + ((nodeId % 4096) * 4096) + (secondary % 4096)
end

local function DecAction(action)
    local page      = math.floor(action / 16777216)
    local remainder = action % 16777216
    local nodeId    = math.floor(remainder / 4096)
    local secondary = remainder % 4096
    return page, nodeId, secondary
end

local function IsBoardAction(action)
    return math.floor(action / 16777216) >= BGA_BOARD_LIST
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DATABASE HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function GetParagonData(guid)
    local q = CharDBQuery(
        "SELECT paragon_level, prestige_count, board_points, paragon_xp "..
        "FROM character_paragon WHERE guid = "..guid.." LIMIT 1"
    )
    if not q then return nil end
    return {
        level        = q:GetUInt32(0),
        prestige     = q:GetUInt32(1),
        board_points = q:GetUInt32(2),
        xp           = q:GetUInt32(3),
    }
end

local function GetUnlockedNodes(guid, boardId)
    local unlocked = {}
    local q = CharDBQuery(
        "SELECT node_id FROM character_paragon_nodes "..
        "WHERE guid = "..guid.." AND board_id = "..boardId
    )
    if q then
        repeat unlocked[q:GetUInt32(0)] = true
        until not q:NextRow()
    end
    return unlocked
end

local function GetSocketedGlyphIds(guid, boardId)
    local socketed = {}
    local q = CharDBQuery(
        "SELECT node_id, glyph_id FROM character_paragon_glyphs "..
        "WHERE guid = "..guid.." AND board_id = "..boardId
    )
    if q then
        repeat socketed[q:GetUInt32(0)] = q:GetUInt32(1)
        until not q:NextRow()
    end
    return socketed
end

local function GetBoardNodes(boardId)
    local nodes   = {}
    local byCoord = {}
    local q = WorldDBQuery(
        "SELECT node_id, x, y, node_type, stat_type, stat_value, name, description "..
        "FROM paragon_board_nodes WHERE board_id = "..boardId.." ORDER BY node_id ASC"
    )
    if not q then return nodes, byCoord end
    repeat
        local n = {
            id    = q:GetUInt32(0),
            x     = q:GetUInt32(1),
            y     = q:GetUInt32(2),
            ntype = q:GetUInt32(3),
            stat  = q:GetUInt32(4),
            val   = q:GetFloat (5),
            name  = q:GetString(6),
            desc  = q:GetString(7),
        }
        table.insert(nodes, n)
        byCoord[n.x..","..n.y] = n
    until not q:NextRow()
    return nodes, byCoord
end

local function GetAllGlyphs()
    local glyphs = {}
    local q = WorldDBQuery(
        "SELECT glyph_id, name, radius, rare_bonus_pct, "..
        "bonus_stat_type, bonus_stat_value, req_stat_type, req_stat_value, item_entry "..
        "FROM paragon_glyphs ORDER BY glyph_id ASC"
    )
    if not q then return glyphs end
    repeat
        local gid = q:GetUInt32(0)
        glyphs[gid] = {
            id             = gid,
            name           = q:GetString(1),
            radius         = q:GetUInt32(2),
            rare_bonus_pct = q:GetFloat(3),
            bonus_stat     = q:GetUInt32(4),
            bonus_val      = q:GetFloat(5),
            req_stat       = q:GetUInt32(6),
            req_val        = q:GetFloat(7),
            item_entry     = q:GetUInt32(8),
        }
    until not q:NextRow()
    return glyphs
end

local function GetAccessibleBoards(player, paragonLevel, prestige)
    local classId = player:GetClass()
    local guid    = player:GetGUIDLow()
    local boards  = {}
    local q = WorldDBQuery(
        "SELECT board_id, name, board_type, required_class, required_board, "..
        "       unlock_paragon_level, unlock_prestige, width, height "..
        "FROM paragon_boards ORDER BY board_id ASC"
    )
    if not q then return boards end
    repeat
        local boardId     = q:GetUInt32(0)
        local name        = q:GetString(1)
        local boardType   = q:GetUInt32(2)
        local reqClass    = q:GetUInt32(3)
        local reqBoard    = q:GetUInt32(4)
        local unlockLevel = q:GetUInt32(5)
        local unlockPres  = q:GetUInt32(6)
        local width       = q:GetUInt32(7)
        local height      = q:GetUInt32(8)

        local visible = false
        if boardType == 0 then
            visible = (paragonLevel >= unlockLevel) and (prestige >= unlockPres)
        elseif boardType == 1 then
            visible = (reqClass == 0 or reqClass == classId)
                   and (paragonLevel >= unlockLevel)
                   and (prestige >= unlockPres)
        elseif boardType == 2 then
            if (reqClass == 0 or reqClass == classId) and (paragonLevel >= unlockLevel) then
                if reqBoard == 0 then
                    visible = true
                else
                    local prereq = CharDBQuery(
                        "SELECT COUNT(*) FROM character_paragon_nodes "..
                        "WHERE guid = "..guid.." AND board_id = "..reqBoard
                    )
                    visible = prereq and (prereq:GetUInt32(0) > 0)
                end
            end
        end

        if visible then
            table.insert(boards, {
                id      = boardId, name = name, btype = boardType,
                width   = width,   height = height,
            })
        end
    until not q:NextRow()
    return boards
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAME LOGIC HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function IsAdjacent(nodes, unlocked)
    local unlockedCoords = {}
    for _, n in ipairs(nodes) do
        if n.ntype == 4 or unlocked[n.id] then
            unlockedCoords[n.x..","..n.y] = true
        end
    end
    local result = {}
    for _, n in ipairs(nodes) do
        if not unlocked[n.id] and n.ntype ~= 4 then
            result[n.id] = (
                unlockedCoords[(n.x-1)..","..n.y]  or
                unlockedCoords[(n.x+1)..","..n.y]  or
                unlockedCoords[n.x..","  ..(n.y-1)] or
                unlockedCoords[n.x..","  ..(n.y+1)]
            ) and true or false
        end
    end
    return result
end

local function StatStr(statType, statVal)
    local name = STAT_NAME[statType] or "Unknown"
    if statType == 0 then return "—" end
    if statVal < 10 then
        return string.format("+%.1f%% %s", statVal, name)
    else
        return string.format("+%d %s", math.floor(statVal), name)
    end
end

local function GlyphBonusStr(g)
    local s = string.format("+%.0f%% Rare  r=%d", g.rare_bonus_pct, g.radius)
    if g.bonus_stat and g.bonus_stat > 0 then
        s = s..string.format("  +%.0f %s", g.bonus_val, STAT_NAME[g.bonus_stat] or "?")
        if g.req_stat and g.req_stat > 0 then
            s = s..string.format(" (need %.0f %s in r)", g.req_val, STAT_NAME[g.req_stat] or "?")
        end
    end
    return s
end

local function StatusStrip(pdata, cd)
    local ptColor = pdata.board_points > 0 and "|cff00FF00" or "|cffFF4444"
    return string.format(
        "|cffFFD700Paragon %d|r  |cff444444·|r  %s%d pts|r  |cff444444·|r  %s",
        pdata.level, ptColor, pdata.board_points, ClassColor(cd, cd.name)
    )
end

local function BuildBar(current, max, width)
    local filled = math.floor((current / math.max(max, 1)) * width)
    filled = math.min(filled, width)
    return "|cff00FF00"..string.rep("█", filled).."|r"..
           "|cff444444"..string.rep("░", width - filled).."|r"
end

local function BuildStars(current, max)
    local s = ""
    for i = 1, max do
        s = s..(i <= current and "|cffFFD700★|r" or "|cff444444☆|r")
    end
    return s
end

local function FormatNum(n)
    if n >= 1000000 then return string.format("%.1fM", n/1000000)
    elseif n >= 1000 then return string.format("%.1fK", n/1000)
    else return tostring(n) end
end

local function FormatNodeEntry(node, isUnlocked, isAdj, canAfford)
    local prefix
    if isUnlocked then
        prefix = "|cff00FF00[OWNED]|r "
    elseif isAdj and canAfford then
        prefix = "|cff00FF00[AVAIL]|r "
    elseif isAdj then
        local cost = NODE_COSTS[node.ntype] or 1
        prefix = "|cffFF4444[NEED "..cost.."pt]|r "
    else
        prefix = "|cff666666[LOCK]|r "
    end

    local typeTag = ""
    if    node.ntype == 0 then typeTag = "|cff888888N|r "
    elseif node.ntype == 1 then typeTag = "|cff1eff00M|r "
    elseif node.ntype == 2 then typeTag = "|cff0070ddR|r "
    elseif node.ntype == 3 then typeTag = "|cffFFFF00S|r "
    end

    local statPart = (node.stat and node.stat > 0) and ("  "..StatStr(node.stat, node.val)) or ""
    return prefix..typeTag..node.name..statPart
end

local function BuildGridRow(nodes, byCoord, unlocked, adjacentSet, boardWidth, row)
    local parts = {}
    for col = 0, boardWidth - 1 do
        local n = byCoord[col..","..row]
        if not n then
            table.insert(parts, "   ")
        elseif n.ntype == 4 then
            table.insert(parts, unlocked[n.id] and "|cffFFD700[@]|r" or "|cffFFFF00[@]|r")
        elseif unlocked[n.id] then
            local t = n.ntype
            if     t == 0 then table.insert(parts, "|cffaaaaaa[N]|r")
            elseif t == 1 then table.insert(parts, "|cff1eff00[M]|r")
            elseif t == 2 then table.insert(parts, "|cff0070dd[R]|r")
            elseif t == 3 then table.insert(parts, "|cffFFFF00[G]|r")
            end
        elseif adjacentSet and adjacentSet[n.id] then
            table.insert(parts, "|cff00FF00[+]|r")
        else
            table.insert(parts, "|cff444444[?]|r")
        end
    end
    return table.concat(parts, " ")
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GOSSIP PAGE RENDERERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ShowMainMenu(player, creature)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    local cd    = GetClassInfo(player)

    player:GossipClearMenu()

    if not pdata then
        player:GossipMenuAddItem(ICON_CHAT,
            "The Archive has no record of your Paragon journey yet.", 0, ACT_CLOSE)
        player:GossipMenuAddItem(ICON_CHAT,
            "Gain Paragon XP by defeating enemies at max level.", 0, ACT_CLOSE)
        player:GossipMenuAddItem(ICON_TAXI, "Farewell.", 0, ACT_CLOSE)
        player:GossipSendMenu(NPC_TEXT_ID, creature)
        return
    end

    local cap = GetCurrentCap(pdata.prestige)
    local header = string.format("Paragon %d/%d   Prestige %d/%d",
        pdata.level, cap, pdata.prestige, GetCFG().MaxPrestige)

    player:GossipMenuAddItem(ICON_CHAT, header, 0, ACT_STATUS)
    player:GossipMenuAddItem(ICON_INTERACT1, "[View Full Progress]", 0, ACT_STATUS)
    player:GossipMenuAddItem(ICON_TRAINER,   "[Scaling System]",     0, ACT_SCALING)
    player:GossipMenuAddItem(ICON_TRAINER,   "[Prestige Info]",      0, ACT_PRESTIGE_INFO)
    player:GossipMenuAddItem(ICON_BATTLE,
        "|cffFFD700>>> Paragon Boards <<<|r",
        0, EncAction(BGA_BOARD_LIST))

    -- Prestige button (only if eligible)
    local eligible = (pdata.level >= cap)
                  and (pdata.prestige < GetCFG().MaxPrestige)
                  and player:HasAchievement(GetCFG().PrestigeAchievId)
    if eligible then
        player:GossipMenuAddItem(ICON_BATTLE,
            "|cffFF8000>>> PRESTIGE NOW <<<|r",
            0, ACT_PRESTIGE_CONFIRM)
    end

    -- Admin panel (SEC level 3 = ADMINISTRATOR)
    if player:GetGMLevel() >= 3 then
        player:GossipMenuAddItem(ICON_INTERACT1,
            "|cffFF4444[GM] Admin Panel|r", 0, ACT_ADMIN_PANEL)
    end

    player:GossipMenuAddItem(ICON_TAXI, "Farewell.", 0, ACT_CLOSE)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowStatusPage(player, creature)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    local cd    = GetClassInfo(player)
    if not pdata then player:GossipComplete(); return end

    local cap       = GetCurrentCap(pdata.prestige)
    local cfg       = GetCFG()
    local xpPerLvl  = cfg.XPPerLevel
    local statBonus = math.min(pdata.level * cfg.StatBonusPerLevel, cfg.StatBonusCap)

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT, StatusStrip(pdata, cd), 0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "Level  "..BuildBar(pdata.level, cap, 16)..
        "  "..pdata.level.."/"..cap,
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "XP     "..BuildBar(pdata.xp, xpPerLvl, 16)..
        "  "..FormatNum(pdata.xp).."/"..FormatNum(xpPerLvl),
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "Prestige  "..BuildStars(pdata.prestige, cfg.MaxPrestige)..
        "  ("..pdata.prestige.."/"..cfg.MaxPrestige..")",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        string.format("Stat Bonus  |cff00FF00+%d%%|r all primary stats (cap: %d%%)",
            math.floor(statBonus), math.floor(cfg.StatBonusCap)),
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "Board Points: |cffFFD700"..pdata.board_points.."|r",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT, "[Back]", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowScalingPage(player, creature)
    local cfg = GetCFG()
    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        string.format("|cff00FF00+%.1f%%|r to STR/AGI/STA/INT/SPI per Paragon Level. Hard cap: |cff00FF00%.0f%%|r.",
            cfg.StatBonusPerLevel, cfg.StatBonusCap),
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "Base cap: |cff00FF00"..cfg.BaseCap..
        "|r    Extended (Prestige 10): |cff00FF00"..cfg.ExtendedCap.."|r",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFFD700Board Nodes:|r Normal/Magic = flat stats. "..
        "Rare = % stats amplified by Glyphs.",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFFD700Hidden Affixes:|r "..GetCFG().HiddenAffixChance..
        "% on looted weapons/armour. Mongoose, Berserking, etc.",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT, "[Back]", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowPrestigeInfo(player, creature)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    if not pdata then player:GossipComplete(); return end

    local cap      = GetCurrentCap(pdata.prestige)
    local metLevel = (pdata.level >= cap)
    local metAchiev= player:HasAchievement(GetCFG().PrestigeAchievId)

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        "1. Reach Paragon Level |cff00FF00"..cap..
        "|r  (current: |cffFFFF00"..pdata.level.."|r)  "..
        (metLevel and "|cff00FF00[MET]|r" or "|cffFF4444[NOT MET]|r"),
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "2. Glory of the Hero (all WotLK HC dungeons)  "..
        (metAchiev and "|cff00FF00[MET]|r" or "|cffFF4444[NOT MET]|r"),
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "Reward: Paragon resets, rank increases. At rank 10: cap → |cff00FF00"..
        GetCFG().ExtendedCap.."|r + The Butcher awakens.",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cff00CCFF+"..GetCFG().PrestigeBoardPtBonus..
        " Board Points|r granted on each Prestige. Board nodes and glyphs are |cff00FF00kept|r.",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT, "[Back]", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowPrestigeConfirm(player, creature)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    if not pdata then player:GossipComplete(); return end

    local cap     = GetCurrentCap(pdata.prestige)
    local newPts  = pdata.board_points + GetCFG().PrestigeBoardPtBonus
    local newCap  = GetCurrentCap(pdata.prestige + 1)

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFF8000Prestige Rank "..(pdata.prestige + 1).."|r — Confirm?",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFF4444RESETS:|r  Paragon Level (→ 0)   Paragon XP",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cff00FF00KEPT:|r  All Board Nodes   All Glyphs   All Items",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "|cff00CCFFBOARD POINTS:|r  "..pdata.board_points..
        " current  +  "..GetCFG().PrestigeBoardPtBonus..
        " bonus  =  |cff00FF00"..newPts.." total|r",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_CHAT,
        "New cap: |cff00FF00"..newCap.."|r  "..
        "New stat bonus: |cff00FF00+"..
        math.min(math.floor(newCap * GetCFG().StatBonusPerLevel), math.floor(GetCFG().StatBonusCap))..
        "% global (capped at "..math.floor(GetCFG().StatBonusCap).."%)|r",
        0, ACT_BACK)
    player:GossipMenuAddItem(ICON_BATTLE,
        "|cff00FF00>>> Yes — Prestige Now! <<<|r", 0, ACT_PRESTIGE_DO)
    player:GossipMenuAddItem(ICON_CHAT, "No — not yet.", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function DoPrestige(player, creature)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    if not pdata then player:GossipComplete(); return end

    local cap = GetCurrentCap(pdata.prestige)
    local ch  = function(msg) player:SendBroadcastMessage(msg) end

    if pdata.level < cap then
        ch("|cffFF4444[Prestige]|r Reach Paragon Level |cff00FF00"..cap.."|r first.")
        ShowMainMenu(player, creature); return
    end
    if pdata.prestige >= GetCFG().MaxPrestige then
        ch("|cffFFD700[Prestige]|r Maximum Prestige Rank already achieved.")
        ShowMainMenu(player, creature); return
    end
    if not player:HasAchievement(GetCFG().PrestigeAchievId) then
        ch("|cffFF4444[Prestige]|r Complete all WotLK Heroic Dungeons first.")
        ShowMainMenu(player, creature); return
    end

    local newPrestige = pdata.prestige + 1
    local newPoints   = pdata.board_points + GetCFG().PrestigeBoardPtBonus

    CharDBExecute(
        "UPDATE character_paragon SET "..
        "paragon_level = 0, paragon_xp = 0, "..
        "prestige_count = "..newPrestige..", "..
        "board_points = "..newPoints..
        " WHERE guid = "..guid
    )

    -- Broadcast to all online players
    -- SendWorldMessage() is the correct Eluna global for server-wide chat messages.
    -- Source: https://azerothcore.github.io/eluna/ → Global Functions
    local msg = "|cffFF8000[Prestige]|r "..player:GetName()..
        " has achieved |cffFF8000Prestige Rank "..newPrestige.."|r!"
    SendWorldMessage(msg)

    player:GossipComplete()
end

-- ── Admin panel ───────────────────────────────────────────────────────────────
local function ShowAdminPanel(player, creature)
    if player:GetGMLevel() < 3 then ShowMainMenu(player, creature); return end

    local target     = player:GetSelection()
    local targetName = target and target:GetName() or "(none selected)"

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFF4444[GM Admin Panel]|r  Target: |cff00FF00"..targetName.."|r",
        0, ACT_BACK)

    if target and target:IsPlayer() then
        local tguid = target:GetGUIDLow()
        local tdata = GetParagonData(tguid)
        if tdata then
            player:GossipMenuAddItem(ICON_CHAT,
                "Stats — Paragon: |cff00FF00"..tdata.level..
                "|r  Prestige: |cffFF8000"..tdata.prestige..
                "|r  Board Pts: |cffFFD700"..tdata.board_points.."|r",
                0, ACT_ADMIN_PANEL)
        end
        player:GossipMenuAddItem(ICON_MONEY,
            "[+10 Board Points] Grant 10 board points to target",
            0, ACT_ADMIN_GIVEPOINTS)
        player:GossipMenuAddItem(ICON_BATTLE,
            "[Set Paragon 50] Set target's Paragon Level to 50",
            0, ACT_ADMIN_SETLEVEL50)
        player:GossipMenuAddItem(ICON_TAXI,
            "[Reset All Boards] Refund all board nodes for target",
            0, ACT_ADMIN_RESETBOARD)
        player:GossipMenuAddItem(ICON_CHAT,
            "|cffFF4444[Reset Prestige]|r Set target's Prestige to 0",
            0, ACT_ADMIN_RESETPRES)
        player:GossipMenuAddItem(ICON_INTERACT1,
            "[Grant Daily Cache] Give Cache of Synival's Treasures",
            0, ACT_ADMIN_GRANTCACHE)
    else
        player:GossipMenuAddItem(ICON_CHAT,
            "|cff888888No player targeted. Right-click a player first.|r",
            0, ACT_BACK)
    end

    player:GossipMenuAddItem(ICON_CHAT, "[Back to Archive]", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function DoAdminAction(player, creature, action)
    if player:GetGMLevel() < 3 then player:GossipComplete(); return end

    local target = player:GetSelection()
    if not (target and target:IsPlayer()) then
        ShowAdminPanel(player, creature); return
    end

    local tguid = target:GetGUIDLow()
    local tdata = GetParagonData(tguid)

    if action == ACT_ADMIN_GIVEPOINTS then
        local newPts = (tdata and tdata.board_points or 0) + 10
        CharDBExecute(
            "UPDATE character_paragon SET board_points = board_points + 10 "..
            "WHERE guid = "..tguid
        )
        player:SendBroadcastMessage(
            "|cffFFD700[Admin]|r Granted +10 Board Points to "..target:GetName()..
            ". Total: "..newPts..".")
        target:SendBroadcastMessage(
            "|cffFFD700[Paragon Board]|r A GM granted you |cff00FF00+10|r Board Points. "..
            "Total: |cff00FF00"..newPts.."|r.")

    elseif action == ACT_ADMIN_SETLEVEL50 then
        CharDBExecute(
            "UPDATE character_paragon SET paragon_level = 50 WHERE guid = "..tguid
        )
        player:SendBroadcastMessage(
            "|cffFFD700[Admin]|r "..target:GetName().." Paragon Level set to 50.")
        target:SendBroadcastMessage(
            "|cffFFD700[Paragon]|r A GM set your Paragon Level to |cff00FF0050|r.")

    elseif action == ACT_ADMIN_RESETBOARD then
        CharDBExecute("DELETE FROM character_paragon_nodes WHERE guid = "..tguid)
        CharDBExecute("DELETE FROM character_paragon_glyphs WHERE guid = "..tguid)
        CharDBExecute("UPDATE character_paragon SET board_points = 0 WHERE guid = "..tguid)
        player:SendBroadcastMessage(
            "|cffFFD700[Admin]|r All boards reset for "..target:GetName()..".")
        target:SendBroadcastMessage(
            "|cffFF4444[Paragon Board]|r A GM reset all your boards.")

    elseif action == ACT_ADMIN_RESETPRES then
        CharDBExecute(
            "UPDATE character_paragon SET prestige_count = 0 WHERE guid = "..tguid
        )
        player:SendBroadcastMessage(
            "|cffFFD700[Admin]|r "..target:GetName().." prestige reset to 0.")
        target:SendBroadcastMessage(
            "|cffFF4444[Paragon]|r A GM reset your Prestige Rank to 0.")

    elseif action == ACT_ADMIN_GRANTCACHE then
        target:AddItem(GetCFG().ItemCacheEntry, 1)
        player:SendBroadcastMessage(
            "|cffFFD700[Admin]|r Cache granted to "..target:GetName()..".")
        target:SendBroadcastMessage(
            "|cffFFD700[Paragon]|r A GM granted you a |cff00FF00Cache of Synival's Treasures|r!")
    end

    ShowAdminPanel(player, creature)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BOARD PAGE RENDERERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function ShowBoardList(player, creature, pdata)
    local guid  = player:GetGUIDLow()
    pdata       = pdata or GetParagonData(guid)
    local cd    = GetClassInfo(player)
    if not pdata then player:GossipComplete(); return end

    local boards = GetAccessibleBoards(player, pdata.level, pdata.prestige)

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT, StatusStrip(pdata, cd), 0, ACT_BACK)

    if #boards == 0 then
        player:GossipMenuAddItem(ICON_CHAT,
            "|cff888888No boards unlocked yet. Reach Paragon 1 to begin.|r",
            0, ACT_CLOSE)
    else
        for _, board in ipairs(boards) do
            local nodes    = GetBoardNodes(board.id)
            local unlocked = GetUnlockedNodes(guid, board.id)
            local total, own = 0, 0
            for _, n in ipairs(nodes) do
                if n.ntype ~= 4 then
                    total = total + 1
                    if unlocked[n.id] then own = own + 1 end
                end
            end
            local displayName = board.btype > 0
                and ClassColor(cd, board.name)
                or  "|cffFFD700"..board.name.."|r"
            local label = displayName.."  ["..own.."/"..total.."]"
            player:GossipMenuAddItem(ICON_INTERACT1, label,
                board.id, EncAction(BGA_BOARD_OVERVIEW))
        end
    end

    player:GossipMenuAddItem(ICON_CHAT, "[Back to Archive]", 0, ACT_BACK)
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowBoardOverview(player, creature, boardId)
    local guid    = player:GetGUIDLow()
    local pdata   = GetParagonData(guid)
    local cd      = GetClassInfo(player)
    if not pdata then player:GossipComplete(); return end

    local nodes, byCoord = GetBoardNodes(boardId)
    local unlocked       = GetUnlockedNodes(guid, boardId)
    local socketed       = GetSocketedGlyphIds(guid, boardId)
    local adjacentSet    = IsAdjacent(nodes, unlocked)

    local boardName, boardWidth, boardHeight, boardType = "Board "..boardId, 7, 7, 0
    local bq = WorldDBQuery(
        "SELECT name, width, height, board_type FROM paragon_boards "..
        "WHERE board_id = "..boardId.." LIMIT 1"
    )
    if bq then
        boardName   = bq:GetString(0)
        boardWidth  = bq:GetUInt32(1)
        boardHeight = bq:GetUInt32(2)
        boardType   = bq:GetUInt32(3)
    end

    local total, own, sockets, nsocketed = 0, 0, 0, 0
    for _, n in ipairs(nodes) do
        if n.ntype ~= 4 then
            total = total + 1
            if unlocked[n.id] then own = own + 1 end
            if n.ntype == 3 then
                sockets = sockets + 1
                if socketed[n.id] then nsocketed = nsocketed + 1 end
            end
        end
    end

    local displayName = boardType > 0
        and ClassColor(cd, boardName)
        or  "|cffFFD700"..boardName.."|r"

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT, StatusStrip(pdata, cd),
        boardId, EncAction(BGA_BOARD_OVERVIEW))
    player:GossipMenuAddItem(ICON_CHAT,
        string.format("%s  %d/%d nodes   Glyphs %d/%d   Points: %d",
            displayName, own, total, nsocketed, sockets, pdata.board_points),
        boardId, EncAction(BGA_BOARD_OVERVIEW))

    for row = 0, boardHeight - 1 do
        local rowStr = "Row "..row.."  "..
            BuildGridRow(nodes, byCoord, unlocked, adjacentSet, boardWidth, row)
        player:GossipMenuAddItem(ICON_CHAT, rowStr, boardId, EncAction(BGA_BOARD_OVERVIEW))
    end

    player:GossipMenuAddItem(ICON_CHAT,
        "|cffFFD700[@]|rStart |cffaaaaaa[N]|rNorm |cff1eff00[M]|rMagic "..
        "|cff0070dd[R]|rRare |cffFFFF00[G]|rSocket |cff00FF00[+]|rAvail "..
        "|cff444444[?]|rLocked",
        boardId, EncAction(BGA_BOARD_OVERVIEW))

    player:GossipMenuAddItem(ICON_INTERACT1, "[Browse Nodes]",
        boardId, EncAction(BGA_NODE_LIST, 0, 0))
    player:GossipMenuAddItem(ICON_TRAINER, "[Manage Glyph Sockets]",
        boardId, EncAction(BGA_GLYPH_LIST))
    player:GossipMenuAddItem(ICON_CHAT, "[Back to Board List]",
        0, EncAction(BGA_BOARD_LIST))
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowNodeList(player, creature, boardId, pageOffset)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    local cd    = GetClassInfo(player)
    if not pdata then player:GossipComplete(); return end

    local nodes, _    = GetBoardNodes(boardId)
    local unlocked    = GetUnlockedNodes(guid, boardId)
    local adjacentSet = IsAdjacent(nodes, unlocked)
    local bp          = pdata.board_points

    local sorted = {}
    for _, n in ipairs(nodes) do
        if n.ntype ~= 4 then
            local isOwned   = unlocked[n.id] and true or false
            local isAdj     = adjacentSet[n.id] and true or false
            local cost      = NODE_COSTS[n.ntype] or 1
            local canAfford = (bp >= cost)
            local prio
            if     isOwned             then prio = 3
            elseif isAdj and canAfford then prio = 0
            elseif isAdj               then prio = 1
            else                            prio = 2
            end
            table.insert(sorted, {
                node=n, unlocked=isOwned, adjacent=isAdj,
                affordable=canAfford, prio=prio
            })
        end
    end
    table.sort(sorted, function(a, b) return a.prio < b.prio end)

    local boardName, boardType = "Board "..boardId, 0
    local bq = WorldDBQuery(
        "SELECT name, board_type FROM paragon_boards WHERE board_id = "..boardId.." LIMIT 1"
    )
    if bq then boardName = bq:GetString(0); boardType = bq:GetUInt32(1) end

    local displayName = boardType > 0
        and ClassColor(cd, boardName)
        or  "|cffFFD700"..boardName.."|r"

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        displayName.." — Nodes  (Points: "..bp..")",
        boardId, EncAction(BGA_BOARD_OVERVIEW))

    local shown, skipped = 0, 0
    for _, sn in ipairs(sorted) do
        if skipped < pageOffset then
            skipped = skipped + 1
        elseif shown < NODES_PER_PAGE then
            local label = FormatNodeEntry(sn.node, sn.unlocked, sn.adjacent, sn.affordable)
            player:GossipMenuAddItem(ICON_INTERACT1, label,
                boardId, EncAction(BGA_NODE_DETAIL, sn.node.id, pageOffset))
            shown = shown + 1
        end
    end

    if pageOffset > 0 then
        player:GossipMenuAddItem(ICON_CHAT, "< Previous Page",
            boardId, EncAction(BGA_NODE_LIST, 0, pageOffset - NODES_PER_PAGE))
    end
    if shown == NODES_PER_PAGE then
        player:GossipMenuAddItem(ICON_CHAT, "Next Page >",
            boardId, EncAction(BGA_NODE_LIST, 0, pageOffset + NODES_PER_PAGE))
    end

    player:GossipMenuAddItem(ICON_CHAT, "[Back to Board]",
        boardId, EncAction(BGA_BOARD_OVERVIEW))
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function ShowNodeDetail(player, creature, boardId, nodeId, returnPage)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    local cd    = GetClassInfo(player)
    if not pdata then player:GossipComplete(); return end

    local nodes, _    = GetBoardNodes(boardId)
    local unlocked    = GetUnlockedNodes(guid, boardId)
    local adjacentSet = IsAdjacent(nodes, unlocked)
    local bp          = pdata.board_points

    local node = nil
    for _, n in ipairs(nodes) do
        if n.id == nodeId then node = n; break end
    end
    if not node then ShowNodeList(player, creature, boardId, returnPage); return end

    local isOwned   = unlocked[node.id] and true or false
    local isAdj     = adjacentSet[node.id] and true or false
    local cost      = NODE_COSTS[node.ntype] or 1
    local canAfford = (bp >= cost)

    local boardName, boardType = "Board "..boardId, 0
    local bq = WorldDBQuery(
        "SELECT name, board_type FROM paragon_boards WHERE board_id = "..boardId.." LIMIT 1"
    )
    if bq then boardName = bq:GetString(0); boardType = bq:GetUInt32(1) end
    local displayBoard = boardType > 0
        and ClassColor(cd, boardName)
        or  "|cffFFD700"..boardName.."|r"

    player:GossipClearMenu()
    player:GossipMenuAddItem(ICON_CHAT,
        string.format("|cffFFD700%s|r  (%s)", node.name, displayBoard),
        boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    player:GossipMenuAddItem(ICON_CHAT,
        string.format("Type: %s   Cost: %d pt   Position: (%d,%d)",
            NODE_TYPE_NAME[node.ntype] or "?", cost, node.x, node.y),
        boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))

    if node.stat and node.stat > 0 then
        player:GossipMenuAddItem(ICON_CHAT, "Bonus: "..StatStr(node.stat, node.val),
            boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    end
    if node.desc and node.desc ~= "" then
        player:GossipMenuAddItem(ICON_CHAT, node.desc,
            boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    end

    if isOwned then
        player:GossipMenuAddItem(ICON_CHAT,
            "|cff00FF00[OWNED]|r This node is already unlocked.",
            boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    elseif not isAdj then
        player:GossipMenuAddItem(ICON_CHAT,
            "|cff666666[LOCKED]|r Unlock an adjacent node first.",
            boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    elseif not canAfford then
        player:GossipMenuAddItem(ICON_CHAT,
            string.format("|cffFF4444Insufficient points.|r Need %d, have %d.", cost, bp),
            boardId, EncAction(BGA_NODE_DETAIL, nodeId, returnPage))
    else
        player:GossipMenuAddItem(ICON_BATTLE,
            string.format("|cff00FF00[Unlock — %d pt]  %s|r", cost, node.name),
            boardId, EncAction(BGA_NODE_UNLOCK, nodeId, returnPage))
    end

    player:GossipMenuAddItem(ICON_CHAT, "[Back to Node List]",
        boardId, EncAction(BGA_NODE_LIST, 0, returnPage))
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function DoNodeUnlock(player, creature, boardId, nodeId, returnPage)
    local guid  = player:GetGUIDLow()
    local pdata = GetParagonData(guid)
    if not pdata then player:GossipComplete(); return end

    local nodes, _    = GetBoardNodes(boardId)
    local unlocked    = GetUnlockedNodes(guid, boardId)
    local adjacentSet = IsAdjacent(nodes, unlocked)

    local node = nil
    for _, n in ipairs(nodes) do
        if n.id == nodeId then node = n; break end
    end

    local cost = NODE_COSTS[node and node.ntype or 0] or 1

    if not node or unlocked[node.id] or not adjacentSet[node.id]
    or pdata.board_points < cost then
        ShowNodeList(player, creature, boardId, returnPage)
        return
    end

    CharDBExecute(
        "INSERT IGNORE INTO character_paragon_nodes (guid, board_id, node_id) "..
        "VALUES ("..guid..", "..boardId..", "..nodeId..")"
    )
    CharDBExecute(
        "UPDATE character_paragon SET board_points = board_points - "..cost..
        " WHERE guid = "..guid.." AND board_points >= "..cost
    )

    local cd = GetClassInfo(player)
    player:SendBroadcastMessage(
        string.format("|cffFFD700Paragon Board:|r %s — Unlocked |cff00FF00%s|r  (-%d pt)",
            ClassColor(cd, cd.name), node.name, cost)
    )
    ShowNodeList(player, creature, boardId, returnPage)
end

local function ShowGlyphList(player, creature, boardId)
    local guid   = player:GetGUIDLow()
    local cd     = GetClassInfo(player)
    local pdata  = GetParagonData(guid)
    local nodes, _ = GetBoardNodes(boardId)
    local unlocked = GetUnlockedNodes(guid, boardId)
    local socketed = GetSocketedGlyphIds(guid, boardId)
    local glyphs   = GetAllGlyphs()

    local boardName, boardType = "Board "..boardId, 0
    local bq = WorldDBQuery(
        "SELECT name, board_type FROM paragon_boards WHERE board_id = "..boardId.." LIMIT 1"
    )
    if bq then boardName = bq:GetString(0); boardType = bq:GetUInt32(1) end
    local displayBoard = boardType > 0
        and ClassColor(cd, boardName)
        or  "|cffFFD700"..boardName.."|r"

    player:GossipClearMenu()
    if pdata then
        player:GossipMenuAddItem(ICON_CHAT, StatusStrip(pdata, cd), 0, ACT_BACK)
    end
    player:GossipMenuAddItem(ICON_CHAT,
        displayBoard.."  — |cffFFD700Glyph Sockets|r",
        boardId, EncAction(BGA_GLYPH_LIST))

    local socketNodes = {}
    for _, n in ipairs(nodes) do
        if n.ntype == 3 then table.insert(socketNodes, n) end
    end

    if #socketNodes == 0 then
        player:GossipMenuAddItem(ICON_CHAT,
            "|cff888888This board has no Glyph Sockets.|r",
            boardId, EncAction(BGA_GLYPH_LIST))
    else
        for _, n in ipairs(socketNodes) do
            local isUnlocked = unlocked[n.id]
            local glyphId    = socketed[n.id]
            local glyph      = glyphId and glyphs[glyphId]

            if not isUnlocked then
                player:GossipMenuAddItem(ICON_CHAT,
                    string.format("|cff444444[LOCKED]|r  %s  (unlock node first)", n.name),
                    boardId, EncAction(BGA_GLYPH_LIST))
            elseif glyph then
                player:GossipMenuAddItem(ICON_TRAINER,
                    string.format("|cffFF8000[%s]|r  → |cff0070dd%s|r  %s",
                        n.name, glyph.name, GlyphBonusStr(glyph)),
                    boardId, EncAction(BGA_GLYPH_DETAIL, n.id))
                player:GossipMenuAddItem(ICON_BATTLE,
                    string.format("|cffFF4444  [Remove %s — item returned]|r", glyph.name),
                    boardId, EncAction(BGA_GLYPH_REMOVE, n.id))
            else
                -- Check for glyphs in player bags via inventory
                local hasAny = false
                for gid, g in pairs(glyphs) do
                    local iq = CharDBQuery(
                        "SELECT COUNT(*) FROM character_inventory ci "..
                        "JOIN item_instance ii ON ci.item = ii.guid "..
                        "WHERE ci.guid = "..guid.." AND ii.itemEntry = "..g.item_entry
                    )
                    local cnt = iq and iq:GetUInt32(0) or 0
                    if cnt > 0 then
                        hasAny = true
                        player:GossipMenuAddItem(ICON_TRAINER,
                            string.format("|cff00FF00[Socket]|r  %s  |cff0070dd%s|r  x%d  —  %s",
                                n.name, g.name, cnt, GlyphBonusStr(g)),
                            boardId, EncAction(BGA_GLYPH_SOCKET, n.id, gid))
                    end
                end
                if not hasAny then
                    player:GossipMenuAddItem(ICON_CHAT,
                        string.format("|cffFFFF00[EMPTY]|r  %s  |cff888888(no glyphs in bags)|r",
                            n.name),
                        boardId, EncAction(BGA_GLYPH_LIST))
                end
            end
        end
    end

    player:GossipMenuAddItem(ICON_CHAT, "[Back to Board]",
        boardId, EncAction(BGA_BOARD_OVERVIEW))
    player:GossipSendMenu(NPC_TEXT_ID, creature)
end

local function DoGlyphSocket(player, creature, boardId, socketNodeId, glyphId)
    local guid    = player:GetGUIDLow()
    local glyphs  = GetAllGlyphs()
    local glyph   = glyphs[glyphId]
    if not glyph then ShowGlyphList(player, creature, boardId); return end

    -- Check player has the glyph item
    local iq = CharDBQuery(
        "SELECT COUNT(*) FROM character_inventory ci "..
        "JOIN item_instance ii ON ci.item = ii.guid "..
        "WHERE ci.guid = "..guid.." AND ii.itemEntry = "..glyph.item_entry
    )
    if not iq or iq:GetUInt32(0) == 0 then
        player:SendBroadcastMessage("|cffFF4444[Glyph]|r You don't have that glyph in your bags.")
        ShowGlyphList(player, creature, boardId); return
    end

    -- Remove from inventory and insert socket record
    player:RemoveItem(glyph.item_entry, 1)
    CharDBExecute(
        "INSERT INTO character_paragon_glyphs (guid, board_id, node_id, glyph_id) "..
        "VALUES ("..guid..", "..boardId..", "..socketNodeId..", "..glyphId..") "..
        "ON DUPLICATE KEY UPDATE glyph_id = "..glyphId
    )
    player:SendBroadcastMessage(
        "|cffFFD700[Glyph Socketed]|r "..glyph.name.." socketed into board "..boardId..".")
    ShowGlyphList(player, creature, boardId)
end

local function DoGlyphRemove(player, creature, boardId, socketNodeId)
    local guid    = player:GetGUIDLow()
    local socketed = GetSocketedGlyphIds(guid, boardId)
    local glyphId  = socketed[socketNodeId]
    if not glyphId then ShowGlyphList(player, creature, boardId); return end

    local glyphs = GetAllGlyphs()
    local glyph  = glyphs[glyphId]

    CharDBExecute(
        "DELETE FROM character_paragon_glyphs "..
        "WHERE guid = "..guid.." AND board_id = "..boardId.." AND node_id = "..socketNodeId
    )

    -- Return item to player bags
    if glyph then
        player:AddItem(glyph.item_entry, 1)
        player:SendBroadcastMessage(
            "|cffFFD700[Glyph Removed]|r "..glyph.name.." returned to your bags.")
    end
    ShowGlyphList(player, creature, boardId)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MAIN EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════

local function OnHello(event, player, creature)
    ShowMainMenu(player, creature)
    return true   -- Return true to prevent default gossip window
end

local function OnSelect(event, player, creature, sender, intid, code, menuId)
    -- ── Board gossip actions ──────────────────────────────────────────────────
    if IsBoardAction(intid) then
        local page, nodeId, secondary = DecAction(intid)
        local boardId = sender

        if page == BGA_BOARD_LIST then
            ShowBoardList(player, creature)
        elseif page == BGA_BOARD_OVERVIEW then
            ShowBoardOverview(player, creature, boardId)
        elseif page == BGA_NODE_LIST then
            ShowNodeList(player, creature, boardId, secondary)
        elseif page == BGA_NODE_DETAIL then
            ShowNodeDetail(player, creature, boardId, nodeId, secondary)
        elseif page == BGA_NODE_UNLOCK then
            DoNodeUnlock(player, creature, boardId, nodeId, secondary)
        elseif page == BGA_GLYPH_LIST then
            ShowGlyphList(player, creature, boardId)
        elseif page == BGA_GLYPH_DETAIL then
            ShowGlyphList(player, creature, boardId)   -- detail collapses to list
        elseif page == BGA_GLYPH_SOCKET then
            DoGlyphSocket(player, creature, boardId, nodeId, secondary)
        elseif page == BGA_GLYPH_REMOVE then
            DoGlyphRemove(player, creature, boardId, nodeId)
        elseif page == BGA_BACK_TO_ARCHIVE then
            ShowMainMenu(player, creature)
        else
            ShowMainMenu(player, creature)
        end
        return true
    end

    -- ── Archive actions ───────────────────────────────────────────────────────
    if intid == ACT_CLOSE then
        player:GossipComplete()

    elseif intid == ACT_BACK then
        ShowMainMenu(player, creature)

    elseif intid == ACT_STATUS then
        ShowStatusPage(player, creature)

    elseif intid == ACT_SCALING then
        ShowScalingPage(player, creature)

    elseif intid == ACT_PRESTIGE_INFO then
        ShowPrestigeInfo(player, creature)

    elseif intid == ACT_PRESTIGE_CONFIRM then
        ShowPrestigeConfirm(player, creature)

    elseif intid == ACT_PRESTIGE_DO then
        DoPrestige(player, creature)

    elseif intid == ACT_ADMIN_PANEL then
        ShowAdminPanel(player, creature)

    elseif intid == ACT_ADMIN_GIVEPOINTS
        or intid == ACT_ADMIN_SETLEVEL50
        or intid == ACT_ADMIN_RESETBOARD
        or intid == ACT_ADMIN_RESETPRES
        or intid == ACT_ADMIN_GRANTCACHE then
        DoAdminAction(player, creature, intid)

    else
        ShowMainMenu(player, creature)
    end

    return true
end

-- ── Event registration ────────────────────────────────────────────────────────
RegisterCreatureGossipEvent(NPC_ENTRY, 1, OnHello)
RegisterCreatureGossipEvent(NPC_ENTRY, 2, OnSelect)

print("[SynParagon] synparagon_board.lua v3 loaded — sole gossip handler for NPC "..NPC_ENTRY)
