--[[
    ██╗  ██╗██╗███╗   ██╗    ████████╗ ██████╗ ██╗    ██╗███╗   ██╗
    ╚██╗██╔╝██║████╗  ██║    ╚══██╔══╝██╔═══██╗██║    ██║████╗  ██║
     ╚███╔╝ ██║██╔██╗ ██║       ██║   ██║   ██║██║ █╗ ██║██╔██╗ ██║
     ██╔██╗ ██║██║╚██╗██║       ██║   ██║   ██║██║███╗██║██║╚██╗██║
    ██╔╝ ██╗██║██║ ╚████║       ██║   ╚██████╔╝╚███╔███╔╝██║ ╚████║
    ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝
    [ XIN TOWN ] - Anti-Cheat Intelligence System v1.0
    [ By K2NTA / TTJY Studio ] - Stealth Edition
--]]

-- ============================================================
--  CONFIGURATION
-- ============================================================
local Config = {
    Version          = "1.0.0",
    Tag              = "[XIN TOWN]",
    ShowDebugOutput  = false,
    BlockLoopCrash   = true,
    PatchOverflow    = true,
    PatchCompareTbl  = true,
    HideLogService   = true,
    HookMetaMethod   = false,
    SpoofIdentity    = true,
    DelayExec        = 0.05,
}

-- ============================================================
--  INTERNAL STATE
-- ============================================================
local State = {
    LogServiceConns  = {},
    FindServiceHits  = {},
    FindServiceInfo  = {},
    RFCallbacks      = {},
    RFInstances      = {},
    HasRFCallback    = false,
    DetectStrings    = false,
    DetectStringsTbl = {},
    AdonisMeta       = false,
    CompareTables    = false,
    CompareTablesInfo= nil,
    OverflowPatched  = false,
    OverflowInfo     = nil,
    IsMetaFS         = false,
    _loadStep        = 0,
    _loadTotal       = 8,
}

local SuspiciousServices = {
    "VirtualUser",
    "VirtualInputManager",
    "UGCValidationService",
    "NetworkClient",
    "ScriptContext",
}

-- ============================================================
--  UTILITIES
-- ============================================================
local function xlog(...)
    if Config.ShowDebugOutput then print("[XIN-DBG]", ...) end
end

