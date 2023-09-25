-- common events
---@diagnostic disable: lowercase-global

local commonEvents

function getCommonEvents()
	return commonEvents
end

GoldenShrine = TextEvent:new{name='Golden Shrine',screen='intro'}
function GoldenShrine:init()
	self.goldAmt = ascension >= 15 and 50 or 100
	self.description = 'Before you lies an elaborate shrine to an ancient spirit.'
	self.options = {
		{description='[Pray] #5#Gain '..self.goldAmt..' Gold.'},
		{description='[Desecrate] #5#Gain 275 Gold. #3#Become Cursed - Regret.',cardItem=CardItem:new{card=Regret:new()}},
		{description='[Leave]'},
	}
end

function GoldenShrine:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			gainGold(self.goldAmt)
			self.description = 'As your hand touches the shrine, #4#gold#12# rains from the ceiling ~showering~ ~you~ ~in~ ~riches.~'
		elseif selection == 2 then
			gainGold(275)
			obtainCardWithEffect(Regret:new())
			self.description = 'Each time you strike the shrine, #4#gold#12# pours forth again and again! NL NL As you pocket the riches, something #2#weighs heavily on you.'
		else
			self.description = 'You ignore the shrine.'
		end
		self.screen = 'leave'
		self.options = {self.options[3]}
		self.selectedOption = 0
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Transmogrifier = TextEvent:new{name='Transmogrifier',screen='intro'}
function Transmogrifier:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	self.description = 'Before you lies an elaborate shrine to a forgotten spirit.'
	self.options = {
		{description='[Pray] #5#Transform a card.'},
		{description='[Leave]'},
	}
end

function Transmogrifier:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			transformCardFromDeck(1,self.random,false,function ()
				self.description = 'As the power of the shrine flows through you, your mind feels altered.'
			end)
		else
			self.description = 'You ignore the shrine.'
		end
		self.screen = 'leave'
		self.options = {self.options[2]}
		self.selectedOption = 0
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

UpgradeShrine = TextEvent:new{name='Upgrade Shrine',screen='intro'}
function UpgradeShrine:init()
	self.description = 'Before you lies an elaborate shrine to a forgotten spirit.'
	self.options = {
		{description='[Pray] #5#Upgrade a card.'},
		{description='[Leave]'},
	}
	if table.allMatch(deck,function(c) return not c:canUpgrade() end) then
		self.options[1] = {description='[Locked] Requires: Upgradeable Cards',locked=true}
	end
end

function UpgradeShrine:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			upgradeCardFromDeck(1,false,function ()
				self.description = 'The shrine\'s energy flows into you, making you stronger.'
			end)
		else
			self.description = 'You ignore the shrine.'
		end
		self.screen = 'leave'
		self.options = {self.options[2]}
		self.selectedOption = 0
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Purifier = TextEvent:new{name='Purifier',screen='intro'}
function Purifier:init()
	self.description = 'Before you lies an elaborate shrine to a forgotten spirit.'
	self.options = {
		{description='[Pray] #5#Remove a card from your deck.'},
		{description='[Leave]'},
	}
end

function Purifier:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			removeCardFromDeck(1,false,function ()
				self.description = 'As you kneel in reverence, you feel a weight lifted off your shoulders.'
			end)
		else
			self.description = 'You ignore the shrine.'
		end
		self.screen = 'leave'
		self.options = {self.options[2]}
		self.selectedOption = 0
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

WheelOfChange = TextEvent:new{
	name='Wheel of Change',screen='intro',hpLoss=0,goldAmt=100,prize=nil,wheelRotation=0,wheelYOffset=-130,wheelIn=true,
	rolling=false,rolled=false,wheelTargetRotation=0,pauseControl=false
}
local wheelIcons = {448,7,451,6,450,449}
local wheelPrizes = {
	{description='"Uh oh! NL You lose!" NL You spot him readying a shiv...',option='[Prize?] #3#Lose {#} HP.',action='lossHp'},
	{description='"Ohh, the power of ~#2#darkness...~#12# NL Choose a card to remove from your deck!"',option='[Prize!] #5#Remove a card from your deck.',action='remove'},
	{description='"Looks like you won a #8#Curse!#12# NL That\'s not good. NL Oh well! Better luck next time!"',option='[Prize?] #3#Curse - Decay.',action='curse'},
	{description='"Oooh, a free #5#Heal#12# for you!"',option='[Prize!] #5#Heal to full health.',action='heal'},
	{description='""Ah, a #5#gift!#12# NL Enjoy!"',option='[Prize!] #5#Obtain a Relic.',action='relic'},
	{description='""You win some #4#GOLD!#12# NL YAY!!!!"',option='[Prize!] YAY!!!!',action='gold'},
}
function WheelOfChange:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	self.description = 'You come upon a dapper looking, cheery gremlin. NL "It\'s time to spin the wheel! Are you ~R~ ~E~ ~A~ ~D~ ~Y~ ~?~ Of course you are!"'
	self.options = {
		{description='[Play]'},
	}
	self.hpLoss = ascension >= 15 and math.floor(player.maxHp * 0.15) or math.floor(player.maxHp * 0.1)
	self.goldAmt = act.id * 100
