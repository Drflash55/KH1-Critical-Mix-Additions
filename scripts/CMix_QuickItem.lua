LUAGUI_NAME = "CMix_QuickItem"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Press R2 to use items"

local TBD = 0x0
local soraPointer = 0x2537E48
local attackCommand = 0x52890C
local cooldown = 0
local delayTargets = {1, 2}
local inputDelay = 3
local usageFinished = true
local soraItemSlots = 0x528980
local swapped = ReadByte(0x4D8632)

function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		canExecute = true
		ConsolePrint("Critical Mix - Quick Item Installed")
	else
		ConsolePrint("-- FAILED to find compatible game for CMix_QuickItem --")
	end
end



function _OnFrame()
	if not canExecute then
		goto done
	end
	swapped = ReadByte(0x4D8632)
	local itemInput = (ReadByte(0x23407B5))
	
	if itemInput == 0x02 then
		quick_item()
	end
	
	if inputDelay < 3 then
		if inputDelay == 1 then
			trigger_menu()
		elseif inputDelay == 2 and itemInput == 0 then
			trigger_menu()
			WriteByte(attackCommand, 0)
			inputDelay = 3
			usageFinished = true
		end
		if inputDelay < 2 then
			inputDelay = inputDelay + 1
		end
	end
	if cooldown > 0 then
		cooldown = cooldown - 1
	end
	::done::
end


function quick_item()
	if cooldown > 0 then
		return
	end

	local currentAnim = ReadLong(soraPointer) + 0x164
	local itemCount = ReadByte(soraItemSlots)
	local allEmpty = itemCount == 0
	local valid = true

	if ReadByte(currentAnim, true) == 0x3E then
		valid = false
		ConsolePrint("Can't use items at this time.")
	end

	if usageFinished == false then
		valid = false
		ConsolePrint("Sora can use an item right now.")
	end

	if allEmpty then
		valid = false
		ConsolePrint("Sora is out of items.")
	end

	if valid then
		usageFinished = false
		inputDelay = 0
		cooldown = 15
		ConsolePrint("Sora is using an item.")
		WriteByte(attackCommand, 2)
		trigger_menu()
	end
end

function trigger_menu()
	WriteInt(0x23D3F80, 0x01)
	WriteInt(0x232DDC4, 0x01)
	ConsolePrint("Menu was opened.")
end
