-- GearGenie Config Window
-- Class/spec selection and settings

---------------------------------------------------------------------------
-- Main Frame
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "GearGenieConfigFrame", UIParent)
f:SetWidth(300)
f:SetHeight(330)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
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
f:SetBackdropColor(0, 0, 0, 0.9)
f:SetFrameStrata("DIALOG")
f:Hide()

tinsert(UISpecialFrames, "GearGenieConfigFrame")

-- Title
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", f, "TOP", 0, -16)
title:SetText("GearGenie")

-- Close button
local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() f:Hide() end)

-- Detected class label
local detectedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
detectedLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -42)
detectedLabel:SetTextColor(0.7, 0.7, 0.7)
detectedLabel:SetText("")

---------------------------------------------------------------------------
-- Class Dropdown
---------------------------------------------------------------------------
local classLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
classLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -62)
classLabel:SetText("Class:")

local classDropdown = CreateFrame("Frame", "GearGenieClassDropdown", f, "UIDropDownMenuTemplate")
classDropdown:SetPoint("TOPLEFT", classLabel, "TOPLEFT", 50, 8)
UIDropDownMenu_SetWidth(classDropdown, 170)

---------------------------------------------------------------------------
-- Spec Dropdown
---------------------------------------------------------------------------
local specLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
specLabel:SetPoint("TOPLEFT", classLabel, "BOTTOMLEFT", 0, -16)
specLabel:SetText("Spec:")

local specDropdown = CreateFrame("Frame", "GearGenieSpecDropdown", f, "UIDropDownMenuTemplate")
specDropdown:SetPoint("TOPLEFT", specLabel, "TOPLEFT", 50, 8)
UIDropDownMenu_SetWidth(specDropdown, 170)

---------------------------------------------------------------------------
-- Dropdown Logic
---------------------------------------------------------------------------
local selectedClass = nil
local selectedSpec = nil

local function UpdateSpecDropdown()
   UIDropDownMenu_Initialize(specDropdown, function(self, level)
      local specs = GearGenieDefaultWeights[selectedClass]
      if not specs then return end

      -- Collect and sort spec names
      local specNames = {}
      for specName in pairs(specs) do
         table.insert(specNames, specName)
      end
      table.sort(specNames, function(a, b)
         if a == "None" then return true end
         if b == "None" then return false end
         return a < b
      end)

      for _, specName in ipairs(specNames) do
         local info = UIDropDownMenu_CreateInfo()
         info.text = specName
         info.checked = (specName == selectedSpec)
         info.func = function()
            selectedSpec = specName
            UIDropDownMenu_SetText(specDropdown, specName)
            GearGenieDB.spec = specName
            GearGenieApplyWeights(selectedClass, selectedSpec)
         end
         UIDropDownMenu_AddButton(info, level)
      end
   end)
   UIDropDownMenu_SetText(specDropdown, selectedSpec or "None")
end

UIDropDownMenu_Initialize(classDropdown, function(self, level)
   for _, classToken in ipairs(GearGenieClassOrder) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = GearGenieClassNames[classToken] or classToken
      info.checked = (classToken == selectedClass)
      info.func = function()
         selectedClass = classToken
         UIDropDownMenu_SetText(classDropdown, GearGenieClassNames[classToken] or classToken)

         -- Reset spec to "None" when class changes
         selectedSpec = "None"
         GearGenieDB.class = classToken
         GearGenieDB.spec = "None"
         UpdateSpecDropdown()
         GearGenieApplyWeights(selectedClass, selectedSpec)
      end
      UIDropDownMenu_AddButton(info, level)
   end
end)

---------------------------------------------------------------------------
-- Filter Checkboxes
---------------------------------------------------------------------------
local filterTypeCheck = CreateFrame("CheckButton", "GearGenieFilterTypeCB", f, "UICheckButtonTemplate")
filterTypeCheck:SetPoint("TOPLEFT", specLabel, "BOTTOMLEFT", -4, -24)
_G["GearGenieFilterTypeCBText"]:SetText("Skip unusable item types")
_G["GearGenieFilterTypeCBText"]:SetFontObject(GameFontNormalSmall)
filterTypeCheck:SetScript("OnClick", function(self)
   GearGenieDB.filterType = self:GetChecked() and true or false
end)

