LUAGUI_NAME = "CMix_ChainAttackReactionCommand"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Adds chain attack Reaction Commands - Ability 28 / A8"

local TBD = 0x0
local rcOpacity = 0x2866D14
local showingBurst = false
local soraPointer = 0x2537E48
local currentAnim = ReadLong(soraPointer)+0x164
local animCancel = ReadLong(soraPointer)
local animationTime = ReadFloat(ReadLong(soraPointer)+0x16C, true)
local swapped = ReadByte(0x4D8632)
local inputDelay = 3
local rcCommand = 0x2866D10
local slot1item = ReadByte(0x2DE9386)
local curComboChain = 0x296B221

local burstTime = 48.0
local world = 0x233FE94


local burstAnims = {0xCB, 0xDA, 0xD9, 0xD2, 0xD7, 0xD8}

function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Critical Mix - Chain Attack Reaction Command Installed")
		canExecute = true
	end
end


function _OnFrame()
	if canExecute == true then
		swapped = ReadByte(0x4D8632)
		currentAnim = ReadLong(soraPointer)+0x164
		animCancel = ReadLong(soraPointer)
		animationTime = ReadFloat(ReadLong(soraPointer)+0x16C, true)
		disable_burst()
		
		if inputDelay < 3 then
			inputDelay = inputDelay + 1
		end
		if inputDelay == 1 then
			trigger_menu()
		elseif inputDelay == 2 then
			WriteByte(0x2DE9386, slot1item)
		end
		local valid = check_ability_count(0x32)
		valid = 1
		if ReadByte(world) ~= 0x00 and valid > 0 then
			if animationTime >= burstTime then
				for i, anim in pairs(burstAnims) do
					if anim == ReadByte(currentAnim, true) then
						enable_burst()
						break
					end
				end
			end
		end
		
		
	end
end

function trigger_burst()
	if ReadShort(rcCommand) == 0 then
		
		local burstID = 0x45
	
		if ReadByte(0x2DE9386) ~= burstID then
			slot1item = ReadByte(0x2DE9386)
		end
		WriteByte(0x52897C, 0x00) -- item menu position
		WriteByte(0x285279C, 0x00) -- item menu position
		WriteByte(0x28527B4, 0x00) -- item menu position
		WriteByte(0x2DE9386, burstID)
		
		inputDelay = 0
		WriteByte(animCancel, 0x03, true)
		local command = 0x52890C
		WriteByte(command, 2)
		trigger_menu()
		WriteByte(comboPosition, 0)
		disable_burst()
	end
end


function trigger_burst_attack()
-- Store item in slot 1. Then place Counter attack in slot 1, use it, and then place the regular item back into slot 1.



end

local triangleMask = 0x10

function enable_burst()
	if (ReadByte(0x23407B5) & triangleMask) ~= 0 then
		trigger_burst()
		return
	end
	WriteFloat(rcOpacity, 1.0)
end

function disable_burst()
	if ReadShort(rcCommand) == 0 then
		WriteFloat(rcOpacity, 0.0)
	end
end



function trigger_menu()
	WriteInt(0x23D3F80, 0x01)
	WriteInt(0x232DDC4, 0x01)
end


function check_ability_count(id)
	local abilitySlots = 0X2DE93A4
	local count = 0
	
	for i = 0, 47 do
		if id == ReadByte(abilitySlots + i) then
		count = count + 1
		end
	end
	return count
end


--Step 1: Force up False RC
--Step 2: Populate False RC
--Step 3: When triangle pressed, perform a quick item
--Step 4: The quick item puts counter into your item slots

-- Look into item menu transparency during it to hide
-- Look for dodge roll and guard in this


--0x2DE9386 is item slot 1 id

-- Counter is 0x45
