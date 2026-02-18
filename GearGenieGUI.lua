-- GearGenie GUI
-- AceGUI-based config window with TreeGroup navigation

local AceGUI = LibStub("AceGUI-3.0")

local mainFrame = nil
local treeGroup = nil

---------------------------------------------------------------------------
-- Forward declarations
---------------------------------------------------------------------------
local DrawGeneralPanel
local DrawFiltersPanel
local DrawComparePanel
local DrawWeightsPanel
local DrawAboutPanel

---------------------------------------------------------------------------
-- Compare panel: persistent state & UI
---------------------------------------------------------------------------
local compareLeftLink = nil
local compareRightLink = nil
local compareFrame = nil       -- persistent raw frame for the compare UI
local compareStatRows = {}
local compareLeftSlot = nil
local compareRightSlot = nil
local compareStatsContainer = nil
local compareLeftScoreText = nil
local compareRightScoreText = nil
local compareVerdictText = nil
local compareDivider = nil
local compareHeaderLeft = nil
local compareHeaderCenter = nil
local compareHeaderRight = nil

---------------------------------------------------------------------------
-- Compare: stat row factory
---------------------------------------------------------------------------
local function CreateStatRow(parent, index)
   local row = CreateFrame("Frame", nil, parent)
   row:SetHeight(18)
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
-- Compare: update stat display
---------------------------------------------------------------------------
local function CompareUpdate()
   if not compareFrame then return end

   -- Hide all existing stat rows
   for _, row in ipairs(compareStatRows) do
      row:Hide()
   end

   -- Nothing to show
   if not compareLeftLink and not compareRightLink then
      compareLeftScoreText:SetText("")
      compareRightScoreText:SetText("")
      compareVerdictText:SetText("")
      compareDivider:Hide()
      return
   end

   -- Read stats
   local lScore, lStats = 0, {}
   local rScore, rStats = 0, {}

   if compareLeftLink then
      lScore, lStats = GearGenieReadItemStatsByLink(compareLeftLink)
   end
   if compareRightLink then
      rScore, rStats = GearGenieReadItemStatsByLink(compareRightLink)
   end

   -- Build sorted union of stat names
   local seen = {}
   local statOrder = {}
   for statName in pairs(lStats) do
      if not seen[statName] then
         seen[statName] = true
         table.insert(statOrder, statName)
      end
   end
   for statName in pairs(rStats) do
      if not seen[statName] then
         seen[statName] = true
         table.insert(statOrder, statName)
      end
   end
   table.sort(statOrder)

   -- Render stat rows
   for i, statName in ipairs(statOrder) do
      local row = compareStatRows[i]
      if not row then
         row = CreateStatRow(compareStatsContainer, i)
         compareStatRows[i] = row
      end

      local lv = lStats[statName] or 0
      local rv = rStats[statName] or 0

      row.centerLabel:SetText(statName)
      row.centerLabel:SetTextColor(1, 0.82, 0)

      row.leftVal:SetText(lv > 0 and tostring(lv) or "-")
      row.rightVal:SetText(rv > 0 and tostring(rv) or "-")

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

   -- Score summary
   compareDivider:Show()
   compareLeftScoreText:SetText("Score: " .. round(lScore, 1))
   compareRightScoreText:SetText("Score: " .. round(rScore, 1))

   if compareLeftLink and compareRightLink then
      if lScore > rScore then
         compareLeftScoreText:SetTextColor(0, 1, 0)
         compareRightScoreText:SetTextColor(1, 0, 0)
         if math.abs(rScore) > 0 then
            local pct = round(((lScore - rScore) / math.abs(rScore)) * 100, 1)
            compareVerdictText:SetText("Left item is " .. pct .. "% better")
         else
            compareVerdictText:SetText("Left item is better")
         end
         compareVerdictText:SetTextColor(0, 1, 0)
      elseif rScore > lScore then
         compareLeftScoreText:SetTextColor(1, 0, 0)
         compareRightScoreText:SetTextColor(0, 1, 0)
         if math.abs(lScore) > 0 then
            local pct = round(((rScore - lScore) / math.abs(lScore)) * 100, 1)
            compareVerdictText:SetText("Right item is " .. pct .. "% better")
         else
            compareVerdictText:SetText("Right item is better")
         end
         compareVerdictText:SetTextColor(0, 1, 0)
      else
         compareLeftScoreText:SetTextColor(1, 1, 1)
         compareRightScoreText:SetTextColor(1, 1, 1)
         compareVerdictText:SetText("Items are equal")
         compareVerdictText:SetTextColor(1, 0.82, 0)
      end
   else
      compareLeftScoreText:SetTextColor(1, 1, 1)
      compareRightScoreText:SetTextColor(1, 1, 1)
      compareVerdictText:SetText("Place a second item to compare")
      compareVerdictText:SetTextColor(0.5, 0.5, 0.5)
   end
