local compareItemStats = {}
local compareItemScore
local compareRunning = false
local savedGameTooltipState = {}

-- Populated dynamically by GearGenieApplyWeights() from GearGenieWeights.lua
statWeightTable = {}
customStatWeigths = {}

local invTypeToSlotNum = {
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

function GearGenieSetTooltip(link)

   compareRunning = true

   -- get current state of gametooltip
   --local ttstate = GameTooltip
   GearGenieGetCurrentGameTooltip()

   GearGenieTooltip:SetOwner(_G["GameTooltip"], "ANCHOR_BOTTOM");
	GearGenieTooltip:ClearLines()

   local tooltipItemScore = GearGenieReadItemStatsFromTooltip()

   local invslot = select(9, GetItemInfo(select(2, GameTooltip:GetItem())))

   GameTooltip:SetInventoryItem("player", invTypeToSlotNum[_G[invslot]])
   local equippedItemScore = GearGenieReadItemStatsFromTooltip()
   --equippedItemScore = 0

   --GearGenieTooltip:SetWidth(_G["GameTooltip"]:GetWidth())


   --GearGenieTooltip:SetHyperlink(select(2, GameTooltip:GetItem()))

   local modColor = GREEN_FONT_COLOR
   if(tooltipItemScore < equippedItemScore) then
      modColor = RED_FONT_COLOR
   end

   GearGenieTooltip:AddLine("GearGenie")
   GearGenieTooltip:AddDoubleLine("This Item:", tooltipItemScore, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, modColor.r, modColor.g, modColor.b);
   GearGenieTooltip:AddDoubleLine("Equipped:", equippedItemScore, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);

   local upgradeper = round(((tooltipItemScore - equippedItemScore) / math.abs(tooltipItemScore)) * 100, 2)
			--print("upgrade: " .. upgradeper .. "%")
			if upgradeper then
				GearGenieTooltip:AddDoubleLine("Change:",
				upgradeper.."%" or "nil",
				HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b,
				modColor.r, modColor.g, modColor.b)
			end

   GearGenieTooltip:SetBackdropBorderColor(modColor:GetRGB());

   GearGenieTooltip:AddLine("")
   --GearGenieTooltip:AddTexture("Interface/Icons/Spell_Frost_FrostArmor02", {width = 32, height = 32})


   --GameTooltip:AddTexture(texturePath)
   
   GearGenieTooltip:Show()


   -- restore old state of gametooltip
   GearGenieRestoreGameTooltip()

   compareRunning = false
   --local pattern = "|H(.-)|h"
   --local result = string.match(link, pattern)
   --print(result)
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

function GearGenieTooltipHook(tooltip)

   if compareRunning then return end

   local name, link = tooltip:GetItem()
	if not link then
		GearGeniePrint("No item link for "..name.." on "..tooltip:GetName())
		return
	end

   --only show for armor and weapons
   local itemdata = GetItemInfoInstant(tonumber(string.match(link, ":(%d+)")))
   if itemdata then
      if itemdata['classID'] == 2 or itemdata['classID'] == 4 then

         --here we do stuff

         GearGenieSetTooltip(link)
         --GearGenieReadItemStatsFromTooltip()

         --GearGenieGetItemStats(link)

         --depending on evaluation, set color of tooltip
         --tooltip:SetBackdropBorderColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
         --tooltip:AddDoubleLine("GearGenie", "Value", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
         
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

   if GearGenieDB.class and GearGenieDB.spec then
      GearGenieApplyWeights(GearGenieDB.class, GearGenieDB.spec)
   else
      local detectedClass, detectedSpec = GearGenieDetectClass()
      GearGenieDB.class = detectedClass
      GearGenieDB.spec = detectedSpec
      GearGenieApplyWeights(detectedClass, detectedSpec)
   end
end)

