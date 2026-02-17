-- GearGenie Comparison Window
-- Drag two items to compare stats side-by-side

local statRows = {}

---------------------------------------------------------------------------
-- Main Frame
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "GearGenieCompareFrame", UIParent)
f:SetWidth(420)
f:SetHeight(450)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetBackdrop({
   bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
   edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
   tile = true, tileSize = 32, edgeSize = 32,
   insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
f:SetBackdropColor(0, 0, 0, 0.85)
f:SetFrameStrata("DIALOG")
f:Hide()

tinsert(UISpecialFrames, "GearGenieCompareFrame")

-- Title
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", f, "TOP", 0, -16)
title:SetText("GearGenie Compare")

-- Close button
local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() f:Hide() end)

---------------------------------------------------------------------------
-- Item Slot Buttons
---------------------------------------------------------------------------
local function CreateItemSlot(parent, name, anchorSide)
   local btn = CreateFrame("Button", name, parent)
   btn:SetWidth(37)
   btn:SetHeight(37)

   if anchorSide == "LEFT" then
      btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 60, -50)
   else
      btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -60, -50)
   end

   -- Border texture (item slot look)
   local border = btn:CreateTexture(nil, "OVERLAY")
   border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
   border:SetWidth(64)
   border:SetHeight(64)
   border:SetPoint("CENTER", btn, "CENTER", 0, 0)
   btn.border = border

   -- Icon texture
   local icon = btn:CreateTexture(nil, "ARTWORK")
   icon:SetAllPoints(btn)
   icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
   btn.icon = icon

   -- Item name label below icon
   local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
   label:SetPoint("TOP", btn, "BOTTOM", 0, -4)
   label:SetWidth(160)
   label:SetJustifyH("CENTER")
   label:SetText("Drag item here")
   btn.label = label

   -- State
   btn.itemLink = nil

   -- Hover tooltip
   btn:SetScript("OnEnter", function(self)
      if self.itemLink then
         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
         GameTooltip:SetHyperlink(self.itemLink)
         GameTooltip:Show()
      end
   end)
   btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

   return btn
end

local leftSlot  = CreateItemSlot(f, "GearGenieCompareLeftSlot",  "LEFT")
local rightSlot = CreateItemSlot(f, "GearGenieCompareRightSlot", "RIGHT")

---------------------------------------------------------------------------
-- Stats Container
---------------------------------------------------------------------------
local statsContainer = CreateFrame("Frame", nil, f)
statsContainer:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -120)
statsContainer:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -120)
statsContainer:SetHeight(260)

-- Column headers
local headerLeft = statsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerLeft:SetPoint("TOPLEFT", statsContainer, "TOPLEFT", 10, 0)
headerLeft:SetWidth(80)
headerLeft:SetJustifyH("RIGHT")
headerLeft:SetText("Left")
headerLeft:SetTextColor(0.7, 0.7, 0.7)

local headerCenter = statsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerCenter:SetPoint("TOP", statsContainer, "TOP", 0, 0)
headerCenter:SetWidth(160)
headerCenter:SetJustifyH("CENTER")
headerCenter:SetText("Stat")
headerCenter:SetTextColor(0.7, 0.7, 0.7)

local headerRight = statsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
headerRight:SetPoint("TOPRIGHT", statsContainer, "TOPRIGHT", -10, 0)
headerRight:SetWidth(80)
headerRight:SetJustifyH("LEFT")
headerRight:SetText("Right")
headerRight:SetTextColor(0.7, 0.7, 0.7)

---------------------------------------------------------------------------
-- Score Summary (anchored to bottom)
---------------------------------------------------------------------------
local divider = f:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
divider:SetHeight(16)
divider:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 65)
divider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 65)

local leftScoreText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
leftScoreText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 40, 35)

local rightScoreText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rightScoreText:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, 35)

local verdictText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
verdictText:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)

---------------------------------------------------------------------------
-- Stat Row Factory
---------------------------------------------------------------------------
local function CreateStatRow(parent, index)
   local row = CreateFrame("Frame", nil, parent)
   row:SetHeight(18)
   -- offset by 18 to skip header row
   row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(index * 18))
   row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -(index * 18))

   local leftVal = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
   leftVal:SetPoint("LEFT", row, "LEFT", 10, 0)
   leftVal:SetWidth(80)
   leftVal:SetJustifyH("RIGHT")
   row.leftVal = leftVal

   local centerLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   centerLabel:SetPoint("CENTER", row, "CENTER", 0, 0)
   centerLabel:SetWidth(160)
   centerLabel:SetJustifyH("CENTER")
   row.centerLabel = centerLabel

   local rightVal = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
   rightVal:SetPoint("RIGHT", row, "RIGHT", -10, 0)
   rightVal:SetWidth(80)
   rightVal:SetJustifyH("LEFT")
   row.rightVal = rightVal

   return row
end