end

-- Keep backward compat for external callers
function GearGenieCompareUpdate()
   CompareUpdate()
end

---------------------------------------------------------------------------
-- Compare: item slot helpers
---------------------------------------------------------------------------
local function SetSlotItem(slot, itemLink, isLeft)
   if isLeft then
      compareLeftLink = itemLink
   else
      compareRightLink = itemLink
   end

   local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(itemLink)
   if texture then
      slot.icon:SetTexture(texture)
   end
   if name and quality then
      local r, g, b = GetItemQualityColor(quality)
      slot.label:SetText(name)
      slot.label:SetTextColor(r, g, b)
   end

   CompareUpdate()
end

local function ClearSlot(slot, isLeft)
   if isLeft then
      compareLeftLink = nil
   else
      compareRightLink = nil
   end
   slot.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
   slot.label:SetText("Drag item here")
   slot.label:SetTextColor(1, 1, 1)
   CompareUpdate()
end

local function SlotOnClick(self, button)
   if button == "RightButton" then
      ClearSlot(self, self.isLeft)
      return
   end

   local infoType, itemID, itemLink = GetCursorInfo()
   if infoType == "item" then
      local itemdata = GetItemInfoInstant(itemID)
      if itemdata and (itemdata['classID'] == 2 or itemdata['classID'] == 4) then
         SetSlotItem(self, itemLink, self.isLeft)
         ClearCursor()
      else
         GearGeniePrint("Only weapons and armor can be compared.")
      end
   end
end

local function SlotOnReceiveDrag(self)
   SlotOnClick(self, "LeftButton")
end

---------------------------------------------------------------------------
-- Compare: create item slot button
---------------------------------------------------------------------------
local function CreateItemSlot(parent, name, isLeft)
   local btn = CreateFrame("Button", name, parent)
   btn:SetWidth(37)
   btn:SetHeight(37)
   btn.isLeft = isLeft

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

   -- Hover tooltip
   btn:SetScript("OnEnter", function(self)
      local link = self.isLeft and compareLeftLink or compareRightLink
      if link then
         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
         GameTooltip:SetHyperlink(link)
         GameTooltip:Show()
      end
   end)
   btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

   -- Drag & drop
   btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
   btn:SetScript("OnClick", SlotOnClick)
   btn:SetScript("OnReceiveDrag", SlotOnReceiveDrag)

   return btn
end

