--[[
    CoordRecorder 坐标记录器 - 客户端插件（5.4.8） v1.5
    ============================================================
    面板：/cr 或 /坐标 打开。四按钮：获取/保存/传送/清空。

    v1.5 改动：
      * 移除 SAY 兜底：指令只走 addon 消息通道，发送失败仅状态栏提示
      * 提示信息不再输出到聊天框（Msg 统一写入面板状态栏，调试探针默认关闭）
      * 列表表头固定在滚动区外，不再与第一行重叠
      * 列表滚动修正：超过可视行数出现滚动条，可显示任意多点
        （配套服务端 v7 的字节预算分块，修复 8 条以上丢失问题）
]]

local ADDON = ...
local ADDON_PREFIX = "CR"     -- addon 消息前缀（服务端 RegisterPlayerEvent(38) 处理）
local DEBUG = false           -- 调试探针开关（排查用，平时关闭保持聊天框干净）

-- ============================ 调试探针 ============================
local function DBG(stage)
    if DEBUG then
        print("|cffff9900[CRDBG]|r " .. tostring(stage))
    end
end
DBG("S0 文件开始执行（解析成功）")

-- ============================ 状态 ============================
local pts = {}          -- {{x,y,z,o}, ...} 镜像服务端列表
local selIdx = nil      -- 选中的行
local chunks = {}       -- pts 分块重组缓冲
local chunkTotal, chunkNeed = 0, 0
local frame, rows, statusFS, fileEdit, entryEdit, countFS

-- ============================ 工具 ============================
-- 提示统一写入面板状态栏，不输出到聊天框（面板未创建时才临时用聊天框）
local function Msg(text)
    if statusFS then
        statusFS:SetText(tostring(text))
        statusFS:SetTextColor(0.7, 0.9, 1)
    else
        print("|cff39c0bb[坐标记录器]|r " .. tostring(text))
    end
end

local function SendCmd(text)
    if not frame then return end
    DBG("S-CMD 发送<" .. text .. ">")
    -- 仅 addon 消息通道（v1.5 起 SAY 兜底已移除）
    if SendAddonMessage then
        local ok, err = pcall(SendAddonMessage, ADDON_PREFIX, text, "WHISPER", UnitName("player"))
        if not ok then
            Msg("|cffff7070addon 发送失败: " .. tostring(err) .. "|r")
        end
    else
        Msg("|cffff7070客户端不支持 SendAddonMessage，需更新核心/客户端|r")
    end
end

local function FormatNum(v, d)
    if not v then return "--" end
    return string.format("%." .. (d or 2) .. "f", v)
end

