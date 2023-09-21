-- combat
---@diagnostic disable: lowercase-global

-- in combat properties
---@type Random
shuffleRand = nil
---@type Random
miscRand = nil
---@type Random
local rewardRand = nil
---@type Random
aiRand = nil
---@type Random
potionRand = nil
---@type Monster[]
enemies = {}
---@type Card[]
drawPile = {}
---@type Card[]
discardPile = {}
---@type Card[]
exhaustPile = {}
---@type CardItem[]
hand = {}
---@type CardItem[]
limbo = {}
energy = 3
turn = 1
endTurnPressed = false
inEnemyTurn = false
combatType = 'monster'
inCombat = false
combatSpriteBank = 1
goldStolen = 0
local handUI = HandUI:new(hand,true)
local combatSelection = {type='hand',index=1,lastTarget=0,handIndex=nil,singleEnemy=false}
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
	goldStolen = 0
	local innateCards = {}
	for _,card in ipairs(deck) do
		local card = card:copy()
		if card.innate or card.linkedBottle then
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
	inCombat = true
	if room.hasKey then
		applyKeyBuff()
	end
	player:onCombatStart()
	for _, enemy in ipairs(enemies) do
		enemy:onCombatStart()
	end
	energy = maxEnergy
	addAction(NewTurnAction:new{additionalCard=math.max(0,#innateCards-5)})
	combatSelection.type = 'hand'
	combatSelection.index = 0
	combatSelection.lastTarget = 0
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
	player:drawEnergyIndicator()
	drawIcon(icons.DrawPile,0,128)
	printShadowed(tostring(#drawPile),8,129,12)
	if combatSelection.type == 'drawPile' then
		drawSelectionBox(0,127,9+strWidth(tostring(#drawPile)),9,4,2)
	end
	drawIcon(icons.DiscardPile,232,128)
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
	if combatSelection.type == 'player' then
		drawSelectionBox(player.x,player.y,8*player.width,8*player.height)
		player:drawTooltips()
	elseif combatSelection.type == 'orb' then
		local orb = player.orbs[combatSelection.index]
		if orb then
			drawSelectionBox(orb.x-7,orb.y-7,14,14)
			orb:drawTooltips()
		end
	elseif combatSelection.type == 'enemy' then
		local enemy = enemies[combatSelection.index]
		if enemy then
			drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
			enemy:drawTooltips()
		end
	end
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
					if enemy.canInteract then
						drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
					end
				end
			else
				local enemy = enemies[combatSelection.index]
				drawSelectionBox(enemy.x,enemy.y,8*enemy.width,8*enemy.height)
				if enemy.x > player.x then
					drawBezier(20,cardItem.x,cardItem.y-23,math.min(cardItem.x-5,enemy.x-20),enemy.y+enemy.height*4-5,enemy.x+enemy.width*4-4,enemy.y+enemy.height*4)
					spr(74,enemy.x+enemy.width*4-8,enemy.y+enemy.height*4-4,0)
				else
					drawBezier(20,cardItem.x,cardItem.y-23,math.max(cardItem.x+5,enemy.x+enemy.width*8+20),enemy.y+enemy.height*4-5,enemy.x+enemy.width*4+4,enemy.y+enemy.height*4)
					spr(74,enemy.x+enemy.width*4,enemy.y+enemy.height*4-4,0,1,1)
				end
			end
		end
	end
end

function drawLimbo()
	for _, cardItem in ipairs(limbo) do
		cardItem:tick()
	end
end

local function enemyCanInteract(i) return enemies[i].canInteract end

function handUISelect(selection)
	if not hand[selection] or hand[selection].isNotInHand or not hand[selection].card:canUse() or endTurnPressed then
		return
	end

	combatSelection.handIndex = selection
	combatSelection.index = keepCurrentIndexInTableIf(enemies,combatSelection.lastTarget,enemyCanInteract)
	local card = hand[combatSelection.handIndex].card
	combatSelection.singleEnemy = card.enemyTarget and not card.toAllEnemies
	if combatSelection.index == 0 and combatSelection.singleEnemy then
		combatSelection.handIndex = nil
	else
		combatSelection.type = 'usecard'
		handUI.cursorOnSelf = false
		if combatSelection.singleEnemy then
			card:applyPowers(enemies[combatSelection.index])
		elseif card.enemyTarget and card.toAllEnemies then
			card:applyPowers(true)
		end
		pauseControl = true
	end
end

function getHoldCard()
	if combatSelection.type == 'usecard' then
		return hand[combatSelection.handIndex].card
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

	for i=27,36 do
		local n = i==27 and 10 or i-27
		if keyp(i) and #hand >= n then
			if combatSelection.type == 'usecard' and combatSelection.handIndex == n then
				combatSelection.type = 'hand'
				handUI.cursorOnSelf = true
				if combatSelection.handIndex >= 1 and combatSelection.handIndex <= #hand then
					hand[combatSelection.handIndex].card:applyPowers()
				end
				combatSelection.handIndex = nil
			else
				handUISelect(n)
				if combatSelection.handIndex == n then
					handUI.selection = n
				end
			end
			return
		end
	end

	if combatSelection.type == 'hand' then
		-- handled in hand UI
		handUI.cursorOnSelf = true
		handUI.hideSelection = false
		if not handUI.justChangedSelection then
			if handUI.selection <= 1 and btnp(2) then
				combatSelection.type = 'drawPile'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
			elseif handUI.selection == #hand and btnp(3) then
				combatSelection.type = 'discardPile'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
			elseif btnp(0) then
				combatSelection.type = 'player'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
			end
		end

	elseif combatSelection.type == 'usecard' then
		handUI.hideSelection = false
		if combatSelection.handIndex < 1 or combatSelection.handIndex > #hand or not hand[combatSelection.handIndex].card:canUse() or endTurnPressed then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
			if combatSelection.handIndex >= 1 and combatSelection.handIndex <= #hand then
				hand[combatSelection.handIndex].card:applyPowers()
			end
			combatSelection.handIndex = nil
			return
		end
		if combatSelection.singleEnemy and (combatSelection.index == 0 or not enemyCanInteract(combatSelection.index)) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
			if combatSelection.index == 0 then
				combatSelection.type = 'hand'
				handUI.cursorOnSelf = true
				hand[combatSelection.handIndex].card:applyPowers()
				combatSelection.handIndex = nil
				return
			end
		end
		if btnp(2) then
			combatSelection.index = previousOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
			local card = hand[combatSelection.handIndex].card
			if card.enemyTarget and not card.toAllEnemies then
				card:applyPowers(enemies[combatSelection.index])
			end
		elseif btnp(3) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
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
			combatSelection.lastTarget = combatSelection.index
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
			if hasRelic(FrozenEye) then
				table.reverse(cardItems)
			else
				table.sort(cardItems,function (a, b) return a.card.name < b.card.name end)
			end
			local gridView = CardGridSelectWindow:new{title='Your Draw Pile',cardItems=cardItems,min=0,max=0,canClose=true}
			openWindowAbove(gridView)
		elseif btnp(0) then
			combatSelection.type = 'player'
			handUI.cursorOnSelf = false
			handUI.hideSelection = true
		end
	elseif combatSelection.type == 'discardPile' then
		if btnp(2) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(0) then
			if #exhaustPile > 0 then
				combatSelection.type = 'exhaustPile'
			else
				combatSelection.type = 'player'
				handUI.cursorOnSelf = false
				handUI.hideSelection = true
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
		elseif btnp(0) then
			combatSelection.type = 'player'
			handUI.cursorOnSelf = false
			handUI.hideSelection = true
		end
	elseif combatSelection.type == 'player' then
		if btnp(0) then
			if #player.orbs > 0 then
				combatSelection.type = 'orb'
				combatSelection.index = 0
			else
				enterTopbar('relic',nil,player.x+player.width*4)
			end
		elseif btnp(1) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(3) then
			combatSelection.type = 'enemy'
			combatSelection.index = 0
		end
	elseif combatSelection.type == 'enemy' then
		if combatSelection.index == 0 or not enemyCanInteract(combatSelection.index) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
			if combatSelection.index == 0 then
				combatSelection.type = 'player'
				return
			end
		end

		if btnp(0) then
			local enemy = enemies[combatSelection.index]
			if enemy then
				enterTopbar('relic',nil,enemy.x+enemy.width*4)
			end
		elseif btnp(1) then
			combatSelection.type = 'hand'
			handUI.cursorOnSelf = true
		elseif btnp(2) then
			local oldIndex = combatSelection.index
			combatSelection.index = previousOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
			if oldIndex == combatSelection.index then
				combatSelection.type = 'player'
			end
		elseif btnp(3) then
			combatSelection.index = nextOrOtherIndexInTableIf(enemies,combatSelection.index,enemyCanInteract)
		end
	elseif combatSelection.type == 'orb' then
		if combatSelection.index == 0 then
			if #player.orbs > 0 then
				combatSelection.index = 1
			else
				combatSelection.type = 'player'
			end
		end
		if btnp(0) then
			local orb = player.orbs[combatSelection.index]
			if orb then
				enterTopbar('relic',nil,orb.x)
			end
		elseif btnp(1) then
			combatSelection.type = 'player'
		elseif btnp(2) then
			combatSelection.index = limit(combatSelection.index+1,1,#player.orbs)
		elseif btnp(3) then
			combatSelection.index = limit(combatSelection.index-1,1,#player.orbs)
		end
	end

	if btnp(7) and not endTurnPressed then
		endTurnPressed = true
		addAction(EndTurnAction:new())
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
	local cardItem = table.remove(hand,index)
	if cardItem then
		cardItem.glow = nil
	end
	player:triggerEvent('onRemoveHand')
	handApplyPowers()
	if combatSelection.type == 'hand' and combatSelection.index > index then
		combatSelection.index = combatSelection.index - 1
	elseif combatSelection.type == 'usecard' and combatSelection.handIndex > index then
		combatSelection.handIndex = combatSelection.handIndex - 1
	end
end

function insertHand(cardItem)
	table.insert(hand,cardItem)
	cardItem.isNotInHand = false
	handApplyPowers()
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

local function normalCombatEnd(escaped)
	completeRoom()
	if room.noReward then
		addEffect(AnonymousEffect:new{duration=2,callback=function (duration)
			if duration <= 1 then
				act:roomProceed()
			end
		end})
	else
		if escaped then
			openWindowAbove(RewardWindow:new{rewards={},title='Fled...'})
		else
			local rewards = generateRewards(rewardRand)
			openWindowAbove(RewardWindow:new{rewards=rewards})
		end
	end
end

function combatEnd(escaped)
	player:onCombatEnd()
	inCombat = false
	if roomActionType == 'eventCombat' then
		currentEvent:onCombatEnd(escaped)
	else
		saveGame(true,(escaped and 1 or 0) | (goldStolen << 1))
		normalCombatEnd(escaped)
	end
end

function loadCombatEnd(eventMeta)
	local escaped = (eventMeta & 1) == 1
	goldStolen = (eventMeta >> 1) & 0xFF
	normalCombatEnd(escaped)
end

local keyBuffAppliers = {
	function (m) addAction(ApplyPowerAction:new(m,StrengthPower:new(m,act.id+1))) end,
	function (m) addAction(AnonymousAction:new(function ()
		local maxHpIncrease = math.floor(m.maxHp*0.25)
		m:increaseMaxHp(maxHpIncrease)
		addEffect(TextEffect:new{str='Max HP +'..tostring(maxHpIncrease),x=m.x+m.width*4,y=m.y,color=12})
	end)) end,
	function (m) addAction(ApplyPowerAction:new(m,MetallicizePower:new(m,2*(act.id+1)))) end,
	function (m) addAction(ApplyPowerAction:new(m,RegenerateMonsterPower:new(m,2*act.id+1))) end,
}
function applyKeyBuff()
	local roll = aiRand:randInt(1,4)
	for _,monster in ipairs(enemies) do
		keyBuffAppliers[roll](monster)
	end
end

-- enemies

function setupEnemies(encounter)
	combatSpriteBank = encounter.spriteBank
	encounter:setupEnemies(aiRand)
	combatType = encounter.type
end

function getRandomInteractableEnemy()
	local aliveEnemies = {}
	for i, enemy in ipairs(enemies) do
		if enemy.canInteract then
			table.insert(aliveEnemies,table.pack(enemy,i))
		end
	end
	if #aliveEnemies == 0 then
		return nil,0
	end
	return table.unpack(aliveEnemies[miscRand:randInt(#aliveEnemies)])
end