---------------------------------------------------------------------------
-- Compare: build the persistent compare frame (lazy init)
---------------------------------------------------------------------------
local function EnsureCompareFrame()
   if compareFrame then return end

   compareFrame = CreateFrame("Frame", nil, UIParent)
   compareFrame:Hide()

   -- Item slot buttons
   compareLeftSlot = CreateItemSlot(compareFrame, "GearGenieCompareLeftSlot", true)
   compareLeftSlot:SetPoint("TOPLEFT", compareFrame, "TOPLEFT", 60, -16)

   compareRightSlot = CreateItemSlot(compareFrame, "GearGenieCompareRightSlot", false)
   compareRightSlot:SetPoint("TOPRIGHT", compareFrame, "TOPRIGHT", -60, -16)

   -- "vs" label between slots
   local vsLabel = compareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
   vsLabel:SetPoint("TOP", compareFrame, "TOP", 0, -28)
   vsLabel:SetText("vs")
   vsLabel:SetTextColor(0.7, 0.7, 0.7)

   -- Stats container
   compareStatsContainer = CreateFrame("Frame", nil, compareFrame)
   compareStatsContainer:SetPoint("TOPLEFT", compareFrame, "TOPLEFT", 10, -86)
   compareStatsContainer:SetPoint("TOPRIGHT", compareFrame, "TOPRIGHT", -10, -86)
   compareStatsContainer:SetHeight(260)

   -- Column headers
   compareHeaderLeft = compareStatsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   compareHeaderLeft:SetPoint("TOPLEFT", compareStatsContainer, "TOPLEFT", 10, 0)
   compareHeaderLeft:SetWidth(80)
   compareHeaderLeft:SetJustifyH("RIGHT")
   compareHeaderLeft:SetText("Left")
   compareHeaderLeft:SetTextColor(0.7, 0.7, 0.7)

   compareHeaderCenter = compareStatsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   compareHeaderCenter:SetPoint("TOP", compareStatsContainer, "TOP", 0, 0)
   compareHeaderCenter:SetWidth(160)
   compareHeaderCenter:SetJustifyH("CENTER")
   compareHeaderCenter:SetText("Stat")
   compareHeaderCenter:SetTextColor(0.7, 0.7, 0.7)

   compareHeaderRight = compareStatsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   compareHeaderRight:SetPoint("TOPRIGHT", compareStatsContainer, "TOPRIGHT", -10, 0)
   compareHeaderRight:SetWidth(80)
   compareHeaderRight:SetJustifyH("LEFT")
   compareHeaderRight:SetText("Right")
   compareHeaderRight:SetTextColor(0.7, 0.7, 0.7)

   -- Score summary (anchored to bottom of frame)
   compareDivider = compareFrame:CreateTexture(nil, "ARTWORK")
   compareDivider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
   compareDivider:SetHeight(16)
   compareDivider:SetPoint("BOTTOMLEFT", compareFrame, "BOTTOMLEFT", 10, 50)
   compareDivider:SetPoint("BOTTOMRIGHT", compareFrame, "BOTTOMRIGHT", -10, 50)

   compareLeftScoreText = compareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
   compareLeftScoreText:SetPoint("BOTTOMLEFT", compareFrame, "BOTTOMLEFT", 20, 25)

   compareRightScoreText = compareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
   compareRightScoreText:SetPoint("BOTTOMRIGHT", compareFrame, "BOTTOMRIGHT", -20, 25)

   compareVerdictText = compareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
   compareVerdictText:SetPoint("BOTTOM", compareFrame, "BOTTOM", 0, 6)

   -- Restore any previously set items (in case panel was re-drawn)
   if compareLeftLink then
      local _, _, quality, _, _, _, _, _, _, texture = GetItemInfo(compareLeftLink)
      if texture then compareLeftSlot.icon:SetTexture(texture) end
      local name = GetItemInfo(compareLeftLink)
      if name and quality then
         local r, g, b = GetItemQualityColor(quality)
         compareLeftSlot.label:SetText(name)
         compareLeftSlot.label:SetTextColor(r, g, b)
      end
   end
   if compareRightLink then
      local _, _, quality, _, _, _, _, _, _, texture = GetItemInfo(compareRightLink)
      if texture then compareRightSlot.icon:SetTexture(texture) end
      local name = GetItemInfo(compareRightLink)
      if name and quality then
         local r, g, b = GetItemQualityColor(quality)
         compareRightSlot.label:SetText(name)
         compareRightSlot.label:SetTextColor(r, g, b)
      end
   end
end

