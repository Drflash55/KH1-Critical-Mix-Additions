LUAGUI_NAME = "CMix_SpiritLink"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Adds Spirit Gague, and Spirit Link option in Items menu // STANDALONE VERSION"

local criticalMix = false

local TBD = 0x0
local swapped = 0
local buttonMask = 0x40
local buttonInput = false
local soraPointer = 0x2537E48
local spiritValue = 0
local spiritNeeded = 115

local hpmpStart = 0x28165E8
local fillStart = 0x28166A8
local soraItemSlotAmount = 0x2DE9385
local itemSlot1 = 0x2DE9386
local itemsOpen = false
local soraItemSlotValue = 0
local inMenu = 0x232DFA0
local commandMenuType = 0x2852790
local commandMenuPosition = 0x2852794
local commandItemPartyHoverPosition = 0x28527A4
local commandItemHoverPosition = 0x28527B4
local linkedSpiritItem = 0x2DE988D

local lastCommandMenuType = 0
local lastMenuPosition = 0
local lastPauseType = 0
local lastItemTypeSelected = 0
local spiritItemId = 10

local boostedAmount = false

local currentForcedSlots = 0
local itemValue = 0

local spiritCheckTimer = 0
local currentLinkItem = 0x2DED271
local currentLink = 0
local spiritDrainTimer = 0
local spiritDrainDelay = 80

local connectCounter = 0x296B230
local curComboChain = 0x296B221

local currentAnim = 0
local soraAnimSpeed = 0
local soraRed = 0
local soraGreen = 0
local soraBlue = 0


-- 0  = unlinked

-- 1 = sora link
-- 30% Increased Animation Speed


-- 2 = donald link
-- 50% Reduced MP Cost
-- Instant MP Recovery

-- 3  = goofy link
-- Life Gain on Hit
-- No stagger?

-- Fire
local fireMP = 0x2D28C98
local firaMP = 0x2D28D08
local firagaMP = 0x2D28D78
-- Blizard
local blizzardMP = 0x2D28DE8
local blizzaraMP = 0x2D28E58
local blizzagaMP = 0x2D28EC8
-- Gravity
local gravityMP = 0x2D291D8
local graviraMP = 0x2D29248
local gravigaMP = 0x2D292B8
-- Thunder
local thunderMP = 0x2D28F38
local thundaraMP = 0x2D28FA8
local thundagaMP = 0x2D29018
-- Cure
local cureMP = 0x2D29088
local curaMP = 0x2D290F8
local curagaMP = 0x2D29168
-- Stop
local stopMP = 0x2D29328
local stopraMP = 0x2D29398
local stopgaMP = 0x2D29408
-- Aero
local aeroMP = 0x2D29478
local aeroraMP = 0x2D294E8
local aerogaMP = 0x2D29558



local lastSpellCostLink = nil
local currentHPAddress = 0x2DE9365
local displayedHPAddress = 0x2D5CC4C
local maxHPAddress = 0x2DE9366
local currentMPAddress = 0x2DE9367
local displayedMPAddress = 0x2D5CC54
local maxMPAddress = 0x2DE9368
local chargeMPAddress = 0x2DE939C
local displayedChargeAddress = 0x2D5CCCE

local maxHPValue = 0
local maxMPValue = 0

local restoredHPValue = 0
local restoredMPValue = 0
local chargeMPValue = 0

function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Critical Mix - Spirit Link Installed")
		canExecute = true
	end
end


