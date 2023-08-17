-- combat
---@diagnostic disable: lowercase-global

-- in combat properties
shuffleRand = nil
miscRand = nil
local rewardRand = nil
aiRand = nil
potionRand = nil
enemies = {}
drawPile = {}
discardPile = {}
exhaustPile = {}
hand = {}
limbo = {}
energy = 3
turn = 1
inEnemyTurn = false
combatSpriteBank = 1
local handUI = HandUI:new(hand)
local combatSelection = {type='hand',index=1}
local pauseControl = false

function startCombat(encounter,completed)
	shuffleRand = makeRand(act.id,room.id,2)
	miscRand = makeRand(act.id,room.id,3)
	rewardRand = makeRand(act.id,room.id,4)
	aiRand = makeRand(act.id,room.id,5)
	potionRand = makeRand(act.id,room.id,6)
	setupEnemies(encounter)
	closeChildWindows()
	resetActions()
	if completed then
		for _, enemy in ipairs(enemies) do
			enemy.visible = false
		end
		return
	end
	drawPile = {}
	discardPile = {}
	exhaustPile = {}
	hand = {}
	handUI.cardItems = hand
	handUI.onSelect = handUISelect
	limbo = {}
	turn = 0
	inEnemyTurn = false
	local innateCards = {}
	for _,card in ipairs(deck) do
		local card = card:copy()
		if card.innate then
			table.insert(innateCards,card)
		else
			table.insert(drawPile,card)
		end
	end
	shuffleRand:shuffle(drawPile)
	shuffleRand:shuffle(innateCards)
	for _,card in ipairs(innateCards) do
		table.insert(drawPile,card)
	end
	player:onCombatStart()
	for _, enemy in ipairs(enemies) do
		enemy:onCombatStart()
	end
	addAction(NewTurnAction:new{additionalCard=math.max(0,#innateCards-5)})
	combatSelection.type = 'hand'
	combatSelection.index = 0
end

function combat()
	act:drawBackground()
	if roomActionType == 'eventCombat' then
		currentEvent:drawForeground()
	end
	player:tick()
	for i=1,#enemies do
		enemies[i]:tick()
	end
	tickEffects()
	handUI:tick()
	drawOverlay()
	tickActions()
	combatControls()
	tickTopBar(true)
end

function drawOverlay()
	map(0,2,3,3,4,96,8)
	local energyText = energy .. '/' .. maxEnergy
	local width = strWidth(energyText)
	printShadowed(energyText,16-width/2,105,12)
	spr(38,0,128,0)
	printShadowed(tostring(#drawPile),8,129,12)
	if combatSelection.type == 'drawPile' then
		drawSelectionBox(0,127,9+strWidth(tostring(#drawPile)),9,4,2)
	end
	mapColor(2,15)
	mapColor(3,9)
	mapColor(4,10)
	spr(38,232,128,0,1,1)
	resetColors{2,3,4}
	width = strWidth(tostring(#discardPile))
	printShadowed(tostring(#discardPile),232-width,129,12)
	if combatSelection.type == 'discardPile' then
		drawSelectionBox(230-width,127,width+10,9,4,2)
	end
	if #exhaustPile > 0 then
		spr(40,232,120,0)
		width = strWidth(tostring(#exhaustPile))
		printShadowed(tostring(#exhaustPile),232-width,121,12)
		if combatSelection.type == 'exhaustPile' then
			drawSelectionBox(230-width,119,width+10,9,4,2)
		end
	end
	drawHand()
	drawLimbo()
end

function drawHand()
	-- handled in hand UI
	if combatSelection.type == 'usecard' then
		local cardItem = hand[combatSelection.handIndex]
		local card = cardItem.card
		if card.playerTarget then
			drawSelectionBox(player.x,player.y,8*player.width,8*player.height)
		end
		if card.enemyTarget then
			if card.toAllEnemies then
				for i = 1,#enemies do
					local enemy = enemies[i]
					if enemy.alive then
						drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
					end
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

function drawLimbo()
	for _, cardItem in ipairs(limbo) do
		cardItem:tick()
	end
end

local function enemyIsAlive(i) return enemies[i].alive end

function handUISelect(selection)
	if not hand[selection].card:canUse() then
		return
	end

	combatSelection.handIndex = selection
	combatSelection.index = nextOrOtherIndexInTableIf(enemies,0,enemyIsAlive)
	local card = hand[combatSelection.handIndex].card
	combatSelection.singleEnemy = card.enemyTarget and not card.toAllEnemies
	if combatSelection.index == 0 and combatSelection.singleEnemy then
		combatSelection.handIndex = nil
	else
		combatSelection.type = 'usecard'
		handUI.cursorOnSelf = false
		if combatSelection.singleEnemy then
			card:applyPowers(enemies[combatSelection.index])
		end
		pauseControl = true
	end
end

function combatControls()
	if cursorOnTopBar then
		if combatSelection.type ~= 'topbar' then
			combatSelection.oldType = combatSelection.type
			combatSelection.type = 'topbar'
			handUI.cursorOnSelf = false
			handUI.hideSelection = true
		end
		return
	elseif combatSelection.type == 'topbar' then
		combatSelection.type = combatSelection.oldType or 'hand'
		combatSelection.oldType = nil
	end

	if pauseControl then
		pauseControl = false
		return
	end

	if combatSelection.type == 'hand' then
		-- handled in hand UI
		handUI.cursorOnSelf = true
		handUI.hideSelection = false
		if not handUI.justChangedSelection then
			if handUI.selection == 1 and btnp(2) then
				combatSelection.type = 'drawPile'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
			elseif handUI.selection == #hand and btnp(3) then
				combatSelection.type = 'discardPile'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
			end
		end

	elseif combatSelection.type == 'usecard' then
		if combatSelection.handIndex < 1 or combatSelection.handIndex > #hand or not hand[combatSelection.handIndex].card:canUse() then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
			if combatSelection.handIndex < 1 or combatSelection.handIndex > #hand then
				hand[combatSelection.handIndex].card:applyPowers()
			end
			combatSelection.handIndex = nil
			return
		end
		if combatSelection.index == 0 or not enemyIsAlive(combatSelection.index) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			if combatSelection.index == 0 and combatSelection.singleEnemy then
				combatSelection.type = 'hand'
				handUI.cursorOnSelf = true
				hand[combatSelection.handIndex].card:applyPowers()
				combatSelection.handIndex = nil
				return
			end
		end
		if btnp(2) then
			combatSelection.index = previousOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			local card = hand[combatSelection.handIndex].card
			if card.enemyTarget and not card.toAllEnemies then
				card:applyPowers(enemies[combatSelection.index])
			end
		elseif btnp(3) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyIsAlive)
			local card = hand[combatSelection.handIndex].card
			if card.enemyTarget and not card.toAllEnemies then
				card:applyPowers(enemies[combatSelection.index])
			end
		elseif btnp(4) then
			local cardItem = hand[combatSelection.handIndex]
			cardItem.ty = cardItem.ty - 16
			addAction(UseCardAction:new{cardItem=cardItem,target=enemies[combatSelection.index],secondary=true,fromHand=true})
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
			combatSelection.handIndex = nil
		elseif btnp(5) or btnp(7) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
			if combatSelection.handIndex <= #hand then
				hand[combatSelection.handIndex].card:applyPowers()
			end
			combatSelection.handIndex = nil
		end
	elseif combatSelection.type == 'drawPile' then
		if btnp(3) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(4) then
			local cardItems = table.map(drawPile, function (card) return CardItem:new{card=card,x=0,y=136,isNotInHand=true} end)
			table.sort(cardItems,function (a, b) return a.card.name < b.card.name end)
			local gridView = CardGridSelectWindow:new{title='Your Draw Pile',cardItems=cardItems,min=0,max=0,canClose=true}
			openWindowAbove(gridView)
		end
	elseif combatSelection.type == 'discardPile' then
		if btnp(2) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(0) then
			if #exhaustPile > 0 then
				combatSelection.type = 'exhaustPile'
			end
		elseif btnp(4) then
			local cardItems = table.map(discardPile, function (card) return CardItem:new{card=card,x=240,y=136,isNotInHand=true} end)
			local gridView = CardGridSelectWindow:new{title='Your Discard Pile',cardItems=cardItems,min=0,max=0,canClose=true}
			openWindowAbove(gridView)
		end
	elseif combatSelection.type == 'exhaustPile' then
		if btnp(2) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(1) then
			combatSelection.type = 'discardPile'
		elseif btnp(4) then
			local cardItems = table.map(exhaustPile, function (card) return CardItem:new{card=card,x=240,y=128,isNotInHand=true} end)
			local gridView = CardGridSelectWindow:new{title='Exhasted Cards',cardItems=cardItems,min=0,max=0,canClose=true}
			openWindowAbove(gridView)
		end
	end

	if btnp(7) and not inEnemyTurn then
		inEnemyTurn = true
		addAction(EndTurnAction:new{secondary=true})
	end
end

function handApplyPowers()
	for _, cardItem in ipairs(hand) do
		cardItem.card:applyPowers()
	end
	if combatSelection.type == 'usecard' and combatSelection.handIndex > 0 and combatSelection.handIndex <= #hand and
		combatSelection.index > 0 and combatSelection.index <= #enemies then
		local card = hand[combatSelection.handIndex].card
		if card.enemyTarget and not card.toAllEnemies then
			card:applyPowers(enemies[combatSelection.index])
		end
	end
end

function removeHand(index)
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
		secondaryActions = {}
		addAction(EndCombatAction:new())
	end
end

local function combatEndImplement()
	completeRoom()
	local rewards = generateRewards(rewardRand)
	openWindowAbove(RewardWindow:new{rewards=rewards})
end

function combatEnd()
	player:onCombatEnd()
	if roomActionType == 'eventCombat' then
		currentEvent:onCombatEnd()
	else
		saveGame(true)
		combatEndImplement()
	end
end

function loadCombatEnd()
	combatEndImplement()
end

-- enemies

function setupEnemies(encounter)
	combatSpriteBank = encounter.spriteBank
	encounter:setupEnemies(aiRand)
end

function getRandomAliveEnemy()
	local aliveEnemies = {}
	for i, enemy in ipairs(enemies) do
		if enemy.alive then
			table.insert(aliveEnemies,table.pack(enemy,i))
		end
	end
	if #aliveEnemies == 0 then
		return nil,0
	end
	return table.unpack(aliveEnemies[miscRand:randInt(#aliveEnemies)])
end
