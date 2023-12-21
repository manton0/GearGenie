local ggPrefixColor 
local compareItemStats = {}
local compareItemScore

local customStatWeigths = {
   [1] = {
      ["Name"] = "DPS",
      ["Match"] = "%((%d+[.,]%d+) " .. string.lower(DAMAGE_PER_SECOND) .. "%)",
      ["Weight"] = 1
   }
}

local statWeightTable = {
   [ITEM_MOD_AGILITY_SHORT] = 1,
   [ITEM_MOD_ATTACK_POWER_SHORT] = 1,
   [ITEM_MOD_BLOCK_RATING_SHORT] = 1,
   [ITEM_MOD_BLOCK_VALUE_SHORT] = 1,
   [ITEM_MOD_CRIT_MELEE_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_RANGED_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_SPELL_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_TAKEN_MELEE_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_TAKEN_RANGED_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_TAKEN_RATING_SHORT] = 1,
   [ITEM_MOD_CRIT_TAKEN_SPELL_RATING_SHORT] = 1,
   [ITEM_MOD_DAMAGE_PER_SECOND_SHORT] = 1,
   [ITEM_MOD_DEFENSE_SKILL_RATING_SHORT] = 1,
   [ITEM_MOD_DODGE_RATING_SHORT] = 1,
   [ITEM_MOD_EXPERTISE_RATING_SHORT] = 1,
   [ITEM_MOD_FERAL_ATTACK_POWER_SHORT] = 1,
   [ITEM_MOD_HASTE_MELEE_RATING_SHORT] = 1,
   [ITEM_MOD_HASTE_RANGED_RATING_SHORT] = 1,
   [ITEM_MOD_HASTE_RATING_SHORT] = 1,
   [ITEM_MOD_HEALTH_REGENERATION_SHORT] = 1,
   [ITEM_MOD_HEALTH_SHORT] = 1,
   [ITEM_MOD_HIT_MELEE_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_RANGED_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_SPELL_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_TAKEN_MELEE_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_TAKEN_RANGED_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_TAKEN_RATING_SHORT] = 1,
   [ITEM_MOD_HIT_TAKEN_SPELL_RATING_SHORT] = 1,
   [ITEM_MOD_INTELLECT_SHORT] = 1,
   [ITEM_MOD_MANA_REGENERATION_SHORT] = 1,
   [ITEM_MOD_MANA_SHORT] = 1,
   [ITEM_MOD_PARRY_RATING_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN0_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN1_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN2_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN3_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN4_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN5_SHORT] = 1,
   [ITEM_MOD_POWER_REGEN6_SHORT] = 1,
   [ITEM_MOD_RANGED_ATTACK_POWER_SHORT] = 1,
   [ITEM_MOD_RESILIENCE_RATING_SHORT] = 1,
   [ITEM_MOD_SPELL_DAMAGE_DONE_SHORT] = 1,
   [ITEM_MOD_SPELL_HEALING_DONE_SHORT] = 1,
   [ITEM_MOD_SPELL_PENETRATION_SHORT] = 1,
   [ITEM_MOD_SPELL_POWER_SHORT] = 1,
   [ITEM_MOD_SPIRIT_SHORT] = 1,
   [ITEM_MOD_STAMINA_SHORT] = 1,
   [ITEM_MOD_STRENGTH_SHORT] = 1  
}

function colorText(text)

   return "\124cff00E5EE" .. text .. "\124r"

end

function GearGeniePrint(text)
   DEFAULT_CHAT_FRAME:AddMessage(colorText("GearGenie: " .. text));
end

GearGeniePrint("loading...")

-- creating tooltip for temp storing of item data
local tooltipFrame = CreateFrame("GameTooltip", "GearGenieTooltip", UIParent, "GameTooltipTemplate")

function GearGenieSetTooltip(link)
   GearGenieTooltip:SetOwner(_G["GameTooltip"], "ANCHOR_BOTTOM");
	GearGenieTooltip:ClearLines()
   --GearGenieTooltip:SetHyperlink(link)

   GearGenieTooltip:SetBackdropBorderColor(GREEN_FONT_COLOR:GetRGB());


   GearGenieReadItemStatsFromTooltip()

   --GearGenieTooltip:SetWidth(_G["GameTooltip"]:GetWidth())

   GearGenieTooltip:AddLine("GearGenie")
   GearGenieTooltip:AddDoubleLine("This Item:", compareItemScore, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
   GearGenieTooltip:AddDoubleLine("Equipped:", "Value", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);


   --GameTooltip:AddTexture(texturePath)
   
   GearGenieTooltip:Show()

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


function GearGenieReadItemStatsFromTooltip()

   compareItemScore = 0

   for i = 1, GameTooltip:NumLines() do
		local lineText = getglobal("GameTooltipTextLeft"..i)	
		if (lineText) then

         local getText = lineText:GetText();
			if(getText == nil) then getText = "0,0" end

         local text = select(1,string.gsub(trim(getText),",",""));

         for k,v in pairs(statWeightTable) do
            local result = string.match(text, "%+(%d+) " .. k)
            if result then
               --print(result .. ' ' .. ITEM_MOD_STRENGTH_SHORT)
               compareItemScore = compareItemScore + result * v
            end
         end

         for k,v in pairs(customStatWeigths) do
            local result = string.match(text, v["Match"])
            if result then
               --print(result .. ' ' .. ITEM_MOD_STRENGTH_SHORT)
               compareItemScore = compareItemScore + result * v["Weight"]
            end
         end

         --print(text)
      end
   end

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
ShoppingTooltip1:HookScript("OnTooltipSetItem", GearGenieTooltipHook)
ShoppingTooltip2:HookScript("OnTooltipSetItem", GearGenieTooltipHook)
ItemRefTooltip:HookScript("OnTooltipSetItem", GearGenieTooltipHook)

GameTooltip:HookScript("OnHide", GearGenieTooltipHide)
ShoppingTooltip1:HookScript("OnHide", GearGenieTooltipHide)
ShoppingTooltip2:HookScript("OnHide", GearGenieTooltipHide)
ItemRefTooltip:HookScript("OnHide", GearGenieTooltipHide)

