local _, Skada = ...
Skada:RegisterModule("Inspect", function(L, P, _, _, M, O)
	local mode = Skada:NewModule("Inspect 3D - SethNubth")
	local mode_detail = mode:NewModule("Gear Snapshot")
	local pairs, format, tinsert = pairs, string.format, table.insert
	local classfmt = Skada.classcolors.format

	-- ICC BIS Trinkets / SR Detect HEAVY
	local ICC_TRINKETS = {
		[50362] = "Death Will 284 BIS",
		[50353] = "DFO 284 BIS",
		[50360] = "Phylactery 284 BIS",
		[50344] = "Organ 264",
		[50348] = "Whisper Skull 264",
		[50351] = "Herkuml 264",
		[50340] = "Tiny Abom 264",
		[50342] = "Sliver Ice 264",
		[50359] = "Althor Trinket 277",
		[50363] = "Death Choice 277",
		[50364] = "Death Choice 277 H",
	}
	local SR_ITEMS = {
		[49623] = "Shadowmourne",
		[46051] = "Val'anyr",
		[47115] = "Shadow's Edge",
	}

	-- Snapshot Guardado al Pull
	local Snapshots = {}
	local ModelFrame = nil

	local function GetModelFrame()
		if ModelFrame then return ModelFrame end
		local f = CreateFrame("Frame", "SethNubthInspect3D", UIParent, "BackdropTemplate")
		f:SetSize(340, 460)
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
		f.model = m

		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -2, -2)

		local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		btn:SetSize(260, 26)
		btn:SetPoint("BOTTOM", 0, 12)
		btn:SetText("Avisar Banda - Snapshot Pull")
		f.btn = btn
		f.title = title

		ModelFrame = f
		return f
	end

	local function TakeSnapshotForUnit(unit, name)
		if not name then name = UnitName(unit) end
		if not name then return end
		NotifyInspect(unit)
		C_Timer.After(0.6, function()
			local gear = {}
			local trinkets = {}
			local sr = {}
			local itemIDs = ""
			for slot=1,19 do
				local link = GetInventoryItemLink(unit, slot)
				if link then
					local id = tonumber(link:match("item:(%d+)"))
					if id then
						gear[slot] = id
						itemIDs = itemIDs .. format("%d ", id)
						if ICC_TRINKETS[id] then tinsert(trinkets, format("%d-%s", id, ICC_TRINKETS[id])) end
						if SR_ITEMS[id] then tinsert(sr, format("%d-%s", id,
