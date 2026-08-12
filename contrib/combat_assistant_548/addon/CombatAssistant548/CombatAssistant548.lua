local ADDON_NAME = ...
local PREFIX = "CA548"

BINDING_HEADER_COMBATASSISTANT548_HEADER = "Combat Assistant 5.4.8"
BINDING_NAME_COMBATASSISTANT548_PRESS = "Use recommended ability"

local defaults = {
    shown = true,
    locked = true,
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = -180,
    scale = 1,
}

local reasonText = {
    RACIAL_ESCAPE = "Human racial: break crowd control",
    ESCAPE_CC = "Break crowd control",
    ESCAPE_MOVEMENT = "Break root / slow",
    EMERGENCY_HEAL = "Emergency instant heal (<15%)",
    INTERRUPT = "Interrupt",
    CLEANSE = "Cleanse poison / disease",
    BUFF = "Maintain Inquisition",
    TALENT = "Talent damage",
    EXECUTE = "Execute",
    SPEND = "Spend Holy Power",
    PROC = "Use proc",
    PROC_AOE = "Use Divine Crusader proc",
    BUILD = "Build Holy Power",
    NO_CAST = "Select an enemy or wait",
    DEAD = "Unavailable while dead",
    DISABLED = "Disabled on server",
    UNSUPPORTED = "Retribution Paladin only",
}

local state = {
    mode = "WAIT",
    spellId = 0,
    reason = "NO_CAST",
    holyPower = 0,
    lastServerUpdate = 0,
}

local frame
local button
local icon
local cooldown
local reasonLabel
local powerLabel
local lockLabel
local elapsed = 0

local function BindRecommendedAbilityToTwo(showMessage)
    if InCombatLockdown and InCombatLockdown() then
        if showMessage then
            print("Combat Assistant 5.4.8: leave combat, then use /ca548 bind2.")
        end
        return false
    end

    local ok = SetBinding("2", "COMBATASSISTANT548_PRESS")
    if not ok then
        if showMessage then
            print("Combat Assistant 5.4.8: could not bind key 2.")
        end
        return false
    end

    SaveBindings(GetCurrentBindingSet())
    CombatAssistant548DB.boundTwo = true
    if showMessage then
        print("Combat Assistant 5.4.8: recommended ability is bound to key 2.")
    end
    return true
end

local function UnbindRecommendedAbilityFromTwo()
    if InCombatLockdown and InCombatLockdown() then
        print("Combat Assistant 5.4.8: leave combat, then use /ca548 unbind2.")
        return
    end

    if GetBindingAction("2") == "COMBATASSISTANT548_PRESS" then
        SetBinding("2")
        SaveBindings(GetCurrentBindingSet())
    end
    CombatAssistant548DB.boundTwo = false
    print("Combat Assistant 5.4.8: key 2 is no longer bound to the assistant.")
end

local function CopyDefaults()
    CombatAssistant548DB = CombatAssistant548DB or {}
    for key, value in pairs(defaults) do
        if CombatAssistant548DB[key] == nil then
            CombatAssistant548DB[key] = value
        end
    end
end

local function SavePosition()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    CombatAssistant548DB.point = point
    CombatAssistant548DB.relativePoint = relativePoint
    CombatAssistant548DB.x = x
    CombatAssistant548DB.y = y
end

local function UpdateMovableState()
    local unlocked = not CombatAssistant548DB.locked
    frame:EnableMouse(unlocked)
    frame:SetMovable(unlocked)
    lockLabel:SetShown(unlocked)
end

