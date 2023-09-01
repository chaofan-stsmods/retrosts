-- topbar
---@diagnostic disable: lowercase-global

cursorOnTopBar = false
local topBarSelection = {type=nil,index=0}
local relicOffset = 0
local relicOffsetTarget = 0
function tickTopBar(control)
	drawTopBar()
	if control then
		controlTopBar()
	else
		cursorOnTopBar = false
	end
end

function drawTopBar()
	rect(0,0,240,7,14)
	rect(0,7,240,1,15)
	map(0,0,30,1,0,0,0)
	drawIcon(icons.Deck,216,0)
	printShadowed(player.hp .. '/' .. player.maxHp,17,1,3)
	printShadowed(tostring(gold),73,1,4)
	printShadowed(tostring(floor),153,1,12)
	printShadowed(#deck,225,1,12)
	if ascension > 0 then
		spr(5,168,0,0)
		printShadowed(tostring(ascension),177,1,12)
	end
	drawPotions()
	drawRelics()
	if topBarSelection.type == 'potion' and topBarSelection.index > 0 and topBarSelection.index <= #potions then
		local potion = potions[topBarSelection.index]
		drawSelectionBox(95+topBarSelection.index*8,0,10,9,nil,2)
		if potion ~= PotionSlot then
			drawItemTooltip(potion,95+topBarSelection.index*8,10)
		end
	elseif topBarSelection.type == 'deck' then
		drawSelectionBox(215,0,10,9,nil,2)
	elseif topBarSelection.type == 'map' then
		drawSelectionBox(207,0,10,9,nil,2)
	elseif topBarSelection.type == 'potionMenu' then
		drawSelectionBox(95+topBarSelection.potionIndex*8,0,10,9,nil,2)
		drawPotionMenu(75+topBarSelection.potionIndex*8)
	elseif topBarSelection.type == 'usePotion' then
		local x = 99+topBarSelection.potionIndex*8
		local enemy = enemies[topBarSelection.index]
		drawSelectionBox(95+topBarSelection.potionIndex*8,0,10,9,nil,2)
		drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
		drawBezier(20,x,8,math.min(x,enemy.x-20),enemy.y+enemy.height*4-5,enemy.x+enemy.width*4-4,enemy.y+enemy.height*4)
		spr(74,enemy.x+enemy.width*4-8,enemy.y+enemy.height*4-4,0)
	end
	if emeraldKeyObtained then spr(3,0,0,0) end
	if rubyKeyObtained then spr(4,0,0,0) end
	if sapphireKeyObtained then
		mapColor(1,15)
		mapColor(2,9)
		mapColor(3,10)
		mapColor(4,11)
		spr(4,1,0,0,1,1)
		resetColors{1,2,3,4}
	end
end

function drawPotions()
	local x = 104
	for i, potion in ipairs(potions) do
		potion:drawImage(x,0)
		x = x + 8
	end
end

function getRelicX(index)
	return 1-relicOffset+(index-1)*12
end

function drawRelics()
	relicOffset = lerp(relicOffset,relicOffsetTarget,0.1)
	local y = 9
	for i, relic in ipairs(relics) do
		local x = getRelicX(i)
		relic:drawImage(x,y)
		if topBarSelection.type == 'relic' and topBarSelection.index == i then
			drawSelectionBox(x-1,y-1,10,10,nil,2)
			drawItemTooltip(relic,math.max(0,x-1),y+10)
			if x > 224 then
				relicOffsetTarget = x + relicOffset - 224
			elseif x < 1 then
				relicOffsetTarget = x + relicOffset - 1
			end
		end
	end
end

function drawPotionMenu(x)
	local y = 9
	drawTooltipBox(x,y,6,4)
	rect(x+3,y+3,42,12,topBarSelection.index == 1 and 13 or 15)
	rect(x+3,y+17,42,12,topBarSelection.index == 2 and 13 or 15)
	local potion = potions[topBarSelection.potionIndex]
	local color = potion:canUse() and 12 or 14
	printShadowed(potion.useTitle,x+25-strWidth(potion.useTitle)/2,y+6,color,15)
	local disard = 'Discard'
	printShadowed(disard,x+25-strWidth(disard)/2,y+20,2,1)
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

	if topBarSelection.type == 'potion' then
		if btnp(2) then
			topBarSelection.index = limit(topBarSelection.index-1,1,#potions)
		elseif btnp(1) then
			topBarSelection.type = 'relic'
			topBarSelection.index = limit(math.floor(relicOffset/12)+10,1,#relics)
		elseif btnp(3) then
			if topBarSelection.index == #potions then
				topBarSelection.type = 'map'
			else
				topBarSelection.index = limit(topBarSelection.index+1,1,#potions)
			end
		elseif btnp(4) then
			if potions[topBarSelection.index] ~= PotionSlot then
				topBarSelection.type = 'potionMenu'
				topBarSelection.potionIndex = topBarSelection.index
				topBarSelection.index = 1
			end
		elseif btnp(5) then
			exitTopBar()
		end
	elseif topBarSelection.type == 'potionMenu' then
		if btnp(0) then
			topBarSelection.index = 1
		elseif btnp(1) then
			topBarSelection.index = 2
		elseif btnp(4) then
			if topBarSelection.index == 1 then
				local potion = potions[topBarSelection.potionIndex]
				if potion:canUse() then
					if potion.enemyTarget then
						topBarSelection.type = 'usePotion'
					else
						trace('usePotion '..potion.name)
						if potion.canUseOutsideCombat then
							potions[topBarSelection.potionIndex] = PotionSlot
							potion:applyPowers()
							potion:use()
							player:triggerEvent('onUsePotion',potion,false)
						else
							addAction(UsePotionAction:new{potion=potion})
						end
						exitTopBar()
					end
				end
			elseif potions[topBarSelection.potionIndex]:canDiscard() then
				potions[topBarSelection.potionIndex] = PotionSlot
				topBarSelection.type = 'potion'
				topBarSelection.index = topBarSelection.potionIndex
				topBarSelection.potionIndex = nil
			end
		elseif btnp(5) then
			topBarSelection.type = 'potion'
			topBarSelection.index = topBarSelection.potionIndex
			topBarSelection.potionIndex = nil
		end
	elseif topBarSelection.type == 'usePotion' then
		local potion = potions[topBarSelection.potionIndex]
		if not potion:canUse() then
			topBarSelection.type = 'potionMenu'
			topBarSelection.index = 1
			return
		end
		local function enemyIsAlive(i) return enemies[i].alive end
		if topBarSelection.index == 0 or not enemies[topBarSelection.index].alive then
			topBarSelection.index = nextOrOtherIndexInTableIf(enemies,topBarSelection.index,enemyIsAlive)
			if topBarSelection.index == 0 then
				topBarSelection.type = 'potionMenu'
				topBarSelection.index = 1
				return
			end
		end
		if btnp(2) then
			topBarSelection.index = previousOrOtherIndexInTableIf(enemies,topBarSelection.index,enemyIsAlive)
		elseif btnp(3) then
			topBarSelection.index = nextOrOtherIndexInTableIf(enemies,topBarSelection.index,enemyIsAlive)
		elseif btnp(4) then
			addAction(UsePotionAction:new{potion=potion,target=enemies[topBarSelection.index]})
			exitTopBar()
		elseif btnp(5) then
			topBarSelection.type = 'potionMenu'
			topBarSelection.index = 1
		end
	elseif topBarSelection.type == 'map' then
		if btnp(2) then
			topBarSelection.type = 'potion'
			topBarSelection.index = #potions
		elseif btnp(1) then
			topBarSelection.type = 'relic'
			topBarSelection.index = limit(math.floor(relicOffset/12)+18,1,#relics)
		elseif btnp(3) then
			topBarSelection.type = 'deck'
			topBarSelection.index = #potions
		elseif btnp(4) then
			if getmetatable(nearestWindow) == MapWindow and nearestWindow.canClose then
				nearestWindow:close()
			else
				local existingMapWindow = findWindow(MapWindow)
				openWindowAbove(MapWindow:new{canClose=existingMapWindow~=nil and existingMapWindow.canClose or true})
			end
			exitTopBar()
		elseif btnp(5) then
			exitTopBar()
		end
	elseif topBarSelection.type == 'deck' then
		if btnp(2) then
			topBarSelection.type = 'map'
		elseif btnp(1) then
			topBarSelection.type = 'relic'
			topBarSelection.index = limit(math.floor(relicOffset/12)+19,1,#relics)
		elseif btnp(4) then
			if getmetatable(nearestWindow) == CardGridSelectWindow and nearestWindow.isDeckView then
				nearestWindow:close()
			else
				closeWindowsIf(function (w) return getmetatable(w) == CardGridSelectWindow and w.isDeckView end)
				local cardItems = table.map(deck, function (card) return CardItem:new{card=card,x=240,y=0,isNotInHand=true} end)
				local gridView = CardGridSelectWindow:new{title='Your Deck',cardItems=cardItems,isDeckView=true,min=0,max=0,canClose=true}
				openWindowAbove(gridView)
			end
			exitTopBar()
		elseif btnp(5) then
			exitTopBar()
		end
	elseif topBarSelection.type == 'relic' then
		if topBarSelection.index < 1 or topBarSelection.index > #relics then
			topBarSelection.index = limit(topBarSelection.index,1,#relics)
			if topBarSelection.index < 1 or topBarSelection.index > #relics then
				exitTopBar()
				return
			end
		end
		if btnp(0) then
			if (topBarSelection.index-14)*12-relicOffset <= 0 then
				topBarSelection.type = 'potion'
				topBarSelection.index = 1
			elseif (topBarSelection.index-18.5)*12-relicOffset < 0 then
				topBarSelection.type = 'map'
			else
				topBarSelection.type = 'deck'
			end
		elseif btnp(2) then
			topBarSelection.index = limit(topBarSelection.index-1,1,#relics)
		elseif btnp(3) then
			topBarSelection.index = limit(topBarSelection.index+1,1,#relics)
		elseif btnp(1) or btnp(5) then
			exitTopBar()
		end
	end
end

function exitTopBar()
	cursorOnTopBar = false
	topBarSelection.type = nil
	topBarSelection.potionIndex = nil
end
