--[[
    PhaseSwitch - 面板与列表渲染（5.4.8）
]]

local ADDON, ns = ...

local FRAME_W = 430
local FRAME_H = 520
local ROW_H   = 54
local LIST_W  = FRAME_W - 32
local LIST_H  = 6 * ROW_H
local CHILD_W = LIST_W - 34

local frame, listChild, statusFS, emptyFS
local rows = {}

local function CreateRow(i)
    local row = CreateFrame("Button", nil, listChild)
    row:SetSize(CHILD_W, ROW_H - 2)
    row:SetPoint("TOPLEFT", 2, -(4 + (i - 1) * ROW_H))

    -- 当前位面底色
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(0.35, 0.28, 0.08, 0.55)
    row.bg:Hide()

    -- 选中高亮
    row.sel = row:CreateTexture(nil, "BORDER")
    row.sel:SetAllPoints()
    row.sel:SetTexture(0.16, 0.38, 0.58, 0.65)
    row.sel:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("TOPLEFT", 6, -11)
    row.icon:SetTexture("Interface\\Icons\\Spell_Nature_AstralRecal")

    row.nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameFS:SetPoint("TOPLEFT", 46, -5)
    row.nameFS:SetWidth(250)
    row.nameFS:SetJustifyH("LEFT")

    row.descFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.descFS:SetPoint("TOPLEFT", 46, -22)
    row.descFS:SetWidth(300)
    row.descFS:SetHeight(24)
    row.descFS:SetJustifyH("LEFT")
    row.descFS:SetTextColor(0.72, 0.72, 0.72)

    row.maskFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.maskFS:SetPoint("TOPLEFT", 46, -42)
    row.maskFS:SetTextColor(0.55, 0.72, 0.9)

    row.badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.badge:SetPoint("TOPRIGHT", -8, -6)
    row.badge:SetText("当前")
    row.badge:SetTextColor(1, 0.82, 0.2)
    row.badge:Hide()

    row:SetScript("OnClick", function()
        ns.state.selected = i
        ns.RenderList()
    end)

    row:SetScript("OnEnter", function(self)
        local e = ns.state.entries[i]
        if not e then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(e.name ~= "" and e.name or ("掩码 " .. e.mask), 1, 0.82, 0.2)
        if e.desc and e.desc ~= "" then
            GameTooltip:AddLine(e.desc, 0.8, 0.8, 0.8, true)
        end
        GameTooltip:AddLine("掩码 " .. e.mask, 0.55, 0.72, 0.9)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    rows[i] = row
    return row
end

function ns.RenderList()
    if not frame then return end

    local entries = ns.state.entries
    local cur = ns.state.currentMask

    for i = 1, #entries do
        local e = entries[i]
        local row = rows[i] or CreateRow(i)

        row.nameFS:SetText(e.name ~= "" and e.name or ("掩码 " .. e.mask))
        row.descFS:SetText(e.desc or "")
        row.maskFS:SetText("掩码 " .. e.mask)

        if cur and e.mask == cur then
            row.bg:Show()
            row.badge:Show()
        else
            row.bg:Hide()
            row.badge:Hide()
        end

        if ns.state.selected == i then
            row.sel:Show()
        else
            row.sel:Hide()
        end

        row:Show()
    end

    for i = #entries + 1, #rows do
        rows[i]:Hide()
    end

    listChild:SetHeight(math.max(1, 4 + #entries * ROW_H))
    if #entries == 0 then
        emptyFS:Show()
    else
        emptyFS:Hide()
    end

    local zoneName = ns.state.zoneName
    if not zoneName or zoneName == "" then
        zoneName = GetRealZoneText() or "未知区域"
    end
    local idText = ""
    if ns.state.zoneId then
        idText = "   |cff888888(ID " .. tostring(ns.state.zoneId) .. ")|r"
    end
    ns.zoneFS:SetText("区域：" .. zoneName .. idText)
    ns.maskFS:SetText("当前掩码：" .. tostring(cur or "?"))
    ns.countFS:SetText("可用位面：" .. #entries)
end

local function MakeBackdrop(f, alpha)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.05, 0.05, 0.05, alpha or 1)
    f:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
end

function ns.CreateUI()
    if frame then return end

    frame = CreateFrame("Frame", "PhaseSwitchFrame", UIParent)
    frame:SetSize(FRAME_W, FRAME_H)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)

    -- 该客户端 OnDragStop 在窗口外松键时会丢失，改为只记录抓取偏移，
    -- 在 OnUpdate 中检测左键状态（与 CoordRecorder 相同）。
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        local cx, cy = GetCursorPosition()
        local s = f:GetEffectiveScale()
        f.dragDX = cx / s - f:GetLeft()
        f.dragDY = cy / s - f:GetBottom()
        f.dragging = true
    end)
    frame:SetScript("OnUpdate", function(f)
        -- 连接超时提示：发出请求 3 秒内没有任何有效响应
        if ns.awaitingSince and (GetTime() - ns.awaitingSince) > 3 then
            ns.awaitingSince = nil
            ns.SetStatus("未连接：请检查服务端 phase_switch.lua 与 addon 前缀", true)
        end

        if not f.dragging then return end
        if IsMouseButtonDown("LeftButton") then
            local cx, cy = GetCursorPosition()
            local s = f:GetEffectiveScale()
            f:ClearAllPoints()
            f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                cx / s - f.dragDX, cy / s - f.dragDY)
        else
            f.dragging = false
        end
    end)
    frame:SetScript("OnDragStop", function(f) f.dragging = false end)
    frame:SetScript("OnMouseUp", function(f) f.dragging = false end)
    frame:SetScript("OnHide", function(f)
        f.dragging = false
        f:StopMovingOrSizing()
    end)

    tinsert(UISpecialFrames, "PhaseSwitchFrame")
    frame:Hide()   -- 关键：默认隐藏，避免登录期渲染

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cffd6b26a位面切换|r |cff9d9d9dv" .. ns.VERSION .. "|r")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)

    -- 信息条
    local info = CreateFrame("Frame", nil, frame)
    info:SetSize(LIST_W, 34)
    info:SetPoint("TOPLEFT", 16, -46)
    MakeBackdrop(info, 0.8)

    ns.zoneFS = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ns.zoneFS:SetPoint("TOPLEFT", 8, -5)
    ns.zoneFS:SetJustifyH("LEFT")

    ns.countFS = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ns.countFS:SetPoint("TOPRIGHT", -8, -5)
    ns.countFS:SetJustifyH("RIGHT")
    ns.countFS:SetTextColor(0.85, 0.72, 0.3)

    ns.maskFS = info:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ns.maskFS:SetPoint("TOPLEFT", 8, -19)
    ns.maskFS:SetJustifyH("LEFT")
    ns.maskFS:SetTextColor(0.55, 0.72, 0.9)

    -- 列表
    local listBG = CreateFrame("Frame", nil, frame)
    listBG:SetSize(LIST_W, LIST_H)
    listBG:SetPoint("TOPLEFT", 16, -86)
    MakeBackdrop(listBG, 1)

    local scroll = CreateFrame("ScrollFrame", "PhaseSwitchScroll", listBG, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -28, 4)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local new = cur - delta * ROW_H
        if new < 0 then new = 0 end
        if new > max then new = max end
        self:SetVerticalScroll(new)
    end)

    listChild = CreateFrame("Frame", nil, scroll)
    listChild:SetSize(CHILD_W, 1)
    scroll:SetScrollChild(listChild)

    -- 空状态提示
    emptyFS = listBG:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyFS:SetPoint("CENTER", listBG, "CENTER", 0, 0)
    emptyFS:SetText("|cff888888该区域没有可切换的位面|r")
    emptyFS:Hide()

    -- 提示行
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 18, -(86 + LIST_H + 8))
    hint:SetWidth(FRAME_W - 36)
    hint:SetJustifyH("LEFT")
    hint:SetText("|cff888888单击列表选择位面，再点「切换到此位面」。切换位面可能隐藏任务 NPC。|r")

    -- 按钮
    local btnSwitch = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnSwitch:SetSize(130, 26)
    btnSwitch:SetPoint("BOTTOMLEFT", 16, 48)
    btnSwitch:SetText("切换到此位面")
    btnSwitch:SetScript("OnClick", function()
        local i = ns.state.selected
        local e = i and ns.state.entries[i]
        if not e then
            ns.SetStatus("请先在列表中选择一个位面", true)
            return
        end
        if ns.state.currentMask and e.mask == ns.state.currentMask then
            ns.SetStatus("已经是当前位面", true)
            return
        end
        ns.SendReq("SET", e.mask)
    end)

    local btnReset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnReset:SetSize(90, 26)
    btnReset:SetPoint("LEFT", btnSwitch, "RIGHT", 10, 0)
    btnReset:SetText("重置")
    btnReset:SetScript("OnClick", function()
        ns.SendReq("RESET")
    end)

    local btnRefresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    btnRefresh:SetSize(90, 26)
    btnRefresh:SetPoint("LEFT", btnReset, "RIGHT", 10, 0)
    btnRefresh:SetText("刷新")
    btnRefresh:SetScript("OnClick", function()
        ns.SendReq("LIST")
        ns.SendReq("GET")
    end)

    -- 状态栏 / 页脚
    statusFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFS:SetPoint("BOTTOMLEFT", 16, 14)
    statusFS:SetWidth(FRAME_W - 160)
    statusFS:SetJustifyH("LEFT")
    statusFS:SetText("状态：未连接")
    ns.statusFS = statusFS

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footer:SetPoint("BOTTOMRIGHT", -16, 14)
    footer:SetText("|cff666666phase_switch_entry · v" .. ns.VERSION .. "|r")

    -- 每次显示时刷新；首次显示额外握手
    frame:SetScript("OnShow", function()
        if not ns.handshaked then
            ns.handshaked = true
            ns.SendReq("PING")
        end
        ns.SendReq("LIST")
        ns.SendReq("GET")
    end)

    ns.frame = frame
    ns.rows = rows
    ns.listChild = listChild
end
