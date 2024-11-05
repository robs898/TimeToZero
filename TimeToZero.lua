local container = CreateFrame("Frame", "TTZContainer", UIParent)
container:SetToplevel(true)
container:SetFrameStrata("DIALOG")
container:SetWidth(50)
container:SetHeight(50)
container:SetPoint("CENTER", UIParent, "CENTER")
container:EnableMouse(true)
container:SetMovable(true)
container:RegisterForDrag("LeftButton")
container:SetScript("OnDragStart", function() container:StartMoving() end)
container:SetScript("OnDragStop", function() container:StopMovingOrSizing() end)
container:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeSize = 0,
})
container:Hide()

local timeToZeroText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
timeToZeroText:SetPoint("CENTER", container, "CENTER")

local healthHistory = {}
local timeHistory = {}
local historyCount = 0
local lastHealth = nil

local function UpdateTimeToZeroText()
    if not UnitExists("target") or UnitIsDead("target") then
        return timeToZeroText:SetText("none")
    end

    local currentHealth = UnitHealth("target")
    if currentHealth == UnitHealthMax("target") then
        return timeToZeroText:SetText("full")
    end

    if not lastHealth then
        lastHealth = currentHealth
        healthHistory = {}
        timeHistory = {}
        table.insert(healthHistory, currentHealth)
        table.insert(timeHistory, GetTime())
        historyCount = 1
        return timeToZeroText:SetText("...")
    end

    if lastHealth < currentHealth then
        lastHealth = currentHealth
        return timeToZeroText:SetText("...")
    end

    table.insert(healthHistory, currentHealth)
    table.insert(timeHistory, GetTime())
    historyCount = historyCount + 1
    if historyCount < 2 then
        lastHealth = currentHealth
        return timeToZeroText:SetText("...")
    end

    local sumX, sumY, sumXY, sumXX = 0, 0, 0, 0
    for i = 1, historyCount do
        local x = timeHistory[i] - timeHistory[1]
        local y = healthHistory[i]
        sumX = sumX + x
        sumY = sumY + y
        sumXY = sumXY + x * y
        sumXX = sumXX + x * x
    end

    local slope = (historyCount * sumXY - sumX * sumY) / (historyCount * sumXX - sumX * sumX)
    local estimatedTimeToZero = currentHealth / -slope
    if estimatedTimeToZero < 0 then
        timeToZeroText:SetText("")
    else
        timeToZeroText:SetText(string.format("%.1f", estimatedTimeToZero))
    end

    lastHealth = currentHealth
end

container:RegisterEvent("PLAYER_TARGET_CHANGED")
container:RegisterEvent("UNIT_HEALTH")
container:SetScript("OnEvent", function()
    if event == "PLAYER_TARGET_CHANGED" then
        lastHealth = nil
        UpdateTimeToZeroText()
    end
    if event == "UNIT_HEALTH" and arg1 == "target" then
        UpdateTimeToZeroText()
    end
end)

SLASH_TTZ1 = "/ttz"
SlashCmdList["TTZ"] = function()
    if container:IsShown() then
        container:Hide()
    else
        container:Show()
    end
end
