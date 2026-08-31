LUAGUI_NAME = "CMix_ItemAutoReload"
LUAGUI_AUTH = "Xendra"
LUAGUI_DESC = "Automatically refills items from stock when out of combat"

local soraItemSlots = 0x2DE9386
local commandColor = 0x2859450

local equippedItems = {}
local reloadableItems = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08}


local potion = 0x2DE97FA
local hiPpotion = potion + 1
local ether = potion + 2
local elixir = potion + 3
local phoenixDown = potion + 4
local megaPotion = potion + 5
local megaEther = potion + 6
local megalixir = potion + 7
local inMenu = 0x2E941C0

function _OnInit()
	if GAME_ID == 0xAF71841E and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Critical Mix - Item Auto Reload Installed")
		canExecute = true
	end
end


function _OnFrame()
	if canExecute == true then
		if ReadShort(commandColor) ~= 0x5950 and ReadByte(inMenu) == 0x00 then
			reload_items()
		end
		if ReadByte(inMenu) ~= 0x00 then
			remember_equipped_items()
		end
	end
end



function remember_equipped_items()
	equippedItems = {}
	for i=0x00,0x07 do
		local slot = ReadByte(soraItemSlots + i)
		table.insert(equippedItems, slot)
	end
end



function reload_items()
	for i, item in pairs(equippedItems) do
		if ReadByte(soraItemSlots + i - 1) == 0 and check_item_stock(item) == true and i <= 0x0E then
			ConsolePrint("R for Reload")
			WriteByte(soraItemSlots + i - 1, item)
			reduce_item_stock(item)
		end
	end
end

function check_item_stock(item)
	local haveItem = false
	if item == 0x01 and ReadByte(potion) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x02 and ReadByte(hiPpotion) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x03 and ReadByte(ether) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x04 and ReadByte(elixir) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x05 and ReadByte(phoenixDown) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x06 and ReadByte(megaPotion) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x07 and ReadByte(megaEther) >= 1 then
		haveItem = true
		return(haveItem)
	elseif item == 0x08 and ReadByte(megalixir) >= 1 then
		haveItem = true
		return(haveItem)
	end
return(haveItem)
end

function reduce_item_stock(item)
	if item == 0x01 and ReadByte(potion) >= 1 then
		WriteByte(potion, ReadByte(potion) - 1)
	elseif item == 0x02 and ReadByte(hiPpotion) >= 1 then
		WriteByte(hiPpotion, ReadByte(hiPpotion) - 1)
	elseif item == 0x03 and ReadByte(ether) >= 1 then
		WriteByte(ether, ReadByte(ether) - 1)
	elseif item == 0x04 and ReadByte(elixir) >= 1 then
		WriteByte(elixir, ReadByte(elixir) - 1)
	elseif item == 0x05 and ReadByte(phoenixDown) >= 1 then
		WriteByte(phoenixDown, ReadByte(phoenixDown) - 1)
	elseif item == 0x06 and ReadByte(megaPotion) >= 1 then
		WriteByte(megaPotion, ReadByte(megaPotion) - 1)
	elseif item == 0x07 and ReadByte(megaEther) >= 1 then
		WriteByte(megaEther, ReadByte(megaEther) - 1)
	elseif item == 0x08 and ReadByte(megalixir) >= 1 then
		WriteByte(megalixir, ReadByte(megalixir) - 1)
	end
end