local _, Skada = ...
local Private = Skada.Private
Skada:RegisterModule("Friendly Fire", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Friendly Fire")
	local mode_target = mode:NewModule("Target List")
	local pairs, format, uformat = pairs, string.format, Private.uformat
	local classfmt = Skada.classcolors.format
	local mode_cols = nil

	-- SethNubth: Formato 5:36,34s
	local function FormatTimeSeth(sec)
		if not sec then return "0:00,00s" end
		local mins = math.floor(sec / 60)
		local secs = math.floor(sec % 60)
		local ms = math.floor((sec % 1) * 100)
		return string.format("%d:%02d,%02ds", mins, secs, ms)
	end

	local function format_valuetext(d, total, metadata, subview)
		d.valuetext = Skada:FormatValueCols(
			mode_cols.Count and Skada:FormatNumber(d.value),
			mode_cols[subview and "sPercent" or "Percent"] and Skada:FormatPercent(d.value, total)
		)
		if metadata and d.value > metadata.maxvalue then metadata.maxvalue = d.value end
	end

	local function log_friendlyfire(set, srcName, srcId, srcFlags, dstName, amount, spellId, spellName)
		local actor = Skada:GetActor(set, srcName, srcId, srcFlags)
		if not actor then return end

		actor.friendlyfire = (actor.friendlyfire or 0) + amount
		set.friendlyfire = (set.friendlyfire or 0) + amount

		-- Detalle con tiempo 5:36,34s
		actor.friendlyfiredetails = actor.friendlyfiredetails or {}
		local cTime = Skada.current and Skada.current:GetTime() or 0
		table.insert(actor.friendlyfiredetails, {
			target = dstName,
			amount = amount,
			spell = spellName or "Melee",
			spellId = spellId,
			time = cTime,
			timeFormatted = FormatTimeSeth(cTime),
		})

		if (set == Skada.total and not P.totalidc) or not dstName then return end
		actor.friendlyfiretargets = actor.friendlyfiretargets or {}
		actor.friendlyfiretargets[dstName] = (actor.friendlyfiretargets[dstName] or 0) + amount

		-- AVISAR EN BANDA POR DEFECTO con tiempo 5:36,34s
		if M.friendlyfireannounce and set ~= Skada.total and amount >= (M.friendlyfire_threshold or 5000) then
			local msg = format("%s hizo Friendly Fire a %s - %d con %s - %s [Total: %d]", srcName, dstName, amount, spellName or "Melee", FormatTimeSeth(cTime), actor.friendlyfire)
			Skada:SendChat(msg, M.friendlyfirechannel, "preset")
		end
	end

	local function friendlyfire_event(t)
		if not t.srcName or not t.dstName then return end
		if t.srcName == t.dstName then return end -- no self
		local amount = t.amount or 0
		if amount <= 0 then return end
		
		local actorid, actorname, actorflags = Skada:FixMyPets(t.srcGUID, t.srcName, t.srcFlags)
		Skada:DispatchSets(log_friendlyfire, actorname, actorid, actorflags, t.dstName, amount, t.spellId, t.spellName)
	end

	function mode_target:Enter(win, id, label, class)
		win.actorid, win.actorname, win.actorclass = id, label, class
		win.title = format("%s - Friendly Fire a -> %s", L["Friendly Fire"] or "Friendly Fire", classfmt(class, label))
	end

	function mode_target:Update(win, set)
		win.title = uformat("%s - %s", L["Friendly Fire"] or "Friendly Fire", classfmt(win.actorclass, win.actorname))
		if not set or not win.actorname then return end
		local actor = set:GetActor(win.actorname, win.actorid)
		if not actor or not actor.friendlyfire then return end

		if actor.friendlyfiredetails and M.showFriendlyDetails then
			if win.metadata then win.metadata.maxvalue = 0 end
			local nr = 0
			for _, detail in ipairs(actor.friendlyfiredetails) do
				nr = nr + 1
				local d = win:actor(nr, detail.target)
				d.value = detail.amount
				d.valuetext = Skada:FormatValueCols(
					format("%d", detail.amount),
					format("%s %s", detail.spell, detail.timeFormatted)
				)
			end
			return
		end

		local total = actor.friendlyfire
		local targets = actor.friendlyfiretargets
		if not targets then return end
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		for targetname, count in pairs(targets) do
			nr = nr + 1
			local d = win:actor(nr, targetname)
			d.value = count
			format_valuetext(d, total, win.metadata, true)
		end
	end

	function mode:Update(win, set)
		win.title = win.class and format("%s (%s)", L["Friendly Fire"] or "Friendly Fire", L[win.class]) or L["Friendly Fire"] or "Friendly Fire"
		local total = set and set:GetTotal(win.class, nil, "friendlyfire")
		if not total or total == 0 then return end
		if win.metadata then win.metadata.maxvalue = 0 end
		local nr = 0
		for actorname, actor in pairs(set.actors) do
			if win:show_actor(actor, set, true) and actor.friendlyfire then
				nr = nr + 1
				local d = win:actor(nr, actor, actor.enemy, actorname)
				d.value = actor.friendlyfire
				format_valuetext(d, total, win.metadata)
			end
		end
	end

	function mode:GetSetSummary(set, win)
		if not set then return end
		return set:GetTotal(win and win.class, nil, "friendlyfire") or 0
	end

	function mode:OnEnable()
		self.metadata = {
			showspots = true, ordersort = true, filterclass = true, click1 = mode_target,
			columns = {Count = true, Percent = true, sPercent = false},
			icon = [[Interface\ICONS\ability_creature_cursed_02]]
		}
		mode_cols = self.metadata.columns
		mode_target.nototal = true
		Skada:RegisterForCL(friendlyfire_event, {src_is_interesting = true, dst_is_interesting = true}, "SWING_DAMAGE", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE", "RANGE_DAMAGE")
		Skada:AddMode(self)
	end

	function mode:OnDisable() Skada:RemoveMode(self) end

	function mode:OnInitialize()
		M.friendlyfirechannel = M.friendlyfirechannel or "AUTO"
		if M.friendlyfireannounce == nil then M.friendlyfireannounce = true end -- POR DEFECTO BANDA ON
		if M.friendlyfire_threshold == nil then M.friendlyfire_threshold = 5000 end
		if M.showFriendlyDetails == nil then M.showFriendlyDetails = true end

		O.modules.args.FriendlyFire = {
			type = "group", name = self.localeName, desc = "Friendly Fire - SethNubth",
			args = {
				header = {type = "description", name = "Friendly Fire - SethNubth v1.0 - No tiene Skada, si Details", fontSize = "large", image = [[Interface\ICONS\ability_creature_cursed_02]], imageWidth = 18, imageHeight = 18, imageCoords = Skada.cropTable, width = "full", order = 0},
				sep = {type = "description", name = " ", width = "full", order = 1},
				friendlyfireannounce = {type = "toggle", name = "Avisar Friendly Fire en Banda", desc = "Por defecto ON - Avisa con tiempo 5:36,34s", order = 10, width = "full", get = function() return M.friendlyfireannounce end, set = function(_, v) M.friendlyfireannounce = v end},
				friendlyfirechannel = {type = "select", name = L["Channel"], values = {AUTO = L["Instance"], SELF = L["Self"]}, order = 20, width = "double", get = function() return M.friendlyfirechannel end, set = function(_, v) M.friendlyfirechannel = v end},
				friendlyfire_threshold = {type = "range", name = "Umbral mínimo para avisar", min = 1000, max = 50000, step = 1000, order = 30, width = "full", get = function() return M.friendlyfire_threshold end, set = function(_, v) M.friendlyfire_threshold = v end},
				showFriendlyDetails = {type = "toggle", name = "Detalle con tiempo 5:36,34s", order = 40, width = "full", get = function() return M.showFriendlyDetails end, set = function(_, v) M.showFriendlyDetails = v end},
			}
		}
	end
end)