-- ============================ 主面板 ============================
local function CreateUI()
    DBG("S1 CreateUI 开始")
    frame = CreateFrame("Frame", "CoordRecorderFrame", UIParent)
    frame:SetSize(430, 380)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    -- 手动拖拽：该客户端的 OnDragStop/OnMouseUp 在窗体外松键时丢失，
    -- 引擎自带的 StartMoving 会永远粘住光标。改为只用 OnDragStart 记录
    -- 抓取偏移，OnUpdate 里检测左键状态——松键即停，完全不依赖松键事件。
    frame:SetScript("OnDragStart", function(f)
        local cx, cy = GetCursorPosition()
        local s = f:GetEffectiveScale()
        f.dragDX = cx / s - f:GetLeft()
        f.dragDY = cy / s - f:GetBottom()
        f.dragging = true
    end)
    frame:SetScript("OnUpdate", function(f)
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
        f:StopMovingOrSetPoint()
    end)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.92)
    tinsert(UISpecialFrames, "CoordRecorderFrame") -- ESC 可关闭
    frame:Hide()  -- 关键：默认隐藏，避免登录期 OnUpdate/渲染

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("|cff39c0bb坐标记录器|r |cff9d9d9dv1.5 addon|r")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    -- 四按钮
    DBG("S2 基础Frame/标题/实时坐标 完成")
    local defs = {
        { text = "获取", onclick = function() SendCmd("add") end },
        { text = "保存", onclick = function()
            local name = (fileEdit:GetText() or ""):gsub("[^%w%-_]", "_")
            if name == "" then name = "route" end
            local entry = (entryEdit:GetText() or "0"):match("^%s*(%d+)%s*$") or "0"
            SendCmd(("save %s %s"):format(name, entry))
        end },
        { text = "传送", onclick = function()
            if selIdx then SendCmd("tele " .. selIdx)
            else Msg("|cffff7070请先在列表中单击选中一个点|r") end
        end },
        { text = "清空", onclick = function()
            if #pts == 0 then Msg("列表已空。") return end
            StaticPopupDialogs["COORDREC_CLEAR"] = StaticPopupDialogs["COORDREC_CLEAR"] or {
                text = "确定清空全部坐标点？",
                button1 = "清空", button2 = "取消",
                OnAccept = function() SendCmd("clear") end,
                timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
            }
            StaticPopup_Show("COORDREC_CLEAR")
        end },
    }
    local prev
    for i, d in ipairs(defs) do
        local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        b:SetSize(94, 26)
        b:SetText(d.text)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 10, 0)
        else b:SetPoint("TOPLEFT", 16, -60) end
        b:SetScript("OnClick", d.onclick)
        prev = b
    end

    -- 文件名 / entry 输入行
    DBG("S3 四按钮 完成")
    local fileLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileLabel:SetPoint("TOPLEFT", 16, -96)
    fileLabel:SetText("文件名:")
    fileEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    fileEdit:SetSize(110, 20)
    fileEdit:SetPoint("LEFT", fileLabel, "RIGHT", 8, 0)
    fileEdit:SetAutoFocus(false)
    fileEdit:SetText("route")

    local entryLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    entryLabel:SetPoint("LEFT", fileEdit, "RIGHT", 14, 0)
    entryLabel:SetText("waypoints entry:")
    entryEdit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    entryEdit:SetSize(70, 20)
    entryEdit:SetPoint("LEFT", entryLabel, "RIGHT", 8, 0)
    entryEdit:SetAutoFocus(false)
    entryEdit:SetText("0")
    entryEdit:SetScript("OnEnterPressed", function(b) b:ClearFocus() end)
    fileEdit:SetScript("OnEnterPressed", function(b) b:ClearFocus() end)

    -- 列表（滚动）
    DBG("S4 输入框 完成")
    local listBG = CreateFrame("Frame", nil, frame)
    listBG:SetSize(398, 190)
    listBG:SetPoint("TOPLEFT", 16, -124)
    listBG:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    listBG:SetBackdropColor(0.05, 0.05, 0.05, 1)

    local scroll = CreateFrame("ScrollFrame", nil, listBG, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", listBG, "TOPLEFT", 6, -24)   -- 顶部留出固定表头行
    scroll:SetPoint("BOTTOMRIGHT", listBG, "BOTTOMRIGHT", -26, 6)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(360, 1)
    scroll:SetScrollChild(child)
    frame.child = child

    -- 表头：固定在滚动区外（不随内容滚动、不与首行重叠）
    -- xs 为行内列位置；+6 补偿滚动区相对 listBG 的横向偏移
    local headers = { "#", "X", "Y", "Z", "O(朝向)" }
    local xs = { 8, 36, 120, 204, 288 }
    for c, h in ipairs(headers) do
        local t = listBG:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("TOPLEFT", listBG, "TOPLEFT", xs[c] + 6, -7)
        t:SetText(h)
        t:SetTextColor(0.85, 0.72, 0.3)
    end

    -- 行工厂（第一行从滚动区顶部往下 4px 起，与表头留有间距）
    rows = {}
    local function GetRow(i)
        if rows[i] then return rows[i] end
        local row = CreateFrame("Button", nil, child)
        row:SetSize(356, 16)
        row:SetPoint("TOPLEFT", 2, -(4 + (i - 1) * 17))
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetTexture(0.11, 0.24, 0.38, 0.95)
        if hl.SetShown then hl:SetShown(false) else hl:Hide() end
        row.hl = hl
        row.texts = {}
        for c = 1, 5 do
            local t = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            t:SetPoint("TOPLEFT", xs[c] - 2, -1)
            t:SetJustifyH("LEFT")
            t:SetTextColor(0.9, 0.88, 0.8)
            row.texts[c] = t
        end
        row:SetScript("OnClick", function()
            selIdx = (selIdx == i) and selIdx or i
            RefreshList()
        end)
        rows[i] = row
        return row
    end
    frame.GetRow = GetRow

    -- 状态栏
    DBG("S5 滚动列表/表头/行工厂 完成")
    statusFS = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusFS:SetPoint("BOTTOMLEFT", 16, 14)
    statusFS:SetJustifyH("LEFT")
    statusFS:SetText("状态：未连接")
    countFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countFS:SetPoint("BOTTOMRIGHT", -18, 14)
    countFS:SetText("共 0 点")
end

-- ============================ 列表渲染 ============================
function RefreshList()
    if not frame then return end
    for i, p in ipairs(pts) do
        local row = frame.GetRow(i)
        row.texts[1]:SetText(tostring(i))
        row.texts[1]:SetTextColor(1, 0.85, 0.45)
        row.texts[2]:SetText(FormatNum(p[1], 2))
        row.texts[3]:SetText(FormatNum(p[2], 2))
        row.texts[4]:SetText(FormatNum(p[3], 2))
        row.texts[5]:SetText(FormatNum(p[4], 4))
        if selIdx == i then row.hl:Show() else row.hl:Hide() end
        row:Show()
    end
    for i = #pts + 1, #rows do rows[i]:Hide() end
    frame.child:SetHeight(math.max(1, 4 + #pts * 17))
    if selIdx and selIdx > #pts then selIdx = nil end
    countFS:SetText("共 " .. #pts .. " 点")
    if selIdx and pts[selIdx] then
        local p = pts[selIdx]
        statusFS:SetText(string.format("传送目标：点 %d (%s, %s, %s, %s)",
            selIdx, FormatNum(p[1], 2), FormatNum(p[2], 2), FormatNum(p[3], 2), FormatNum(p[4], 4)))
    end
end

-- ============================ 服务端回复解析 ============================
function OnSystemMessage(text)
    if type(text) ~= "string" then return end
    if #text > 4000 then return end
    if text:sub(1, 4) ~= "[CR]" then return end
    -- 收到任意服务端回复即视为已连接
    if statusFS then
        statusFS:SetText("状态：已连接服务端")
        statusFS:SetTextColor(0.5, 1, 0.5)
    end
    local payload = text:sub(5)
    local kind, data = payload:match("^(%w+)|(.*)$")
    if kind == "pts" then
        local total, idx, cnt, seg = payload:match("^pts|(%d+)|(%d+)|(%d+)|(.*)$")
        total, idx, cnt = tonumber(total), tonumber(idx), tonumber(cnt)
        if not (idx and cnt and seg) then return end
        if cnt < 1 or cnt > 100 or idx < 1 or idx > cnt then return end
        chunks[idx] = seg
        if idx == 1 then chunkNeed = cnt; chunks = { [1] = seg } end
        -- 齐了就重组
        local got = 0
        for c = 1, chunkNeed do if chunks[c] then got = got + 1 end end
        if got >= chunkNeed then
            local all = table.concat(chunks, ";", 1, chunkNeed)
            chunks, chunkNeed = {}, 0
            pts = {}
            if all and all ~= "" then
                for item in all:gmatch("[^;]+") do
                    local si, coords = item:match("^(%d+):(.+)$")
                    if coords then
                        local x, y, z, o = coords:match("^([^,]+),([^,]+),([^,]+),([^,]+)$")
                        if x then
                            pts[#pts + 1] = { tonumber(x), tonumber(y), tonumber(z), tonumber(o) }
                        end
                    end
                end
            end
            RefreshList()
        end
    elseif kind == "msg" then
        statusFS:SetText(data)
        statusFS:SetTextColor(0.5, 1, 0.5)
    elseif kind == "err" then
        statusFS:SetText("|cffff7070" .. data .. "|r")
    elseif kind == "saved" then
        local file, n = data:match("^([^|]+)|(%d+)$")
        statusFS:SetText("已保存 " .. n .. " 点 -> " .. file)
    elseif kind == "pong" then
        DBG("S10 收到服务端 pong，握手完成")
        statusFS:SetText("状态：已连接服务端")
        statusFS:SetTextColor(0.5, 1, 0.5)
    end
end

-- ============================ 入口 ============================
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("CHAT_MSG_ADDON")
loader:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            CreateUI()
            -- 注册 addon 前缀（服务端回发消息的前缀校验依赖此注册）
            if RegisterAddonMessagePrefix then
                local ok, ret = pcall(RegisterAddonMessagePrefix, ADDON_PREFIX)
                if ok and ret and ret ~= 0 then
                    Msg("|cffff7070前缀注册失败 ret=" .. tostring(ret) .. "|r")
                end
            end
            SlashCmdList["COORDRECORDER"] = function()
                DBG("S-CR /cr 触发（" .. (frame:IsShown() and "可见→隐藏" or "隐藏→显示") .. "）")
                if frame:IsShown() then frame:Hide() else frame:Show() end
            end
            SLASH_COORDRECORDER1 = "/cr"
            SLASH_COORDRECORDER2 = "/坐标"
            loader:UnregisterEvent("ADDON_LOADED")
            Msg("v1.5 已加载，输入 /cr 打开面板。")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        DBG("S6 PLAYER_ENTERING_WORLD 触发（登录不自动发消息）")
    elseif event == "CHAT_MSG_ADDON" then
        -- arg1=prefix arg2=message arg3=channel arg4=sender
        if arg1 == ADDON_PREFIX and type(arg2) == "string" then
            OnSystemMessage(arg2)
        end
    end
end)
