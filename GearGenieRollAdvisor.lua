-- GearGenie Roll Advisor
-- Shows score comparison on loot roll frames in dungeons

local rollAdvisors = {}   -- rollAdvisors[rollID] = advisor frame
local NUM_ROLL_FRAMES = 4 -- WoW 3.3.5 supports up to 4 simultaneous rolls

---------------------------------------------------------------------------
-- Attach an advisor frame below a GroupLootFrame
---------------------------------------------------------------------------
local function AttachRollAdvisor(rollID, parentFrame, isUpgrade, pctChange, equippedLink, newScore, equippedScore)
   -- Reuse or create advisor frame
   local advisor = rollAdvisors[rollID]
   if not advisor then
      advisor = CreateFrame("Frame", "GearGenieRollAdvisor" .. rollID, parentFrame)
      advisor:SetHeight(24)
      advisor:SetBackdrop({
         bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
         edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
         tile = true, tileSize = 16, edgeSize = 12,
         insets = { left = 3, right = 3, top = 3, bottom = 3 }
      })
      advisor:SetBackdropColor(0, 0, 0, 0.85)

      -- GearGenie label
      local label = advisor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      label:SetPoint("LEFT", advisor, "LEFT", 8, 0)
      label:SetTextColor(0, 0.898, 0.933) -- GearGenie cyan
      label:SetText("GG:")
      advisor.label = label

      -- Verdict text
      local verdictText = advisor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      verdictText:SetPoint("LEFT", label, "RIGHT", 4, 0)
      verdictText:SetPoint("RIGHT", advisor, "RIGHT", -8, 0)
      verdictText:SetJustifyH("LEFT")
      advisor.verdictText = verdictText

      rollAdvisors[rollID] = advisor
   end

   -- Anchor below the roll frame
   advisor:SetParent(parentFrame)
   advisor:ClearAllPoints()
   advisor:SetPoint("TOPLEFT", parentFrame, "BOTTOMLEFT", 0, -2)
   advisor:SetPoint("TOPRIGHT", parentFrame, "BOTTOMRIGHT", 0, -2)

   -- Build verdict string
   local modColor
   local verdictStr

   if equippedScore and equippedScore > 0 then
      if isUpgrade then
         modColor = { r = 0, g = 1, b = 0 }
         verdictStr = "+" .. pctChange .. "% upgrade (" .. round(newScore, 1) .. " vs " .. round(equippedScore, 1) .. ")"
      else
         modColor = { r = 1, g = 0, b = 0 }
         verdictStr = pctChange .. "% (" .. round(newScore, 1) .. " vs " .. round(equippedScore, 1) .. ")"
      end
   elseif newScore and newScore > 0 then
      modColor = { r = 0, g = 1, b = 0 }
      verdictStr = "Upgrade! Empty slot (Score: " .. round(newScore, 1) .. ")"
   else
      modColor = { r = 1, g = 1, b = 1 }
      verdictStr = "No score data"
   end

   advisor.verdictText:SetText(verdictStr)
   advisor.verdictText:SetTextColor(modColor.r, modColor.g, modColor.b)
   advisor:SetBackdropBorderColor(modColor.r, modColor.g, modColor.b, 0.7)
   advisor:Show()
end

---------------------------------------------------------------------------
-- Find the GroupLootFrame showing a given rollID
---------------------------------------------------------------------------
local function FindRollFrame(rollID)
   for i = 1, NUM_ROLL_FRAMES do
      local glFrame = _G["GroupLootFrame" .. i]
      if glFrame and glFrame:IsShown() and glFrame.rollID == rollID then
         return glFrame
      end
   end
   return nil
end

---------------------------------------------------------------------------
-- Show advisor for a loot roll
---------------------------------------------------------------------------
local function ShowRollAdvisor(rollID)
   if not GearGenieDB or not GearGenieDB.rollAdvisor then return end

   local itemLink = GetLootRollItemLink(rollID)
   if not itemLink then return end

   -- Use shared comparison helper (handles classID check, filters, scoring)
   local isUpgrade, pctChange, equippedLink, newScore, equippedScore = GearGenieCompareToEquipped(itemLink)
   if isUpgrade == nil then return end -- filtered or not comparable

   -- Find the roll frame; retry briefly if not shown yet
   local parentFrame = FindRollFrame(rollID)
   if parentFrame then
      AttachRollAdvisor(rollID, parentFrame, isUpgrade, pctChange, equippedLink, newScore, equippedScore)
   else
      -- START_LOOT_ROLL may fire before the frame is created; retry after a short delay
      local retryFrame = CreateFrame("Frame")
      local retryElapsed = 0
      retryFrame:SetScript("OnUpdate", function(self, dt)
         retryElapsed = retryElapsed + dt
         if retryElapsed >= 0.15 then
            self:SetScript("OnUpdate", nil)
            local frame = FindRollFrame(rollID)
            if frame then
               AttachRollAdvisor(rollID, frame, isUpgrade, pctChange, equippedLink, newScore, equippedScore)
            end
         end
      end)
   end
end

---------------------------------------------------------------------------
-- Event Registration
---------------------------------------------------------------------------
local rollEventFrame = CreateFrame("Frame")
rollEventFrame:RegisterEvent("START_LOOT_ROLL")
rollEventFrame:SetScript("OnEvent", function(self, event, rollID, rollTime)
   ShowRollAdvisor(rollID)
end)

---------------------------------------------------------------------------
-- Cleanup: hook GroupLootFrame OnHide to remove advisors
---------------------------------------------------------------------------
for i = 1, NUM_ROLL_FRAMES do
   local glFrame = _G["GroupLootFrame" .. i]
   if glFrame then
      glFrame:HookScript("OnHide", function(self)
         for rollID, advisor in pairs(rollAdvisors) do
            if advisor:GetParent() == self then
               advisor:Hide()
               rollAdvisors[rollID] = nil
               break
            end
         end
      end)
   end
end
