-- combat
---@diagnostic disable: lowercase-global

-- in combat properties
shuffleRand = nil
enemies = {}
drawPile = {}
discardPile = {}
exhaustPile = {}
hand = {}
energy = 3
turn = 1
inEnemyTurn = false
combatSpriteBank = 1
local combatSelection = {type='hand',index=1}

function startCombat()
	shuffleRand = makeRand(act,room.id,1)
	setupEnemies()
	closeChildWindows()
	resetActions()
	drawPile = {}
	discardPile = {}
	exhaustPile = {}
	hand = {}
	turn = 0
	inEnemyTurn = false
	for _,card in ipairs(deck) do
		table.insert(drawPile,card:copy())
	end
	shuffleRand:shuffle(drawPile)
	player:onCombatStart()
	for _, enemy in ipairs(enemies) do
		enemy:onCombatStart()
	end
	addAction(NewTurnAction:new())
	combatSelection.type = 'hand'
	combatSelection.index = 0
end

function setupEnemies()
	combatSpriteBank = 1
	enemies = {}
	local enemy
	--enemy = Cultist:new({ hp=51,maxHp=51,x=110,y=48,width=4,height=4 })
	--table.insert(enemies,enemy)
	enemy = Cultist:new({ hp=1,maxHp=51,x=150,y=48,width=4,height=4 })
	table.insert(enemies,enemy)
	--enemy = Cultist:new({ hp=51,maxHp=51,x=190,y=48,width=4,height=4 })
	--table.insert(enemies,enemy)
end

function combat()
	drawActBackground()
	player:tick()
	for i=1,#enemies do
		enemies[i]:tick()
	end
	tickEffects()
	tickActions()
	combatControls()
	drawOverlay()
	tickTopBar(true)
end

function drawActBackground()
	map(30,0,30,17,0,0)
end

function tickEffects()
	for i=#effects,1,-1 do
		effects[i]:tick()
		if effects[i].isDone then
			table.remove(effects,i)
		end
	end
	for i=#pendingEffects,1,-1 do
		table.insert(effects,pendingEffects[i])
		table.remove(pendingEffects,i)
	end
end

