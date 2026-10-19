--[[
    PhaseSwitch - 客户端插件 v1.0（5.4.8 / Interface 50400）
    ============================================================
    /ph 或 /位面 打开面板。

    协议（addon 消息，前缀 PH）：
      REQ|<seq>|<CMD>|<arg>
      RES|<seq>|<OK|ERR>|<code>|<payload>

    所有反馈只写入面板状态栏，聊天框零输出。
]]

local ADDON, ns = ...

ns.PREFIX  = "PH"
ns.VERSION = "1.0"

-- 未完成请求：seq -> { cmd = "LIST"|"CUR"|"SWITCHED"|"PONG", chunks = {}, total = nil }
-- 用表而不是单一 currentSeq：LIST 与 GET 可能同时在途，
-- 且 LIST 分块响应共用同一个 seq。
ns.pending = {}
ns.nextSeq = 0

ns.state = {
    entries     = {},
    currentMask = nil,
    currentName = nil,
    zoneId      = nil,
    zoneName    = nil,
    selected    = nil,
}

ns.ERR_TEXT = {
    E_ZONE     = "该区域没有可切换的位面",
    E_MASK     = "该位面不可用",
    E_PERM     = "你没有切换到该位面的权限",
    E_LEVEL    = "需要等级 %d",
    E_COOLDOWN = "请 %d 秒后再试",
    E_BUSY     = "战斗中无法切换位面",
    E_ARGS     = "参数错误",
    E_GM       = "GM 模式已可见全部位面，无需切换",
    E_BIND     = "服务端未启用位面切换（缺少核心绑定，请重新编译）",
}

-- ============================ 状态栏 ============================
function ns.SetStatus(text, isErr)
    if not ns.statusFS then return end
    ns.statusFS:SetText(tostring(text))
    if isErr then
        ns.statusFS:SetTextColor(1, 0.35, 0.35)
    else
        ns.statusFS:SetTextColor(0.5, 1, 0.5)
    end
end

function ns.FormatErr(code, arg)
    local t = ns.ERR_TEXT[code] or ("未知错误：" .. tostring(code))
    local n = tonumber(arg)
    if n and t:find("%%d") then
        return string.format(t, n)
    end
    return (t:gsub("%%d", "?"))
end

-- ============================ 发送 ============================
function ns.SendReq(cmd, arg)
    -- 清理超时请求，避免服务端无响应时 pending 无限增长
    local now = GetTime()
    for k, v in pairs(ns.pending) do
        if now - (v.t or now) > 15 then
            ns.pending[k] = nil
        end
    end

    ns.nextSeq = ns.nextSeq + 1
    local seq = ns.nextSeq
    ns.pending[seq] = { cmd = cmd, chunks = {}, t = now }
    if not ns.awaitingSince then
        ns.awaitingSince = now
    end

    local msg = "REQ|" .. seq .. "|" .. cmd .. (arg and ("|" .. tostring(arg)) or "")
    if not SendAddonMessage then
        ns.SetStatus("客户端不支持 SendAddonMessage", true)
        return seq
    end
    local ok, err = pcall(SendAddonMessage, ns.PREFIX, msg, "WHISPER", UnitName("player"))
    if not ok then
        ns.SetStatus("发送失败：" .. tostring(err), true)
    end
    return seq
end

-- ============================ 响应解析 ============================
local function OnListChunk(payload, req)
    local idx, total, zoneId, zoneName, items =
        payload:match("^(%d+)|(%d+)|(%d+)|([^|]*)|(.*)$")
    if not idx then return false end
    idx, total = tonumber(idx), tonumber(total)
    if not idx or not total or total < 1 then return false end

    -- 初始化一次，允许分块乱序到达
    if not req.total then
        req.total, req.chunks = total, {}
    end
    req.chunks[idx] = items or ""
    req.zoneId   = tonumber(zoneId)
    req.zoneName = zoneName

    -- 收齐所有块才渲染（不依赖“最后一块最后到达”）
    local got = 0
    for c = 1, req.total do
        if req.chunks[c] then got = got + 1 end
    end
    if got < req.total then
        return false
    end

    -- 收齐：重组并渲染
    ns.state.zoneId   = req.zoneId
    ns.state.zoneName = req.zoneName
    ns.state.entries  = {}

    local all = table.concat(req.chunks, ";", 1, req.total)
    for item in all:gmatch("[^;]+") do
        local mask, name, desc = item:match("^(%d+):([^:]*):(.*)$")
        if mask then
            ns.state.entries[#ns.state.entries + 1] = {
                mask = tonumber(mask),
                name = name or "",
                desc = desc or "",
            }
        end
    end

    if ns.state.selected and ns.state.selected > #ns.state.entries then
        ns.state.selected = nil
    end
    ns.RenderList()
    return true
