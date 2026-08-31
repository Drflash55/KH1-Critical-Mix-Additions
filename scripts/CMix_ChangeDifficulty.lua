LUAGUI_NAME = "CMix_ChangeDifficulty"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Allows you to change difficulty in the config menu."

local soraPointer = 0x2537E48
local configOpen = 0x2E92C28
local configPosition = 0x2E98F18
local difficulty = 0x2DFF78C
local menu = 0x232DFA0
local swapped = ReadByte(0x4D8632)
local cooldown = 0
local startCooldown = 10

function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		canExecute = true
		ConsolePrint("Critical Mix - Change Difficulty Installed")
	else
		ConsolePrint("-- FAILED to find compatible game for CMix_ChangeDifficulty --")
	end
end

local crossMask = 0x40
local rightMask = 0x20
local leftMask = 0x80

if swapped == 1 then
    crossMask = 0x20
end

function _OnFrame()
	if not canExecute then
		goto done
	end
	swapped = ReadByte(0x4D8632)
	if cooldown > 0 then
		cooldown = cooldown - 1
	end
	if cooldown <= 0 then
		if ReadByte(configOpen) == 0x03 and ReadByte(configPosition) == 0x06 then
			-- Cross Button
			if (ReadByte(0x23407B5) & crossMask) ~= 0 then
				increase_difficulty()
				ConsolePrint("Difficulty Increased")
			end
			-- D-Pad Right
			if (ReadByte(0x23407B4) & rightMask) ~= 0 then
				increase_difficulty()
				ConsolePrint("Difficulty Increased")
			end
			-- D-Pad Left
			if (ReadByte(0x23407B4) & leftMask) ~= 0 then
				decrease_difficulty()
				ConsolePrint("Difficulty Decreased")
			end
		end
	end
	::done::
end

function increase_difficulty()
	cooldown = startCooldown
	if ReadByte(difficulty) < 2 then
		WriteByte(difficulty, ReadByte(difficulty) + 1)
	else
		WriteByte(difficulty, 0x00)
	end
	
end

function decrease_difficulty()
	cooldown = startCooldown
	if ReadByte(difficulty) > 0 then
		WriteByte(difficulty, ReadByte(difficulty) - 1)
	else
		WriteByte(difficulty, 0x02)
	end
	
end