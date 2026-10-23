local _, Skada = ...
Skada:RegisterModule("SindraFF", function(L, P)
	local mode = Skada:NewModule("Sindragosa 25H - Ultima Face")
	local mode_detail = mode:NewModule("Detalle por PJ")
	local mode_report = mode:NewModule("Muertos por Magia")

	local Sindra = {}
	local inP3 = false
	local combatStart = 0

	local function Reset()
		wipe(Sindra)
		inP3 = false
		combatStart = 0
	end

	local function GetTimeStr(sec)
		if sec <= 0 then return "0:00,00s" end
		local m = math.floor(sec / 60)
		local secs = math.floor(sec % 60)
		local ms = math.floor((sec % 1) * 100)
		return string.format("%d:%02d,%02ds", m, secs, ms)
	end

	function mode_detail:Enter(win, id, label)
		win.actorname = label
		win.title = string.format("Magia %s - Dañó %s", label, Skada:FormatNumber(Sindra[label] and Sindra[label].total or 0))
	end

	function mode_detail:Update(win)
		if not win.actorname then return end
		local info = Sindra[win.actorname]
		if not info then return end
		local nr = 0
		for victima, dmg in pairs(info.targets) do
			nr = nr + 1
			local d = win:actor(nr, victima)
			d.value = dmg
			d.valuetext = info.muertos[victima] and Skada:FormatNumber(dmg) .. " - MATO" or Skada:FormatNumber(dmg)
		end
	end

	function mode_report:Enter(win, id, label) win.actorname = label end
	function mode_report:Update(win)
		if not win.actorname then return end
		local info = Sindra[win.actorname]
		if not info then return end
		local nr = 0
		for muerto in pairs(info.muertos) do
			nr = nr + 1
			local d = win:actor(nr, muerto)
			d.value = 999999
			d.valuetext = "MUERTO - Carga " .. info.maxCarga
		end
	end

	function mode:Update(win, set)
		win.title = "Sindragosa 25H P3 - Magia Desencadenada"
		if not inP3 then
			win:actor(1, "Esperando Ultima Face (35%)").valuetext = "No es P3"
			return
		end
		local nr = 0
		for name, info in pairs(Sindra) do
			nr = nr + 1
			local d = win:actor(nr, name, name, info.class)
			d.value = info.total
			local muertos = 0
			for _ in pairs(info.muertos) do muertos = muertos + 1 end
			if muertos > 0 then
				d.valuetext = string.format("Magia %d Dañó %s Mató %d %s", info.maxCarga, Skada:FormatNumber(info.total), muertos, info.time)
			else
				d.valuetext = string.format("Magia %d Dañó %s %s", info.maxCarga, Skada:FormatNumber(info.total), info.time)
			end
		end
		if nr == 0 then win:actor(1, "P3 Limpia").valuetext = "Sin fuego amigo" end
	end

	function mode:OnEnable()
		self.metadata = {
			showspots = true,
			ordersort = true,
			click1 = mode_detail,
			click2 = mode_report,
			icon = [[Interface\ICONS\spell_frost_frostnova]]
		}
		mode_detail.metadata = {showspots=true, click1=mode_report, icon=[[Interface\ICONS\spell_arcane_arcane04]]}
		mode_report.metadata = {showspots=true, icon=[[Interface\ICONS\ability_creature_cursed_02]]}
		
		Skada:AddMode(self)

		local frame = CreateFrame("Frame")
		frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		frame:RegisterEvent("UNIT_HEALTH")
		frame:RegisterEvent("PLAYER_REGEN_DISABLED")

		frame:SetScript("OnEvent", function(_, event, ...)
			if event == "PLAYER_REGEN_DISABLED" then
				-- Reset en cada try
				if not inP3 then Reset() end
				return
			end

			if event == "UNIT_HEALTH" then
				local unit = ...
				if unit ~= "boss1" and unit ~= "boss2" then return end
				if not UnitExists(unit) then return end
				if not string.find((UnitName(unit) or ""), "Sindragosa") then return end
				local hp = UnitHealth(unit) / UnitHealthMax(unit)
				if hp <= 0.355 and not inP3 then
					inP3 = true
					combatStart = GetTime()
					wipe(Sindra)
					print("|cFFFF0000[KadeSkada]|r >>> ULTIMA FACE (35%) - Registrando Magia Desencadenada <<<")
				end
				if hp > 0.40 and inP3 then -- Wipe
					inP3 = false
				end
				return
			end

			if not inP3 then return end
			local _, subevent, _, _, srcName, _, _, _, dstName, _, _, spellID, _, _, amount, _, _, _, _, stack = CombatLogGetCurrentEventInfo()
			if not srcName then return end

			local isMagic = (spellID == 69762 or spellID == 69766 or spellID == 70126 or spellID == 70127 or spellID == 69729)

			if (subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_APPLIED_DOSE" or subevent == "SPELL_AURA_REFRESH") and isMagic then
				if not Sindra[dstName] then
					local _, class = UnitClass(dstName)
					Sindra[dstName] = {cargas=0, maxCarga=0, total=0, targets={}, muertos={}, time="0:00,00s", firstHit=GetTime(), lastHit=GetTime(), class=class or "UNKNOWN"}
				end
				local c = stack or 1
				if subevent == "SPELL_AURA_APPLIED_DOSE" then c = (Sindra[dstName].cargas or 0) + 1 end
				Sindra[dstName].cargas = c
				if c > Sindra[dstName].maxCarga then Sindra[dstName].maxCarga = c end
			end

			if (subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE") and isMagic then
				if not dstName then return end
				if srcName == dstName then return end
				if not Sindra[srcName] then
					local _, class = UnitClass(srcName)
					Sindra[srcName] = {cargas=8, maxCarga=8, total=0, targets={}, muertos={}, time="0:00,00s", firstHit=GetTime(), lastHit=GetTime(), class=class or "UNKNOWN"}
				end
				Sindra[srcName].targets[dstName] = (Sindra[srcName].targets[dstName] or 0) + (amount or 0)
				Sindra[srcName].total = Sindra[srcName].total + (amount or 0)
				Sindra[srcName].lastHit = GetTime()
				Sindra[srcName].time = GetTimeStr(Sindra[srcName].lastHit - combatStart)
			end

			if subevent == "UNIT_DIED" and dstName then
				for _, info in pairs(Sindra) do
					if info.targets[dstName] then info.muertos[dstName] = true end
				end
			end
		end)

		SLASH_SINDRA1 = "/sindra"
		SlashCmdList["SINDRA"] = function() inP3 = true combatStart = GetTime() wipe(Sindra) print("|cFFFF0000[Sindra]|r P3 FORZADA") end
	end

	function mode:OnDisable() Skada:RemoveMode(self) end
end)