---------------------------------------------------------------------------
-- Core Update Logic
---------------------------------------------------------------------------
function GearGenieCompareUpdate()
   -- Hide all existing stat rows
   for _, row in ipairs(statRows) do
      row:Hide()
   end

   -- Nothing to show
   if not leftSlot.itemLink and not rightSlot.itemLink then
      leftScoreText:SetText("")
      rightScoreText:SetText("")
      verdictText:SetText("")
      return
   end

   -- Read stats
   local lScore, lStats = 0, {}
   local rScore, rStats = 0, {}

   if leftSlot.itemLink then
      lScore, lStats = GearGenieReadItemStatsByLink(leftSlot.itemLink)
   end
   if rightSlot.itemLink then
      rScore, rStats = GearGenieReadItemStatsByLink(rightSlot.itemLink)
   end

   -- Build sorted union of stat names
   local seen = {}
   local statOrder = {}
   for statName, _ in pairs(lStats) do
      if not seen[statName] then
         seen[statName] = true
         table.insert(statOrder, statName)
      end
   end
   for statName, _ in pairs(rStats) do
      if not seen[statName] then
         seen[statName] = true
         table.insert(statOrder, statName)
      end
   end
   table.sort(statOrder)

   -- Render stat rows
   for i, statName in ipairs(statOrder) do
      local row = statRows[i]
      if not row then
         row = CreateStatRow(statsContainer, i)
         statRows[i] = row
      end

      local lv = lStats[statName] or 0
      local rv = rStats[statName] or 0

      row.centerLabel:SetText(statName)
      row.centerLabel:SetTextColor(1, 0.82, 0) -- gold

      row.leftVal:SetText(lv > 0 and tostring(lv) or "-")
      row.rightVal:SetText(rv > 0 and tostring(rv) or "-")

      -- Color: green = better side, red = worse, white = equal
      if lv > rv then
         row.leftVal:SetTextColor(0, 1, 0)
         row.rightVal:SetTextColor(1, 0, 0)
      elseif rv > lv then
         row.leftVal:SetTextColor(1, 0, 0)
         row.rightVal:SetTextColor(0, 1, 0)
      else
         row.leftVal:SetTextColor(1, 1, 1)
         row.rightVal:SetTextColor(1, 1, 1)
      end

      row:Show()
   end

   -- Resize frame to fit content
   local numStats = #statOrder
   local statsHeight = (numStats + 1) * 18 -- +1 for header
   local baseHeight = 200 -- title + slots + score area + padding
   f:SetHeight(baseHeight + statsHeight)
   statsContainer:SetHeight(statsHeight)

   -- Score summary
   leftScoreText:SetText("Score: " .. round(lScore, 1))
   rightScoreText:SetText("Score: " .. round(rScore, 1))

   if leftSlot.itemLink and rightSlot.itemLink then
      if lScore > rScore then
         leftScoreText:SetTextColor(0, 1, 0)
         rightScoreText:SetTextColor(1, 0, 0)
         if math.abs(rScore) > 0 then
            local pct = round(((lScore - rScore) / math.abs(rScore)) * 100, 1)
            verdictText:SetText("Left item is " .. pct .. "% better")
         else
            verdictText:SetText("Left item is better")
         end
         verdictText:SetTextColor(0, 1, 0)
      elseif rScore > lScore then
         leftScoreText:SetTextColor(1, 0, 0)
         rightScoreText:SetTextColor(0, 1, 0)
         if math.abs(lScore) > 0 then
            local pct = round(((rScore - lScore) / math.abs(lScore)) * 100, 1)
            verdictText:SetText("Right item is " .. pct .. "% better")
         else
            verdictText:SetText("Right item is better")
         end
         verdictText:SetTextColor(0, 1, 0)
      else
         leftScoreText:SetTextColor(1, 1, 1)
         rightScoreText:SetTextColor(1, 1, 1)
         verdictText:SetText("Items are equal")
         verdictText:SetTextColor(1, 0.82, 0)
      end
   else
      leftScoreText:SetTextColor(1, 1, 1)
      rightScoreText:SetTextColor(1, 1, 1)
      verdictText:SetText("Place a second item to compare")
      verdictText:SetTextColor(0.5, 0.5, 0.5)
   end
end

---------------------------------------------------------------------------
-- Drag & Drop Handling
---------------------------------------------------------------------------
local function SetSlotItem(slot, itemLink)
   slot.itemLink = itemLink

   local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
   if texture then
      slot.icon:SetTexture(texture)
   end
   if name and quality then
      local r, g, b = GetItemQualityColor(quality)
      slot.label:SetText(name)
      slot.label:SetTextColor(r, g, b)
   end

   GearGenieCompareUpdate()
end

local function ClearSlot(slot)
   slot.itemLink = nil
   slot.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
   slot.label:SetText("Drag item here")
   slot.label:SetTextColor(1, 1, 1)
   GearGenieCompareUpdate()
end

local function SlotOnClick(self, button)
   if button == "RightButton" then
      ClearSlot(self)
      return
   end

   local infoType, itemID, itemLink = GetCursorInfo()
   if infoType == "item" then
      local itemdata = GetItemInfoInstant(itemID)
      if itemdata and (itemdata['classID'] == 2 or itemdata['classID'] == 4) then
         SetSlotItem(self, itemLink)
         ClearCursor()
      else
         GearGeniePrint("Only weapons and armor can be compared.")
      end
   end
end

local function SlotOnReceiveDrag(self)
   SlotOnClick(self, "LeftButton")
end

leftSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
rightSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
leftSlot:SetScript("OnClick", SlotOnClick)
rightSlot:SetScript("OnClick", SlotOnClick)
leftSlot:SetScript("OnReceiveDrag", SlotOnReceiveDrag)
rightSlot:SetScript("OnReceiveDrag", SlotOnReceiveDrag)

-- Slash command is registered in GearGenieConfig.lua
-- /gg opens config, /gg compare opens this window