local function UpdateDisplay()
    local spellName, _, spellTexture = nil, nil, nil
    if state.spellId and state.spellId > 0 then
        spellName, _, spellTexture = GetSpellInfo(state.spellId)
    end

    icon:SetTexture(spellTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
    powerLabel:SetText("HP " .. tostring(state.holyPower or 0))
    reasonLabel:SetText(reasonText[state.reason] or state.reason or "Waiting")

    if state.mode == "READY" and spellName then
        button:Enable()
        icon:SetDesaturated(false)
        if state.reason == "RACIAL_ESCAPE" or state.reason == "ESCAPE_CC" or
            state.reason == "ESCAPE_MOVEMENT" or state.reason == "EMERGENCY_HEAL" or
            state.reason == "CLEANSE" then
            button.border:SetVertexColor(1, 0.2, 0.2, 1)
        elseif state.reason == "INTERRUPT" then
            button.border:SetVertexColor(1, 0.75, 0.1, 1)
        else
            button.border:SetVertexColor(0.2, 1, 0.2, 1)
        end
    else
        button:Disable()
        icon:SetDesaturated(true)
        button.border:SetVertexColor(0.45, 0.45, 0.45, 1)
    end
end

local function ApplyServerMessage(message)
    local mode, spellId, reason, holyPower = strsplit("|", message)
    if not mode then
        return
    end

    state.mode = mode
    state.spellId = tonumber(spellId) or 0
    state.reason = reason or "NO_CAST"
    state.holyPower = tonumber(holyPower) or 0
    state.lastServerUpdate = GetTime()
    UpdateDisplay()
end

local function RequestCast()
    if state.mode ~= "READY" or not state.spellId or state.spellId == 0 then
        return
    end

    SendChatMessage(".combatassist cast", "SAY")
end

function CombatAssistant548_Press()
    RequestCast()
end

local function CreateUI()
    frame = CreateFrame("Frame", "CombatAssistant548Frame", UIParent)
    frame:SetSize(72, 96)
    frame:SetScale(CombatAssistant548DB.scale)
    frame:SetPoint(
        CombatAssistant548DB.point,
        UIParent,
        CombatAssistant548DB.relativePoint,
        CombatAssistant548DB.x,
        CombatAssistant548DB.y)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not CombatAssistant548DB.locked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    button = CreateFrame("Button", "CombatAssistant548Button", frame)
    button:SetSize(64, 64)
    button:SetPoint("TOP", frame, "TOP", 0, 0)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", RequestCast)

    icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints(button)
    button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.border:SetBlendMode("ADD")

    cooldown = CreateFrame("Cooldown", "CombatAssistant548Cooldown", button, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 4, -4)
    cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -4, 4)

    powerLabel = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    powerLabel:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
    powerLabel:SetTextColor(1, 0.9, 0.2)

    reasonLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    reasonLabel:SetWidth(150)
    reasonLabel:SetPoint("TOP", button, "BOTTOM", 0, -3)
    reasonLabel:SetTextColor(1, 1, 1)

    lockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockLabel:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    lockLabel:SetText("Unlocked: drag me")
    lockLabel:SetTextColor(1, 0.8, 0)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if state.spellId and state.spellId > 0 then
            GameTooltip:SetSpellByID(state.spellId)
        else
            GameTooltip:SetText("Combat Assistant 5.4.8")
            GameTooltip:AddLine(reasonText[state.reason] or "Waiting for server", 1, 1, 1)
        end
        GameTooltip:AddLine("One physical click requests one normal server-validated cast.", 0.7, 0.9, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    if CombatAssistant548DB.shown then
        frame:Show()
    else
        frame:Hide()
    end

    UpdateMovableState()
    UpdateDisplay()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedName = ...
        if loadedName ~= ADDON_NAME then
            return
        end
        CopyDefaults()
        CreateUI()
    elseif event == "PLAYER_LOGIN" then
        if RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(PREFIX)
        end
        if not CombatAssistant548DB.boundTwo then
            BindRecommendedAbilityToTwo(true)
        end
        SendChatMessage(".combatassist status", "SAY")
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message = ...
        if prefix == PREFIX then
            ApplyServerMessage(message)
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if state.spellId and state.spellId > 0 then
            local start, duration, enabled = GetSpellCooldown(state.spellId)
            if enabled == 1 and start and duration then
                CooldownFrame_SetTimer(cooldown, start, duration, 1)
            end
        end
    end
end)

eventFrame:SetScript("OnUpdate", function(self, delta)
    if not frame then
        return
    end

    elapsed = elapsed + delta
    if elapsed < 0.1 then
        return
    end
    elapsed = 0

    if state.spellId and state.spellId > 0 then
        local start, duration, enabled = GetSpellCooldown(state.spellId)
        if enabled == 1 and start and duration then
            CooldownFrame_SetTimer(cooldown, start, duration, 1)
        end
    end

    if state.lastServerUpdate > 0 and GetTime() - state.lastServerUpdate > 5 then
        reasonLabel:SetText("Waiting for server update")
    end
end)

SLASH_COMBATASSISTANT5481 = "/ca548"
SlashCmdList.COMBATASSISTANT548 = function(message)
    message = string.lower(message or "")
    if message == "show" then
        CombatAssistant548DB.shown = true
        frame:Show()
    elseif message == "hide" then
        CombatAssistant548DB.shown = false
        frame:Hide()
    elseif message == "unlock" then
        CombatAssistant548DB.locked = false
        UpdateMovableState()
    elseif message == "lock" then
        CombatAssistant548DB.locked = true
        UpdateMovableState()
    elseif message == "status" then
        SendChatMessage(".combatassist status", "SAY")
    elseif message == "bind2" then
        BindRecommendedAbilityToTwo(true)
    elseif message == "unbind2" then
        UnbindRecommendedAbilityFromTwo()
    else
        print("Combat Assistant 5.4.8: /ca548 show | hide | unlock | lock | status | bind2 | unbind2")
    end
end