function drawOverlay()
	map(0,2,3,3,4,96,8)
	local energyText = energy .. '/' .. maxEnergy
	local width = strWidth(energyText)
	printShadowed(energyText,16-width/2,105,12)
	spr(38,0,128,0)
	printShadowed(tostring(#drawPile),8,129,12)
	spr(39,232,128,0)
	width = strWidth(tostring(#discardPile))
	printShadowed(tostring(#discardPile),232-width,129,12)
	if #exhaustPile > 0 then
		spr(40,232,120,0)
		width = strWidth(tostring(#exhaustPile))
		printShadowed(tostring(#exhaustPile),232-width,121,12)
	end
	drawHand()
end

function drawHand()
	local handWidth
	local handDistance
	local handStart
	if #hand < 7 then
		handWidth = #hand * 24 + 8
		handDistance = 24
		handStart = 120 - handWidth / 2 + 16 - handDistance
	else
		handWidth = 180
		handDistance = (handWidth - 32) / (#hand - 1)
		handStart = 30
	end
	for i = 1,#hand do
		if not hand[i].isNotInHand then
			hand[i].tx = handStart + i * handDistance
			hand[i].ty = 136
		end
		hand[i].large = false
		if combatSelection.type == 'usecard' and combatSelection.handIndex == i then
			hand[i].ty = 128
		end
		if combatSelection.type ~= 'hand' or combatSelection.index ~= i then
			hand[i]:tick()
		end
	end
	if combatSelection.type == 'hand' and combatSelection.index <= #hand and combatSelection.index >= 1 then
		local index = combatSelection.index
		hand[index].ty = 108
		hand[index].large = true
		hand[index]:tick()
	end
	if combatSelection.type == 'usecard' then
		local cardItem = hand[combatSelection.handIndex]
		local card = cardItem.card
		if card.playerTarget then
			drawSelectionBox(player.x,player.y,8*player.width,8*player.height)
		end
		if card.enemyTarget then
			if card.toAllEnemy then
				for i = 1,#enemies do
					local enemy = enemies[i]
					drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
				end
			else
				local enemy = enemies[combatSelection.index]
				drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
				drawBezier(20,cardItem.x,cardItem.y-10,math.min(cardItem.x-5,enemy.x-20),enemy.y+enemy.height*4-5,enemy.x+enemy.width*4-4,enemy.y+enemy.height*4)
				spr(74,enemy.x+enemy.width*4-8,enemy.y+enemy.height*4-4,0)
			end
		end
	end
end

function combatControls()
	if cursorOnTopBar then
		if combatSelection.type ~= 'topbar' then
			combatSelection.oldType = combatSelection.type
			combatSelection.type = 'topbar'
		end
		return
	elseif combatSelection.type == 'topbar' then
		combatSelection.type = combatSelection.oldType or 'hand'
		combatSelection.oldType = nil
	end

	local function cardIsInHand(i) return not hand[i].isNotInHand end
	local function enemyIsAlive(i) return enemies[i].alive end

	if combatSelection.type == 'hand' then
		if combatSelection.index == 0 and #hand > 0 and not inEnemyTurn then
			combatSelection.index = nextOrOtherIndexInTableIf(hand,combatSelection.index,cardIsInHand)
		end
		if btnp(2) then
			combatSelection.index = previousOrOtherIndexInTableIf(hand,combatSelection.index,cardIsInHand)
		elseif btnp(3) then
			combatSelection.index = nextOrOtherIndexInTableIf(hand,combatSelection.index,cardIsInHand)
		elseif btnp(4) and combatSelection.index >= 1 and combatSelection.index <= #hand and hand[combatSelection.index].card:canUse() then
			combatSelection.handIndex = combatSelection.index
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,0,enemyIsAlive)
			local card = hand[combatSelection.handIndex].card
			combatSelection.singleEnemy = card.enemyTarget and not card.toAllEnemy
			if combatSelection.index == 0 and combatSelection.singleEnemy then
				combatSelection.index = combatSelection.handIndex
				combatSelection.handIndex = nil
			else
				combatSelection.type = 'usecard'
				if combatSelection.singleEnemy then
					card:applyPowers(enemies[combatSelection.index])
				end
			end
		elseif btnp(7) then
			combatSelection.index = 0
		end

	elseif combatSelection.type == 'usecard' then
		if combatSelection.index == 0 or not enemyIsAlive(combatSelection.index) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			if combatSelection.index == 0 and combatSelection.singleEnemy then
				combatSelection.type = 'hand'
				combatSelection.index = combatSelection.handIndex
				hand[combatSelection.handIndex].card:applyPowers()
				combatSelection.handIndex = nil
			end
		end
		if btnp(2) then
			combatSelection.index = previousOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			local card = hand[combatSelection.handIndex].card
			if card.enemyTarget and not card.toAllEnemy then
				card:applyPowers(enemies[combatSelection.index])
			end
		elseif btnp(3) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			local card = hand[combatSelection.handIndex].card
			if card.enemyTarget and not card.toAllEnemy then
				card:applyPowers(enemies[combatSelection.index])
			end
		elseif btnp(4) then
			addAction(UseCardAction:new(hand[combatSelection.handIndex],enemies[combatSelection.index]))
			combatSelection.type = 'hand'
			combatSelection.index = nextOrOtherIndexInTableIf(hand,combatSelection.handIndex,cardIsInHand)
			combatSelection.handIndex = nil
		elseif btnp(5) or btnp(7) then
			combatSelection.type = 'hand'
			combatSelection.index = combatSelection.handIndex
			if combatSelection.handIndex <= #hand then
				hand[combatSelection.handIndex].card:applyPowers()
			end
			combatSelection.handIndex = nil
			if btnp(7) then
				combatSelection.index = 0
			end
		end
	end

	if btnp(7) and not inEnemyTurn then
		inEnemyTurn = true
		addAction(EndTurnAction:new())
	end
end

function removeHand(index)
	hand[index].card:resetPower()
	table.remove(hand,index)
	if combatSelection.type == 'hand' and combatSelection.index > index then
		combatSelection.index = combatSelection.index - 1
	elseif combatSelection.type == 'usecard' and combatSelection.handIndex > index then
		combatSelection.handIndex = combatSelection.handIndex - 1
	end
end

function checkCombatEnd()
	local hasAlive = false
	for _, enemy in ipairs(enemies) do
		if enemy.alive then
			hasAlive = true
		end
	end
	if not hasAlive then
		combatEnd()
	end
end

function combatEnd()
	local rewardRandom = makeRand(act,room.id,2)
	local rewards = generateRewards(rewardRandom)
	player:onCombatEnd()
	completeRoom()
	openWindowAbove(RewardWindow:new(rewards))
end