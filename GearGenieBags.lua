-- GearGenie Bag Auto-Compare
-- Detects new items in bags, compares against equipped gear,
-- prints chat upgrades, and marks bag slots with green overlays

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local bagSnapshot = {}         -- bagSnapshot[bag][slot] = itemLink or nil
local upgradeMarkers = {}      -- upgradeMarkers["bag:slot"] = { bag, slot, pct, link, overlayFrame }
local initialized = false
local pendingRescan = false
local RESCAN_DELAY = 0.3       -- seconds; throttle rapid BAG_UPDATE events

---------------------------------------------------------------------------
-- Bag Snapshot
---------------------------------------------------------------------------
local function TakeBagSnapshot()
   table.wipe(bagSnapshot)
   for bag = 0, 4 do
      bagSnapshot[bag] = {}
      local numSlots = GetContainerNumSlots(bag)
      for slot = 1, numSlots do
         bagSnapshot[bag][slot] = GetContainerItemLink(bag, slot)
      end
   end
end

-- Returns list of genuinely new items: { { bag, slot, link }, ... }
-- Filters out items that simply moved between bag slots
local function DiffBags()
   local newItems = {}

   -- Build a set of all links that existed in the old snapshot
   local oldLinks = {}
   for bag = 0, 4 do
      if bagSnapshot[bag] then
         for slot, link in pairs(bagSnapshot[bag]) do
            if link then
               oldLinks[link] = (oldLinks[link] or 0) + 1
            end
         end
      end
   end

   -- Check current bags for links not present (or present in greater quantity)
   local currentCounts = {}
   for bag = 0, 4 do
      local numSlots = GetContainerNumSlots(bag)
      for slot = 1, numSlots do
         local currentLink = GetContainerItemLink(bag, slot)
         if currentLink then
            currentCounts[currentLink] = (currentCounts[currentLink] or 0) + 1
            -- If this link appears more times than before, it's new
            local oldCount = oldLinks[currentLink] or 0
            if currentCounts[currentLink] > oldCount then
               table.insert(newItems, { bag = bag, slot = slot, link = currentLink })
            end
         end
      end
   end

   return newItems
end

---------------------------------------------------------------------------
-- Overlay System
---------------------------------------------------------------------------

-- Find the bag item button frame for a given bag and slot
local function GetBagButtonFrame(bag, slot)
   for i = 1, NUM_CONTAINER_FRAMES do
      local frameName = "ContainerFrame" .. i
      local frame = _G[frameName]
      if frame and frame:IsShown() and frame:GetID() == bag then
         local numSlots = GetContainerNumSlots(bag)
         -- WoW bag buttons are numbered bottom-to-top
         local buttonIndex = numSlots - slot + 1
         return _G[frameName .. "Item" .. buttonIndex]
      end
   end
   return nil
end

local function CreateUpgradeOverlay(button)
   if not button then return nil end

   local overlay = CreateFrame("Frame", nil, button)
   overlay:SetAllPoints(button)
   overlay:SetFrameLevel(button:GetFrameLevel() + 5)

   -- Green arrow icon in top-right corner
   local arrow = overlay:CreateTexture(nil, "OVERLAY")
   arrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Green")
   arrow:SetWidth(16)
   arrow:SetHeight(16)
   arrow:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 2, 2)
   overlay.arrow = arrow

   -- Green glow border
   local glow = overlay:CreateTexture(nil, "OVERLAY")
   glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
   glow:SetBlendMode("ADD")
   glow:SetVertexColor(0, 1, 0, 0.5)
   glow:SetWidth(64)
   glow:SetHeight(64)
   glow:SetPoint("CENTER", overlay, "CENTER", 0, 0)
   overlay.glow = glow

   -- Percentage text at bottom
   local pctText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
   pctText:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 2)
   pctText:SetTextColor(0, 1, 0)
   overlay.pctText = pctText

   return overlay
end