local function safe_call(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then xlog("safe_call error:", res) end
    return ok and res or nil
end

local function stealth_wait(t)
    local start = tick()
    repeat until tick() - start >= t
end

-- ============================================================
--  LOADING DISPLAY
-- ============================================================
local BAR_WIDTH = 40

local function make_bar(step, total)
    local filled = math.floor((step / total) * BAR_WIDTH)
    local empty   = BAR_WIDTH - filled
    local pct     = math.floor((step / total) * 100)
    return ("█"):rep(filled) .. ("░"):rep(empty), pct
end

local function loading_print(label, step, total)
    local bar, pct = make_bar(step, total)
    warn(("  [%s] %s  %d%%"):format(bar, label, pct))
end

local function phase_start(name)
    State._loadStep = State._loadStep + 1
    loading_print(name, State._loadStep, State._loadTotal)
end

-- ============================================================
--  BOOT HEADER (แสดงก่อนเริ่ม)
-- ============================================================
local SEP = ("═"):rep(66)
warn(SEP)
warn("  ██╗  ██╗██╗███╗   ██╗    ████████╗ ██████╗ ██╗    ██╗███╗   ██╗")
warn("  ╚██╗██╔╝██║████╗  ██║    ╚══██╔══╝██╔═══██╗██║    ██║████╗  ██║")
warn("   ╚███╔╝ ██║██╔██╗ ██║       ██║   ██║   ██║██║ █╗ ██║██╔██╗ ██║")
warn("   ██╔██╗ ██║██║╚██╗██║       ██║   ██║   ██║██║███╗██║██║╚██╗██║")
warn("  ██╔╝ ██╗██║██║ ╚████║       ██║   ╚██████╔╝╚███╔███╔╝██║ ╚████║")
warn("  ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝")
warn(SEP)
warn("  [ XIN TOWN ] Anti-Cheat Intelligence System  v" .. Config.Version)
warn("  [ By K2NTA / TTJY Studio ]  --  Stealth Edition")
warn(SEP)
warn("  กำลังโหลด... Loading XIN TOWN")
warn("")

-- ============================================================
--  PHASE 0 : Block loop crash
-- ============================================================
phase_start("ป้องกันลูปค้าง  (Loop-Crash Guard)")
if Config.BlockLoopCrash then
    safe_call(function()
        game:GetService("ScriptContext"):SetTimeout(2)
    end)
end

-- ============================================================
--  PHASE 1 : LogService connections scan
-- ============================================================
phase_start("ตรวจ Console Listener  (LogService Scan)")
safe_call(function()
    if not Config.HideLogService then return end
    local conns = getconnections(game:GetService("LogService").MessageOut)
    for _, c in ipairs(conns) do
        table.insert(State.LogServiceConns, c)
        -- c:Disable()
    end
end)

-- ============================================================
--  PHASE 2 : Patch overflow constant
-- ============================================================
phase_start("แก้ Overflow Constant  (C_Closure Patch)")
if Config.PatchOverflow then
    safe_call(function()
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local consts = getconstants(v)
                local idx = table.find(consts, "overflow")
                if idx and not table.find(consts, "__index") then
                    setconstant(v, idx, "xin_safe")
                    State.OverflowPatched = true
                    State.OverflowInfo    = getinfo(v)
                end
            end
        end
    end)
end

-- ============================================================
--  PHASE 3 : Hook FindService
-- ============================================================
stealth_wait(Config.DelayExec)
phase_start("Hook FindService  (Suspicious Service Block)")
safe_call(function()
    local _orig; _orig = hookfunction(game.FindService, newcclosure(function(self, service)
        xlog("FindService called:", service)
        if table.find(SuspiciousServices, service) then
            table.insert(State.FindServiceHits, service)
            State.FindServiceInfo[service] = getcallingscript()
            return nil
        end
        return _orig(self, service)
    end))
end)

-- ============================================================
--  PHASE 4 : String-table fingerprint detection
-- ============================================================
phase_start("ตรวจ String-Table Fingerprint  (Executor Detect)")
safe_call(function()
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table" and table.find(v, "islclosure") then
            State.DetectStringsTbl = table.clone(v)
            table.clear(v)
            State.DetectStrings = true
            break
        end
    end
end)

-- ============================================================
--  PHASE 5 : Adonis meta + patch compareTables
-- ============================================================
phase_start("ตรวจ Adonis Meta + Patch compareTables")
safe_call(function()
    for _, v in ipairs(getgc(true)) do
        if
            typeof(v) == "table"
            and rawget(v, "indexInstance")
            and rawget(v, "newindexInstance")
            and rawget(v, "namecallInstance")
            and type(rawget(v, "newindexInstance")) == "table"
        then
            State.AdonisMeta = true
            break
        end
    end
end)
if Config.PatchCompareTbl then
    safe_call(function()
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" and getinfo(v).name == "compareTables" then
                local info = getinfo(v)
                if string.find(info.source or "", "Anti") then
                    local _o; _o = hookfunction(v, newcclosure(function()
                        return true
                    end))
                    State.CompareTables     = true
                    State.CompareTablesInfo = info.source
                end
            end
        end
    end)
end

-- ============================================================
--  PHASE 6 : __namecall hook (optional)
-- ============================================================
phase_start("Hook __namecall / __index  (Meta Hook)")
if Config.HookMetaMethod then
    stealth_wait(Config.DelayExec)
    safe_call(function()
        local _o; _o = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not checkcaller() then
                if getnamecallmethod() == "FindService" then
                    local svc = select(1, ...)
                    if table.find(SuspiciousServices, svc) then
                        State.IsMetaFS = true
                        return nil
                    end
                end
            end
            return _o(self, ...)
        end))
    end)
end

