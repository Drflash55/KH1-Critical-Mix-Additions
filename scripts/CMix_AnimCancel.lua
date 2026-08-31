LUAGUI_NAME = "CMix_AnimCancel"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Allows you to cancel attacks into other actions, and Guard / Dodge into each other."

local swapped = ReadByte(0x4D8632)

local soraPointer = 0x2537E48
local menuStatus = 0x232DF80
local buttonPress = 0x23407B5
local cancelFinished = true
local forceSquareInput = 0x2A7BE0
local forceCircleInput = 0x2A7CFA
local leftStickInput = 0x23407B7
local forceSquareResetTimer = 0
local forceCircleResetTimer = 0
local dodgeWaitTimer = 0
local jumpWaitTimer = 0
local resetBlockTimer = 0

local cancelAnimations = {0x6E, 0xC8, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE, 0xD1, 0xCF, 0x70, 0xD2, 0xD3, 0xD5, 0xD7, 0xD8, 0xD9, 0xDA, 0x0C, 0xD0}
local jumpCancelExtraAnims = {0xD4, 0xDC}
--airborneStatus = ReadFloat(ReadLong(soraPointer)+0x70, true)



function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Critical Mix - Animation Cancelling Installed")
		canExecute = true
	end
end

local squareMask = 0x80
local circleMask = 0x0


function _OnFrame()
	if canExecute == true then
		swapped = ReadByte(0x4D8632)
		
		if swapped == 1 then
			circleMask = 0x40
		else
			circleMask = 0x20
		end
		if dodgeWaitTimer > 0 then
			dodgeWaitTimer = dodgeWaitTimer - 1
			-- ConsolePrint("Dodge Wait Timer now at: " .. dodgeWaitTimer)
		end
		if jumpWaitTimer > 0 then
			jumpWaitTimer = jumpWaitTimer - 1
		end
		--airborneStatus = ReadFloat(ReadLong(soraPointer)+0x70, true)
		
		if forceSquareResetTimer == 1 then
			WriteByte(forceSquareInput, 0x84)
		end
		if forceSquareResetTimer > 0 then
			forceSquareResetTimer = forceSquareResetTimer - 1
			ConsolePrint("Guard Timer now at: " .. forceSquareResetTimer)
		end
		
		if forceCircleResetTimer == 1 then
			WriteByte(forceCircleInput, 0x74)
		end
		if forceCircleResetTimer > 0 then
			forceCircleResetTimer = forceCircleResetTimer - 1
		end
		
		local cancelInput = false
		local cancelButton = "square"
		if (ReadByte(0x23407B5) & squareMask) ~= 0 and dodgeWaitTimer == 0 then
			cancelInput = true
		elseif (ReadByte(0x23407B5) & circleMask) ~= 0 and jumpWaitTimer == 0 then
			cancelInput = true
			cancelButton = "circle"
		end
		
		if cancelInput then
			cancelFinished = true
		end
		
		local canCancel = false
		local currentAnim = ReadLong(soraPointer)+0x164
		local animationTime = ReadFloat(ReadLong(soraPointer)+0x16C, true)
		
		for i, anim in pairs(cancelAnimations) do
			if anim == ReadByte(currentAnim, true) then
				canCancel = true
				break
			end
		end
		
		if ReadByte(leftStickInput) == 0 and ReadByte(currentAnim, true) == 0xDC then -- allow guarding out of dodge
			canCancel = true
		end
		
		if ReadByte(leftStickInput) ~= 0 and ReadByte(currentAnim, true) == 0xD4 then -- allow dodging out of guard
			canCancel = true
		end
		
		--[[
		if airborneStatus == 0x00 and cancelButton == "circle" then
			for i, anim in pairs(jumpCancelExtraAnims) do
				if anim == ReadByte(currentAnim, true) then
					canCancel = true
					break
				end
			end
		end
		if airborneStatus ~= 0x00 and cancelButton == "circle" then
			canCancel = false
		end
		]]

		if cancelInput and canCancel == true and cancelFinished == true then
			local animCancel = ReadLong(soraPointer)
			WriteByte(animCancel, 0x03, true)
			if cancelButton == "square" then
				force_defensive_action()
			elseif cancelButton == "circle" then
				force_circle_action()
			end
			cancelFinished = false
		end
		if resetBlockTimer <= 119 then
			resetBlockTimer = resetBlockTimer + 1
		end
		if resetBlockTimer == 120 then
			WriteByte(forceSquareInput, 0x82)
			resetBlockTimer = 0
		end
	end
end

function force_defensive_action()
	WriteByte(forceSquareInput, 0x82)
	ConsolePrint("Cancelled with dodge")
	forceSquareResetTimer = 30
	dodgeWaitTimer = 30
end

function force_circle_action()
	WriteByte(forceCircleInput, 0x72)
	ConsolePrint("Cancelled with jump")
	forceCircleResetTimer = 30
	jumpWaitTimer = 30
end