function _OnFrame()
	--ConsolePrint("Crash Test 3 - Checking to see if the new frame can be rendered.")
	if canExecute == true then
		swapped = ReadByte(0x4D8632)
		buttonMask = 0x40
		if swapped == 1 then
			buttonMask = 0x20
		end

		local soraBase = ReadLong(soraPointer)
		if soraBase == 0 then
			currentAnim = 0
			soraAnimSpeed = 0
			soraRed = 0
			soraGreen = 0
			soraBlue = 0
			currentLink = 0
			--WriteByte(currentLinkItem, 0)
			return
		end

		maxHPValue = ReadByte(maxHPAddress)
		maxMPValue = ReadByte(maxMPAddress)
		restoredHPValue = maxHPValue + 18
		restoredMPValue = maxMPValue + 3
		chargeMPValue = restoredMPValue * 30

		soraRed = soraBase + 0xA0
		soraGreen = soraBase + 0xA4
		soraBlue = soraBase + 0xA8

		if ReadByte(linkedSpiritItem) == 0 then
			WriteByte(currentLinkItem, 0)
		end
		currentLink = ReadByte(currentLinkItem)
		calculate_spirit_drain()

		soraAnimSpeed = soraBase + 0x284
		currentAnim = soraBase + 0x164
		buttonInput = (ReadByte(0x23407B5) & buttonMask) ~= 0
		if ReadByte(0x2DE9386) ~= 0x45 then
			store_sora_item_slots()
		end
		if ReadByte(linkedSpiritItem) > 115 then
			WriteByte(linkedSpiritItem, 115)
		end
		spiritValue = ReadByte(linkedSpiritItem)
		draw_spirit_bar()
		apply_bar_fill()
		add_spirit_command()
		lastCommandMenuType = ReadByte(commandMenuType)
		lastMenuPosition = ReadByte(commandMenuPosition)
		lastPauseType = ReadByte(inMenu)
		insert_dummy_item_to_make_menu_available()
		if ReadByte(commandMenuType) == 2 then
			local equipped = {}
			for i = 0, 7 do
				if ReadByte(itemSlot1 + i) ~= 00 then
					table.insert(equipped, ReadByte(itemSlot1 + i))
				end
			end
			for i, equip in pairs(equipped) do
				if i - 1 == ReadByte(commandItemHoverPosition) then
					lastItemTypeSelected = equip
				end
			end
		end
		activate_spirit_link()
		currentLink = ReadByte(currentLinkItem)
		spirit_link_effects()
		set_spell_costs()
	end
end

function calculate_spirit_drain()
	if ReadByte(inMenu) == 0 then
		if spiritDrainTimer > 0 then
			spiritDrainTimer = spiritDrainTimer - 1
		else
			if currentLink > 0 and ReadByte(linkedSpiritItem) > 0 then
				WriteByte(linkedSpiritItem, ReadByte(linkedSpiritItem) - 1)
			end
			spiritDrainTimer = spiritDrainDelay
		end
	end
end

function store_sora_item_slots()
	-- When you open the item menu, save Sora's current item slot amount
	local changeItemText = false
	itemValue = 0
	buttonInput = (ReadByte(0x23407B5))
		--[[if ReadByte(soraItemSlotAmount) >= 9 then
			itemValue = soraItemSlotValue
			changeItemText = false
			boostedAmount = false
		end
		]]
	if spiritValue >= spiritNeeded and lastCommandMenuType == 0 and ReadByte(commandMenuType) == 2 and buttonInput ~= 0x02 then
		soraItemSlotValue = ReadByte(soraItemSlotAmount)
		ConsolePrint("Sora Item Slots Stored")
		itemValue = soraItemSlotValue + 1
		changeItemText = true
		boostedAmount = true
	end
	if lastMenuPosition == 2 and lastCommandMenuType >= 2 and ReadByte(commandMenuType) == 0 then
		ConsolePrint("Left Item Menu")
		itemValue = soraItemSlotValue
		changeItemText = false
		boostedAmount = false
		--ConsolePrint("The last item type selected was: " .. lastItemTypeSelected)
		--ConsolePrint("The Item ID of the spirit item is: " .. spiritItemId)
		if (lastItemTypeSelected == spiritItemId) and lastCommandMenuType == 4 then
			ConsolePrint("Start Spirit Timer")
			spiritCheckTimer = 10
		end
	end
	if lastPauseType == 0 and ReadByte(inMenu) == 1 and boostedAmount == true then
		ConsolePrint("Entered Pause Menu")
		itemValue = soraItemSlotValue
		changeItemText = false
	end
	if lastPauseType == 1 and ReadByte(inMenu) == 0 and boostedAmount == true then
		ConsolePrint("Exited Pause Menu")
		itemValue = soraItemSlotValue + 1
		changeItemText = true
	end
	
	if ReadByte(itemSlot1) == spiritItemId then
		itemValue = soraItemSlotValue
	end
	
	if itemValue > 0 then
		WriteByte(soraItemSlotAmount, itemValue)
	end
	if boostedAmount == false and ReadByte(soraItemSlotAmount) > 7 then
		WriteByte(soraItemSlotAmount, 7)
	end
end

