LUAGUI_NAME = "CMix_MagicHandler"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Intercepts magic system,  allowing you to customize it with code"



local magicArtsBoost = true
local criticalMixEnabled = false
--

local curComboChain = 0x296B221
local maxGroundComboLength = 0x2E942B4
local maxAirComboLength = 0x2E942B5
local soraPointer = 0x2537E48
local animCancel = ReadLong(soraPointer)

-- Costs and damage can be changed in real time while the spell anim is playing, and it will work since it doesnt spend immediately
-- Use this for magic arts 20% chance for free cast


-- Cure
local cureCost = 200
local cureCostText = 0x2E1C235
local curaCostText = 0x2E1C26B
local curagaCostText = 0x2E1C2AC
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

-- Offensive Power
local fireDamageAddress = 0x2D28CB0
local firaDamageAddress = 0x2D28D20
local firagaDamageAddress = 0x2D28D90

local blizzardDamageAddress = 0x2D28E00
local blizzaraDamageAddress = 0x2D28E70
local blizzagaDamageAddress = 0x2D28EE0

local thunderDamageAddress = 0x2D28F50
local thundaraDamageAddress = 0x2D28FC0
local thundagaDamageAddress = 0x2D29030

local gravityDamageAddress = 0x2D291F0
local graviraDamageAddress = 0x2D29260
local gravigaDamageAddress = 0x2D292D0

local fireDamage = 20
local firaDamage = 30
local firagaDamage = 40

local blizzardDamage = 15
local blizzaraDamage = 25
local blizzagaDamage = 35

local thunderDamage = 15
local thundaraDamage = 20
local thundagaDamage = 25

local gravityDamage = 40
local graviraDamage = 55
local gravigaDamage = 70

-- Magic Arts
local fireArts = 0x2DE9897
local blizzardArts = 0x2DE9898
local thunderArts = 0x2DE9899
local cureArts = 0x2DE989A
local gravityArts = 0x2DE989B
local stopArts = 0x2DE989C
local aeroArts = 0x2DE989D

-- Sora RGB Modulate
local soraRedValue = 1.0
local soraGreenValue = 1.0
local soraBlueValue = 1.0


function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		canExecute = true
		ConsolePrint("Critical Mix - Magic Handler Installed")
	else
		ConsolePrint("-- FAILED to find compatible game for CMix_MagicHandler --")
	end
end



function _OnFrame()
	if not canExecute then
		goto done
	end
	-- Refresh pointed values
	animCancel = ReadLong(soraPointer)
	currentAnim = ReadLong(soraPointer)+0x164
	soraRed = ReadLong(soraPointer)+0xA0
	soraGreen = ReadLong(soraPointer)+0xA4
	soraBlue = ReadLong(soraPointer)+0xA8
	
	-- Execute Functions
	if magicArtsBoost == true then
		reset_magic_art_spell_costs()
		apply_white_mushroom_arts()
	end
	reset_combo_position()
	reset_sora_color_values()
	initialize_magic_damage()
	apply_magic_finishers()
	apply_magic_power()
	apply_sora_color()
	::done::
end

function reset_magic_art_spell_costs()

	WriteByte(cureMP, 100)
	WriteByte(curaMP, 100)
	WriteByte(curagaMP, 100)
	
	WriteByte(aeroMP, 200)
	WriteByte(aeroraMP, 200)
	WriteByte(aerogaMP, 200)
	
	WriteByte(stopMP, 200)
	WriteByte(stopraMP, 200)
	WriteByte(stopgaMP, 200)

	if criticalMixEnabled == true then
		adjust_cure_cost()
	end
end

function reset_combo_position()
	local cancelValues = {0x00, 0x01, 0x02, 0xD4, 0xDC, 0x04, 0x05, 0x06, 0x07}
	for i, value in pairs(cancelValues) do
		if value == ReadByte(currentAnim, true) then
			WriteByte(curComboChain, 0)
			break
		end
	end
end


function reset_sora_color_values()
	soraRedValue = 1.15
	soraGreenValue = 1.15
	soraBlueValue = 1.15
end


function apply_sora_color()
	WriteFloat(soraRed, soraRedValue, true)
	WriteFloat(soraGreen, soraGreenValue, true)
	WriteFloat(soraBlue, soraBlueValue, true)
end