---------------------------------------------------------------------------
-- Compare: restore slot visuals when re-entering the compare tab
---------------------------------------------------------------------------
local function RefreshSlotVisuals()
   if compareLeftLink then
      local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(compareLeftLink)
      if texture then compareLeftSlot.icon:SetTexture(texture) end
      if name and quality then
         local r, g, b = GetItemQualityColor(quality)
         compareLeftSlot.label:SetText(name)
         compareLeftSlot.label:SetTextColor(r, g, b)
      end
   else
      compareLeftSlot.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
      compareLeftSlot.label:SetText("Drag item here")
      compareLeftSlot.label:SetTextColor(1, 1, 1)
   end

   if compareRightLink then
      local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(compareRightLink)
      if texture then compareRightSlot.icon:SetTexture(texture) end
      if name and quality then
         local r, g, b = GetItemQualityColor(quality)
         compareRightSlot.label:SetText(name)
         compareRightSlot.label:SetTextColor(r, g, b)
      end
   else
      compareRightSlot.icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
      compareRightSlot.label:SetText("Drag item here")
      compareRightSlot.label:SetTextColor(1, 1, 1)
   end
end

---------------------------------------------------------------------------
-- Tree definition
---------------------------------------------------------------------------
local function GetTreeStructure()
   return {
      { value = "general",  text = "General",      icon = "Interface\\Icons\\INV_Misc_Gear_01" },
      { value = "filters",  text = "Filters",      icon = "Interface\\Icons\\INV_Misc_EngGizmos_20" },
      { value = "compare",  text = "Compare",      icon = "Interface\\Icons\\INV_Misc_ArmorKit_17" },
      { value = "weights",  text = "Stat Weights",  icon = "Interface\\Icons\\INV_Scroll_02" },
      { value = "about",    text = "About",         icon = "Interface\\Icons\\INV_Misc_Book_09" },
   }
end

---------------------------------------------------------------------------
-- OnGroupSelected callback
---------------------------------------------------------------------------
local function OnGroupSelected(container, event, group)
   -- Always hide the compare frame when switching panels
   if compareFrame then
      compareFrame:Hide()
   end

   container:ReleaseChildren()

   if group == "general" then
      DrawGeneralPanel(container)
   elseif group == "filters" then
      DrawFiltersPanel(container)
   elseif group == "compare" then
      DrawComparePanel(container)
   elseif group == "weights" then
      DrawWeightsPanel(container)
   elseif group == "about" then
      DrawAboutPanel(container)
   end
end

---------------------------------------------------------------------------
-- Create / Toggle the main window
---------------------------------------------------------------------------
function GearGenieToggleMainWindow()
   if mainFrame then
      AceGUI:Release(mainFrame)
      mainFrame = nil
      treeGroup = nil
      return
   end

   mainFrame = AceGUI:Create("Window")
   mainFrame:SetTitle("GearGenie")
   mainFrame:SetWidth(620)
   mainFrame:SetHeight(450)
   mainFrame:SetLayout("Fill")
   mainFrame.frame:SetFrameStrata("HIGH")

   -- Escape key closes the window
   _G["GearGenieMainFrame"] = mainFrame.frame
   tinsert(UISpecialFrames, "GearGenieMainFrame")

   mainFrame:SetCallback("OnClose", function(widget)
      if compareFrame then compareFrame:Hide() end
      AceGUI:Release(widget)
      mainFrame = nil
      treeGroup = nil
   end)

   treeGroup = AceGUI:Create("TreeGroup")
   treeGroup:SetFullHeight(true)
   treeGroup:SetLayout("Fill")
   treeGroup:EnableButtonTooltips(false)
   treeGroup:SetTree(GetTreeStructure())
   treeGroup:SetCallback("OnGroupSelected", OnGroupSelected)
   mainFrame:AddChild(treeGroup)

   -- Default to General panel
   treeGroup:SelectByPath("general")
end

-- Open window and navigate to a specific tab
function GearGenieOpenToTab(tabValue)
   if not mainFrame then
      GearGenieToggleMainWindow()
   end
   if treeGroup then
      treeGroup:SelectByPath(tabValue)
   end
end