function GearGenieRefreshBagOverlays()
   for key, marker in pairs(upgradeMarkers) do
      -- Hide existing overlay first
      if marker.overlayFrame then
         marker.overlayFrame:Hide()
      end

      -- Verify the item is still at this bag:slot
      local currentLink = GetContainerItemLink(marker.bag, marker.slot)
      if not currentLink or currentLink ~= marker.link then
         -- Item moved/removed, clean up this marker
         if marker.overlayFrame then
            marker.overlayFrame:Hide()
         end
         upgradeMarkers[key] = nil
      else
         -- Try to find and attach to the bag button
         local button = GetBagButtonFrame(marker.bag, marker.slot)
         if button then
            if not marker.overlayFrame then
               marker.overlayFrame = CreateUpgradeOverlay(button)
            else
               marker.overlayFrame:SetParent(button)
               marker.overlayFrame:ClearAllPoints()
               marker.overlayFrame:SetAllPoints(button)
               marker.overlayFrame:SetFrameLevel(button:GetFrameLevel() + 5)
            end
            if marker.overlayFrame then
               marker.overlayFrame.pctText:SetText("+" .. marker.pct .. "%")
               marker.overlayFrame:Show()
            end
         end
      end
   end
end

function GearGenieMarkBagSlot(bag, slot, pct, itemLink)
   local key = bag .. ":" .. slot
   -- Clean up any existing overlay at this slot
   if upgradeMarkers[key] and upgradeMarkers[key].overlayFrame then
      upgradeMarkers[key].overlayFrame:Hide()
   end
   upgradeMarkers[key] = { bag = bag, slot = slot, pct = pct, link = itemLink, overlayFrame = nil }
   GearGenieRefreshBagOverlays()
end

function GearGenieClearAllMarkers()
   for key, marker in pairs(upgradeMarkers) do
      if marker.overlayFrame then
         marker.overlayFrame:Hide()
      end
   end
   table.wipe(upgradeMarkers)
end

---------------------------------------------------------------------------
-- Process New Items
---------------------------------------------------------------------------
local function ProcessNewItem(bag, slot, itemLink)
   if not GearGenieDB or not GearGenieDB.autoCompare then return end

   local isUpgrade, pctChange, equippedLink, newScore, equippedScore = GearGenieCompareToEquipped(itemLink)
   if isUpgrade == nil then return end -- filtered or not comparable

   if isUpgrade then
      -- Popup notification
      GearGenieShowUpgradePopup(itemLink, pctChange, equippedLink)

      -- Mark the bag slot
      GearGenieMarkBagSlot(bag, slot, pctChange, itemLink)
   end
end

---------------------------------------------------------------------------
-- Event Handling with Throttle
---------------------------------------------------------------------------
local bagEventFrame = CreateFrame("Frame")
local rescanElapsed = 0

bagEventFrame:RegisterEvent("PLAYER_LOGIN")
bagEventFrame:RegisterEvent("BAG_UPDATE")

bagEventFrame:SetScript("OnEvent", function(self, event, ...)
   if event == "PLAYER_LOGIN" then
      -- Take initial snapshot after a short delay to let bags fully load
      local loginElapsed = 0
      self:SetScript("OnUpdate", function(self, dt)
         loginElapsed = loginElapsed + dt
         if loginElapsed >= 2.0 then
            self:SetScript("OnUpdate", nil)
            TakeBagSnapshot()
            initialized = true
         end
      end)
      return
   end

   if event == "BAG_UPDATE" then
      if not initialized then return end
      if not GearGenieDB or not GearGenieDB.autoCompare then return end

      -- Throttle: reset timer on each BAG_UPDATE, process after delay
      pendingRescan = true
      rescanElapsed = 0
      self:SetScript("OnUpdate", function(self, dt)
         rescanElapsed = rescanElapsed + dt
         if rescanElapsed >= RESCAN_DELAY then
            self:SetScript("OnUpdate", nil)
            if pendingRescan then
               pendingRescan = false
               local newItems = DiffBags()
               for _, item in ipairs(newItems) do
                  ProcessNewItem(item.bag, item.slot, item.link)
               end
               TakeBagSnapshot()
            end
         end
      end)
   end
end)

---------------------------------------------------------------------------
-- Periodic Overlay Refresh (for when bags open/close/scroll)
---------------------------------------------------------------------------
local overlayRefreshFrame = CreateFrame("Frame")
local overlayRefreshElapsed = 0

overlayRefreshFrame:SetScript("OnUpdate", function(self, dt)
   overlayRefreshElapsed = overlayRefreshElapsed + dt
   if overlayRefreshElapsed >= 0.5 then
      overlayRefreshElapsed = 0
      if next(upgradeMarkers) then
         GearGenieRefreshBagOverlays()
      end
   end
end)