end

function WheelOfChange:drawBackground(below)
	if self.screen ~= 'roll' then
		TextEvent.drawBackground(self,below)
		return
	end
	if below then
		cls(15)
	else
		cls(13)
	end
	self:drawWheel()
end

function WheelOfChange:drawOptions()
	if self.screen ~= 'roll' then
		TextEvent.drawOptions(self)
	end
end

function WheelOfChange:tick()
	TextEvent.tick(self)
	if self.screen ~= 'roll' then
		return
	end

	self:rollWheel()
	if cursorOnTopBar then
		return
	end

	if not self.pauseControl and (btnp(7) or btnp(4)) then
		if not self.rolling and not self.rolled then
			self.rolling = true
			local targetPrize = self.random:randInt(1,6)
			self.wheelTargetRotation = math.pi*10+targetPrize*1.04719755
			self.description = wheelPrizes[targetPrize].description
			self.options = {{description=wheelPrizes[targetPrize].option:gsub('{#}',tostring(self.hpLoss))}}
			self.prize = wheelPrizes[targetPrize].action
			if self.prize == 'curse' then
				self.options[1].cardItem = CardItem:new{card=Decay:new()}
			end
		elseif not self.rolling and self.rolled then
			self.wheelIn = false
		end
	end
	self.pauseControl = false
end

function WheelOfChange:rollWheel()
	if self.wheelIn then
		self.wheelYOffset = lerp(self.wheelYOffset,0,0.2)
	else
		self.wheelYOffset = lerp(self.wheelYOffset,-130,0.2)
		if self.wheelYOffset < -120 then
			self.screen = 'prize'
		end
	end
	local diff = lerp(self.wheelRotation,self.wheelTargetRotation,0.02,0.01)-self.wheelRotation
	if self.rolling then
		local distance = math.abs(self.wheelRotation-self.wheelTargetRotation)
		if distance < 0.02 then
			self.rolling = false
			self.rolled = true
		end
		self.wheelRotation = self.wheelRotation + limit(diff,0.01,0.5)
	end
end

function WheelOfChange:drawWheel()
	local rotation = self.wheelRotation
	local diffRadius = 3
	local radius = 50
	local cx,cy = 120+diffRadius*math.sin(rotation),72-diffRadius*math.cos(rotation)+self.wheelYOffset
	circ(cx,cy,radius+2,14)
	circ(cx,cy,radius,3)
	circ(cx,cy,radius-1,4)
	circ(cx,cy,radius-4,12)
	circ(cx,cy,radius-5,14)
	spr(428,120+radius,72-16,0,2,0,0,2,2)
	local step = 2.09439510
	local width = 0.02
	for i=0,2 do
		local x1,y1 = cx+(radius-1)*math.sin(rotation-width+i*step),cy-(radius-1)*math.cos(rotation-width+i*step)
		local x2,y2 = cx+(radius-1)*math.sin(rotation+width+i*step),cy-(radius-1)*math.cos(rotation+width+i*step)
		local x3,y3 = cx-(radius-1)*math.sin(rotation-width+i*step),cy+(radius-1)*math.cos(rotation-width+i*step)
		local x4,y4 = cx-(radius-1)*math.sin(rotation+width+i*step),cy+(radius-1)*math.cos(rotation+width+i*step)
		tri(x1,y1,x2,y2,x3,y3,4)
		tri(x1,y1,x4,y4,x3,y3,4)
	end
	for i=1,6 do
		local r = rotation+(i-0.5)*step/2
		local x1,y1 = cx+(radius*0.6)*math.sin(r),cy-(radius*0.6)*math.cos(r)
		if ttri then
			local d1,d2,d3,d4=math.sin(r-math.pi/4),-math.cos(r-math.pi/4),math.sin(r+math.pi/4),-math.cos(r+math.pi/4)
			local d = 1.414*8
			d1,d2,d3,d4 = d1*d,d2*d,d3*d,d4*d
			local icon = wheelIcons[i]
			local u,v = 8*(icon%16),8*math.floor(icon/16)
			ttri(x1+d1,y1+d2,x1+d3,y1+d4,x1-d1,y1-d2,u,v,u+8,v,u+8,v+8,0,0,1,1,1)
			ttri(x1+d1,y1+d2,x1-d3,y1-d4,x1-d1,y1-d2,u,v,u,v+8,u+8,v+8,0,0,1,1,1)
		else
			spr(wheelIcons[i],x1-8,y1-8,0,2)
		end
	end