---------------------------------------------------------------------------
-- General Panel: Class/Spec selection
---------------------------------------------------------------------------
DrawGeneralPanel = function(container)
   local scroll = AceGUI:Create("ScrollFrame")
   scroll:SetLayout("List")
   scroll:SetFullWidth(true)
   scroll:SetFullHeight(true)
   container:AddChild(scroll)

   -- Header
   local heading = AceGUI:Create("Heading")
   heading:SetText("GearGenie Settings")
   heading:SetFullWidth(true)
   scroll:AddChild(heading)

   -- Detected class/spec label
   local detClass, detSpec = GearGenieDetectClass()
   local detLabel = AceGUI:Create("Label")
   detLabel:SetFullWidth(true)
   detLabel:SetText("Detected: " .. (GearGenieClassNames[detClass] or detClass) .. " - " .. detSpec)
   detLabel:SetColor(0.7, 0.7, 0.7)
   scroll:AddChild(detLabel)

   -- Spacer
   local spacer = AceGUI:Create("Label")
   spacer:SetFullWidth(true)
   spacer:SetText(" ")
   scroll:AddChild(spacer)

   -- Class & Spec heading
   local csHeading = AceGUI:Create("Heading")
   csHeading:SetText("Class & Spec")
   csHeading:SetFullWidth(true)
   scroll:AddChild(csHeading)

   -- Build class list
   local classList = {}
   local classTokens = {}
   for i, token in ipairs(GearGenieClassOrder) do
      classList[i] = GearGenieClassNames[token] or token
      classTokens[i] = token
   end

   -- Class Dropdown
   local classDropdown = AceGUI:Create("Dropdown")
   classDropdown:SetLabel("Class")
   classDropdown:SetFullWidth(true)
   classDropdown:SetList(classList)

   -- Set current value
   for i, token in ipairs(GearGenieClassOrder) do
      if token == (GearGenieDB and GearGenieDB.class or "") then
         classDropdown:SetValue(i)
         break
      end
   end

   -- Spec Dropdown (declared before class callback so it can be referenced)
   local specDropdown = AceGUI:Create("Dropdown")
   specDropdown:SetLabel("Spec")
   specDropdown:SetFullWidth(true)

   -- Helper to rebuild spec list
   local function RebuildSpecDropdown(classToken)
      local specs = GearGenieDefaultWeights[classToken]
      if not specs then
         specDropdown:SetList({})
         return
      end

      local specNames = {}
      for specName in pairs(specs) do
         table.insert(specNames, specName)
      end
      table.sort(specNames, function(a, b)
         if a == "None" then return true end
         if b == "None" then return false end
         return a < b
      end)

      local specList = {}
      local currentIdx = 1
      for i, name in ipairs(specNames) do
         specList[i] = name
         if name == (GearGenieDB and GearGenieDB.spec or "None") then
            currentIdx = i
         end
      end
      specDropdown:SetList(specList)
      specDropdown:SetValue(currentIdx)
   end

   classDropdown:SetCallback("OnValueChanged", function(widget, event, key)
      local token = classTokens[key]
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.class = token
      GearGenieDB.spec = "None"
      GearGenieApplyWeights(token, "None")
      RebuildSpecDropdown(token)
   end)
   scroll:AddChild(classDropdown)

   specDropdown:SetCallback("OnValueChanged", function(widget, event, key)
      local classToken = GearGenieDB and GearGenieDB.class or "WARRIOR"
      local specs = GearGenieDefaultWeights[classToken]
      if not specs then return end

      local specNames = {}
      for specName in pairs(specs) do
         table.insert(specNames, specName)
      end
      table.sort(specNames, function(a, b)
         if a == "None" then return true end
         if b == "None" then return false end
         return a < b
      end)

      local specName = specNames[key] or "None"
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.spec = specName
      GearGenieApplyWeights(GearGenieDB.class, specName)
   end)

   RebuildSpecDropdown(GearGenieDB and GearGenieDB.class or "WARRIOR")
   scroll:AddChild(specDropdown)
end

