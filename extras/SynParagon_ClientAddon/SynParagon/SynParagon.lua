--[[============================================================================
    SynParagon.lua  — Client Addon
    ============================================================================
    CoffingQuest client addon. Injects colored tier labels into item tooltips.

    Tier labels injected below the item name (same position as "Heroic" on
    native Heroic dungeon loot):

      SynHeroic        — green
      Mythical         — blue
      Ascended         — purple
      Synival's Chosen — orange

    Requires the ItemRandomSuffix.dbc patch (patch-A.MPQ) to be installed.
    Without it the tooltip injection does nothing — the DBC patch is what
    appends the suffix text to the item name that this addon reads.

    Installation
    ────────────
    Drop the SynParagon folder into:
      World of Warcraft\Interface\AddOns\SynParagon\

    Note on the Paragon Board
    ─────────────────────────
    The Paragon Board UI (NPC 99996 — Runic Archive) is handled server-side
    by synparagon_board.lua running on the server via mod-ale (Eluna).
    This addon only handles the client-side tooltip tier labels.
============================================================================--]]

-- ── Tier definitions ──────────────────────────────────────────────────────────
-- key   = suffix string exactly as stored in ItemRandomSuffix.dbc
-- value = { label, r, g, b }  (0-1 float colors)

local TIERS = {
    ["SynHeroic"]        = { label = "SynHeroic",        r = 0.10, g = 1.00, b = 0.10 },
    ["Mythical"]         = { label = "Mythical",          r = 0.20, g = 0.60, b = 1.00 },
    ["Ascended"]         = { label = "Ascended",          r = 0.64, g = 0.21, b = 0.93 },
    ["Synival's Chosen"] = { label = "Synival's Chosen",  r = 1.00, g = 0.50, b = 0.00 },
}

-- ── Suffix detection ──────────────────────────────────────────────────────────
-- GetItemInfo returns the full name with suffix appended, e.g.:
--   "Ironbreaker, Edge of Warlords SynHeroic"
-- We match " <suffix>" at the end of the name string.

local function GetTierForLink(itemLink)
    if not itemLink then return nil end
    local itemName = GetItemInfo(itemLink)
    if not itemName then return nil end
    for suffix, tier in pairs(TIERS) do
        if itemName:match("%s+" .. suffix:gsub("'", "%%'") .. "$") then
            return tier
        end
    end
    return nil
end

-- ── Tooltip line injection ────────────────────────────────────────────────────
-- WoW tooltip frames don't support inserting lines — only appending.
-- We snapshot all existing lines, clear the tooltip, then re-add them
-- with our colored tier line injected at position 2 (below the item name).
-- This mirrors the position of the green "Heroic" line on Heroic dungeon loot.

local function InjectTierLine(tooltip, tier)
    local numLines = tooltip:NumLines()
    if numLines < 1 then return end

    local name = tooltip:GetName()

    -- Snapshot every line (left text + color, right text + color)
    local lines = {}
    for i = 1, numLines do
        local L = _G[name .. "TextLeft"  .. i]
        local R = _G[name .. "TextRight" .. i]
        if L then
            local lr, lg, lb = L:GetTextColor()
            local entry = {
                ltext = L:GetText() or "",
                lr = lr, lg = lg, lb = lb,
            }
            if R and R:GetText() then
                local rr, rg, rb = R:GetTextColor()
                entry.rtext = R:GetText()
                entry.rr = rr; entry.rg = rg; entry.rb = rb
            end
            lines[i] = entry
        end
    end

    -- Rebuild tooltip with tier line after line 1
    tooltip:ClearLines()
    for i = 1, numLines do
        local ln = lines[i]
        if not ln then break end

        if ln.rtext then
            tooltip:AddDoubleLine(ln.ltext, ln.rtext,
                ln.lr, ln.lg, ln.lb, ln.rr, ln.rg, ln.rb)
        else
            tooltip:AddLine(ln.ltext, ln.lr, ln.lg, ln.lb)
        end

        -- Inject tier label immediately after the item name (line 1)
        if i == 1 then
            tooltip:AddLine(tier.label, tier.r, tier.g, tier.b)
        end
    end
end

-- ── Hook handler ──────────────────────────────────────────────────────────────

local function OnTooltipSetItem(tooltip)
    local _, link = tooltip:GetItem()
    local tier = GetTierForLink(link)
    if tier then
        InjectTierLine(tooltip, tier)
    end
end

-- ── Register on all item-displaying tooltip frames ───────────────────────────

local tooltips = {
    GameTooltip,
    ItemRefTooltip,
    ShoppingTooltip1,
    ShoppingTooltip2,
}

for _, tt in ipairs(tooltips) do
    if tt and tt.HookScript then
        tt:HookScript("OnTooltipSetItem", OnTooltipSetItem)
    end
end
