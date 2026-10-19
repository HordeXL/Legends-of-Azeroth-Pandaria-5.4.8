--[[
    PhaseSwitch - 服务端 Eluna 脚本 v1.0
    ============================================================
    配合客户端插件 Interface\AddOns\PhaseSwitch（v1.0+）使用。

    通信通道（与 CoordRecorder 相同的模式）：
      客户端 RegisterAddonMessagePrefix("PH")
        -> SendAddonMessage("PH", payload, "WHISPER", UnitName("player"))
        -> 服务端 PLAYER_EVENT_ON_ADDON_MESSAGE(38)
        -> player:SendAddonMessage("PH", payload, player)
        -> 客户端 CHAT_MSG_ADDON

    协议：
      REQ|<seq>|<CMD>|<arg>
      RES|<seq>|<OK|ERR>|<code>|<payload>

    依赖：
      * 核心新增 Player:SetCustomPhase(mask) 绑定
        （PhaseMgr::SetCustomPhase，mask=0 恢复自动计算）
      * world 库：phase_switch_entry
      * auth 库：phase_switch_permission（仅 MODE=1 使用）

    重要：
      * GM 账号始终返回 PHASEMASK_ANYWHERE，SetCustomPhase 对 GM 不可见，
        因此 SET/RESET 对 GM 返回 E_GM。验收必须使用非 GM 账号。
      * 缓存重载命令为 #phreload（不是 .phreload：以 . 开头的未知命令会被
        核心 ParseCommands 拦截并回复 LANG_NO_CMD，到不了 Eluna 的 OnChat）。
]]

local PREFIX      = "PH"
local VERSION     = "1.0"
local COOLDOWN    = 3        -- 两次切换之间的冷却（秒）
local RATE_LIMIT  = 20       -- 每玩家每分钟请求硬上限
local MAX_REQ_LEN = 64       -- 请求 payload 字节上限
local MAX_MASK    = 4294967295

-- 权限模式：
--   0 = 仅 GM 可操作（GM 实际无法切换，仅能查看）
--   1 = GM + phase_switch_permission 白名单
--   2 = 全开放（仍受清单 / 等级 / 冷却限制）
local MODE = 2

local sessions  = {}   -- guid -> { lastSwitch = n, reqTimes = {} }
local cache     = {}   -- zoneId -> { {mask=, name=, desc=, minLevel=}, ... }
local permCache = {}   -- accountId -> { {zoneId=, mask=}, ... }

-- ============================ 工具 ============================
local function DLOG(s)
    -- 仅输出到服务端控制台，不影响玩家聊天框
    print("|cffd6b26a[PhaseSwitch]|r " .. tostring(s))
end

local function Sanitize(s)
    s = tostring(s or "")
    return (s:gsub("[|;:]", " "))
end

-- 按字节截断，且不截断在 UTF-8 连续字节上
local function Utf8Truncate(s, maxBytes)
    if #s <= maxBytes then return s end
    local cut = maxBytes
    while cut > 0 do
        local b = s:byte(cut + 1)
        if not b or b < 0x80 or b >= 0xC0 then break end
        cut = cut - 1
    end
    return s:sub(1, cut)
end

local function GetSession(player)
    local guid = player:GetGUIDLow()
    local s = sessions[guid]
    if not s then
        s = { lastSwitch = 0, reqTimes = {} }
        sessions[guid] = s
    end
    return s
end