end

function WheelOfChange:onOption(selection)
	if self.screen == 'intro' then
		self.screen = 'roll'
		self.options = {}
		self.pauseControl = true
	elseif self.screen == 'roll' then
	elseif self.screen == 'prize' then
		self[self.prize](self)
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function WheelOfChange:lossHp()
	self.description = 'You slash at the crazy gremlin but he\'s simply too quick! NL He gets you a few times with a crude shiv. NL '..
		'"The price has been paid!!" NL and with that, both the gremlin and its wheel disappear in a puff of smoke.'
	player:damage(player,self.hpLoss,'hpLoss')
end

function WheelOfChange:heal()
	player:heal(player.maxHp)
end

function WheelOfChange:gold()
	gainGold(self.goldAmt)
end

function WheelOfChange:relic()
	local rewards = {}
	local relic = getRandomNonBottleRelic(self.random)
	addRelicReward(rewards,relic)
	completeRoom()
	openWindowAbove(RewardWindow:new{rewards=rewards})
end

function WheelOfChange:curse()
	obtainCardWithEffect(Decay:new())
end

function WheelOfChange:remove()
	removeCardFromDeck(1)
end

MatchAndKeep = TextEvent:new{
	name='Match and Keep!',screen='intro',cardItems=nil,pauseControl=false,cursorCard=0,flippedCard=0,flippedCard2=0,resetTimer=0,attempts=5,
}
function MatchAndKeep:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	self.description = 'A gremlin is madly shuffling cards on a table. This monster seems to be a harmless one. You approach him out of curiosity.'
	self.options = {{description='[Continue]'}}
	self.cardItems = self:initCards()
end

function MatchAndKeep:initCards()
	local cards = {}
	local random = self.random
	local card = getPlayerCardType(random,'common'):new()
	cards[1],cards[2] = card,card
	card = getPlayerCardType(random,'uncommon'):new()
	cards[3],cards[4] = card,card
	card = getPlayerCardType(random,'rare'):new()
	cards[5],cards[6] = card,card
	if ascension >= 15 then
		card = getCurseCardType(random):new()
		cards[7],cards[8] = card,card
	else
		card = getColorlessCardType(random,'uncommon'):new()
		cards[7],cards[8] = card,card
	end
	card = getCurseCardType(random):new()
	cards[9],cards[10] = card,card
	card = player:getMatchAndKeepCardType():new()
	cards[11],cards[12] = card,card
	random:shuffle(cards)

	return table.map(cards,function (v,i)
		local x = (i-1)%4
		local y = math.floor((i-1)/4)
		player:triggerEvent('onPreviewObtainCard',v)
		return CardItem:new{card=v,x=120,y=-20,isNotInHand=true,tx=120-60+40*x,ty=35+40*y,flipped=true}
	end)
end