end

local function OnCurrent(payload)
    local mask, name, zoneId = payload:match("^(%d+)|([^|]*)|(%d+)$")
    if not mask then return end
    ns.state.currentMask = tonumber(mask)
    ns.state.currentName = name
    ns.state.zoneId      = tonumber(zoneId)
    ns.RenderList()
    if #ns.state.entries == 0 then
        -- 空区域：不要把 E_ZONE 的提示覆盖掉
        ns.SetStatus("该区域没有可切换的位面", true)
    else
        ns.SetStatus("当前位面：" .. (name ~= "" and name or tostring(mask)) ..
            "（掩码 " .. mask .. "）", false)
    end
end

local function OnSwitched(payload)
    local mask, name = payload:match("^(%d+)|(.*)$")
    if not mask then return end
    ns.state.currentMask = tonumber(mask)
    ns.state.currentName = name
    ns.RenderList()
    ns.SetStatus("已切换到：" .. (name ~= "" and name or tostring(mask)) ..
        "（掩码 " .. mask .. "）", false)
end

local function ParseResponse(msg)
    local seq, status, code, payload =
        msg:match("^RES|(%d+)|(%a+)|([%w_]+)|(.*)$")
    if not seq then return end

    local seqNum = tonumber(seq)
    ns.awaitingSince = nil              -- 收到任意响应即视为服务端在线
    local req = seqNum and ns.pending[seqNum]
    if not req then return end          -- 未知/过期响应，丢弃

    if status == "ERR" then
        ns.pending[seqNum] = nil
        if code == "E_ZONE" then
            -- 空状态：清空旧列表，避免显示上一个区域的位面
            ns.state.entries  = {}
            ns.state.selected = nil
            ns.state.zoneId   = nil
            ns.state.zoneName = nil
            ns.RenderList()
        end
        ns.SetStatus(ns.FormatErr(code, payload), true)
        return
    end

    if code == "LIST" then
        -- 分块响应共用同一 seq，收齐后才消费
        if OnListChunk(payload, req) then
            ns.pending[seqNum] = nil
        end
    else
        ns.pending[seqNum] = nil
        if code == "CUR" then
            OnCurrent(payload)
        elseif code == "SWITCHED" then
            OnSwitched(payload)
        elseif code == "PONG" then
            ns.SetStatus("已连接服务端 v" .. tostring(payload), false)
        end
    end
end

-- ============================ 事件 ============================
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("CHAT_MSG_ADDON")

loader:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end

        ns.CreateUI()

        -- 服务端回发消息依赖此前缀注册
        if RegisterAddonMessagePrefix then
            pcall(RegisterAddonMessagePrefix, ns.PREFIX)
        end

        SlashCmdList["PHASESWITCH"] = function()
            if ns.frame:IsShown() then
                ns.frame:Hide()
            else
                ns.frame:Show()
            end
        end
        SLASH_PHASESWITCH1 = "/ph"
        SLASH_PHASESWITCH2 = "/位面"

        loader:UnregisterEvent("ADDON_LOADED")
        ns.SetStatus("已加载，输入 /ph 打开面板。", false)

    elseif event == "PLAYER_ENTERING_WORLD" then
        if ns.frame and ns.frame:IsShown() then
            ns.SendReq("LIST")
            ns.SendReq("GET")
        end

    elseif event == "CHAT_MSG_ADDON" then
        -- arg1=prefix arg2=message arg3=channel arg4=sender
        if arg1 == ns.PREFIX and type(arg2) == "string" then
            ParseResponse(arg2)
        end
    end
end)
