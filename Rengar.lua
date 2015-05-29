if myHero.charName ~= "Rengar" then return end
	require 'HPrediction'

function Debug(message) print("<font color=\"#FFFFFF\"><b>Rengar:</font> </b><font color=\"#4c934c\">" .. message) end

function OnLoad() 
    local ToUpdate = {}
    ToUpdate.Version = 0.01
    ToUpdate.UseHttps = true
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/BoLRepository/Scripts/master/Rengar.version"
    ToUpdate.ScriptPath =  "/BoLRepository/Scripts/master/Rengar.lua"
    --ToUpdate.SavePath = SCRIPT_PATH.."/Test.lua"
	ToUpdate.SavePath = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FFFFFF\"><b>Rengar: </b></font> <font color=\"#4c934c\">Updated to "..NewVersion..". </b></font>") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#FFFFFF\"><b>Rengar: </b></font> <font color=\"#4c934c\">No Updates Found</b></font>") end
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FFFFFF\"><b>Rengar: </b></font> <font color=\"#4c934c\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FFFFFF\"><b>Rengar: </b></font> <font color=\"#4c934c\">Error while Downloading. Please try again.</b></font>") end
    ScriptUpdate(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

    Spells = {  Q = { Name = "RengarQ", Ready = function() return myHero:CanUseSpell(_Q) end },
            W = { Name = "RengarW", Ready = function() return myHero:CanUseSpell(_W) end, Range = 480 }, --500
            E = { Name = "RengarE", Ready = function() return myHero:CanUseSpell(_E) end, Range = 1000, Speed = 1500, Width = 75, Delay = 0.25 },
            R = { Name = "RengarR", Ready = function() return myHero:CanUseSpell(_R) end } }
    TH = {  Slot = function() return GetInventorySlotItem(3077) or GetInventorySlotItem(3074) or nil end, Ready = function() return myHero:CanUseSpell(TH.Slot) or false end }      

    _SAC = false
    --_TrueRange = myHero.range + GetDistance(myHero.minBBox) + 50
    _TrueRange = myHero.range + GetDistance(myHero.minBBox)
    _LastLeap = 0

    HPred = HPrediction()
    HPred:AddSpell("E","Rengar", {collisionM = true, collisionH = true, delay = Spells.E.Delay, range = Spells.E.Range, speed = Spells.E.Speed, type = "DelayLine", width = Spells.E.Width, IsLowAccuracy = false})

    enemyTable = GetEnemyHeroes()
    minions = minionManager(MINION_ENEMY, Spells.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)
    jminions = minionManager(MINION_JUNGLE, Spells.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)

    Menu = scriptConfig("Rengar", "Rengar")
    Menu:addSubMenu("Combo Menu", "Combo")
        Menu.Combo:addParam("empQ", "Use Empowered Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("empW", "Use Empowered W", SCRIPT_PARAM_ONOFF, false)
        Menu.Combo:addParam("empE", "Use Empowered E", SCRIPT_PARAM_ONOFF, true)
        Menu.Combo:addParam("sep", "", SCRIPT_PARAM_INFO, "")
        Menu.Combo:addParam("comboType", "Combo Type", SCRIPT_PARAM_LIST, 1, { "Savagery (Q)", "Battle Roar (W)", "Bola Strike (E)"})
        Menu.Combo:addParam("comboDelay", "Leap Combo Delay", SCRIPT_PARAM_SLICE, 1000, 0, 2000, 0)
        --Menu.combo:addParam("comboMode", "Switch Combo Mode (Default: T)", SCRIPT_PARAM_ONKEYTOGGLE, false, GetKey("T"))
    Menu:addSubMenu("Harass Menu", "Harass")
        Menu.Harass:addParam("empQ", "Use Empowered Q", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("empW", "Use Empowered W", SCRIPT_PARAM_ONOFF, true)
        Menu.Harass:addParam("empE", "Use Empowered E", SCRIPT_PARAM_ONOFF, true)
    Menu:addParam("sep", "", SCRIPT_PARAM_INFO, "")
    Menu:addParam("autoHeal", "Auto-Heal", SCRIPT_PARAM_ONOFF, false)
    Menu:addParam("autoHealHP", "Auto-Heal % Health", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
    Menu:addParam("sep", "", SCRIPT_PARAM_INFO, "") 
    Menu:addParam("comboKey", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Menu:addParam("harassKey", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("C"))

    DelayAction(function() 
        if _G.AutoCarry then
            Debug("Found SAC!")
            _SAC = true
        end
    end, 6)
end

function OnTick()
    if myHero.dead then return end
    if _TrueRange > 300 then _TrueRange = myHero.range + GetDistance(myHero.minBBox) end
    
    local function getTarget()
        if _SAC and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then 
            return _G.AutoCarry.Crosshair:GetTarget()
        end
        return nil
    end
    Target = getTarget()

    if Menu.autoHeal and ((myHero.health / myHero.maxHealth * 100) < Menu.autoHealHP) then
        if Spells.W.Ready == false then return end
        if myHero.mana == 5 then CastSpell(_W) end

        for i, enemy in pairs(enemyTable) do
            if GetDistance(myHero, enemy) < Spells.W.Range and myHero.mana == 4 then    
                CastSpell(_W)
            end
        end
    end

    if Target and Menu.comboKey then
        if myHero.mana == 5 then
            if (GetTickCount() - _LastLeap) <= Menu.Combo.comboDelay then
                if Menu.Combo.comboType == 1 then CastSpell(_Q) end
                if Menu.Combo.comboType == 2 then CastW(Target) end
                if Menu.Combo.comboType == 3 then CastE(Target) end
            else
                if Menu.Combo.empQ then CastQ(Target) end              
                if Menu.Combo.empW then CastW(Target) end
                if Menu.Combo.empE then CastE(Target) end   
            end       
        elseif myHero.mana < 5 then
            CastQ(Target)
            CastW(Target)
            CastE(Target)
        end
    end

    if Target and Menu.harassKey then
        if myHero.mana == 5 then
            if Menu.Harass.empQ then CastQ(Target) end              
            if Menu.Harass.empW then CastW(Target) end
            if Menu.Harass.empE then CastE(Target) end          
        else
            CastQ(Target)
            CastW(Target)
            CastE(Target)
        end
    end
end

function CastQ(t)
    if GetDistance(t, myHero) < _TrueRange then 
        CastSpell(_Q) 
    end
end

function CastW(t)
    if GetDistance(t, myHero) < Spells.W.Range then 
        CastSpell(_W) 
    end
end

function CastE(t)
    EPos, EHitChance = HPred:GetPredict("E", t, myHero)
    if EPos and EHitChance and EHitChance >= 2 then
        CastSpell(_E, EPos.x, EPos.z)
    end
end

function OnDraw()
    --if Target then DrawCircle(Target.x, Target.y, Target.z, 200, 0xFFFFFF) end
    --[[if GetTickCount() - _LastLeap <= Menu.comboDelay then
        DrawText("LEAPING", 20, 100, 100, ARGB(255,178, 0 , 0 ))
    end]]
end

function OnCreateObj(object)
    --if object and object.name == "Rengar_LeapSound.troy" and GetDistance(myHero, object) < 50 then 
    if object and object.name:lower():find("leap") and GetDistance(myHero, object) < 50 then
        _LastLeap = GetTickCount()
    end
end

--[[
    AUTO-UPDATER - CREDIT: Aroc
]]
class "ScriptUpdate"
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    AddDrawCallback(function() self:OnDraw() end)
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
    print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function ScriptUpdate:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function ScriptUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function ScriptUpdate:DownloadUpdate()
    if self.GotScriptUpdate then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            if newf:len() ~= self.Size then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
                return
            end
            local newf = Base64Decode(newf)
            if type(load(newf)) ~= 'function' then
                if self.CallbackError and type(self.CallbackError) == 'function' then
                    self.CallbackError()
                end
            else
                local f = io.open(self.SavePath,"w+b")
                f:write(newf)
                f:close()
                if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                    self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
                end
            end
        end
        self.GotScriptUpdate = true
    end
end
--[[
    AUTO-UPDATER - CREDIT: Aroc
]]