function MatchAndKeep:drawBackground(below)
	if self.screen ~= 'play' then
		TextEvent.drawBackground(self,below)
		return
	end
	if below then
		cls(15)
	else
		cls(13)
	end
	printGlowed('Remaining',2,20,12,15,1,true)
	printGlowed('Attempts:',2,28,12,15,1,true)
	printGlowed(tostring(self.attempts),2,36,12,15,1,true)
	for i,cardItem in ipairs(self.cardItems) do
		if not cardItem.picked then
			cardItem.flipped = i ~= self.flippedCard and i ~= self.flippedCard2
			if i ~= self.cursorCard or self.attempts == 0 then
				cardItem.large = false
				cardItem:tick()
			end
		end
	end
	if self.attempts > 0 and self.cursorCard > 0 and self.cursorCard <= #self.cardItems then
		local cardItem = self.cardItems[self.cursorCard]
		if not cardItem.picked then
			cardItem.large = true
			cardItem:tick()
		end
	end
end

function MatchAndKeep:drawOptions()
	if self.screen ~= 'play' then
		TextEvent.drawOptions(self)
	end
end

function MatchAndKeep:tick()
	TextEvent.tick(self)
	if self.screen ~= 'play' then
		return
	end

	if self.resetTimer > 0 then
		self.resetTimer = self.resetTimer - 1
		if self.resetTimer == 0 then
			self.flippedCard = 0
			self.flippedCard2 = 0
			if self.attempts == 0 then
				self.screen = 'leave'
				self.description = 'You complete the gremlin\'s game and look up. NL He disappeared?'
				self.options = {{description='[Leave]'}}
				self.pauseControl = true
			end
		elseif self.resetTimer == 20 and self.attempts == 0 then
			for _,cardItem in ipairs(self.cardItems) do
				cardItem.tx,cardItem.ty = 120,-20
			end
		end
	end

	if cursorOnTopBar then
		return
	end

	local function cardExist(i) return not self.cardItems[i].picked end
	if self.cursorCard == 0 or not cardExist(self.cursorCard) then
		self.cursorCard = nextOrOtherIndexInTableIf(self.cardItems,self.cursorCard,cardExist)
	end

	if self.pauseControl then
		self.pauseControl = false
		return
	end

	if btnp(0) then
		self.cursorCard = previousOrOtherIndexInTableIf(self.cardItems,self.cursorCard-3,cardExist)
	elseif btnp(1) then
		self.cursorCard = nextOrOtherIndexInTableIf(self.cardItems,self.cursorCard+3,cardExist)
	elseif btnp(2) then
		self.cursorCard = previousOrOtherIndexInTableIf(self.cardItems,self.cursorCard,cardExist)
	elseif btnp(3) then
		self.cursorCard = nextOrOtherIndexInTableIf(self.cardItems,self.cursorCard,cardExist)
	elseif btnp(4) then
		if self.flippedCard == 0 then
			self.flippedCard = self.cursorCard
		elseif self.flippedCard2 == 0 and self.flippedCard ~= self.cursorCard then
			self.flippedCard2 = self.cursorCard
			self.attempts = self.attempts - 1
			if getmetatable(self.cardItems[self.flippedCard].card) == getmetatable(self.cardItems[self.flippedCard2].card) then
				local cardItem1 = self.cardItems[self.flippedCard]
				local cardItem2 = self.cardItems[self.flippedCard2]
				cardItem1.tx,cardItem1.ty,cardItem1.large = 120,68,false
				cardItem2.tx,cardItem2.ty,cardItem2.large = 120,68,false
				addEffect(CardEffect:new{cardItem=cardItem1,pauseDuration=30,duration=50,tx=240,ty=0})
				addEffect(CardEffect:new{cardItem=cardItem2,pauseDuration=30,duration=50,tx=240,ty=0})
				obtainCard(cardItem1.card)
				self.cardItems[self.flippedCard] = {picked=true}
				self.cardItems[self.flippedCard2] = {picked=true}
				self.flippedCard = 0
				self.flippedCard2 = 0
			else
				self.resetTimer = 40
			end
			if self.attempts == 0 then
				self.resetTimer = 60
			end
		end
	end
end

function MatchAndKeep:onOption()
	if self.screen == 'intro' then
		self.screen = 'near'
		self.description = '"#10#Twelve#12# cards! Match them to keep them! #10#Five#12# tries, no do-overs. NL Are you ready? Let\'s start!"'
		self.options = {{description='[Play]'}}
	elseif self.screen == 'near' then
		self.screen = 'play'
		self.options = {}
		self.pauseControl = true
	elseif self.screen == 'leave' then
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

commonEvents = {
	GoldenShrine,Transmogrifier,UpgradeShrine,Purifier,WheelOfChange,MatchAndKeep
}
