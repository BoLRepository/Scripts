if myHero.charName ~= "Rengar" then return end
	require 'HPrediction'

function Debug(message) print("<font color=\"#FFFFFF\"><b>Rengar:</font> </b><font color=\"#4c934c\">" .. message) end

function OnLoad() 
	Debug("Loaded!")

	Spells = {	Q = { Name = "RengarQ", Ready = function() return myHero:CanUseSpell(_Q) end},
				W = { Name = "RengarW", Ready = function() return myHero:CanUseSpell(_W) end, Range = 500},
				E = { Name = "RengarE", Ready = function() return myHero:CanUseSpell(_E) end, Range = 1000, Speed = 1500, Width = 75, Delay = 0.25},
				R = { Name = "RengarR", Ready = function() return myHero:CanUseSpell(_R) end} }

	TH = {	Slot = function() return GetInventorySlotItem(3077) or GetInventorySlotItem(3074) or nil end, Ready = function() return myHero:CanUseSpell(TH.Slot) or false end }		

	Menu = scriptConfig("Rengar", "Rengar")
		Menu:addParam("autoHeal", "Auto-Heal", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("autoHealHP", "Auto-Heal % Health", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
		Menu:addParam("sep", "", SCRIPT_PARAM_INFO, "")	
		Menu:addParam("empQ", "Use Empowered Q", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("empW", "Use Empowered W", SCRIPT_PARAM_ONOFF, false)
		Menu:addParam("empE", "Use Empowered E", SCRIPT_PARAM_ONOFF, true)
		Menu:addParam("sep", "", SCRIPT_PARAM_INFO, "")	
		Menu:addParam("comboKey", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		Menu:addParam("comboMode", "Switch Combo Mode (Default: T)", SCRIPT_PARAM_ONKEYTOGGLE, false, GetKey("T"))

	_SAC = false
	_TrueRange = 0
	_LastLeap = 0
	_ComboMode = "oneshot"

	HPred = HPrediction()
  	HPred:AddSpell("E","Rengar", {collisionM = true, collisionH = true, delay = Spells.E.Delay, range = Spells.E.Range, speed = Spells.E.Speed, type = "DelayLine", width = Spells.E.Width, IsLowAccuracy = false})

	enemyTable = GetEnemyHeroes()
	minions = minionManager(MINION_ENEMY, Spells.E.Range, myHero, MINION_SORT_MAXHEALTH_DEC)

	DelayAction(function() 
		if _G.AutoCarry then
			Debug("Found SAC!")
			_SAC = true
		end
	end, 6)
end

function OnTick() 
	if myHero.dead then return end
	--_TrueRange = myHero.range + GetDistance(myHero.minBBox) + 50
	_TrueRange = myHero.range + GetDistance(myHero.minBBox)

	local function getTarget()
		if _SAC and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then 
			return _G.AutoCarry.Crosshair:GetTarget()
		end
		return nil
	end
	Target = getTarget()

	if Menu.comboMode then
		if _ComboMode == "oneshot" then 
			_ComboMode = "root"
		elseif _ComboMode == "root" then 
			_ComboMode = "oneshot"
		end
		Menu.comboMode = false
	end

	--if _LastLeap then Debug("Last Leap: " .. tostring(GetTickCount() - _LastLeap)) end
	if Target and Menu.comboKey then
		if GetTickCount() - _LastLeap <= 1500 then
			if myHero.mana == 5 then
				if _ComboMode == "oneshot" then Cast(Target, "Q") end 
				if _ComboMode == "root" then Cast(Target, "E") end
			else
				Cast(Target, "Q")
				Cast(Target, "E")
				if TH.Slot ~= nil and GetDistance(Target, myHero) < _TrueRange and TH.Ready == true then CastSpell(TH.Slot) end
				Cast(Target, "W")				
			end
		elseif myHero.mana == 5 then
			if Menu.empQ then Cast(Target, "Q") end
			if Menu.empE then Cast(Target, "E") end				
			if Menu.empW then Cast(Target, "W") end				
		end
		Cast(Target, "Q")
		Cast(Target, "E")
		Cast(Target, "W")
	end

	if Menu.autoHeal and ((myHero.health / myHero.maxHealth * 100) < Menu.autoHealHP) then
		if Spells.W.Ready == false then return end
		if myHero.mana == 5 then CastSpell(_W) end

		for i, enemy in pairs(enemyTable) do
			if GetDistance(myHero, enemy) < Spells.W.Range and myHero.mana == 4 then	
				CastSpell(_W)
			end
		end
	end
end

function OnDraw()
	DrawText(_ComboMode, 15, 50, 50, ARGB(255,178, 0 , 0 ))
end

function OnCreateObj(object)
	if object and object.name == "Rengar_LeapSound.troy" and GetDistance(myHero, object) < 50 then 
		_LastLeap = GetTickCount()
	end
end

function Cast(unit, s) 
	if s == "Q" then
		if GetDistance(unit, myHero) < _TrueRange then 
			CastSpell(_Q) 
		end
	elseif s == "W" then
		if GetDistance(unit, myHero) < Spells.W.Range then 
			CastSpell(_W) 
		end
	elseif s == "E" then
		EPos, EHitChance = HPred:GetPredict("E", unit, myHero)
		if EPos and EHitChance and EHitChance >= 2 then
			CastSpell(_E, EPos.x, EPos.z)
		end
	end
end