function initialize_magic_damage()
	fireDamage = 20
	firaDamage = 30
	firagaDamage = 40

	blizzardDamage = 15
	blizzaraDamage = 25
	blizzagaDamage = 35

	thunderDamage = 15
	thundaraDamage = 20
	thundagaDamage = 25

	gravityDamage = 30
	graviraDamage = 45
	gravigaDamage = 60
	
	if criticalMixEnabled == true then
		gravityDamage = gravityDamage - 10
		graviraDamage = graviraDamage - 10
		gravigaDamage = gravigaDamage - 10
	end
end

function apply_magic_finishers()
	local maxCombo = ReadByte(maxGroundComboLength)
	local airborneStatus = ReadFloat(ReadLong(soraPointer)+0x70, true)
	
	if airborneStatus ~= 0x00 then
		 maxCombo = ReadByte(maxAirComboLength)
	end
	
	
	if ReadByte(curComboChain) >= maxCombo - 1 then
	
		soraRedValue = 1.5
		soraGreenValue = 1.5
		soraBlueValue = 1.7
		
		fireDamage = fireDamage + 10
		firaDamage = firaDamage + 12
		firagaDamage = firagaDamage + 14

		blizzardDamage = blizzardDamage + 8
		blizzaraDamage = blizzaraDamage + 9
		blizzagaDamage = blizzagaDamage + 10

		thunderDamage = thunderDamage + 6
		thundaraDamage = thundaraDamage + 7
		thundagaDamage = thundagaDamage + 8

		gravityDamage = gravityDamage + 5
		graviraDamage = graviraDamage + 5
		gravigaDamage = gravigaDamage + 5
	end
end

function apply_white_mushroom_arts()
	if ReadByte(fireArts) >= 0x01 then
		fireDamage = fireDamage + 4
		firaDamage = firaDamage + 4
		firagaDamage = firagaDamage + 4
	end
	if ReadByte(blizzardArts) >= 0x01 then
		blizzardDamage = blizzardDamage + 3
		blizzaraDamage = blizzaraDamage + 3
		blizzagaDamage = blizzagaDamage + 3
	end
	if ReadByte(thunderArts) >= 0x01 then
		thunderDamage = thunderDamage + 2
		thundaraDamage = thundaraDamage + 2
		thundagaDamage = thundagaDamage + 2
	end
	if ReadByte(gravityArts) >= 0x01 then
		gravityDamage = gravityDamage + 2
		graviraDamage = graviraDamage + 2
		gravigaDamage = gravigaDamage + 2
	end
	
	
	
	
	local rng = math.random(1, 100)
	
	if rng <= 20 and ReadByte(animCancel, true) ~= 3 then
		if ReadByte(cureArts) >= 0x01 then
			if ReadByte(currentAnim, true) == 0x39 or ReadByte(currentAnim, true) == 0x86 then
				WriteByte(cureMP, 0)
				WriteByte(curaMP, 0)
				WriteByte(curagaMP, 0)
			end
		end
		if ReadByte(stopArts) >= 0x01 then
			if ReadByte(currentAnim, true) == 0x3B or ReadByte(currentAnim, true) == 0x88 then
				WriteByte(stopMP, 0)
				WriteByte(stopraMP, 0)
				WriteByte(stopgaMP, 0)
			end
		end
		if ReadByte(aeroArts) >= 0x01 then
		if ReadByte(currentAnim, true) == 0x3C or ReadByte(currentAnim, true) == 0x89 then
				WriteByte(aeroMP, 0)
				WriteByte(aeroraMP, 0)
				WriteByte(aerogaMP, 0)
			end
		end
	end
end

function adjust_cure_cost()
	cost = cureCost
	
	WriteByte(cureCostText, 0x23)
	WriteByte(curaCostText, 0x23)
	WriteByte(curagaCostText, 0x23)
	WriteByte(cureMP, cost)
	WriteByte(curaMP, cost)
	WriteByte(curagaMP, cost)
end

function apply_magic_power()
	WriteByte(fireDamageAddress, fireDamage)
	WriteByte(firaDamageAddress, firaDamage)
	WriteByte(firagaDamageAddress, firagaDamage)

	WriteByte(blizzardDamageAddress, blizzardDamage)
	WriteByte(blizzaraDamageAddress, blizzaraDamage)
	WriteByte(blizzagaDamageAddress, blizzagaDamage)

	WriteByte(thunderDamageAddress, thunderDamage)
	WriteByte(thundaraDamageAddress, thundaraDamage)
	WriteByte(thundagaDamageAddress, thundagaDamage)

	WriteByte(gravityDamageAddress, gravityDamage)
	WriteByte(graviraDamageAddress, graviraDamage)
	WriteByte(gravigaDamageAddress, gravigaDamage)
end