function add_spirit_command()
	if spiritValue >= spiritNeeded then
		-- ConsolePrint("Spirit Command has been added")
		WriteByte(itemSlot1 + ReadByte(soraItemSlotAmount), spiritItemId)
	end
end

-- Some spirit link effects must be duplicated both here and in CMix files
function insert_dummy_item_to_make_menu_available()
	local value = ReadByte(soraItemSlotAmount)

	if soraItemSlotValue > 0 then
		value = soraItemSlotValue
	end
	value = math.max(0, math.min(value, 7))

	if spiritValue >= spiritNeeded then
		local allEmpty = true
		for i = 0, value - 1 do
			if ReadByte(itemSlot1 + i) ~= 0 and ReadByte(itemSlot1 + i) ~= spiritItemId then
				allEmpty = false
			end
		end
		
		if allEmpty == true then
			if ReadByte(0x2DE9386) ~= 0x45 and ReadByte(inMenu) == 0 then
				-- ConsolePrint("Empty Item Slots")
				WriteByte(itemSlot1, spiritItemId)
			end
		end
		
	elseif ReadByte(itemSlot1) == spiritItemId then
		WriteByte(itemSlot1, 0)
	end
	if ReadByte(inMenu) == 1 and ReadByte(itemSlot1) == spiritItemId then
		WriteByte(itemSlot1, 0x00)
	end
	for i = value + 1, 7 do
		if ReadByte(itemSlot1 + i) == spiritItemId then
			WriteByte(itemSlot1 + i, 0)
			--ConsolePrint("Dummy Item Inserted")
		end
	end
end

function activate_spirit_link()
	local itemAnims = {0x3E, 0x3F, 0x8B}
	local activate = false

	if spiritCheckTimer > 0 then
		local animation = ReadByte(currentAnim, true)

		for _, anim in pairs(itemAnims) do
			if animation == anim then
				activate = true
				break
			end
		end

		-- Decrease the timer whether or not the animation matched.
		spiritCheckTimer = spiritCheckTimer - 1
	end

	if not activate then
		return
	end

	ConsolePrint("SPIRIT LINK")
	spiritCheckTimer = 0

	--ConsolePrint("Your new HP value: " .. restoredHPValue)
	--ConsolePrint("Your Max HP value: " .. maxHPValue)
	
	WriteByte(currentHPAddress, restoredHPValue)
	WriteByte(displayedHPAddress, restoredHPValue)
	ConsolePrint("HP Restored")

	local hoverPosition = ReadByte(commandItemPartyHoverPosition)

	local link = 0

	if hoverPosition == 0 then
		ConsolePrint("- Sora Link -")
		link = 1
		spiritDrainDelay = 80

	elseif hoverPosition == 1 then
		ConsolePrint("- Link Ally 1 -")
		local allyValue = ReadByte(0x2DE97EF)
		link = math.min(3, allyValue + 1)
		--ConsolePrint("Link Number Successful")

	elseif hoverPosition == 2 then
		ConsolePrint("- Link Ally 2 -")
		local allyValue = ReadByte(0x2DE97F0)
		link = math.min(3, allyValue + 1)
		--ConsolePrint("Link Number Successful")
	end

	--ConsolePrint("Calculated link: " .. link)

	if link == 2 then

		if chargeMPValue > 0xFFFF then
			ConsolePrint("Warning: charge value exceeds one byte.")
		end
		-- Use this clamped version while diagnosing.
		WriteShort(chargeMPAddress, chargeMPValue)
		WriteShort(displayedChargeAddress, chargeMPValue)
		ConsolePrint("MP Charge Refilled")

		WriteByte(currentMPAddress, restoredMPValue)
		WriteByte(displayedMPAddress, restoredMPValue)
		ConsolePrint("MP Refilled")
		spiritDrainDelay = 40

	elseif link == 3 then
		spiritDrainDelay = 80
	end

	currentLink = link
		WriteByte(currentLinkItem, link)
		--ConsolePrint("Link Item Written")
end

