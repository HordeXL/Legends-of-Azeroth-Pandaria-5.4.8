--[[
    CoordRecorder 坐标记录器 - 服务端 Eluna 脚本 v7
    ============================================================
    配合客户端插件 Interface\AddOns\CoordRecorder（v1.5+）使用。

    通信方式（v7 起为 addon 消息单通道，SAY 兜底已移除）：
      - 核心需支持 PLAYER_EVENT_ON_ADDON_MESSAGE(38) + Player:SendAddonMessage
        （本仓库 2026-10-02 已实现，见 HookMgr/PlayerMethods/ChatHandler）
      - 客户端 RegisterAddonMessagePrefix("CR") 后经 WHISPER 自发自收，
        服务端处理后经 SendAddonMessage 回发，全程无聊天广播、无 UI 时序风险
      - 所有回复只走 addon 通道，聊天框不会出现任何本插件消息

    指令：ping / add / list / tele <n> / undo / clear / save <文件名> [entry]

    输出目录：lua_scripts/coords_output/
        <文件名>.txt   每行: 序号 X Y Z O
        <文件名>.sql   可直接导入 world 库（entry = waypoints 表路径ID）

    v7 改动：
      * 移除 SAY "#cr" 兜底通道（注册的 18 号事件已删除）
      * Reply() 不再回退 SendBroadcastMessage——聊天框零输出
      * SendList 分块改为按字节预算（addon 消息单条上限 255 字节，
        旧版按 40 点/块拼接会在第 9 点左右超限截断，导致列表只显示 8 条）
]]

local ADDON_PREFIX = "CR"    -- addon 通道前缀（客户端 RegisterAddonMessagePrefix 需一致）
local OUT_DIR = "lua_scripts/coords_output"

-- 每个玩家一个会话（点列表 + 文件名），登出不持久化
local sessions = {}

-- 轻量调试日志
local function DLOG(s)
    xpcall(function()
        local f = io.open(OUT_DIR .. "/cr_server.log", "a")
        if f then f:write(os.date("%H:%M:%S"), " ", s, "\n"); f:close() end
    end, function(e) return e end)
end

local function GetSession(player)
    local guid = player:GetGUIDLow()
    local s = sessions[guid]
    if not s then
        s = { points = {}, file = "route" }
        sessions[guid] = s
    end
    return s
end

local function FormatPoint(p)
    return string.format("%.2f,%.2f,%.2f,%.4f", p[1], p[2], p[3], p[4])
end

-- 统一回发：仅 addon 通道（v7 起聊天框零输出，失败只记日志）
local function Reply(player, text)
    local payload = "[CR]" .. text
    if player.SendAddonMessage then
        local ok, err = pcall(player.SendAddonMessage, player, ADDON_PREFIX, payload, player)
        if not ok then DLOG("Reply addon 失败: " .. tostring(err)) end
    else
        DLOG("Reply 失败: 核心 lacks SendAddonMessage")
    end
end

