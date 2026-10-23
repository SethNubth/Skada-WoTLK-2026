local _, Skada = ...
local Private = Skada.Private
Skada:RegisterModule("Parry-Haste", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Parry-Haste")
	local mode_target = mode:NewModule("Target List")
	local pairs, format, uformat = pairs, string.format, Private.uformat
	local classfmt = Skada.classcolors.format
	local mode_cols = nil

	local parrybosses = {
		[10184] = true, -- Onyxia
		[34797] = true, -- Icehowl
		[34799] = true, -- Dreadscale
		[35144] = true, -- Acidmaw
		[36853] = true, -- Sindragosa
		[36855] = true, -- Lady Deathwhisper
		[39863] = true, -- Halion
		[15932] = true, -- Gluth
		[15989] = true, -- Sapphiron
		[15990] = true, -- Kel'Thuzad
		[33271] = true, -- General Vezax
	}

	local DragonOnly = {
		[10184] = true, [36853] = true, [39863] = true, [15989] = true,
	}

	local function FormatTimeSeth(sec)
		if not sec then return "0:00,00s" end
		local mins = math.floor(sec / 60)
		local secs = math.floor(sec % 60)
		local ms = math.floor((sec % 1) * 100)
		return string.format("%d:%02d,%02ds", mins, secs, ms)
	end

	local function format_valuetext(d, total, metadata, subview)
		d.valuetext = Skada:FormatValueCols(
			mode_cols.Count and d.value,
			mode_cols[subview and "sPercent" or "Percent"] and Skada:FormatPercent(d.value, total)
		)
		if metadata and d.value > metadata.maxvalue then metadata.maxvalue = d.value end
	end

	local lastParryInfo = {}

	local function log_parry(set, actorname, actorid, actorflags, dstName, extraDamage)
		local actor = Skada:GetActor(set, actorname, actorid, actorflags)
		if not actor then return end

		if extraDamage and extraDamage > 0 then
			if actor.parrydetails and lastParryInfo[actorname] then
				local idx = lastParryInfo[actorname].index
				if actor.parrydetails[idx] and actor.parrydetails[idx].damage == 0 then
					actor.parrydetails[idx].damage = extraDamage
					actor.parrytotalDamage = (actor.parrytotalDamage or 0) + extraDamage
				end
			end
			return
		end

		actor.parry = (actor.parry or 0) + 1
		set.parry = (set.parry or 0) + 1

		actor.parrydetails = actor.parrydetails or {}
		actor.parrytotalDamage = actor.parrytotalDamage or 0
		local cTime = Skada.current and Skada.current:GetTime() or 0
		table.insert(actor.parrydetails, {
			id = actor.parry,
			damage = 0,
			boss = dstName or "Boss",
			combatTime = cTime,
			combatTimeFormatted = FormatTimeSeth(cTime),
		})
		lastParryInfo[actorname] = {time = GetTime(), boss = dstName, index = #actor.parrydetails}

		if (set == Skada.total and not P.totalidc) or not dstName then return end
		actor.parrytargets = actor.parrytargets or {}
		actor.parrytargets[dstName] = (actor.parrytargets[dstName] or 0) + 1

		-- POR DEFECTO AVISAR EN BANDA CON TIEMPO
		if M.parryannounce and set ~= Skada.total then
			local msg = format("%s parreó a %s (%d) - %s [Parry %d]", dstName, actorname, actor.parrytargets[dstName] or 1, FormatTimeSeth(cTime), actor.parry)
			Skada:SendChat(msg, M.parrychannel, "preset")
		end
	end

	local GetCreatureId = Skada.GetCreatureId
	local function is_parry_boss(name, guid)
		if M.onlyDragons then
			if DragonOnly[name] or DragonOnly[GetCreatureId(guid)] then return true end
			return false
		end
		if parrybosses[name] or parrybosses[GetCreatureId(guid)] then
			parrybosses[name] = parrybosses[name] or true
			return true
		end
		return false
	end

	local function spell_missed(t)
		if t.misstype == "PARRY" and t.dstName and is_parry_boss(t.dstName, t.dstGUID) then
			local actorid, actorname, actorflags = Skada:FixMyPets(t.srcGUID, t.srcName, t.srcFlags)
			Skada:DispatchSets(log_parry, actorname, actorid, actorflags, t.dstName, nil)
		end
	end

	local function boss_damage_after_parry(t)
		if not t.srcName or not is_parry_boss(t.srcName, t.srcGUID) then return end
		local amount = t.amount or 0
		if amount <= 0 then return end
		for actorname, info in pairs(lastParryInfo) do
			if GetTime() - info.time <= 3.5 and info.boss == t.srcName then
				Skada:DispatchSets(log_parry, actorname, nil, nil, t.srcName, amount)
				lastParryInfo[actorname] = nil
				break
			end
		end
	end

	function mode_target:Enter(win, id, label, class)
		win.actorid, win.actorname, win.actorclass = id, label, class
		win.title = format(L["%s's targets"], classfmt(class, label))
	end

	function mode_target:Update(win, set)
		win.title = uformat(L["%s's targets"], classfmt(win.actorclass, win.actorname))
		if not set or not win.actorname then return end
		local actor = set:GetActor(win.actorname, win.actorid)
		if actor and actor.parrydetails and M.showParryDetails then
			if win.metadata then win.metadata.maxvalue = 0 end
			for i, detail in ipairs(actor.parrydetails) do
				local d = win:actor(i, detail.boss)
				d.class = "BOSS"
				d.value = detail.damage
				d.valuetext = Skada:FormatValueCols(format("= %d", detail.damage), format("%s %s", detail.boss, detail.combatTimeFormatted))
			end
			return
		end
		local total = (actor and not actor.enemy) and actor.parry
		local targets = (total and total > 0) and actor.parrytargets
		if not targets then return end
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		for targetname, count in pairs(targets) do
			nr = nr + 1
			local d = win:actor(nr, targetname)
			d.class = "BOSS"
			d.value = count
			format_valuetext(d, total, win.metadata, true)
		end
	end

	function mode:Update(win, set)
		win.title = win.class and format("%s (%s)", L["Parry-Haste"], L[win.class]) or L["Parry-Haste"]
		local total = set and set:GetTotal(win.class, nil, "parry")
		if not total or total == 0 then return end
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		local actors = set.actors
		for actorname, actor in pairs(actors) do
			if win:show_actor(actor, set, true) and actor.parry then
				nr = nr + 1
				local d = win:actor(nr, actor, actor.enemy, actorname)
				d.value = actor.parry
				if M.showTotalDamage and actor.parrytotalDamage then
					d.valuetext = Skada:FormatValueCols(format("%d Parry", actor.parry), Skada:FormatNumber(actor.parrytotalDamage))
				else
					format_valuetext(d, total, win.metadata)
				end
			end
		end
	end

	function mode:GetSetSummary(set, win)
		if not set then return end
		return set:GetTotal(win and win.class, nil, "parry") or 0
	end

	function mode:OnEnable()
		self.metadata = {
			showspots = true, ordersort = true, filterclass = true, click1 = mode_target,
			columns = {Count = true, Percent = false, sPercent = false},
			icon = [[Interface\ICONS\ability_parry]]
		}
		mode_cols = self.metadata.columns
		mode_target.nototal = true
		Skada:RegisterForCL(spell_missed, {src_is_interesting = true, dst_is_not_interesting = true}, "SPELL_MISSED", "SWING_MISSED")
		Skada:RegisterForCL(boss_damage_after_parry, {src_is_not_interesting = true}, "SWING_DAMAGE", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE")
		Skada:AddMode(self)
	end

	function mode:OnDisable() Skada:RemoveMode(self) end

	function mode:OnInitialize()
		-- POR DEFECTO TODO ACTIVADO Y AVISAR EN BANDA
		M.parrychannel = M.parrychannel or "AUTO"
		if M.parryannounce == nil then M.parryannounce = true end
		if M.onlyDragons == nil then M.onlyDragons = true end
		if M.showTotalDamage == nil then M.showTotalDamage = true end
		if M.showParryDetails == nil then M.showParryDetails = true end

		O.modules.args.Parry = {
			type = "group", name = self.localeName, desc = format(L["Options for %s."], self.localeName),
			args = {
				header = {type = "description", name = self.localeName.." - SethNubth v3.2", fontSize = "large", image = [[Interface\ICONS\ability_parry]], imageWidth = 18, imageHeight = 18, imageCoords = Skada.cropTable, width = "full", order = 0},
				sep = {type = "description", name = " ", width = "full", order = 1},
				parryannounce = {type = "toggle", name = format(L["Announce %s"], self.localeName).." (POR DEFECTO BANDA)", order = 10, width = "double", get = function() return M.parryannounce end, set = function(_, v) M.parryannounce = v end},
				parrychannel = {type = "select", name = L["Channel"], values = {AUTO = L["Instance"], SELF = L["Self"]}, order = 20, width = "double", get = function() return M.parrychannel end, set = function(_, v) M.parrychannel = v end},
				sep2 = {type = "description", name = " ", width = "full", order = 25},
				onlyDragons = {type = "toggle", name = "Solo Dragones", order = 30, width = "full", get = function() return M.onlyDragons end, set = function(_, v) M.onlyDragons = v end},
				showTotalDamage = {type = "toggle", name = "Opcion 1: Juan 6 Parry total: 12054600", order = 40, width = "full", get = function() return M.showTotalDamage end, set = function(_, v) M.showTotalDamage = v end},
				showParryDetails = {type = "toggle", name = "Opcion 2: #1•Juan 1 = 5300 5:36,34s", order = 50, width = "full", get = function() return M.showParryDetails end, set = function(_, v) M.showParryDetails = v end},
			}
		}
	end
end)
