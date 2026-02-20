local compareItemStats = {}
local compareItemScore
local compareRunning = false
local savedGameTooltipState = {}

-- Populated dynamically by GearGenieApplyWeights() from GearGenieWeights.lua
statWeightTable = {}
customStatWeigths = {}

GearGenieInvTypeToSlotNum = {
   [INVTYPE_AMMO] = 0,
   [INVTYPE_HEAD] = 1,
   [INVTYPE_NECK] = 2,
   [INVTYPE_SHOULDER] = 3,
   [INVTYPE_BODY] = 4,
   [INVTYPE_CHEST] = 5,
   [INVTYPE_ROBE] = 5,
   [INVTYPE_WAIST] = 6,
   [INVTYPE_LEGS] = 7,
   [INVTYPE_FEET] = 8,
   [INVTYPE_WRIST] = 9,
   [INVTYPE_HAND] = 10,
   [INVTYPE_FINGER] = 11, --{11, 12},
   [INVTYPE_TRINKET] = 13, --{13, 14},
   [INVTYPE_CLOAK] = 15,
   [INVTYPE_WEAPON] = 16, --{16, 17},
   [INVTYPE_SHIELD] = 17,
   [INVTYPE_2HWEAPON] = 16,
   [INVTYPE_WEAPONMAINHAND] = 16,
   [INVTYPE_WEAPONOFFHAND] = 17,
   [INVTYPE_HOLDABLE] = 17,
   [INVTYPE_RANGED] = 18,
   [INVTYPE_THROWN] = 18,
   [INVTYPE_RANGEDRIGHT] = 18,
   [INVTYPE_RELIC] = 18,
   [INVTYPE_TABARD] = 19,
   [INVTYPE_BAG] = {20, 21, 22, 23},
   [INVTYPE_QUIVER] = {20, 21, 22, 23},
}

-- Multi-slot equip locations (items that can go in more than one slot)
GearGenieMultiSlotMap = {
   [INVTYPE_FINGER]  = { 11, 12 },
   [INVTYPE_TRINKET] = { 13, 14 },
   [INVTYPE_WEAPON]  = { 16, 17 },
}

-- Human-readable labels for multi-slot inventory slots
local GearGenieSlotLabels = {
   [11] = "Ring 1",
   [12] = "Ring 2",
   [13] = "Trinket 1",
   [14] = "Trinket 2",
   [16] = "Main Hand",
   [17] = "Off Hand",
}

function colorText(text)

   return "\124cff00E5EE" .. text .. "\124r"

end

function GearGeniePrint(text)
   DEFAULT_CHAT_FRAME:AddMessage(colorText("GearGenie: " .. text));
end

GearGeniePrint("loading...")



local tooltipFrame = CreateFrame("GameTooltip", "GearGenieTooltip", UIParent, "GameTooltipTemplate")
local scanTooltip = CreateFrame("GameTooltip", "GearGenieScanTooltip", UIParent, "GameTooltipTemplate")

-- Find an item in bags by link, returns bag, slot or nil
function GearGenieFindInBags(itemLink)
   for bag = 0, 4 do
      local numSlots = GetContainerNumSlots(bag)
      for slot = 1, numSlots do
         local link = GetContainerItemLink(bag, slot)
         if link and link == itemLink then
            return bag, slot
         end
      end
   end
   return nil, nil
end

-- Find an item in equipped slots by link, returns inventory slot or nil
function GearGenieFindEquipped(itemLink)
   for invSlot = 0, 19 do
      local link = GetInventoryItemLink("player", invSlot)
      if link and link == itemLink then
         return invSlot
      end
   end
   return nil
end

function GearGenieReadItemStatsByLink(itemLink)
   GearGenieScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
   GearGenieScanTooltip:ClearLines()

   -- Try bag context first (shows scaled stats), then equipped, then fallback to hyperlink
   local bag, slot = GearGenieFindInBags(itemLink)
   if bag then
      GearGenieScanTooltip:SetBagItem(bag, slot)
   else
      local invSlot = GearGenieFindEquipped(itemLink)
      if invSlot then
         GearGenieScanTooltip:SetInventoryItem("player", invSlot)
      else
         GearGenieScanTooltip:SetHyperlink(itemLink)
      end
   end

   local score, stats = GearGenieReadItemStatsFromTooltip("GearGenieScanTooltip")
   GearGenieScanTooltip:Hide()
   return score, stats
end

