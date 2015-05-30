if myHero.charName ~= "Draven" then return end
    require "SxOrbWalk"
    require "HPrediction"

function Debug(message) print("<font color=\"#4c934c\"><b>Draven:</font> </b><font color=\"#FFFFFF\">" .. message) end

function OnLoad() 
    local ToUpdate = {}
    ToUpdate.Version = 0.01
    ToUpdate.UseHttps = true
    ToUpdate.Host = "raw.githubusercontent.com"
    ToUpdate.VersionPath = "/BoLRepository/Scripts/master/Draven.version"
    ToUpdate.ScriptPath =  "/BoLRepository/Scripts/master/Draven.lua"
    ToUpdate.SavePath = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
    ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) print("<font color=\"#FFFFFF\"><b>Draven: </b></font> <font color=\"#4c934c\">Updated to "..NewVersion..". </b></font>") end
    ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#FFFFFF\"><b>Draven: </b></font> <font color=\"#4c934c\">No Updates Found</b></font>") end
    ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#FFFFFF\"><b>Draven: </b></font> <font color=\"#4c934c\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
    ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#FFFFFF\"><b>Draven: </b></font> <font color=\"#4c934c\">Error while Downloading. Please try again.</b></font>") end
    ScriptUpdate(ToUpdate.Version,ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)

    Spells = {  Q = { Name = "DravenSpinning",   Ready = function() return myHero:CanUseSpell(_Q) end, Delay = 0.25},
                W = { Name = "DravenFury",       Ready = function() return myHero:CanUseSpell(_W) end, Delay = 0.25},
                E = { Name = "DravenDoubleShot", Ready = function() return myHero:CanUseSpell(_E) end, Delay = 0.25, Width = 130, Speed = 1400, Range = 1100}, --incorrect?
                R = { Name = "DravenRCast",      Ready = function() return myHero:CanUseSpell(_R) end, Delay = 0.5, Width = 160, Speed = 2000} }

    _SAC = false
    _Axes = {}
    _AxesHeld = 0
    _AxesDelay = 1250

    HPred = HPrediction()
    HPred:AddSpell("E","Draven", {collisionM = false, collisionH = false, delay = Spells.E.Delay, range = Spells.E.Range, speed = Spells.E.Speed, type = "DelayLine", width = Spells.E.Width, IsLowAccuracy = false})

    enemyTable = GetEnemyHeroes()
    
    Menu = scriptConfig("Draven", "Draven")
    Menu:addSubMenu("Spinning Axe (Q)", "SpinningAxe")
        Menu.SpinningAxe:addParam("drawmouse", "Mouse Circle: Draw", SCRIPT_PARAM_ONOFF, true)
        Menu.SpinningAxe:addParam("mousesize", "Mouse Circle: Catch Radius", SCRIPT_PARAM_SLICE, 400, 100, 1000, 0)
        Menu.SpinningAxe:addParam("catchoffset", "Reticle: Catch Offset", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
        Menu.SpinningAxe:addParam("stopmove", "Reticle: Stop Movement Near", SCRIPT_PARAM_ONOFF, false)
        Menu.SpinningAxe:addParam("sep", "", SCRIPT_PARAM_INFO, "")
        Menu.SpinningAxe:addParam("catchall", "Catch ALL Axes (Default: T)", SCRIPT_PARAM_ONKEYTOGGLE, false, GetKey("T"))
        Menu.SpinningAxe:addParam("catchallt", "  --> Toggle OFF w/ Combo", SCRIPT_PARAM_ONOFF, true)
    Menu:addSubMenu("Blood Rush (W)", "BloodRush")
        Menu.BloodRush:addParam("combo", "Use in Combo", SCRIPT_PARAM_ONOFF, false)
        Menu.BloodRush:addParam("harass", "Use in Harass", SCRIPT_PARAM_ONOFF, false)
        Menu.BloodRush:addParam("laneclear", "Use in LaneClear", SCRIPT_PARAM_ONOFF, false)
        Menu.BloodRush:addParam("sep", "", SCRIPT_PARAM_INFO, "")
        Menu.BloodRush:addParam("mana", "Minimum % Mana", SCRIPT_PARAM_SLICE, 35, 0, 100, 0)
    Menu:addSubMenu("Stand Aside (E)", "StandAside")
        Menu.StandAside:addParam("combo", "Use in Combo", SCRIPT_PARAM_ONOFF, true)
        Menu.StandAside:addParam("harass", "Use in Harass", SCRIPT_PARAM_ONOFF, false)
        Menu.StandAside:addParam("laneclear", "Use in LaneClear", SCRIPT_PARAM_ONOFF, false)
        Menu.StandAside:addParam("sep", "", SCRIPT_PARAM_INFO, "")
        Menu.StandAside:addParam("mana", "Minimum % Mana", SCRIPT_PARAM_SLICE, 35, 0, 100, 0)
        Menu.StandAside:addParam("ks", "Killsteal", SCRIPT_PARAM_ONOFF, false)
    Menu:addSubMenu("Whirling Death (R)", "WhirlingDeath")
        Menu.WhirlingDeath:addParam("ks", "Killsteal", SCRIPT_PARAM_ONOFF, false)
        Menu.WhirlingDeath:addParam("ksr", "Maximum Range", SCRIPT_PARAM_SLICE, 2000, 0, 4000, 0)
        Menu:addSubMenu('Orbwalker', 'Orbwalker')
        SxOrb:LoadToMenu(Menu.Orbwalker, true)
        SxOrb:RegisterHotKey('fight',     Menu, 'comboKey')
        SxOrb:RegisterHotKey('harass',    Menu, 'harassKey')
        SxOrb:RegisterHotKey('laneclear', Menu, 'laneclearKey')
        SxOrb:RegisterHotKey('lasthit',   Menu, 'lasthitKey')
    Menu:addParam("comboKey", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    Menu:addParam("harassKey", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("C"))
    Menu:addParam("laneclearKey", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("V"))
    Menu:addParam("lasthitKey", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("X"))
    Menu.SpinningAxe:permaShow("catchall")
    Menu.SpinningAxe:permaShow("catchallt")

    DelayAction(function() 
        if _G.AutoCarry and Menu.Orbwalker.General.Enabled and Menu.Orbwalker.General.Enabled == true then
            Debug("Found SAC!")
            Menu.Orbwalker.General.Enabled = false
            _SAC = true
        end
    end, 6)
end

function OnTick() 
    if myHero.dead then 
        _AxesHeld = 0
        _Axes = {}
        return
    end

    if _Axes[1] ~= nil and (GetTickCount() - _Axes[1].t) >= _AxesDelay then
        table.remove(_Axes, 1) 
    end

    local function getTarget()
        if _SAC and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then 
            return _G.AutoCarry.Crosshair:GetTarget()
        elseif Menu.Orbwalker.General.Enabled and Menu.Orbwalker.General.Enabled == true and ValidTarget(SxOrb:GetTarget()) then
            return SxOrb:GetTarget()
        end
        return nil
    end
    Target = getTarget()

    if Menu.comboKey and Menu.SpinningAxe.catchall and Menu.SpinningAxe.catchallt then Menu.SpinningAxe.catchall = false end
    if Menu.comboKey or Menu.harassKey or Menu.lasthitKey or Menu.laneclearKey then catchAxes() end

    for i, enemy in pairs(enemyTable) do
        if enemy.isDead then return end
        --Invulnerability Check // Tryn Kayle etc.
        if Menu.StandAside.ks and Spells.E.Ready and (getDmg('E', enemy, myHero) < enemy.health) then
            CastE(enemy)
        end

        if Menu.WhirlingDeath.ks and Spells.R.Ready and (getDmg('R', enemy, myHero) < enemy.health) then
           CastR(enemy)
        end
    end

    if not Target then return end
    if (Menu.comboKey and Menu.BloodRush.combo) or (Menu.harassKey and Menu.BloodRush.harass) or (Menu.laneclearKey and Menu.BloodRush.laneclear) then 
        if not TargetHaveBuff("dravenfurybuff", myHero) and Spells.W.Ready and ((myHero.mana / myHero.maxMana * 100) > Menu.BloodRush.mana) then 
            CastW(Target)
        end
    end

    if (Menu.comboKey and Menu.StandAside.combo) or (Menu.harassKey and Menu.StandAside.harass) or (Menu.laneclearKey and Menu.StandAside.laneclear) then 
        if Spells.E.Ready and ((myHero.mana / myHero.maxMana * 100) > Menu.StandAside.mana) then
            CastE(Target)
        end
    end
end

function OnDraw() 
    if myHero.dead then return end
    if Menu.SpinningAxe.catchall ~= true and Menu.SpinningAxe.drawmouse then DrawCircle(mousePos.x, mousePos.y, mousePos.z, Menu.SpinningAxe.mousesize, 0xFFFFFF) end
    for i, v in ipairs(_Axes) do 
        if _Axes[i] ~= nil then
            DrawCircle(_Axes[i].x, _Axes[i].y, _Axes[i].z, 125, 0xFFFFFF) 
        end
    end
end

function OnProcessSpell(unit, spell) 
    if unit.isMe then
        if spell.name:lower():find("attack") then
            if Spells.Q.Ready and _AxesHeld < 2 then 
                CastSpell(_Q)
            end
        end
    end
end

function OnCreateObj(object) 
    if object.name == "Draven_Base_Q_buf.troy" then _AxesHeld = _AxesHeld + 1 end
    if object.name == "Draven_Base_Q_reticle.troy" then 
        _Axes[#_Axes + 1] = {   t = GetTickCount(), 
                                x = object.x,
                                y = object.y,
                                z = object.z   }
    end
end

function OnDeleteObj(object) 
    if object.name == "Draven_Base_Q_buf.troy" then _AxesHeld = _AxesHeld - 1 end
end

--={====================================}=--
--={            LOGIKERINO              }=--
--={===================================~}=--

function CastW(t)
    if GetDistance(myHero, Target) < Spells.E.Range then
        CastSpell(_W)
    end
end

function CastE(t)
    EPos, EHitChance = HPred:GetPredict("E", t, myHero)
    if EPos and EHitChance and EHitChance >= 2 then
        CastSpell(_E, EPos.x, EPos.z)
    end
end

function CastR(t)
    HPred:AddSpell("R","Draven", {collisionM = false, collisionH = true, delay = Spells.R.Delay, range = Menu.WhirlingDeath.ksr, speed = Spells.R.Speed, type = "DelayLine", width = Spells.R.Width, IsLowAccuracy = false})
    EPos, EHitChance = HPred:GetPredict("R", t, myHero)
    if EPos and EHitChance and EHitChance >= 2 then
        CastSpell(_R, EPos.x, EPos.z)
    end
end

function catchAxes()
    --Check if movement disabled by accident
    if #_Axes < 1 then  
        if _SAC then
            _G.AutoCarry.MyHero:MovementEnabled(true)
            AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
            return 
        elseif Menu.Orbwalker.General.Enabled then
            SxOrb:EnableMove()
        end
    end

    for k, v in ipairs(_Axes) do        
        --Stop moving near catch reticle
        catchDist = GetDistance(myHero, _Axes[k])
        if catchDist <= Menu.SpinningAxe.catchoffset and Menu.SpinningAxe.stopmove then
            if _SAC then
                _G.AutoCarry.MyHero:MovementEnabled(false)
                break
            elseif Menu.Orbwalker.General.Enabled then
                SxOrb:DisableMove()
                break
            end
        else    
            if _SAC then
                _G.AutoCarry.MyHero:MovementEnabled(true)
                AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
            elseif Menu.Orbwalker.General.Enabled then
                SxOrb:EnableMove()
            end
        end

        --Do we catch it?
        mouseDist = GetDistance(mousePos, _Axes[k])
        if Menu.SpinningAxe.catchall or mouseDist <= Menu.SpinningAxe.mousesize then
            if _SAC then
                AutoCarry.Orbwalker:OverrideOrbwalkLocation(_Axes[k])
                break
            elseif Menu.Orbwalker.General.Enabled then
                if SxOrb:CanMove() then
                    SxOrb:DisableMove()
                    myHero:MoveTo(_Axes[k].x, _Axes[k].z)
                    break
                end
            end
        end
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