-- ============================================================
--  PHASE 7 : RemoteFunction.OnClientInvoke scan
-- ============================================================
phase_start("สแกน RemoteFunction.OnClientInvoke")
safe_call(function()
    local scanned = {}
    for _, v in ipairs(getinstances()) do
        if v and v:IsA("RemoteFunction") and not table.find(scanned, v) then
            table.insert(scanned, v)
            local cb = getcallbackvalue(v, "OnClientInvoke")
            if cb then
                State.HasRFCallback = true
                State.RFCallbacks[v] = cb
                table.insert(State.RFInstances, v)
            end
        end
    end
end)

-- ============================================================
--  PHASE 8 : Identity Spoofer
-- ============================================================
phase_start("ซ่อน Executor Identity  (Source Spoof)")
if Config.SpoofIdentity then
    safe_call(function()
        for _, v in ipairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local info = getinfo(v)
                if info and info.source and not string.find(info.source, "game") then
                    if setinfo then
                        pcall(setinfo, v, {source = "=game.CoreGui"})
                    end
                end
            end
        end
    end)
end

-- ============================================================
--  DONE BAR
-- ============================================================
warn("")
local full_bar, _ = make_bar(State._loadTotal, State._loadTotal)
warn(("  [%s] โหลดเสร็จสมบูรณ์  100%%"):format(full_bar))
warn("")
warn(SEP)
warn("  [XIN TOWN] พร้อมใช้งาน! v" .. Config.Version)
warn("  [XIN TOWN] พิมพ์ XIN.Report() เพื่อดูรายงาน Anti-Cheat")
warn("  [XIN TOWN] พิมพ์ XIN.Help()   เพื่อดูคำสั่งทั้งหมด")
warn(SEP)

-- ============================================================
--  PUBLIC API
-- ============================================================
getgenv().XIN = {}

