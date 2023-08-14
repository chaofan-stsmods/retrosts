-- common events
---@diagnostic disable: lowercase-global

local commonEvents

function getCommonEvents()
	return commonEvents
end

GoldenShrine = TextEvent:new{name='Golden Shrine',screen='entry'}
function GoldenShrine:init()
	self.goldAmt = ascension >= 15 and 50 or 100
	self.description = 'Before you lies an elaborate shrine to an ancient spirit.'
	self.options = {
		{description='[Pray] #5#Gain '..self.goldAmt..' Gold.'},
		{description='[Desecrate] #5#Gain 275 Gold. #3#Become Cursed - Regret.'},
		{description='[Leave]'},
	}
end

function GoldenShrine:onOption(selection)
	if self.screen == 'entry' then
		if selection == 1 then
			gold = gold + self.goldAmt
			self.description = 'As your hand touches the shrine, #4#gold#12# rains from the ceiling showering you in riches.'
		elseif selection == 2 then
			gold = gold + 275
			local cardItem = CardItem:new{card=Regret:new(),x=0,y=136,tx=120,ty=68,isNotInHand=true}
			addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
			table.insert(deck,cardItem.card)
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

Transmogrifier = TextEvent:new{name='Transmogrifier',screen='entry'}
function Transmogrifier:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	self.description = 'Before you lies an elaborate shrine to a forgotten spirit.'
	self.options = {
		{description='[Pray] #5#Transform a card.'},
		{description='[Leave]'},
	}
end

function Transmogrifier:onOption(selection)
	if self.screen == 'entry' then
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

UpgradeShrine = TextEvent:new{name='Upgrade Shrine',screen='entry'}
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
	if self.screen == 'entry' then
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

Purifier = TextEvent:new{name='Purifier',screen='entry'}
function Purifier:init()
	self.description = 'Before you lies an elaborate shrine to a forgotten spirit.'
	self.options = {
		{description='[Pray] #5#Remove a card from your deck.'},
		{description='[Leave]'},
	}
end

function Purifier:onOption(selection)
	if self.screen == 'entry' then
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
	name='Wheel of Change',screen='entry',hpLoss=0,goldAmt=100,prize=nil,wheelRotation=0,wheelYOffset=-130,wheelIn=true,
	rolling=false,rolled=false,wheelTargetRotation=0,pauseControl=false
}
local wheelIcons = {448,7,451,6,450,449}
local wheelPrizes = {
	{description='"Uh oh! NL You lose!" NL You spot him readying a shiv...',option='[Prize?] #2#Lose {#} HP.',action='lossHp'},
	{description='"Ohh, the power of #r~darkness...~ NL Choose a card to remove from your deck!"',option='[Prize!] #5#Remove a card from your deck.',action='remove'},
	{description='"Looks like you won a #pCurse! NL That\'s not good. NL Oh well! Better luck next time!"',option='[Prize?] #2#Curse - Decay.',action='curse'},
	{description='"Oooh, a free #gHeal for you!"',option='[Prize!] #5#Heal to full health.',action='heal'},
	{description='""Ah, a #ggift! NL Enjoy!"',option='[Prize!] #5#Obtain a Relic.',action='relic'},
	{description='""You win some #yGOLD! NL YAY!!!!"',option='[Prize!] YAY!!!!',action='gold'},
}
function WheelOfChange:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	self.description = 'You come upon a dapper looking, cheery gremlin. NL "It\'s time to spin the wheel! Are you R E A D Y ? Of course you are!"'
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
			self.wheelTargetRotation = 3.14159265*10+targetPrize*1.04719755
			self.description = wheelPrizes[targetPrize].description:gsub('{#}',tostring(self.hpLoss))
			self.options = {{description=wheelPrizes[targetPrize].option}}
			self.prize = wheelPrizes[targetPrize].action
		elseif not self.rolling and self.rolled then
			self.screen = 'prize'
		end
	end
	self.pauseControl = false
end

function WheelOfChange:rollWheel()
	if self.wheelIn then
		self.wheelYOffset = lerp(self.wheelYOffset,0,0.2)
	else
		self.wheelYOffset = lerp(self.wheelYOffset,-130,0.2)
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
		local x1,y1 = cx+(radius*0.6)*math.sin(rotation+(i-0.5)*step/2),cy-(radius*0.6)*math.cos(rotation+(i-0.5)*step/2)
		spr(wheelIcons[i],x1-8,y1-8,0,2)
	end
end

function WheelOfChange:onOption(selection)
	if self.screen == 'entry' then
		self.screen = 'roll'
		self.options = {}
		self.pauseControl = true
	elseif self.screen == 'roll' then
	elseif self.screen == 'prize' then
		self[self.prize](self)
		self.screen = 'complete'
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
	gold = gold + self.goldAmt
end

function WheelOfChange:relic()
	local rewards = {}
	local tier = getRelicTier(self.random)
	local relic = getRelicTypeByTier(tier):new()
	addRelicReward(rewards,relic)
	completeRoom()
	openWindowAbove(RewardWindow:new{rewards=rewards})
end

function WheelOfChange:curse()
	local cardItem = CardItem:new{card=Decay:new(),x=0,y=136,tx=120,ty=68,isNotInHand=true}
	addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=30,duration=50,tx=240,ty=0})
	table.insert(deck,cardItem.card)
end

function WheelOfChange:remove()
	removeCardFromDeck(1)
end

commonEvents = {
	GoldenShrine,Transmogrifier,UpgradeShrine,Purifier,WheelOfChange
}