local filterLevelCheck = CreateFrame("CheckButton", "GearGenieFilterLevelCB", f, "UICheckButtonTemplate")
filterLevelCheck:SetPoint("TOPLEFT", filterTypeCheck, "BOTTOMLEFT", 0, -2)
_G["GearGenieFilterLevelCBText"]:SetText("Skip items above my level")
_G["GearGenieFilterLevelCBText"]:SetFontObject(GameFontNormalSmall)
filterLevelCheck:SetScript("OnClick", function(self)
   GearGenieDB.filterLevel = self:GetChecked() and true or false
end)

local autoCompareCheck = CreateFrame("CheckButton", "GearGenieAutoCompareCB", f, "UICheckButtonTemplate")
autoCompareCheck:SetPoint("TOPLEFT", filterLevelCheck, "BOTTOMLEFT", 0, -2)
_G["GearGenieAutoCompareCBText"]:SetText("Auto-compare new bag items")
_G["GearGenieAutoCompareCBText"]:SetFontObject(GameFontNormalSmall)
autoCompareCheck:SetScript("OnClick", function(self)
   GearGenieDB.autoCompare = self:GetChecked() and true or false
   if not GearGenieDB.autoCompare and GearGenieClearAllMarkers then
      GearGenieClearAllMarkers()
   end
end)

local rollAdvisorCheck = CreateFrame("CheckButton", "GearGenieRollAdvisorCB", f, "UICheckButtonTemplate")
rollAdvisorCheck:SetPoint("TOPLEFT", autoCompareCheck, "BOTTOMLEFT", 0, -2)
_G["GearGenieRollAdvisorCBText"]:SetText("Show score on loot rolls")
_G["GearGenieRollAdvisorCBText"]:SetFontObject(GameFontNormalSmall)
rollAdvisorCheck:SetScript("OnClick", function(self)
   GearGenieDB.rollAdvisor = self:GetChecked() and true or false
end)

---------------------------------------------------------------------------
-- Compare Items Button
---------------------------------------------------------------------------
local compareBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
compareBtn:SetWidth(140)
compareBtn:SetHeight(24)
compareBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
compareBtn:SetText("Compare Items")
compareBtn:SetScript("OnClick", function()
   if GearGenieCompareFrame:IsShown() then
      GearGenieCompareFrame:Hide()
   else
      GearGenieCompareFrame:Show()
   end
end)

---------------------------------------------------------------------------
-- Sync UI state from saved variables on show
---------------------------------------------------------------------------
f:SetScript("OnShow", function()
   if GearGenieDB then
      selectedClass = GearGenieDB.class
      selectedSpec = GearGenieDB.spec
   end
   if not selectedClass then
      selectedClass, selectedSpec = GearGenieDetectClass()
   end

   UIDropDownMenu_SetText(classDropdown, GearGenieClassNames[selectedClass] or selectedClass)
   UpdateSpecDropdown()

   -- Sync filter checkboxes
   filterTypeCheck:SetChecked(GearGenieDB.filterType or false)
   filterLevelCheck:SetChecked(GearGenieDB.filterLevel or false)
   autoCompareCheck:SetChecked(GearGenieDB.autoCompare or false)
   rollAdvisorCheck:SetChecked(GearGenieDB.rollAdvisor or false)

   -- Show detected info
   local detClass, detSpec = GearGenieDetectClass()
   detectedLabel:SetText("Detected: " .. (GearGenieClassNames[detClass] or detClass) .. " - " .. detSpec)
end)

---------------------------------------------------------------------------
-- Slash Command: /gg opens config
---------------------------------------------------------------------------
SLASH_GEARGENIE1 = "/gg"
SLASH_GEARGENIE2 = "/geargenie"

SlashCmdList["GEARGENIE"] = function(msg)
   msg = string.lower(trim(msg or ""))

   if msg == "" or msg == "config" then
      if GearGenieConfigFrame:IsShown() then
         GearGenieConfigFrame:Hide()
      else
         GearGenieConfigFrame:Show()
      end
   elseif msg == "compare" or msg == "cmp" then
      if GearGenieCompareFrame:IsShown() then
         GearGenieCompareFrame:Hide()
      else
         GearGenieCompareFrame:Show()
      end
   elseif msg == "clear" then
      if GearGenieClearAllMarkers then
         GearGenieClearAllMarkers()
         GearGeniePrint("Bag upgrade markers cleared.")
      end
   elseif msg == "help" then
      GearGeniePrint("Commands:")
      GearGeniePrint("  /gg - Toggle config window")
      GearGeniePrint("  /gg compare - Toggle comparison window")
      GearGeniePrint("  /gg clear - Clear bag upgrade markers")
      GearGeniePrint("  /gg help - Show this help")
   else
      GearGeniePrint("Unknown command. Type /gg help for usage.")
   end
end