XIN.Report = function()
    local tag = Config.Tag
    warn(SEP)
    warn(tag .. " [ Anti-Cheat Intelligence Report v" .. Config.Version .. " ]")
    warn(SEP)

    if #State.FindServiceHits > 0 then
        warn(tag .. " [FOUND] FindService Scan:")
        for _, svc in ipairs(State.FindServiceHits) do
            local src = State.FindServiceInfo[svc]
            warn(("\t[+] %s -- called by: %s"):format(svc, tostring(src)))
            if src and src.GetFullName then
                warn(("\t    [Script] %s"):format(src:GetFullName()))
            end
        end
    else
        warn(tag .. " [SAFE] FindService: ไม่พบบริการต้องสงสัย")
    end

    if State.IsMetaFS then
        warn(tag .. " [FOUND] __namecall FindService hook triggered")
    end

    if #State.LogServiceConns > 0 then
        warn(tag .. (" [FOUND] LogService Listener : %d จุด"):format(#State.LogServiceConns))
    else
        warn(tag .. " [SAFE] LogService: ไม่พบ")
    end

    if State.DetectStrings then
        warn(tag .. " [FOUND] String-Table Fingerprint (executor-detection log)")
        warn(tag .. "         XIN.ShowStrings() เพื่อดูรายการ")
    end

    if State.CompareTables then
        local subtype = State.AdonisMeta and "Adonis-Meta" or "Unknown"
        warn(tag .. (" [FOUND] compareTables [%s] -- PATCHED"):format(subtype))
        if State.CompareTablesInfo then
            warn(tag .. "         Source: " .. State.CompareTablesInfo)
        end
    else
        warn(tag .. " [SAFE] compareTables: ไม่พบ")
    end

    if State.OverflowPatched then
        warn(tag .. " [FOUND] Overflow C_Closure Check -- PATCHED")
        if State.OverflowInfo then
            for k, v in pairs(State.OverflowInfo) do
                warn(("\t  %s = %s"):format(tostring(k), tostring(v)))
            end
        end
    else
        warn(tag .. " [SAFE] Overflow: ไม่พบ")
    end

    if State.HasRFCallback then
        warn(tag .. " [FOUND] RemoteFunction.OnClientInvoke:")
        for rf, cb in pairs(State.RFCallbacks) do
            local idx = table.find(State.RFInstances, rf) or "?"
            warn(("\t  [%s] %s --> %s"):format(tostring(idx), tostring(rf), tostring(cb)))
        end
        warn(tag .. "         XIN.RFDetail(n) เพื่อดูรายละเอียด")
    else
        warn(tag .. " [SAFE] RemoteFunction.OnClientInvoke: ไม่พบ")
    end

    if Config.BlockLoopCrash then
        warn(tag .. " [ACTIVE] Loop-Crash Timeout Protection: เปิดอยู่")
    end

    warn(SEP)
    warn(tag .. " XIN.Help() เพื่อดูคำสั่งทั้งหมด")
    warn(SEP)
end

XIN.RFDetail = function(n)
    local rf = State.RFInstances[n]
    if not rf then warn("[XIN TOWN] RFDetail: ไม่พบ index " .. tostring(n)); return end
    local cb = State.RFCallbacks[rf]
    warn(("[XIN TOWN] RF[%d] : %s"):format(n, tostring(rf)))
    if cb then
        local ups  = safe_call(getupvalues, cb) or {}
        local cons = safe_call(getconstants, cb) or {}
        local pros = safe_call(getprotos,   cb) or {}
        warn(("  upvalues  : %d"):format(#ups))
        warn(("  constants : %d"):format(#cons))
        warn(("  protos    : %d"):format(#pros))
        safe_call(setclipboard, ("-- XIN TOWN RF[%d] snippet\nfor _,v in pairs(getinstances()) do\n  if v.Name == %q then\n    local cb = getcallbackvalue(v,'OnClientInvoke')\n    if cb then print(debug.info(cb,'slanf')) end\n  end\nend"):format(n, tostring(rf)))
        warn("  [Clipboard] snippet คัดลอกแล้ว")
    end
end

XIN.ShowStrings = function()
    if not State.DetectStrings then
        warn("[XIN TOWN] ไม่พบ String-Table"); return
    end
    warn("[XIN TOWN] String-Table Dump:")
    for i, v in ipairs(State.DetectStringsTbl) do
        warn(("  [%d] %s"):format(i, tostring(v)))
    end
end

XIN.TimingTest = function(method)
    method = method or "namecall"
    if not table.find({"index","namecall","newindex"}, method) then
        warn("[XIN TOWN] method ต้องเป็น: index | namecall | newindex"); return
    end
    for i = 1, 2 do
        stealth_wait(Config.DelayExec)
        local _o; _o = hookmetamethod(game, "__" .. method, newcclosure(function(...)
            return _o(...)
        end))
    end
    warn(("[XIN TOWN] TimingTest [__%s] เสร็จสิ้น (delay %.2fs/hook)"):format(method, Config.DelayExec))
end

XIN.Decompile = function(serviceName)
    local src = State.FindServiceInfo[serviceName]
    if not src then warn("[XIN TOWN] ไม่พบข้อมูล: " .. tostring(serviceName)); return end
    warn("[XIN TOWN] กำลัง decompile:", tostring(src))
    local code = safe_call(decompile, src)
    warn(code or "[XIN TOWN] decompile ล้มเหลว")
end

XIN.KillLogListeners = function()
    if #State.LogServiceConns == 0 then
        warn("[XIN TOWN] ไม่มี LogService connections"); return
    end
    for _, c in ipairs(State.LogServiceConns) do safe_call(function() c:Disable() end) end
    warn(("[XIN TOWN] Killed %d listener(s)"):format(#State.LogServiceConns))
end

XIN.StealthWait = stealth_wait

XIN.Help = function()
    warn(("="):rep(55))
    warn("[XIN TOWN] คำสั่งทั้งหมด:")
    warn("  XIN.Report()             -- รายงาน AC ทั้งหมด")
    warn("  XIN.RFDetail(n)          -- รายละเอียด RemoteFunction[n]")
    warn("  XIN.ShowStrings()        -- dump string-table fingerprint")
    warn("  XIN.TimingTest('method') -- test timing hook")
    warn("  XIN.Decompile('service') -- decompile script FindService")
    warn("  XIN.KillLogListeners()   -- disable LogService connections")
    warn("  XIN.StealthWait(sec)     -- stealth delay")
    warn(("="):rep(55))
end