---------------------------------------------------------------------------
-- Filters Panel: Checkboxes
---------------------------------------------------------------------------
DrawFiltersPanel = function(container)
   local scroll = AceGUI:Create("ScrollFrame")
   scroll:SetLayout("List")
   scroll:SetFullWidth(true)
   scroll:SetFullHeight(true)
   container:AddChild(scroll)

   local h1 = AceGUI:Create("Heading")
   h1:SetText("Tooltip Filters")
   h1:SetFullWidth(true)
   scroll:AddChild(h1)

   local filterType = AceGUI:Create("CheckBox")
   filterType:SetLabel("Skip unusable item types")
   filterType:SetFullWidth(true)
   filterType:SetValue(GearGenieDB and GearGenieDB.filterType or false)
   filterType:SetCallback("OnValueChanged", function(w, e, val)
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.filterType = val
   end)
   scroll:AddChild(filterType)

   local filterLevel = AceGUI:Create("CheckBox")
   filterLevel:SetLabel("Skip items above my level")
   filterLevel:SetFullWidth(true)
   filterLevel:SetValue(GearGenieDB and GearGenieDB.filterLevel or false)
   filterLevel:SetCallback("OnValueChanged", function(w, e, val)
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.filterLevel = val
   end)
   scroll:AddChild(filterLevel)

   local h2 = AceGUI:Create("Heading")
   h2:SetText("Bag Scanner")
   h2:SetFullWidth(true)
   scroll:AddChild(h2)

   local autoCompare = AceGUI:Create("CheckBox")
   autoCompare:SetLabel("Auto-compare new bag items")
   autoCompare:SetFullWidth(true)
   autoCompare:SetValue(GearGenieDB and GearGenieDB.autoCompare or false)
   autoCompare:SetCallback("OnValueChanged", function(w, e, val)
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.autoCompare = val
      if not val and GearGenieClearAllMarkers then
         GearGenieClearAllMarkers()
      end
   end)
   scroll:AddChild(autoCompare)

   local h3 = AceGUI:Create("Heading")
   h3:SetText("Roll Advisor")
   h3:SetFullWidth(true)
   scroll:AddChild(h3)

   local rollAdvisor = AceGUI:Create("CheckBox")
   rollAdvisor:SetLabel("Show score on loot rolls")
   rollAdvisor:SetFullWidth(true)
   rollAdvisor:SetValue(GearGenieDB and GearGenieDB.rollAdvisor or false)
   rollAdvisor:SetCallback("OnValueChanged", function(w, e, val)
      if not GearGenieDB then GearGenieDB = {} end
      GearGenieDB.rollAdvisor = val
   end)
   scroll:AddChild(rollAdvisor)
end

---------------------------------------------------------------------------
-- Compare Panel: embedded drag-and-drop comparison
---------------------------------------------------------------------------
DrawComparePanel = function(container)
   EnsureCompareFrame()

   -- Reparent the persistent compare frame into the TreeGroup content area
   local parentFrame = container.content or container.frame
   compareFrame:SetParent(parentFrame)
   compareFrame:ClearAllPoints()
   compareFrame:SetAllPoints(parentFrame)
   compareFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 1)
   compareFrame:Show()

   -- Refresh slot visuals and stat display
   RefreshSlotVisuals()
   CompareUpdate()
end

---------------------------------------------------------------------------
-- Stat Weights Panel: Display current weight profile
---------------------------------------------------------------------------
DrawWeightsPanel = function(container)
   local scroll = AceGUI:Create("ScrollFrame")
   scroll:SetLayout("List")
   scroll:SetFullWidth(true)
   scroll:SetFullHeight(true)
   container:AddChild(scroll)

   local heading = AceGUI:Create("Heading")
   heading:SetText("Current Stat Weights")
   heading:SetFullWidth(true)
   scroll:AddChild(heading)

   local className = GearGenieDB and GearGenieDB.class or "?"
   local specName = GearGenieDB and GearGenieDB.spec or "?"
   local profileLabel = AceGUI:Create("Label")
   profileLabel:SetFullWidth(true)
   profileLabel:SetText("Profile: " .. (GearGenieClassNames[className] or className) .. " - " .. specName)
   scroll:AddChild(profileLabel)

   local spacer = AceGUI:Create("Label")
   spacer:SetFullWidth(true)
   spacer:SetText(" ")
   scroll:AddChild(spacer)

   local profile = GearGenieDefaultWeights[className]
      and GearGenieDefaultWeights[className][specName]

   if not profile then
      local noData = AceGUI:Create("Label")
      noData:SetFullWidth(true)
      noData:SetText("No weight profile found for this class/spec.")
      noData:SetColor(1, 0.3, 0.3)
      scroll:AddChild(noData)
      return
   end

   local keys = {}
   for k in pairs(profile) do
      table.insert(keys, k)
   end
   table.sort(keys)

   for _, key in ipairs(keys) do
      local w = profile[key]
      local label = AceGUI:Create("Label")
      label:SetFullWidth(true)

      if w > 1 then
         label:SetText("|cFF00FF00" .. key .. "|r: " .. w)
      elseif w > 0 then
         label:SetText("|cFFFFFF00" .. key .. "|r: " .. w)
      else
         label:SetText("|cFF888888" .. key .. ": " .. w .. "|r")
      end

      scroll:AddChild(label)
   end
