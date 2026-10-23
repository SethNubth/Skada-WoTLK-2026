-- Original: Skada-WoTLK by bkader (https://github.com/bkader/Skada-WoTLK)
-- Interface: 30300 (3.3.5 12340)
-- Adiciones por SethNubth - Sempiternal - Naerzone
-- Feature: Aviso a Banda >95% NO tanke cada 20s

local _, Skada = ...
local Private = Skada.Private
Skada:RegisterModule("Threat", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Threat")

	local format, max, select = string.format, math.max, select
	local UnitExists, UnitName = UnitExists, UnitName
	local UnitDetailedThreatSituation, InCombatLockdown = UnitDetailedThreatSituation, InCombatLockdown
	local GroupIterator, GetUnitRole, GetUnitSpec = Skada.GroupIterator, Skada.GetUnitRole, Skada.GetUnitSpec
	local PlaySoundFile = PlaySoundFile
	local new, del, clear = Private.newTable, Private.delTable, Private.clearTable
	local mode_cols = nil

	local aggro_icon = [[Interface\ICONS\ability_physical_taunt]]

	do
		local CheckInteractDistance, ItemRefTooltip = CheckInteractDistance, ItemRefTooltip
		local GetItemInfo, IsItemInRange = GetItemInfo, IsItemInRange
		local UnitGUID, UnitClass = UnitGUID, UnitClass
		local UnitFullName, guidToClass = Private.UnitFullName, Private.guidToClass
		local nr, max_threat, aggro_coef, my_percent = 0, 0, 1.1, nil
		local last_warn, last_time = Skada._time, 0
		local last_raid_warn = 0 -- ADICION SethNubth: cooldown 20s
		local threat_table, we_should_warn = {}, false
		local tank_threat, ruby_acorn, queried

		local aggro_color = RED_FONT_COLOR
		local negative_color = GRAY_FONT_COLOR

		local function add_to_threattable(unit, owner, target, win)
			if unit == "AGGRO" then
				if not mode.db.showAggroBar or not tank_threat or tank_threat == 0 then return end
				nr = nr + 1
				local d = win:nr(nr)
				d.id = "AGGRO"
				d.label = L["> Pull Aggro <"]
				d.icon = aggro_icon
				d.color = aggro_color
				d.ignore = true
				d.changed = nil
				d.isTanking = nil
				ruby_acorn = ruby_acorn or GetItemInfo(37727)
				if ruby_acorn then
					aggro_coef = (IsItemInRange(37727, target) == 1 and 1.1 or 1.3)
				else
					aggro_coef = (CheckInteractDistance(target, 3) and 1.1 or 1.3)
					if not queried and not ItemRefTooltip:IsVisible() then
						ItemRefTooltip:SetHyperlink("item:37727")
						queried = true
					end
				end
				d.threat = tank_threat * aggro_coef
				d.value = max_threat * aggro_coef
				return
			end
			if mode.db.ignorePets and owner then return end
			local actorname = UnitFullName(unit, owner, true)
			local actor = threat_table[actorname]
			if not actor then
				actor = new()
				actor.unit = unit
				local guid = UnitGUID(unit)
				actor.id = guid
				if owner ~= nil then actor.class = "PET"
				else actor.class = guidToClass[guid] or select(2, UnitClass(unit)) actor.spec = GetUnitSpec(guid) actor.role = GetUnitRole(guid) end
				threat_table[actorname] = actor
			end
			if not actor or not actor.unit then return end
			local isTanking, _, threatpct, _, threatvalue = UnitDetailedThreatSituation(actor.unit, target)
			if threatvalue then
				nr = nr + 1
				local d = win:nr(nr)
				d.id = actor.id or actorname
				d.label = actorname
				d.text = actor.id and Skada:FormatName(actorname, actor.id)
				d.class = actor.class
				d.role = actor.role
				d.spec = actor.spec
				d.isTanking = isTanking
				d.unit = actor.unit -- ADICION SethNubth: para filtro
				if mode.db.rawvalue then
					if threatvalue < 0 then d.value = threatvalue + 410065408 d.threat = threatvalue + 410065408 d.color = negative_color d.changed = true
					else d.value = threatvalue d.threat = threatvalue d.color = nil d.changed = nil end
				elseif threatpct then d.value = threatpct d.threat = threatvalue end
				if d.value > max_threat then max_threat = d.value end
				if isTanking then tank_threat = d.threat end
			end
		end

		local function format_threatvalue(value)
			if value == nil then return "0"
			elseif value >= 100000 then return format("%2.1fk", value * 1e-05)
			else return format("%d", value * 0.01) end
		end

		local function get_tps(threatvalue)
			return Skada.current and format_threatvalue(threatvalue / Skada.current:GetTime()) or "0"
		end

		-- ADICION SethNubth INICIO: Aviso a banda >95% NO tanke cada 20s
		local function Seth_RaidAnnounce(win)
			if not mode.db.enableRaidWarn then return end
			if not IsInRaid() then return end
			if (Skada._time or time()) - last_raid_warn < (mode.db.raidFrequency or 20) then return end
			local high = {}
			for i=1, #win.dataset do
				local data = win.dataset[i]
				if data and data.id and data.id ~= "AGGRO" and data.value then
					local percent = mode.db.rawvalue and (100 * data.value / max(0.000001, max_threat)) or data.value
					if percent > (mode.db.raidThreshold or 95) and not data.isTanking and data.role ~= "TANK" then
						table.insert(high, {name = data.label, pct = percent})
					end
				end
			end
			table.sort(high, function(a,b) return a.pct > b.pct end)
			if #high >= 1 then
				local msg = ""
				if #high == 1 then msg = string.format("Amenaza De: %s %d%% Bajar el agro Porfavor.......", high[1].name, math.floor(high[1].pct))
				else msg = string.format("Amenaza De: %s %d%% %s %d%% Bajar el agro Porfavor.......", high[1].name, math.floor(high[1].pct), high[2].name, math.floor(high[2].pct)) end
				local chan = "RAID"
				if mode.db.raidChannel == 2 then chan = "RAID_WARNING" elseif mode.db.raidChannel == 1 then chan = (IsRaidLeader() or IsRaidOfficer()) and "RAID_WARNING" or "RAID" end
				SendChatMessage(msg, chan)
				last_raid_warn = Skada._time or time()
			end
		end
		-- ADICION SethNubth FIN

		function mode:Update(win, set)
			win.title = L["Threat"]
			if not Skada.inCombat then return end
			if not self.unitID or not UnitExists(self.unitID) then return end
			self.unitName = self.unitName or UnitName(self.unitID)
			win.title = self.unitName or win.title
			max_threat, nr = 0, 0
			GroupIterator(add_to_threattable, self.unitID, win)
			if max_threat > 0 and self.db.showAggroBar then add_to_threattable("AGGRO", nil, self.unitID, win) end
			if nr == 0 then return end
			max_threat = self.db.rawvalue and max_threat or 100
			if win.metadata then win.metadata.maxvalue = max_threat end
			we_should_warn = false
			for i = 1, #win.dataset do
				local data = win.dataset[i]
				if data and data.id == "AGGRO" then
					if self.db.showAggroBar and tank_threat and tank_threat > 0 then
						data.valuetext = Skada:FormatValueCols(mode_cols.Threat and format_threatvalue(data.threat), mode_cols.TPS and get_tps(data.threat), mode_cols.Percent and Skada:FormatPercent(data.value, max(0.000001, max_threat)))
						if win.metadata then win.metadata.maxvalue = self.db.rawvalue and data.threat or data.value end
					else data.id = nil end
				elseif data and data.id then
					if data.threat and data.threat > 0 then
						local percent = 100 * data.value / max(0.000001, max_threat)
						if data.id == Skada.userGUID then
							my_percent = percent
							if self.db.threshold and self.db.threshold < percent and (not data.isTanking or not self.db.notankwarnings) then we_should_warn = (data.color == nil) end
						end
						data.valuetext = Skada:FormatValueCols(mode_cols.Threat and format_threatvalue(data.threat), mode_cols.TPS and get_tps(data.threat), mode_cols.Percent and Skada:FormatPercent(percent))
					else data.id = nil end
				end
			end
			last_time = Skada._time or time()
			if we_should_warn and last_time - last_warn > (self.db.frequency or 2) then
				self:Warn(self.db.sound, self.db.flash, self.db.shake, my_percent and format(L["%d%% Threat"], my_percent) or L["High Threat"])
				last_warn = last_time
			end
			-- ADICION SethNubth: Aviso cada 20s
			Seth_RaidAnnounce(win)
		end

		function mode:CombatLeave()
			tank_threat = nil
			clear(threat_table)
			self.unitID, self.unitName = nil, nil
		end
	end

	local function flasher_OnShow(self) self.elapsed = 0 self:SetAlpha(0) end
	local function flasher_OnUpdate(self, elapsed)
		elapsed = self.elapsed + elapsed
		if elapsed < 2.6 then
			local alpha = elapsed % 1.3
			if alpha < 0.15 then self:SetAlpha(alpha / 0.15)
			elseif alpha < 0.9 then self:SetAlpha(max(0, 1 - (alpha - 0.15) / 0.6))
			else self:SetAlpha(0) end
		else self:Hide() end
		self.elapsed = elapsed
	end
	function mode:Flash()
		if not self.FlashFrame then
			local flasher = CreateFrame("Frame", "SkadaThreatFlashFrame")
			flasher:SetToplevel(true) flasher:SetFrameStrata("FULLSCREEN_DIALOG") flasher:SetAllPoints(UIParent) flasher:EnableMouse(false) flasher:Hide()
			flasher.texture = flasher:CreateTexture(nil, "BACKGROUND") flasher.texture:SetTexture([[Interface\FullScreenTextures\LowHealth]]) flasher.texture:SetAllPoints(UIParent) flasher.texture:SetBlendMode("ADD")
			flasher:SetScript("OnShow", flasher_OnShow) flasher:SetScript("OnUpdate", flasher_OnUpdate) self.FlashFrame = flasher
		end
		self.FlashFrame:Show()
	end
	local function shaker_OnShow(self)
		if not self.originalPoints then
			self.originalPoints = {}
			for i = 1, WorldFrame:GetNumPoints() do self.originalPoints[#self.originalPoints + 1] = {WorldFrame:GetPoint(i)} end
		end
		self.elapsed = 0
	end
	local function shaker_OnUpdate(self, elapsed)
		elapsed = self.elapsed + elapsed
		local x, y = 0, 0
		if elapsed >= 0.8 then self:Hide() else x, y = random(-8, 8), random(-8, 8) end
		if WorldFrame:IsProtected() and InCombatLockdown() then if not self.fail then self.fail = true end self:Hide()
		else WorldFrame:ClearAllPoints() for i = 1, #self.originalPoints do local v = self.originalPoints[i] WorldFrame:SetPoint(v[1], v[2], v[3], v[4] + x, v[5] + y) end end
		self.elapsed = elapsed
	end
	function mode:Shake()
		local shaker = self.ShakerFrame
		if not shaker then shaker = CreateFrame("Frame", "SkadaThreatShaker", UIParent) shaker:Hide() shaker:SetScript("OnShow", shaker_OnShow) shaker:SetScript("OnUpdate", shaker_OnUpdate) self.ShakerFrame = shaker end
		shaker:Show()
	end
	do
		local CombatText_StandardScroll = CombatText_StandardScroll
		local RaidNotice_AddMessage = RaidNotice_AddMessage
		local UIErrorsFrame = UIErrorsFrame
		local WrapTextInColorCode = Private.WrapTextInColorCode
		local RGBPercToHex = Private.RGBPercToHex
		local white = HIGHLIGHT_FONT_COLOR
		local handlers = {
			[1] = function(text, r, g, b, font, size, outline, sticky)
				if tostring(SHOW_COMBAT_TEXT) ~= "0" then CombatText_AddMessage(text, CombatText_StandardScroll, r, g, b, sticky and "crit" or nil, false)
				else UIErrorsFrame:AddMessage(text, r, g, b, 1.0) end
			end,
			[2] = function(text, r, g, b)
				if r or g or b then text = WrapTextInColorCode(text, RGBPercToHex(r or 0, g or 0, b or 0, true)) end
				RaidNotice_AddMessage(RaidWarningFrame, text, white)
			end,
			[3] = function(text, r, g, b) UIErrorsFrame:AddMessage(text, r, g, b, 1.0) end,
			[4] = function(text, r, g, b) DEFAULT_CHAT_FRAME:AddMessage(text, r, g, b) end
		}
		function mode:Pour(text, r, g, b, ...) local func = handlers[self.db.output or 4] func(text, r or 1, g or 1, b or 1, ...) end
	end
	function mode:Warn(sound, flash, shake, message)
		if sound then PlaySoundFile(Skada:MediaFetch("sound", self.db.soundfile), "Master") end
		if flash then self:Flash() end
		if shake then self:Shake() end
		if self.db.message and message then self:Pour(message, 1, 0, 0, nil, 24, "OUTLINE", true) end
	end
	do
		local opts = {
			type = "group",
			name = mode.localeName,
			desc = format(L["Options for %s."], mode.localeName),
			get = function(i) return mode.db[i[#i]] end,
			set = function(i, val) mode.db[i[#i]] = val mode:ApplySettings() end,
			args = {
				header = {type = "description", name = mode.localeName, fontSize = "large", image = aggro_icon, imageWidth = 18, imageHeight = 18, imageCoords = Skada.cropTable, width = "full", order = 0},
				sep = {type = "description", name = " ", width = "full", order = 1},
				warning = {
					type = "group", name = L["Threat Warning"], inline = true, order = 10,
					args = {
						flash = {type = "toggle", name = L["Flash Screen"], desc = L["This will cause the screen to flash as a threat warning."], order = 10},
						shake = {type = "toggle", name = L["Shake Screen"], desc = L["This will cause the screen to shake as a threat warning."], order = 20},
						message = {type = "toggle", name = L["Warning Message"], desc = L["Print a message to screen when you accumulate too much threat."], order = 30},
						sound = {type = "toggle", name = L["Play sound"], desc = L["This will play a sound as a threat warning."], order = 40},
						output = {type = "select", name = L["Message Output"], desc = L["Choose where warning messages should be displayed."], order = 50, width = "double", values = {L["Default"], L["Raid Warning"], L["Blizzard Error Frame"], L["Chat Frame"]}, hidden = function() return not mode.db.message end, disabled = function() return not mode.db.message end},
						soundfile = {type = "select", name = L["Threat sound"], desc = L["opt_threat_soundfile_desc"], order = 60, width = "double", dialogControl = "LSM30_Sound", values = Skada:MediaList("sound"), hidden = function() return not mode.db.sound end, disabled = function() return not mode.db.sound end},
						frequency = {type = "range", name = L["Warning Frequency"], order = 70, min = 2, max = 15, step = 1},
						threshold = {type = "range", name = L["Threat Threshold"], desc = L["opt_threat_threshold_desc"], order = 80, min = 60, max = 130, step = 1}
					}
				},
				-- ADICION SethNubth INICIO
				raidwarn = {
					type = "group", name = "Aviso a Banda (SethNubth)", inline = true, order = 15,
					args = {
						enableRaidWarn = {type = "toggle", name = "Activar aviso a banda >95%", desc = "Avisa en /Banda o /RW cuando alguien pasa 95% de amenaza. No avisa de tankes. Repite cada 20s si no bajan. - Adicion SethNubth", order = 10, width = "full"},
						raidThreshold = {type = "range", name = "Umbral banda %", desc = "Solo si traspasa este %", order = 20, min = 85, max = 99, step = 1, disabled = function() return not mode.db.enableRaidWarn end},
						raidFrequency = {type = "range", name = "Frecuencia banda (seg)", desc = "Cada cuantos segundos repite si no bajan agro", order = 30, min = 10, max = 60, step = 5, disabled = function() return not mode.db.enableRaidWarn end},
						raidChannel = {type = "select", name = "Canal", order = 40, width = "double", values = {"Banda", "Auto: /RW si lider", "Solo /RW"}, disabled = function() return not mode.db.enableRaidWarn end},
					}
				},
				-- ADICION SethNubth FIN
				rawvalue = {type = "toggle", name = L["Show raw threat"], desc = L["opt_threat_rawvalue_desc"], order = 20},
				focustarget = {type = "toggle", name = L["Use focus target"], desc = L["opt_threat_focustarget_desc"], order = 30},
				notankwarnings = {type = "toggle", name = L["Disable while tanking"], desc = L["opt_threat_notankwarnings_desc"], order = 40},
				ignorePets = {type = "toggle", name = L["Ignore Pets"], desc = L["opt_threat_ignorepets_desc"], order = 50},
				showAggroBar = {type = "toggle", name = L["Show Pull Aggro Bar"], desc = L["opt_threat_showaggrobar_desc"], order = 60},
				sep2 = {type = "description", name = " ", width = "full", order = 90},
				test = {type = "execute", name = L["Test Warnings"], width = "double", order = 100, func = function() mode:Warn(mode.db.sound, mode.db.flash, mode.db.shake, mode.db.message and L["Test Warnings"]) end}
			}
		}
		function mode:OnInitialize()
			if not M.threat then
				M.threat = {
					sound = true, flash = true, output = 1, frequency = 2, threshold = 90,
					soundfile = "Fel Nova", notankwarnings = true, ignorePets = true, showAggroBar = true,
					-- ADICION SethNubth DEFAULTS
					enableRaidWarn = true, raidThreshold = 95, raidFrequency = 20, raidChannel = 1
				}
			else
				M.threat.sinkOptions = nil
				M.threat.output = M.threat.output or 1
				if M.threat.enableRaidWarn == nil then M.threat.enableRaidWarn = true end
				if M.threat.raidThreshold == nil then M.threat.raidThreshold = 95 end
				if M.threat.raidFrequency == nil then M.threat.raidFrequency = 20 end
				if M.threat.raidChannel == nil then M.threat.raidChannel = 1 end
			end
			self.db = M.threat
			O.modules.args.threat = opts
		end
	end
	do
		local function add_threat_feed()
			if Skada.current and UnitExists("target") then
				local _, _, threatpct = UnitDetailedThreatSituation("player", "target")
				return threatpct and Skada:FormatPercent(threatpct)
			end
		end
		function mode:OnEnable()
			self.metadata = {wipestale = true, columns = {Threat = true, TPS = false, Percent = true}, notitleset = true, icon = aggro_icon}
			mode_cols = self.metadata.columns
			Skada.RegisterBucketEvent(self, "UNIT_THREAT_LIST_UPDATE", 0.1, "SetUnit")
			Skada.RegisterBucketEvent(self, "UNIT_THREAT_SITUATION_UPDATE", 0.1, "SetUnit")
			Skada.RegisterBucketEvent(self, "PLAYER_TARGET_CHANGED", 0.1, "SetUnit")
			Skada.RegisterCallback(self, "Skada_ApplySettings", "ApplySettings")
			Skada.RegisterMessage(self, "COMBAT_PLAYER_LEAVE", "CombatLeave")
			Skada:AddFeed(L["Threat: Personal Threat"], add_threat_feed)
			Skada:AddMode(self)
		end
	end
	function mode:OnDisable()
		Skada.UnregisterAllBuckets(self) Skada.UnregisterAllCallbacks(self) Skada.UnregisterAllMessages(self)
		Skada:RemoveFeed(L["Threat: Personal Threat"]) Skada:RemoveMode(self)
	end
	function mode:ApplySettings()
		self.db = self.db or M.threat
		if self.db.focustarget then Skada.RegisterEvent(self, "UNIT_TARGET") else Skada.UnregisterEvent(self, "UNIT_TARGET") end
	end
	do
		local UnitIsPlayer = UnitIsPlayer
		local UnitCanAttack = UnitCanAttack
		local UnitHealth = UnitHealth
		local throttleFrame = CreateFrame("Frame")
		local threatUnits = {"focus", "focustarget", "target", "targettarget"}
		local function find_threat_unit()
			mode.unitID, mode.unitName = nil, nil
			local n = mode.db.focustarget and 1 or 3
			for i = n, 4 do
				local unit = threatUnits[i]
				if UnitExists(unit) and not UnitIsPlayer(unit) and UnitCanAttack("player", unit) and UnitHealth(unit) > 0 then mode.unitID = unit mode.unitName = UnitName(unit) break end
			end
			throttleFrame:Hide()
		end
		throttleFrame:Hide() throttleFrame:SetScript("OnUpdate", find_threat_unit)
		function mode:SetUnit() throttleFrame:Show() end
		function mode:UNIT_TARGET(_, unit) if unit == "focus" and self.db.focustarget and self.unitID == "focustarget" then throttleFrame:Show() end end
	end
end)