local function RateOk(player)
    local s = GetSession(player)
    local now = os.time()
    local kept = {}
    for _, t in ipairs(s.reqTimes) do
        if now - t < 60 then
            kept[#kept + 1] = t
        end
    end
    s.reqTimes = kept
    if #kept >= RATE_LIMIT then
        return false
    end
    kept[#kept + 1] = now
    return true
end

-- 统一回发：只走 addon 通道，聊天框零输出
local function Reply(player, seq, status, payload)
    local text = "RES|" .. tostring(seq) .. "|" .. status .. "|" .. tostring(payload or "")
    if #text > 255 then
        text = "RES|" .. tostring(seq) .. "|ERR|E_ARGS"
    end
    if player and player.SendAddonMessage then
        local ok, err = pcall(player.SendAddonMessage, player, PREFIX, text, player)
        if not ok then DLOG("Reply 失败: " .. tostring(err)) end
    end
end

-- ============================ 数据 ============================
local function LoadEntries(zoneId)
    zoneId = tonumber(zoneId) or 0
    local list = {}
    local q = WorldDBQuery(
        "SELECT `mask`, `name`, `description`, `minLevel` " ..
        "FROM `phase_switch_entry` " ..
        "WHERE `zoneId` = " .. zoneId .. " AND `enabled` = 1 " ..
        "ORDER BY `sortOrder` ASC, `mask` ASC")
    if q then
        repeat
            local mask = q:GetUInt32(0)
            if mask and mask > 0 then
                list[#list + 1] = {
                    mask     = mask,
                    name     = Sanitize(q:GetString(1)),
                    desc     = Sanitize(q:GetString(2)),
                    minLevel = q:GetUInt8(3) or 0,
                }
            end
        until not q:NextRow()
    end
    cache[zoneId] = list
    return list
end

local function FindEntry(zoneId, mask)
    local list = cache[zoneId] or LoadEntries(zoneId)
    for _, e in ipairs(list) do
        if e.mask == mask then
            return e
        end
    end
    return nil
end

local function LoadPermissions(player)
    local acc = player:GetAccountId()
    local rows = permCache[acc]
    if rows then
        return rows
    end
    rows = {}
    local q = AuthDBQuery(
        "SELECT `zoneId`, `mask` FROM `phase_switch_permission` " ..
        "WHERE `accountId` = " .. (tonumber(acc) or 0))
    if q then
        repeat
            rows[#rows + 1] = {
                zoneId = q:GetUInt32(0),
                mask   = q:GetUInt32(1),
            }
        until not q:NextRow()
    end
    permCache[acc] = rows
    return rows
end

local function HasAccess(player, zoneId, mask)
    if MODE >= 2 then return true end
    if player:IsGM() then return true end
    if MODE == 0 then return false end

    for _, r in ipairs(LoadPermissions(player)) do
        if (r.zoneId == 0 or r.zoneId == zoneId) and
           (r.mask == 0 or r.mask == mask) then
            return true
        end
    end
    return false
end

local function HasZoneAccess(player, zoneId)
    if MODE >= 2 then return true end
    if player:IsGM() then return true end
    if MODE == 0 then return false end

    for _, r in ipairs(LoadPermissions(player)) do
        if r.zoneId == 0 or r.zoneId == zoneId then
            return true
        end
    end
    return false
end

-- ============================ 命令 ============================
local function SendList(player, seq)
    local zoneId = player:GetZoneId()
    local list = cache[zoneId] or LoadEntries(zoneId)
    if #list == 0 then
        Reply(player, seq, "ERR", "E_ZONE")
        return
    end

    local items = {}
    for _, e in ipairs(list) do
        -- 单项字节上限：name 48 + desc 120 + mask/分隔符，确保 < BUDGET
        -- （varchar 的 96 是字符数，中文 3 字节/字，必须按字节截断）
        local name = Utf8Truncate(e.name, 48)
        local desc = Utf8Truncate(e.desc, 120)
        items[#items + 1] = e.mask .. ":" .. name .. ":" .. desc
    end

    -- 按字节分块：单条 payload 上限 255，数据体预算 200
    local BUDGET = 200
    local blocks, cur, curLen = {}, {}, 0
    for _, it in ipairs(items) do
        local add = #it + ((#cur > 0) and 1 or 0)
        if #cur > 0 and curLen + add > BUDGET then
            blocks[#blocks + 1] = table.concat(cur, ";")
            cur, curLen = {}, 0
        end
        cur[#cur + 1] = it
        curLen = curLen + #it + ((#cur > 1) and 1 or 0)
    end
    if #cur > 0 then
        blocks[#blocks + 1] = table.concat(cur, ";")
    end

    -- zoneName 留空，客户端用 GetRealZoneText() 显示本地化区域名
    local total = #blocks
    for i, body in ipairs(blocks) do
        Reply(player, seq, "OK",
            "LIST|" .. i .. "|" .. total .. "|" .. zoneId .. "||" .. body)
    end
end

local function CmdGet(player, seq)
    local zoneId = player:GetZoneId()
    local mask = player:GetPhaseMask()
    local name = "自动"
    local entry = FindEntry(zoneId, mask)
    if entry then
        name = entry.name
    end
    Reply(player, seq, "OK", "CUR|" .. mask .. "|" .. name .. "|" .. zoneId)
end

local function CmdSet(player, seq, arg)
    local mask = tonumber(arg)
    if not mask or mask < 0 or mask > MAX_MASK or mask ~= math.floor(mask) then
        return Reply(player, seq, "ERR", "E_ARGS")
    end

    if not player.SetCustomPhase then
        DLOG("核心缺少 Player:SetCustomPhase 绑定，请重新编译（ELUNA=1）")
        return Reply(player, seq, "ERR", "E_BIND")
    end
    if player:IsGM() then
        return Reply(player, seq, "ERR", "E_GM")
    end
    if player:IsInCombat() then
        return Reply(player, seq, "ERR", "E_BUSY")
    end
    -- 只对切换类请求做每分钟硬限流，LIST/GET/PING 不受影响
    if not RateOk(player) then
        return Reply(player, seq, "ERR", "E_COOLDOWN|60")
    end

    local s = GetSession(player)
    local now = os.time()
    local remain = COOLDOWN - (now - s.lastSwitch)
    if remain > 0 then
        return Reply(player, seq, "ERR", "E_COOLDOWN|" .. remain)
    end

    local zoneId = player:GetZoneId()
    local entry = FindEntry(zoneId, mask)
    if not entry then
        return Reply(player, seq, "ERR", "E_MASK")
    end
    if entry.minLevel > 0 and player:GetLevel() < entry.minLevel then
        return Reply(player, seq, "ERR", "E_LEVEL|" .. entry.minLevel)
    end
    if not HasAccess(player, zoneId, mask) then
        return Reply(player, seq, "ERR", "E_PERM")
    end

    player:SetCustomPhase(mask)
    s.lastSwitch = now
    -- 回传实际生效掩码（SetCustomPhase 会立即 Update）
    local effective = player:GetPhaseMask()
    DLOG(string.format("switch: %s (guid %s, account %s) zone %s -> mask %s",
        tostring(player:GetName()), tostring(player:GetGUIDLow()),
        tostring(player:GetAccountId()), tostring(zoneId), tostring(effective)))
    Reply(player, seq, "OK", "SWITCHED|" .. effective .. "|" .. entry.name)
end

local function CmdReset(player, seq)
    if not player.SetCustomPhase then
        DLOG("核心缺少 Player:SetCustomPhase 绑定，请重新编译（ELUNA=1）")
        return Reply(player, seq, "ERR", "E_BIND")
    end
    if player:IsGM() then
        return Reply(player, seq, "ERR", "E_GM")
    end
    if player:IsInCombat() then
        return Reply(player, seq, "ERR", "E_BUSY")
    end
    if not RateOk(player) then
        return Reply(player, seq, "ERR", "E_COOLDOWN|60")
    end
    if not HasZoneAccess(player, player:GetZoneId()) then
        return Reply(player, seq, "ERR", "E_PERM")
    end

    player:SetCustomPhase(0)
    GetSession(player).lastSwitch = os.time()
    -- 恢复自动计算后，实际生效掩码由 phase_definitions 决定
    local effective = player:GetPhaseMask()
    DLOG(string.format("reset: %s (guid %s, account %s) zone %s -> auto (mask %s)",
        tostring(player:GetName()), tostring(player:GetGUIDLow()),
        tostring(player:GetAccountId()), tostring(player:GetZoneId()),
        tostring(effective)))
    Reply(player, seq, "OK", "SWITCHED|" .. effective .. "|自动")
end

local function Dispatch(player, seq, cmd, arg)
    if cmd == "PING" then
        Reply(player, seq, "OK", "PONG|" .. VERSION)
    elseif cmd == "LIST" then
        SendList(player, seq)
    elseif cmd == "GET" then
        CmdGet(player, seq)
    elseif cmd == "SET" then
        CmdSet(player, seq, arg)
    elseif cmd == "RESET" then
        CmdReset(player, seq)
    else
        Reply(player, seq, "ERR", "E_ARGS")
    end
end

-- ============================ 事件 ============================
-- PLAYER_EVENT_ON_ADDON_MESSAGE = 38 (event, player, msg, prefix, type)
local function OnAddonMessage(event, player, msg, prefix, type)
    if prefix ~= PREFIX or not player then return end
    -- 前缀 "PH" 已足够唯一；不依赖 CHAT_MSG_* 枚举（本 Eluna 未导出）
    if not msg or #msg > MAX_REQ_LEN then return end

    local seq, cmd, arg = msg:match("^REQ|(%d+)|([A-Z]+)|?(.*)$")
    if not seq or #seq > 9 then return end

    local ok, err = pcall(Dispatch, player, seq, cmd, arg or "")
    if not ok then
        DLOG("处理 " .. tostring(cmd) .. " 出错: " .. tostring(err))
        Reply(player, seq, "ERR", "E_ARGS")
    end
end

-- 缓存重载：GM 在聊天框输入 #phreload
-- （以 . 开头的未知命令会被核心拦截，无法到达这里）
local function OnChat(event, player, msg, msgType, lang)
    if msg ~= "#phreload" and msg ~= "#相位重载" then
        return
    end
    if not player or not player:IsGM() then
        return false
    end
    cache = {}
    permCache = {}
    player:SendBroadcastMessage("|cffd6b26a[PhaseSwitch]|r 缓存已重载。")
    return false
end

pcall(RegisterPlayerEvent, 38, OnAddonMessage)
pcall(RegisterPlayerEvent, 18, OnChat)

print(">>Script: PhaseSwitch (v" .. VERSION .. ", MODE=" .. MODE .. ") loading...OK")