-- 回发坐标列表（分块，客户端按 pts|total|idx|cnt|data 重组）
-- addon 消息单条上限 255 字节：按字节预算分块，杜绝超长截断丢点
local function SendList(player)
    local s = GetSession(player)
    local n = #s.points
    local items = {}
    for i, p in ipairs(s.points) do
        items[#items + 1] = i .. ":" .. FormatPoint(p)
    end
    local budget = 200  -- 单块数据体字节上限（加头部后 < 255）
    local blocks = {}
    local cur, curLen = {}, 0
    for _, it in ipairs(items) do
        local l = #it + ((#cur > 0) and 1 or 0)  -- 含分隔符 ";"
        if #cur > 0 and curLen + l > budget then
            blocks[#blocks + 1] = table.concat(cur, ";")
            cur, curLen = {}, 0
        end
        cur[#cur + 1] = it
        curLen = curLen + #it + ((#cur > 1) and 1 or 0)
    end
    if #cur > 0 or #blocks == 0 then blocks[#blocks + 1] = table.concat(cur, ";") end
    local total = #blocks
    for c, seg in ipairs(blocks) do
        Reply(player, string.format("pts|%d|%d|%d|%s", n, c, total, seg))
    end
end

local function CmdPing(player, rank)
    Reply(player, "msg|服务端已连接（addon 通道），GM 等级 " .. rank)
    Reply(player, "pong|" .. rank)
    SendList(player)
end

local function CmdAdd(player)
    local s = GetSession(player)
    local p = { player:GetX(), player:GetY(), player:GetZ(), player:GetO() }
    table.insert(s.points, p)
    Reply(player, "msg|已记录第 " .. #s.points .. " 点: (" .. FormatPoint(p) .. ")")
    SendList(player)
end

local function CmdUndo(player)
    local s = GetSession(player)
    if #s.points == 0 then
        Reply(player, "err|列表已空，没有可撤销的点")
        return
    end
    local p = table.remove(s.points)
    Reply(player, "msg|已撤销最后一点 (" .. FormatPoint(p) .. ")，剩余 " .. #s.points .. " 点")
    SendList(player)
end

local function CmdClear(player)
    local s = GetSession(player)
    local n = #s.points
    s.points = {}
    Reply(player, "msg|已清空 " .. n .. " 点")
    SendList(player)
end

local function CmdTele(player, arg)
    local s = GetSession(player)
    local idx = tonumber(arg)
    if not idx or not s.points[idx] then
        Reply(player, "err|传送目标无效，先在列表中选中一个点")
        return
    end
    local p = s.points[idx]
    local ok = player:Teleport(player:GetMapId(), p[1], p[2], p[3], p[4])
    if ok then
        Reply(player, "msg|已传送到点 " .. idx .. " (" .. FormatPoint(p) .. ")")
    else
        Reply(player, "err|传送失败（坐标非法或目标不可达）")
    end
end

local function CmdSave(player, arg)
    local s = GetSession(player)
    local n = #s.points
    if n == 0 then
        Reply(player, "err|坐标列表为空，先「获取」几个点")
        return
    end
    local name, entryStr = arg:match("^(%S+)%s*(%S*)$")
    if not name then
        Reply(player, "err|用法: #cr save <文件名> [waypoints的entry]")
        return
    end
    name = name:gsub("[^%w%-_]", "_")
    local entry = tonumber(entryStr) or 0
    local mapId = player:GetMapId()

    -- 1) txt
    local path = OUT_DIR .. "/" .. name .. ".txt"
    local f = io.open(path, "w")
    if not f then
        Reply(player, "err|无法写入 " .. path .. "（检查目录是否存在）")
        return
    end
    f:write(string.format("# CoordRecorder route: %s\n# Map: %d  Points: %d  Time: %s\n",
        name, mapId, n, os.date("%Y-%m-%d %H:%M:%S")))
    for i, p in ipairs(s.points) do
        f:write(string.format("%d %.2f %.2f %.2f %.4f\n", i, p[1], p[2], p[3], p[4]))
    end
    f:close()

    -- 2) 可选 SQL（waypoints 表：SmartAI 护送路径）
    local extra = ""
    if entry > 0 then
        local spath = OUT_DIR .. "/" .. name .. ".sql"
        local sf = io.open(spath, "w")
        if sf then
            sf:write("-- Generated by CoordRecorder  (entry = " .. entry .. ")\n")
            sf:write(string.format("DELETE FROM `waypoints` WHERE `entry` = %d;\n", entry))
            sf:write("INSERT INTO `waypoints` (`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`orientation`) VALUES\n")
            local vals = {}
            for i, p in ipairs(s.points) do
                vals[#vals + 1] = string.format("(%d,%d,%.2f,%.2f,%.2f,%.4f)", entry, i, p[1], p[2], p[3], p[4])
            end
            sf:write(table.concat(vals, ",\n") .. ";\n")
            sf:close()
            extra = string.format(" 及 %s.sql（entry=%d，导入后 .reload smart_scripts 生效）", name, entry)
        else
            extra = "（SQL 写入失败）"
        end
    end
    Reply(player, "msg|已保存 " .. n .. " 点 -> " .. path .. extra)
    Reply(player, "saved|" .. name .. ".txt|" .. n)
end

-- 命令分发（addon/SAY 两通道共用；由 pcall 包裹调用）
function ProcessCommand(player, msg)
    local rank = player:GetGMRank()
    local body = msg:sub(1, 4) == "[CR]" and msg:sub(5) or msg
    local cmd, rest = body:match("^%s*(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    rest = rest or ""

    if cmd == "" or cmd == "help" or cmd == "帮助" then
        Reply(player, "msg|指令: 获取(add) / list / tele <n> / undo / clear / save <文件名> [entry] / ping")
    elseif cmd == "ping" then
        CmdPing(player, rank)
    elseif cmd == "add" then
        if rank < 1 then Reply(player, "err|需要 GM 权限") return end
        CmdAdd(player)
    elseif cmd == "list" then
        SendList(player)
    elseif cmd == "tele" then
        if rank < 1 then Reply(player, "err|需要 GM 权限") return end
        CmdTele(player, rest)
    elseif cmd == "undo" then
        if rank < 1 then Reply(player, "err|需要 GM 权限") return end
        CmdUndo(player)
    elseif cmd == "clear" then
        if rank < 1 then Reply(player, "err|需要 GM 权限") return end
        CmdClear(player)
    elseif cmd == "save" then
        if rank < 1 then Reply(player, "err|需要 GM 权限") return end
        CmdSave(player, rest)
    else
        Reply(player, "err|未知指令 " .. cmd)
    end
end

-- ============================ 主通道：addon 消息 ============================
-- PLAYER_EVENT_ON_ADDON_MESSAGE = 38 (event, player, msg, prefix, type)
-- 需要新编译的核心支持；旧核心上 pcall 兜底，不影响 SAY 通道
local function OnAddonMessage(event, player, msg, prefix, type)
    if prefix ~= ADDON_PREFIX then return end
    DLOG("addon<" .. tostring(msg) .. "> from " .. ((player and player.GetName) and player:GetName() or "?"))
    local ok, err = pcall(ProcessCommand, player, msg)
    if not ok then
        DLOG("ERROR: " .. tostring(err))
        Reply(player, "err|服务端处理出错，详见 cr_server.log")
    end
end
pcall(RegisterPlayerEvent, 38, OnAddonMessage)

print(">>Script: CoordRecorder (服务端 v7: addon 单通道, 聊天框零输出) loading...OK")