end

---------------------------------------------------------------------------
-- About Panel: Version, author, commands
---------------------------------------------------------------------------
DrawAboutPanel = function(container)
   local scroll = AceGUI:Create("ScrollFrame")
   scroll:SetLayout("List")
   scroll:SetFullWidth(true)
   scroll:SetFullHeight(true)
   container:AddChild(scroll)

   local heading = AceGUI:Create("Heading")
   heading:SetText("GearGenie")
   heading:SetFullWidth(true)
   scroll:AddChild(heading)

   local version = AceGUI:Create("Label")
   version:SetFullWidth(true)
   version:SetText("Version: 1.3.0")
   scroll:AddChild(version)

   local author = AceGUI:Create("Label")
   author:SetFullWidth(true)
   author:SetText("Author: Discord: the_mazer")
   scroll:AddChild(author)

   local spacer = AceGUI:Create("Label")
   spacer:SetFullWidth(true)
   spacer:SetText(" ")
   scroll:AddChild(spacer)

   local cmdHeading = AceGUI:Create("Heading")
   cmdHeading:SetText("Slash Commands")
   cmdHeading:SetFullWidth(true)
   scroll:AddChild(cmdHeading)

   local commands = {
      "/gg - Toggle this window",
      "/gg compare - Open compare tab",
      "/gg clear - Clear bag upgrade markers",
      "/gg test - Show a test upgrade popup",
      "/gg help - Show this help",
   }

   for _, cmd in ipairs(commands) do
      local label = AceGUI:Create("Label")
      label:SetFullWidth(true)
      label:SetText(cmd)
      scroll:AddChild(label)
   end
end

---------------------------------------------------------------------------
-- Slash Commands
---------------------------------------------------------------------------
SLASH_GEARGENIE1 = "/gg"
SLASH_GEARGENIE2 = "/geargenie"

SlashCmdList["GEARGENIE"] = function(msg)
   msg = string.lower(trim(msg or ""))

   if msg == "" or msg == "config" then
      GearGenieToggleMainWindow()
   elseif msg == "compare" or msg == "cmp" then
      GearGenieOpenToTab("compare")
   elseif msg == "clear" then
      if GearGenieClearAllMarkers then
         GearGenieClearAllMarkers()
         GearGeniePrint("Bag upgrade markers cleared.")
      end
   elseif msg == "test" then
      GearGenieShowUpgradePopup(
         GetInventoryItemLink("player", 1) or "[Test Item]",
         12.5,
         GetInventoryItemLink("player", 2) or nil
      )
      GearGeniePrint("Test popup shown.")
   elseif msg == "help" then
      GearGeniePrint("Commands:")
      GearGeniePrint("  /gg - Toggle config window")
      GearGeniePrint("  /gg compare - Open compare tab")
      GearGeniePrint("  /gg clear - Clear bag upgrade markers")
      GearGeniePrint("  /gg test - Show a test upgrade popup")
      GearGeniePrint("  /gg help - Show this help")
   else
      GearGeniePrint("Unknown command. Type /gg help for usage.")
   end
end
