-- topbar
---@diagnostic disable: lowercase-global

cursorOnTopBar = false
topBarSelection = {type=nil,index=0}
function tickTopBar(control)
	drawTopBar()
	if control then
		controlTopBar()
	else
		cursorOnTopBar = false
	end
end

function drawTopBar()
	map(0,0,30,1,0,0)
	printShadowed(player.hp .. '/' .. player.maxHp,17,1,3)
	printShadowed(tostring(gold),73,1,4)
	printShadowed(tostring(floor),153,1,12)
	printShadowed(#deck,225,1,12)
	for i = 1,#potions do
		if potions[i] == 'slot' then
			spr(41,96+i*8,0,0)
		end
	end
	if topBarSelection.type == 'potion' then
		drawSelectionBox(95+topBarSelection.index*8,0,10,9,nil,2)
	elseif topBarSelection.type == 'deck' then
		drawSelectionBox(215,0,10,9,nil,2)
	elseif topBarSelection.type == 'map' then
		drawSelectionBox(207,0,10,9,nil,2)
	end
	if emeraldKeyObtained then spr(3,0,0,0) end
	if rubyKeyObtained then spr(4,0,0,0) end
	if sapphireKeyObtained then spr(5,0,0,0) end
end

function controlTopBar()
	if btnp(6) then
		if cursorOnTopBar then
			exitTopBar()
		else
			cursorOnTopBar = true
			topBarSelection.type = 'potion'
			topBarSelection.index = 1
		end
	end

	if btnp(2) then
		if topBarSelection.type == 'potion' then
			topBarSelection.index = limit(topBarSelection.index-1,1,#potions)
		elseif topBarSelection.type == 'map' then
			topBarSelection.type = 'potion'
			topBarSelection.index = #potions
		elseif topBarSelection.type == 'deck' then
			topBarSelection.type = 'map'
		end
	elseif btnp(3) then
		if topBarSelection.type == 'potion' then
			if topBarSelection.index == #potions then
				topBarSelection.type = 'map'
			else
				topBarSelection.index = limit(topBarSelection.index+1,1,#potions)
			end
		elseif topBarSelection.type == 'map' then
			topBarSelection.type = 'deck'
			topBarSelection.index = #potions
		end
	elseif btnp(1) or btnp((5)) then
		exitTopBar()
	end

	if btnp(4) then
		if topBarSelection.type == 'map' then
			if getmetatable(nearestWindow) == MapWindow then
				nearestWindow:close()
			else
				openWindowAbove(MapWindow:new())
			end
			exitTopBar()
		end
	end
end

function exitTopBar()
	cursorOnTopBar = false
	topBarSelection.type = nil
end
