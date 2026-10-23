local _, Skada = ...
local Private = Skada.Private
Skada:RegisterModule("Avoidance", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Avoidance")
	local mode_target = mode:NewModule("Target List")
	local pairs, format, uformat = pairs, string.format, Private.uformat
	local classfmt = Skada.classcolors.format
	local mode_cols = nil

	-- Kade Fix Sindragosa P3 - IDs de Tumba Helada Naerzone
	local ICE_TOMB_IDS = {
		[70157] = true, -- Ice Tomb
		[71057] = true, -- Ice Tomb (otro id)
		[70126] = true, -- Frost Beacon -> marca para tumba
		[46272] = true, -- Ice Tomb old
	}

	local function FormatTimeSeth(sec)
		if not sec then return "0:00,00s" end
		local mins = math.floor(sec / 60)
		local secs = math.floor(sec % 60)
		local ms = math.floor((sec % 1) * 100)
		return string.format("%d:%02d,%02ds", mins, secs, ms)
	end

	local function format_valuetext(d, total, metadata)
		d.valuetext = Skada:FormatValueCols(
			mode_cols.Count and d.value,
			mode_cols.Percent and Skada:FormatPercent(d.value, total)
		)
		if metadata and d.value > metadata.maxvalue then metadata.maxvalue = d.value end
	end

	local AvoidanceTypes = {
		DODGE = "Dodge",
		PARRY = "Parry",
		BLOCK = "Block",
		ABSORB = "Absorb",
		RESIST = "Resist",
		MISS = "Miss",
	}

	local function log_avoidance(set, dstName, dstId, dstFlags, srcName, missType, amount)
		local actor = Skada:GetActor(set, dstName, dstId, dstFlags)
		if not actor then return end

		actor.avoidance = (actor.avoidance or 0) + 1
		set.avoidance = (set.avoidance or 0) + 1

		actor.avoidance_count = actor.avoidance_count or {}
		actor.avoidance_count[missType] = (actor.avoidance_count[missType] or 0) + 1

		-- Detalle con 5:36,34s
		actor.avoidancedetails = actor.avoidancedetails or {}
		local cTime = Skada.current and Skada.current:GetTime() or 0
		table.insert(actor.avoidancedetails, {
			boss = srcName or "Boss",
			type = missType,
			amount = amount or 0,
			time = cTime,
			timeFormatted = FormatTimeSeth(cTime),
		})

		if (set == Skada.total and not P.totalidc) then return end
		actor.avoidance_sources = actor.avoidance_sources or {}
		actor.avoidance_sources[srcName] = (actor.avoidance_sources[srcName] or 0) + 1
	end

	local function avoidance_event(t)
		if not t.dstName or not t.misstype then return end
		if not AvoidanceTypes[t.misstype] then return end
		if not t.dstFlags then return end
		
		-- Kade Fix: Si el evento es de Tumba Helada, ignorar - No es avoidance real
		if t.spellId and ICE_TOMB_IDS[t.spellId] then return end
		if t.extraSpellId and ICE_TOMB_IDS[t.extraSpellId] then return end

		local actorid, actorname, actorflags = t.dstGUID, t.dstName, t.dstFlags
		Skada:DispatchSets(log_avoidance, actorname, actorid, actorflags, t.srcName, t.misstype, t.amount or 0)
	end

	function mode_target:Enter(win, id, label, class)
		win.actorid, win.actorname, win.actorclass = id, label, class
		win.title = format("%s - %s", "Avoidance", classfmt(class, label))
	end

	function mode_target:Update(win, set)
		win.title = uformat("Avoidance - %s", classfmt(win.actorclass, win.actorname))
		if not set or not win.actorname then return end
		local actor = set:GetActor(win.actorname, win.actorid)
		if not actor or not actor.avoidance then return end

		if actor.avoidancedetails and M.showAvoidanceDetails then
			if win.metadata then win.metadata.maxvalue = 0 end
			for i, detail in ipairs(actor.avoidancedetails) do
				local d = win:actor(i, detail.boss)
				d.value = 1
				d.valuetext = Skada:FormatValueCols(
					format("%s", detail.type),
					format("%s %s", detail.boss, detail.timeFormatted)
				)
			end
			return
		end

		local total = actor.avoidance
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		if actor.avoidance_count then
			for atype, count in pairs(actor.avoidance_count) do
				nr = nr + 1
				local d = win:actor(nr, atype)
				d.value = count
				format_valuetext(d, total, win.metadata)
			end
		end
	end

	function mode:Update(win, set)
		win.title = win.class and format("Avoidance (%s)", L[win.class]) or "Avoidance - SethNubth"
		local total = set and set:GetTotal(win.class, nil, "avoidance")
		if not total or total == 0 then return end
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		for actorname, actor in pairs(set.actors) do
			if win:show_actor(actor, set, true) and actor.avoidance and actor.avoidance > 0 then
				nr = nr + 1
				local d = win:actor(nr, actor, actor.enemy, actorname)
				d.value = actor.avoidance
				if M.showAvoidanceTotal and actor.avoidance_count then
					local txt = format("D:%d P:%d B:%d", actor.avoidance_count.DODGE or 0, actor.avoidance_count.PARRY or 0, actor.avoidance_count.BLOCK or 0)
					d.valuetext = Skada:FormatValueCols(format("%d Avoid", actor.avoidance), txt)
				else
					format_valuetext(d, total, win.metadata)
				end
			end
		end
	end

	function mode:GetSetSummary(set, win)
		if not set then return end
		return set:GetTotal(win and win.class, nil, "avoidance") or 0
	end

	function mode:OnEnable()
		self.metadata = {
			showspots = true, ordersort = true, filterclass = true, click1 = mode_target,
			columns = {Count = true, Percent = true, sPercent = false},
			icon = [[Interface\ICONS\ability_defend]]
		}
		mode_cols = self.metadata.columns
		mode_target.nototal = true
		Skada:RegisterForCL(avoidance_event, {dst_is_interesting = true}, "SWING_MISSED", "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "RANGE_MISSED")
		Skada:AddMode(self)
	end

	function mode:OnDisable() Skada:RemoveMode(self) end

	function mode:OnInitialize()
		if M.showAvoidanceTotal == nil then M.showAvoidanceTotal = true end
		if M.showAvoidanceDetails == nil then M.showAvoidanceDetails = true end

		O.modules.args.Avoidance = {
			type = "group", name = "Avoidance", desc = "Avoidance - SethNubth - Mitigación de Tanke",
			args = {
				header = {type = "description", name = "Avoidance v1.0 SethNubth - Tanke Mitigation - No tiene Skada", fontSize = "large", image = [[Interface\ICONS\ability_defend]], imageWidth = 18, imageHeight = 18, imageCoords = Skada.cropTable, width = "full", order = 0},
				sep = {type = "description", name = " ", width = "full", order = 1},
				showAvoidanceTotal = {type = "toggle", name = "Opcion 1: Desglose D:P:B", desc = "Muestra Dodge Parry Block totales", order = 10, width = "full", get = function() return M.showAvoidanceTotal end, set = function(_, v) M.showAvoidanceTotal = v end},
				showAvoidanceDetails = {type = "toggle", name = "Opcion 2: Detalle con 5:36,34s", desc = "#1 Parry Sindragosa 5:36,34s", order = 20, width = "full", get = function() return M.showAvoidanceDetails end, set = function(_, v) M.showAvoidanceDetails = v end},
			}
		}
	end
end)