function spirit_link_effects()
	local r = 1.1
	local g = 1.1
	local b = 1.1

	WriteFloat(soraAnimSpeed, 1.0, true)
	if currentLink == 1 then
		if criticalMix == false then
			WriteFloat(soraAnimSpeed, 1.3, true)
		end
		r = 1.5
		b = 0.9
		g = 0.9
	elseif currentLink == 2 then
		r = 0.8
		g = 0.8
		b = 1.8
	elseif currentLink == 3 then
		g = 1.5
		r = 0.9
		b = 0.9
		if criticalMix == false then
			if ReadByte(connectCounter) > 0 then
				WriteByte(
					currentHPAddress,
					math.min(
						ReadByte(currentHPAddress) + 2,
						ReadByte(maxHPAddress) + 18
					)
				)
			end
		end
	end
	if criticalMix == false and ReadByte(connectCounter) > 0 then
		if currentLink > 0 then
			WriteByte(linkedSpiritItem, math.max(0, ReadByte(linkedSpiritItem) - 2))
		else
			WriteByte(linkedSpiritItem, math.max(0, ReadByte(linkedSpiritItem) + math.max(1, ReadByte(curComboChain) - 1) + 2))
			ConsolePrint("Something has been struck, updating spirit bar.")
		end
		WriteByte(connectCounter, 0)
	end
	local color = true
	if criticalMix == true and currentLink == 0 then
		color = false
		ConsolePrint("Critical Mix is true??")
	end
	if color == true then
		WriteFloat(soraRed, r, true)
		WriteFloat(soraGreen, g, true)
		WriteFloat(soraBlue, b, true)
	end
end


function set_spell_costs()
	if criticalMix == true then
		return
	end

	if currentLink == lastSpellCostLink then
		return
	end

	lastSpellCostLink = currentLink

	local small = 30
	local mid = 100
	local big = 200

	if currentLink == 2 then
		ConsolePrint("Spell Costs Set")
		small = small * 0.5
		mid = mid * 0.5
		big = big * 0.5
	end

	WriteByte(fireMP, small)
	WriteByte(firaMP, small)
	WriteByte(firagaMP, small)

	WriteByte(blizzardMP, small)
	WriteByte(blizzaraMP, small)
	WriteByte(blizzagaMP, small)

	WriteByte(gravityMP, mid)
	WriteByte(graviraMP, mid)
	WriteByte(gravigaMP, mid)

	WriteByte(thunderMP, mid)
	WriteByte(thundaraMP, mid)
	WriteByte(thundagaMP, mid)

	WriteByte(cureMP, mid)
	WriteByte(curaMP, mid)
	WriteByte(curagaMP, mid)

	WriteByte(stopMP, big)
	WriteByte(stopraMP, big)
	WriteByte(stopgaMP, big)

	WriteByte(aeroMP, big)
	WriteByte(aeroraMP, big)
	WriteByte(aerogaMP, big)
end

-- Create an array of your items and use that instead

function draw_spirit_bar()
	WriteLong(hpmpStart+0x00, 0x0000014E00000144)
	WriteLong(hpmpStart+0x08, 0x0000003900000075) -- Bar Height and length
	WriteLong(hpmpStart+0x10, 0x0000001700000008)
	WriteLong(hpmpStart+0x18, 0x0000003E00000007)
	WriteLong(hpmpStart+0x20, 0x0000000000000000)
	WriteLong(hpmpStart+0x28, 0x0000008000000000)
		
	WriteLong(fillStart+0x10, 0x0000001700000008)
	WriteLong(fillStart+0x18, 0x0000003C00000007)
	
	if currentLink ~= 2 then
		WriteShort(fillStart+0x28, 0x0020)
	end
	WriteShort(fillStart+0x2A, 0x0000)
	
	if currentLink == 0 then -- No link
		if spiritValue >= 115 then -- Sora link
			WriteLong(fillStart+0x20, 0x000000A0000000D0)
		else
			WriteLong(fillStart+0x20, 0x0000007000000090)
		end
	elseif currentLink == 1 then -- Sora link
		WriteLong(fillStart+0x20, 0x00000050000000F0)
	
	elseif currentLink == 2 then -- Donald Link
		WriteLong(fillStart+0x20, 0x0000007000000000)
		WriteShort(fillStart+0x28, 0x00FF)
		
	elseif currentLink == 3 then -- Goofy Link
		WriteLong(fillStart+0x20, 0x000000F000000000)
		
	end
end


function apply_bar_fill()
	local fillAmount = 0x0000014F000001BA - spiritValue
	local fillAmount2 = 0x0000003000000000 + spiritValue

	WriteLong(fillStart+0x00, fillAmount) -- Increase to reduce bar
	WriteLong(fillStart+0x08, fillAmount2) -- Decrease to reduce bar
end