-- Read the score of an equipped item directly by slot number.
-- Uses the hidden scan tooltip with SetInventoryItem.
local function readEquippedSlotScore(slotNum)
   GearGenieScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
   GearGenieScanTooltip:ClearLines()
   GearGenieScanTooltip:SetInventoryItem("player", slotNum)
   local score, stats = GearGenieReadItemStatsFromTooltip("GearGenieScanTooltip")
   GearGenieScanTooltip:Hide()
   return score, stats
end

-- Add small-font stat breakdown lines to the GearGenie sub-tooltip.
-- label: header text (e.g. "This Item" or "Main Hand")
-- stats: table of { statName = value } from GearGenieReadItemStatsFromTooltip
local function addStatBreakdown(label, stats)
   if not (GearGenieDB and GearGenieDB.detailedTooltip) then return end
   if not stats then return end

   local lines = {}
   -- Weighted stats
   for k, v in pairs(statWeightTable) do
      if stats[k] and stats[k] > 0 then
         table.insert(lines, { name = k, value = stats[k], weight = v })
      end
   end
   -- Custom stats (DPS, Armor, etc.)
   for k, v in pairs(customStatWeigths) do
      if stats[v["Name"]] and stats[v["Name"]] > 0 then
         table.insert(lines, { name = v["Name"], value = stats[v["Name"]], weight = v["Weight"] })
      end
   end

   if #lines == 0 then return end

   table.sort(lines, function(a, b) return (a.value * a.weight) > (b.value * b.weight) end)

   GearGenieTooltip:AddLine("  " .. label .. " stats:", 0.6, 0.6, 0.6)
   for _, entry in ipairs(lines) do
      GearGenieTooltip:AddDoubleLine(
         "    " .. entry.name,
         entry.value .. " x" .. round(entry.weight, 2) .. " = " .. round(entry.value * entry.weight, 2),
         0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
   end
end

function GearGenieSetTooltip(link)

   compareRunning = true

   -- Force Ascension's item scaling by triggering the built-in Shift-comparison
   -- flow. This primes the scaling cache so our subsequent reads return correct
   -- scaled values. Hide the shopping tooltips if Shift isn't held.
   if GameTooltip_ShowCompareItem then
      GameTooltip_ShowCompareItem()
      if not IsShiftKeyDown() then
         if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
         if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
         if ShoppingTooltip3 then ShoppingTooltip3:Hide() end
      end
   end

   GearGenieTooltip:SetOwner(_G["GameTooltip"], "ANCHOR_BOTTOM")
   GearGenieTooltip:ClearLines()

   -- Read the hovered item score from GameTooltip (set by the game, has correct scaled stats)
   local tooltipItemScore, tooltipItemStats = GearGenieReadItemStatsFromTooltip()

   local invslot = select(9, GetItemInfo(select(2, GameTooltip:GetItem())))
   local equipLoc = _G[invslot]
   local multiSlots = equipLoc and GearGenieMultiSlotMap[equipLoc]

   if multiSlots then
      -- Multi-slot item (weapon, ring, trinket): show all equipped slots
      local equippedScores = {}
      local worstScore = math.huge
      for _, slotNum in ipairs(multiSlots) do
         local slotLink = GetInventoryItemLink("player", slotNum)
         local score, stats = 0, nil
         if slotLink then
            score, stats = readEquippedSlotScore(slotNum)
         end
         table.insert(equippedScores, { slot = slotNum, score = score, stats = stats })
         if score < worstScore then
            worstScore = score
         end
      end

      -- Border color: green if the item beats at least the worst equipped slot
      local borderColor = GREEN_FONT_COLOR
      if tooltipItemScore < worstScore then
         borderColor = RED_FONT_COLOR
      end

      GearGenieTooltip:AddLine("GearGenie")
      GearGenieTooltip:AddDoubleLine("This Item:", round(tooltipItemScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
      addStatBreakdown("This Item", tooltipItemStats)

      for _, entry in ipairs(equippedScores) do
         local label = GearGenieSlotLabels[entry.slot] or ("Slot " .. entry.slot)
         -- Equipped score in white
         GearGenieTooltip:AddDoubleLine(label .. ":", round(entry.score, 2),
            HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
            HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
         addStatBreakdown(label, entry.stats)
         -- Change percentage in green/red
         local changeColor = GREEN_FONT_COLOR
         if tooltipItemScore < entry.score then
            changeColor = RED_FONT_COLOR
         end
         local pct = 0
         if entry.score > 0 then
            pct = round(((tooltipItemScore - entry.score) / math.abs(entry.score)) * 100, 2)
         elseif tooltipItemScore > 0 then
            pct = 100
         end
         GearGenieTooltip:AddDoubleLine("Change:",
            pct .. "%",
            HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
            changeColor.r, changeColor.g, changeColor.b)
      end

      GearGenieTooltip:SetBackdropBorderColor(borderColor:GetRGB())
   elseif equipLoc == INVTYPE_2HWEAPON and GetInventoryItemLink("player", 17) then
      -- 2H weapon while dual-wielding: combine both equipped weapon scores
      local mhScore, mhStats = readEquippedSlotScore(16)
      local ohScore, ohStats = readEquippedSlotScore(17)
      local combinedScore = mhScore + ohScore

      local modColor = GREEN_FONT_COLOR
      if tooltipItemScore < combinedScore then
         modColor = RED_FONT_COLOR
      end

      GearGenieTooltip:AddLine("GearGenie")
      GearGenieTooltip:AddDoubleLine("This Item:", round(tooltipItemScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         modColor.r, modColor.g, modColor.b)
      addStatBreakdown("This Item", tooltipItemStats)
      GearGenieTooltip:AddDoubleLine("Main Hand:", round(mhScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
      addStatBreakdown("Main Hand", mhStats)
      GearGenieTooltip:AddDoubleLine("Off Hand:", round(ohScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
      addStatBreakdown("Off Hand", ohStats)
      GearGenieTooltip:AddDoubleLine("Combined:", round(combinedScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)

      local pct = 0
      if combinedScore > 0 then
         pct = round(((tooltipItemScore - combinedScore) / math.abs(combinedScore)) * 100, 2)
      elseif tooltipItemScore > 0 then
         pct = 100
      end
      GearGenieTooltip:AddDoubleLine("Change:",
         pct .. "%",
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         modColor.r, modColor.g, modColor.b)

      GearGenieTooltip:SetBackdropBorderColor(modColor:GetRGB())
   else
      -- Single-slot item
      local slotNum = GearGenieInvTypeToSlotNum[equipLoc]
      local equippedItemScore, equippedItemStats = readEquippedSlotScore(slotNum)

      local modColor = GREEN_FONT_COLOR
      if tooltipItemScore < equippedItemScore then
         modColor = RED_FONT_COLOR
      end

      GearGenieTooltip:AddLine("GearGenie")
      GearGenieTooltip:AddDoubleLine("This Item:", round(tooltipItemScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         modColor.r, modColor.g, modColor.b)
      addStatBreakdown("This Item", tooltipItemStats)
      GearGenieTooltip:AddDoubleLine("Equipped:", round(equippedItemScore, 2),
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
         HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
      addStatBreakdown("Equipped", equippedItemStats)

      local upgradeper = round(((tooltipItemScore - equippedItemScore) / math.abs(tooltipItemScore)) * 100, 2)
      if upgradeper then
         GearGenieTooltip:AddDoubleLine("Change:",
            upgradeper .. "%",
            HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
            modColor.r, modColor.g, modColor.b)
      end

      GearGenieTooltip:SetBackdropBorderColor(modColor:GetRGB())
   end

   GearGenieTooltip:AddLine("")
   GearGenieTooltip:Show()

   compareRunning = false
end

function GearGenieTooltipHide()
   if GearGenieTooltip:IsVisible() then
      GearGenieTooltip:Hide()
   end
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
  end

function GearGenieGetCurrentGameTooltip() 
   
   table.wipe(savedGameTooltipState)
   
    for i = 1, GameTooltip:NumLines() do
        local fontNameL, fontSizeL = _G["GameTooltipTextLeft"..i]:GetFont()
        local fontNameR, fontSizeR = _G["GameTooltipTextRight"..i]:GetFont()
        local textL = getglobal("GameTooltipTextLeft"..i):GetText()
        local textR = getglobal("GameTooltipTextRight"..i):GetText()

        savedGameTooltipState[i] = {
         ["L"] = {
            ["Font"] = fontNameL,
            ["Size"] = fontSizeL,
            ["Text"] = textL,
            ["Color"] = {getglobal("GameTooltipTextLeft"..i):GetTextColor()}
         },
         ["R"] = {
            ["Font"] = fontNameR,
            ["Size"] = fontSizeR,
            ["Text"] = textR,
            ["Color"] = {getglobal("GameTooltipTextRight"..i):GetTextColor()}
         },
        }

    end

    --print(dump(savedGameTooltipState))

end

function GearGenieRestoreGameTooltip()

   GameTooltip:ClearLines()

   for k,v in pairs(savedGameTooltipState) do
      --print(k,v)
      if v["R"]["Text"] then
         GameTooltip:AddDoubleLine(v["L"]["Text"], v["R"]["Text"], v["L"]["Color"][1], v["L"]["Color"][2], v["L"]["Color"][3], v["R"]["Color"][1], v["R"]["Color"][2], v["R"]["Color"][3])
      else
         --unpack(v["L"]["Color"]) ???
         GameTooltip:AddLine(v["L"]["Text"], v["L"]["Color"][1], v["L"]["Color"][2], v["L"]["Color"][3], true)
      end
    end
end


function GearGenieReadItemStatsFromTooltip(tooltipName)

   tooltipName = tooltipName or "GameTooltip"
   local tooltip = _G[tooltipName]
   local score = 0
   local stats = {}

   for i = 1, tooltip:NumLines() do
      local lineText = _G[tooltipName .. "TextLeft" .. i]
      if (lineText) then

         local getText = lineText:GetText();
         if(getText == nil) then getText = "0,0" end

         local text = select(1,string.gsub(trim(getText),",",""));

         for k,v in pairs(statWeightTable) do
            local result = string.match(text, "%+(%d+) " .. k)
            if result then
               result = tonumber(result)
               stats[k] = (stats[k] or 0) + result
               score = score + result * v
            end
         end

         for k,v in pairs(customStatWeigths) do
            local result = string.match(text, v["Match"])
            if result then
               result = tonumber((string.gsub(result, ",", ".")))
               stats[v["Name"]] = (stats[v["Name"]] or 0) + result
               score = score + result * v["Weight"]
            end
         end
      end
   end

   return score, stats

end

function GearGenieGetItemStats(link)
   --GetItemStats("item:727:0:0:0:0:0:6946:0:3", compareItemStats)
   GetItemStats(link, compareItemStats)
   print(dump(compareItemStats))
   table.wipe(compareItemStats)

   local pattern = "|H(.-)|h"
   local result = string.match(link, pattern)
   print(result)
end

---------------------------------------------------------------------------
-- Upgrade Popup Notification System
---------------------------------------------------------------------------
local POPUP_DURATION   = 10    -- seconds before fade starts
local POPUP_FADE_TIME  = 1     -- seconds to fade out
local POPUP_HEIGHT     = 44
local POPUP_WIDTH      = 380
local POPUP_SPACING    = 4
local POPUP_MAX        = 4     -- max simultaneous popups

local activePopups = {}

local function RepositionPopups()
   local anchor = ChatFrame1 or DEFAULT_CHAT_FRAME
   for i, popup in ipairs(activePopups) do
      popup:ClearAllPoints()
      local yOffset = 10 + (i - 1) * (POPUP_HEIGHT + POPUP_SPACING)
      popup:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, yOffset)
   end
end

local function RemovePopup(popup)
   for i, p in ipairs(activePopups) do
      if p == popup then
         table.remove(activePopups, i)
         break
      end
   end
   popup:SetScript("OnUpdate", nil)
   popup:Hide()
   RepositionPopups()
end

local function FormatItemName(itemLink)
   if not itemLink then return "empty slot" end
   local name, _, quality = GetItemInfo(itemLink)
   if not name then return "?" end
   local r, g, b = GetItemQualityColor(quality or 1)
   return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, name)
end

local function CreatePopupFrame()
   local f = CreateFrame("Frame", nil, UIParent)
   f:SetWidth(POPUP_WIDTH)
   f:SetHeight(POPUP_HEIGHT)
   f:SetFrameStrata("HIGH")
   f:SetBackdrop({
      bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 }
   })
   f:SetBackdropColor(0, 0, 0, 0.85)
   f:SetBackdropBorderColor(0, 1, 0, 0.8)

   -- Item icon
   local icon = f:CreateTexture(nil, "ARTWORK")
   icon:SetWidth(28)
   icon:SetHeight(28)
   icon:SetPoint("LEFT", f, "LEFT", 8, 0)
   f.icon = icon

   -- GearGenie label
   local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 6, 0)
   label:SetTextColor(0, 0.898, 0.933) -- GearGenie cyan
   label:SetText("GearGenie")
   f.label = label

   -- Upgrade text
   local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
   text:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
   text:SetPoint("RIGHT", f, "RIGHT", -22, 0)
   text:SetJustifyH("LEFT")
   text:SetWordWrap(false)
   f.text = text

   -- Close button
   local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
   close:SetWidth(18)
   close:SetHeight(18)
   close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
   close:SetScript("OnClick", function() RemovePopup(f) end)

   -- Tooltip on hover
   f:EnableMouse(true)
   f:SetScript("OnEnter", function(self)
      if self.itemLink then
         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
         GameTooltip:SetHyperlink(self.itemLink)
         GameTooltip:Show()
      end
   end)
   f:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
   end)

   f:Hide()
   return f
end

function GearGenieShowUpgradePopup(itemLink, pctChange, equippedLink)
   -- Remove oldest if at max
   if #activePopups >= POPUP_MAX then
      RemovePopup(activePopups[1])
   end

   local popup = CreatePopupFrame()
   popup.itemLink = itemLink

   -- Set icon
   local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
   popup.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

   -- Build text
   local itemName = FormatItemName(itemLink)
   if equippedLink then
      local eqName = FormatItemName(equippedLink)
      popup.text:SetText(itemName .. "  |cff00ff00+" .. pctChange .. "%|r over " .. eqName)
   else
      popup.text:SetText(itemName .. "  |cff00ff00upgrade|r for empty slot!")
   end

   -- Add to stack and show
   table.insert(activePopups, popup)
   RepositionPopups()
   popup:SetAlpha(1)
   popup:Show()

   -- Auto-hide: wait POPUP_DURATION then fade over POPUP_FADE_TIME
   local elapsed = 0
   local fading = false
   popup:SetScript("OnUpdate", function(self, dt)
      elapsed = elapsed + dt
      if not fading and elapsed >= POPUP_DURATION then
         fading = true
         elapsed = 0
      end
      if fading then
         local alpha = 1 - (elapsed / POPUP_FADE_TIME)
         if alpha <= 0 then
            self:SetScript("OnUpdate", nil)
            RemovePopup(self)
         else
            self:SetAlpha(alpha)
         end
      end
   end)
end

---------------------------------------------------------------------------
-- Shared helpers for equipped item comparison (used by bags + roll advisor)
---------------------------------------------------------------------------

-- Returns a list of { slot = N, link = itemLink or nil } for the equipped
-- item(s) matching an equip location string (e.g. "INVTYPE_HEAD")
function GearGenieGetEquippedForSlot(equipLocGlobalName)
   local equipLoc = _G[equipLocGlobalName]
   if not equipLoc then return {} end

   local results = {}
   local multiSlots = GearGenieMultiSlotMap[equipLoc]
   if multiSlots then
      for _, slotNum in ipairs(multiSlots) do
         local link = GetInventoryItemLink("player", slotNum)
         table.insert(results, { slot = slotNum, link = link })
      end
   else
      local slotNum = GearGenieInvTypeToSlotNum[equipLoc]
      if slotNum and type(slotNum) == "number" then
         local link = GetInventoryItemLink("player", slotNum)
         table.insert(results, { slot = slotNum, link = link })
      end
   end
   return results
end

-- Compare an item against the equipped item(s) for its slot.
-- Returns: isUpgrade, pctChange, equippedLink, newScore, equippedScore
-- Returns nil if the item cannot be compared (not weapon/armor, filtered, no equip slot).
function GearGenieCompareToEquipped(itemLink)
   local itemID = tonumber(string.match(itemLink, ":(%d+)"))
   if not itemID then return nil end

   local itemdata = GetItemInfoInstant(itemID)
   if not itemdata then return nil end
   if itemdata['classID'] ~= 2 and itemdata['classID'] ~= 4 then return nil end

   -- Apply type filter
   if GearGenieDB and GearGenieDB.filterType then
      local _, _, _, _, _, _, itemSubType = GetItemInfo(itemID)
      local _, playerClass = UnitClass("player")
      if not GearGenieCanUseItem(playerClass, itemdata['classID'], itemSubType) then
         return nil
      end
   end

   -- Apply level filter
   if GearGenieDB and GearGenieDB.filterLevel then
      local _, _, _, _, reqLevel = GetItemInfo(itemID)
      if reqLevel and reqLevel > UnitLevel("player") then
         return nil
      end
   end

   -- Get equip location
   local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
   if not equipLoc or equipLoc == "" then return nil end

   -- Score the new item
   local newScore = GearGenieReadItemStatsByLink(itemLink)

   -- Find equipped item(s) for this slot
   local equippedSlots = GearGenieGetEquippedForSlot(equipLoc)
   if #equippedSlots == 0 then return nil end

   -- Separate equipped slots with items vs empty
   local equippedWithItems = {}
   for _, equipped in ipairs(equippedSlots) do
      if equipped.link then
         table.insert(equippedWithItems, equipped)
      end
   end

   -- 2H weapon while dual-wielding: combine both equipped weapon scores
   local is2HDualWield = false
   if _G[equipLoc] == INVTYPE_2HWEAPON then
      local ohLink = GetInventoryItemLink("player", 17)
      if ohLink and #equippedWithItems > 0 then
         is2HDualWield = true
      end
   end

   local worstScore, worstLink
   if #equippedWithItems == 0 then
      -- All slots empty: any item is an upgrade
      worstScore = 0
      worstLink = nil
   elseif is2HDualWield then
      -- Sum main hand + off hand scores since 2H replaces both
      local mhLink = GetInventoryItemLink("player", 16)
      local ohLink = GetInventoryItemLink("player", 17)
      local mhScore = mhLink and GearGenieReadItemStatsByLink(mhLink) or 0
      local ohScore = ohLink and GearGenieReadItemStatsByLink(ohLink) or 0
      worstScore = mhScore + ohScore
      worstLink = mhLink
   else
      -- Compare against the worst equipped item (the one you'd replace)
      worstScore = math.huge
      worstLink = nil
      for _, equipped in ipairs(equippedWithItems) do
         local eqScore = GearGenieReadItemStatsByLink(equipped.link)
         if eqScore < worstScore then
            worstScore = eqScore
            worstLink = equipped.link
         end
      end
   end

   local isUpgrade = newScore > worstScore
   local pctChange = 0
   if worstScore > 0 then
      pctChange = round(((newScore - worstScore) / math.abs(worstScore)) * 100, 1)
   elseif newScore > 0 then
      pctChange = 100
   end

   return isUpgrade, pctChange, worstLink, newScore, worstScore
end

---------------------------------------------------------------------------

function GearGenieTooltipHook(tooltip)

   if compareRunning then return end

   local name, link = tooltip:GetItem()
	if not link then
		GearGeniePrint("No item link for "..name.." on "..tooltip:GetName())
		return
	end

   --only show for armor and weapons
   local itemID = tonumber(string.match(link, ":(%d+)"))
   local itemdata = GetItemInfoInstant(itemID)
   if itemdata then
      if itemdata['classID'] == 2 or itemdata['classID'] == 4 then

         -- Filter: skip items the player's class cannot equip
         if GearGenieDB and GearGenieDB.filterType then
            local _, _, _, _, _, _, itemSubType = GetItemInfo(itemID)
            local _, playerClass = UnitClass("player")
            if not GearGenieCanUseItem(playerClass, itemdata['classID'], itemSubType) then
               return
            end
         end

         -- Filter: skip items above the player's level
         if GearGenieDB and GearGenieDB.filterLevel then
            local _, _, _, _, reqLevel = GetItemInfo(itemID)
            if reqLevel and reqLevel > UnitLevel("player") then
               return
            end
         end

         GearGenieSetTooltip(link)

      end
   end

end


GameTooltip:HookScript("OnTooltipSetItem", GearGenieTooltipHook)
GameTooltip:HookScript("OnHide", GearGenieTooltipHide)

---------------------------------------------------------------------------
-- Initialization: load saved or auto-detected weights on login
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
   if not GearGenieDB then GearGenieDB = {} end
   if GearGenieDB.filterType == nil then GearGenieDB.filterType = true end
   if GearGenieDB.filterLevel == nil then GearGenieDB.filterLevel = true end
   if GearGenieDB.autoCompare == nil then GearGenieDB.autoCompare = true end
   if GearGenieDB.rollAdvisor == nil then GearGenieDB.rollAdvisor = true end

   -- Always verify saved class matches the current character
   local detectedClass, detectedSpec = GearGenieDetectClass()
   if GearGenieDB.class and GearGenieDB.spec and GearGenieDB.class == detectedClass then
      GearGenieApplyWeights(GearGenieDB.class, GearGenieDB.spec)
   else
      GearGenieDB.class = detectedClass
      GearGenieDB.spec = detectedSpec
      GearGenieApplyWeights(detectedClass, detectedSpec)
   end
end)

