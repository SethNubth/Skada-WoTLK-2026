local _, Skada = ...
Skada:RegisterModule("Inspect", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Inspect 3D - SethNubth")
	local mode_detail = mode:NewModule("Gear Snapshot")
	local pairs, format, tinsert = pairs, string.format, table.insert
	local classfmt = Skada.classcolors.format

	local ICC_TRINKETS = {
		[50362] = "Death Will 284 BIS",
		[50353] = "DFO 284 BIS",
		[50360] = "Phylactery 284 BIS",
		[50344] = "Organ 264",
		[50348] = "Whisper Skull 264",
		[50351] = "Herkuml 264",
		[50340] = "Tiny Abom 264",
		[50342] = "Sliver Ice 264",
		[50359] = "Althor 277",
		[50363] = "Death Choice 277",
		[50364] = "Death Choice 277 H",
	}
	local SR_ITEMS = {
		[49623] = "Shadowmourne",
		[46051] = "Val'anyr",
		[47115] = "Shadow's Edge",
	}

	local Snapshots = {}
	local ModelFrame = nil

	local function GetModelFrame()
		if ModelFrame then return ModelFrame end
		local f = CreateFrame("Frame", "SethNubthInspect3D", UIParent, "BackdropTemplate")
		f:SetSize(340, 480)
		f:SetPoint("CENTER", 0, 0)
		f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=24, insets={left=8,right=8,top=8,bottom=8}})
		f:SetMovable(true) f:EnableMouse(true) f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		f:Hide()
		f:SetFrameStrata("DIALOG")

		local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", 0, -12)
		title:SetText("SethNubth Inspect 3D")

		local m = CreateFrame("DressUpModel", nil, f)
		m:SetSize(320, 380)
		m:SetPoint("TOP", 0, -35)
		m:SetUnit("player")
		m:SetRotation(0.5)
		f.model = m

		m:EnableMouse(true)
		m:SetScript("OnMouseDown", function(self, button)
			if button == "RightButton" then self:MouseDown() end
		end)
		m:SetScript("OnMouseUp", function(self) self:MouseUp() end)

		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)

		local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		btn:SetSize(260, 26)
		btn:SetPoint("BOTTOM", 0, 12)
		btn:SetText("Avisar Banda - Snapshot Pull")
		f.btn = btn
		f.title = title
		f.trinketText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		f.trinketText:SetPoint("BOTTOM", btn, "TOP", 0, 6)
		f.trinketText:SetWidth(320)
		f.trinketText:SetJustifyH("CENTER")

		ModelFrame = f
		return f
	end

	local function TakeSnapshotForUnit(unit, name)
		if not name then name = UnitName(unit) end
		if not name then return end
		if not CanInspect(unit) then return end
		NotifyInspect(unit)
		-- Fix 3.3.5a: No C_Timer, usar ScheduleTimer de Skada
		Skada:ScheduleTimer(function()
			local gear = {}
			local trinkets = {}
			local sr = {}
			local avgIlvl = 0
			local count = 0
			for slot=1,19 do
				if slot ~= 4 then -- no shirt
					local link = GetInventoryItemLink(unit, slot)
					if link then
						local id = tonumber(link:match("item:(%d+)"))
						if id then
							gear[slot] = id
							count = count + 1
							if ICC_TRINKETS[id] then tinsert(trinkets, ICC_TRINKETS[id]) end
							if SR_ITEMS[id] then tinsert(sr, SR_ITEMS[id]) end
							local _, _, _, ilvl = GetItemInfo(link)
							if ilvl then avgIlvl = avgIlvl + ilvl end
						end
					end
				end
			end
			if count > 0 then avgIlvl = math.floor(avgIlvl / count) else avgIlvl = 0 end
			Snapshots[name] = {
				gear = gear,
				trinkets = trinkets,
				sr = sr,
				ilvl = avgIlvl,
				class = select(2, UnitClass(unit)) or "UNKNOWN",
				time = date("%H:%M:%S"),
			}
			if M.debug then print(format("|cFF00FFFF[Inspect3D]|r Snapshot %s - ilvl %d - %s", name, avgIlvl, table.concat(trinkets, ", "))) end
		end, 0.7)
	end

	function mode_detail:Enter(win, id, label)
		win.actorname = label
		win.title = format("Gear - %s", classfmt(Snapshots[label] and Snapshots[label].class or "UNKNOWN", label))
	end

	function mode_detail:Update(win, set)
		if not win.actorname then return end
		local snap = Snapshots[win.actorname]
		if not snap then
			win:actor(1, "Sin Snapshot").valuetext = "No inspeccionado en pull"
			return
		end
		local nr = 0
		nr = nr + 1
		win:actor(nr, format("ilvl Promedio: %d", snap.ilvl)).valuetext = snap.time
		for _, t in ipairs(snap.trinkets) do
			nr = nr + 1
			win:actor(nr, t).valuetext = "TRINKET"
		end
		for _, s in ipairs(snap.sr) do
			nr = nr + 1
			local d = win:actor(nr, s)
			d.value = 999
			d.valuetext = "SR LEGENDARY"
		end
	end

	function mode:Update(win, set)
		win.title = "Inspect 3D - Pull Snapshot"
		local nr = 0
		for name, snap in pairs(Snapshots) do
			nr = nr + 1
			local d = win:actor(nr, name, name, snap.class)
			d.value = snap.ilvl
			local tri = #snap.trinkets > 0 and table.concat(snap.trinkets, "/") or "No Trinket"
			d.valuetext = format("%d ilvl - %s - %s", snap.ilvl, tri, snap.time)
		end
		if nr == 0 then
			win:actor(1, "Esperando Pull").valuetext = "Auto-inspect al entrar en combate"
		end
	end

	function mode:OnEnable()
		self.metadata = {
			showspots = true,
			ordersort = true,
			click1 = mode_detail,
			icon = [[Interface\ICONS\inv_misc_enggizmos_19]]
		}
		mode_detail.metadata = {showspots=true, icon=[[Interface\ICONS\inv_helmet_158]]}
		Skada:AddMode(self)

		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
		f:RegisterEvent("INSPECT_READY")
		f:RegisterEvent("PLAYER_TARGET_CHANGED")

		f:SetScript("OnEvent", function(_, event, arg1)
			if event == "PLAYER_REGEN_DISABLED" then
				-- Auto snapshot banda en pull
				if IsInRaid() then
					for i=1, GetNumGroupMembers() do
						local unit = "raid"..i
						if UnitExists(unit) then TakeSnapshotForUnit(unit) end
					end
				end
			elseif event == "INSPECT_READY" then
				-- Ya tomado en TakeSnapshot
			elseif event == "PLAYER_TARGET_CHANGED" then
				if UnitExists("target") and UnitIsPlayer("target") then
					local mf = GetModelFrame()
					mf.title:SetText(format("Inspect 3D - %s", UnitName("target")))
					mf.model:SetUnit("target")
					local snap = Snapshots[UnitName("target")]
					if snap then
						mf.trinketText:SetText(table.concat(snap.trinkets, " | "))
					else
						mf.trinketText:SetText("Sin snapshot - Pulsa Inspeccionar")
						TakeSnapshotForUnit("target")
					end
				end
			end
		end)

		-- Click para abrir modelo 3D
		SLASH_INSPECT3D1 = "/inspect3d"
		SLASH_INSPECT3D2 = "/insp3d"
		SlashCmdList["INSPECT3D"] = function(msg)
			local mf = GetModelFrame()
			if msg and msg ~= "" then
				mf.model:SetUnit(msg)
				mf.title:SetText("Inspect 3D - "..msg)
			end
			if mf:IsShown() then mf:Hide() else mf:Show() end
		end
	end

	function mode:OnDisable() Skada:RemoveMode(self) end

	function mode:OnInitialize()
		if M.debug == nil then M.debug = false end
	end
end)
