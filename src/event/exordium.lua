-- exordium events
---@diagnostic disable: lowercase-global

BigFish = TextEvent:new{name='Big Fish',screen='intro',healAmt=0}
function BigFish:init()
	self.random = makeRand(act.id,room.id,1)
	self.healAmt = math.floor(player.maxHp / 3)
	self.description = 'As you make your way down a long corridor you see a #4#banana,#12# a #4#donut,#12# and a #4#box#12# ~floating~ about. No... upon closer inspection they are tied to strings coming from holes in the ceiling. There is a quiet @cackling@ from above as you approach the objects. NL What do you do?'
	self.options = {
		{description='[Banana] #5#Heal '..self.healAmt..' HP.'},
		{description='[Donut] #5#Max HP +5.'},
		{description='[Box] #5#Obtain a Relic. #3#Become Cursed - Regret.',cardItem=CardItem:new{card=Regret:new()}},
	}
end

function BigFish:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:heal(self.healAmt)
			self.description = 'You eat the #4#banana.#12# It is nutritious and slightly #10#magical#12#, healing you.'
		elseif selection == 2 then
			player:increaseMaxHp(5)
			self.description = 'You eat the #4#donut.#12# It really hits the spot! Your Max HP increases.'
		else
			local relic = getRandomNonBottleRelic(self.random)
			obtainRelic(relic)

			obtainCardWithEffect(Regret:new())
			self.description = 'You grab the box. Inside you find a #4#relic!#12#'..
				' NL However, you really craved the donut... NL You are filled with ~sadness,~ but mostly #2#regret.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheCleric = TextEvent:new{name='The Cleric',screen='intro',healAmt=0,removeCost=50}
function TheCleric:init()
	self.random = makeRand(act.id,room.id,1)
	self.healAmt = math.floor(player.maxHp * 0.25)
	self.removeCost = ascension >= 15 and 75 or 50
	self.description = 'A strange blue humanoid with a golden helm(?) approaches you with a huge smile. NL @\"Hello@ @friend!@ I am #10#Cleric!#12# Are you interested in my services?!\" the creature shouts, loudly.'
	self.options = {
		{description='[Heal] #4#35 Gold: #5#Heal '..self.healAmt..' HP.'},
		{description='[Purify] #4#'..self.removeCost..' Gold: #5#Remove a card from your deck.'},
		{description='[Leave]'},
	}
	if gold < 35 then
		self.options[1] = {description='[Locked] Requires: 35 Gold.',locked=true}
	end
	if gold < self.removeCost then
		self.options[2] = {description='[Locked] Requires: '..self.removeCost..' Gold.',locked=true}
	end
end

function TheCleric:isAvailable()
	return gold >= 35
end

function TheCleric:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			loseGold(35)
			player:heal(self.healAmt)
			self.description = 'A warm golden light envelops your body and dissipates. NL The creature grins. \"Cleric best healer. @Have@ @a@ @good@ @day!\"@'
		elseif selection == 2 then
			loseGold(self.removeCost)
			removeCardFromDeck(1,false,function ()
				self.description = 'A cold blue flame envelops your body and dissipates. NL The creature grins. \"Cleric talented. @Have@ @a@ @good@ @day!\"@'
			end)
		else
			self.description = 'You don\'t trust this #10#"Cleric",#12# so you leave.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

WingStatue = TextEvent:new{name='Wing Statue',screen='intro',hpLoss=7}
function WingStatue:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'Among the stone and boulders, you notice an intricate large blue statue resembling a wing. NL You find #4#gold#12# spilling from its cracks. Maybe there is more inside...'
	self.options = {
		{description='[Pray] #5#Remove a card from your deck. #3#Lose '..self.hpLoss..' HP.'},
		{description='[Destroy] #5#Gain 50 - 80 Gold.'},
		{description='[Leave]'},
	}
	if table.allMatch(deck,function (card) return card.type ~= 'attack' or card.baseDamage < 10 end) then
		self.options[2] = {description='[Locked] Requires: Card with 10 or more damage.',locked=true}
	end
end

function WingStatue:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:damage(player,self.hpLoss)
			self.screen = 'purge'
			self.options = {{description='[Continue]'}}
			self.description = 'Someone once told you of a cult that worshipped a giant bird. As you kneel in prayer, you begin to ~feel~ ... ~lightheaded~ . NL NL You wake up some time later, feeling strangely fleet of foot.'
			return
		elseif selection == 2 then
			gainGold(self.random:randInt(50,80))
			self.description = 'With all your might, you hack away at the statue. NL It soon @crumbles,@ revealing a #4#pile of gold#12#. You grab as much as you can and continue onwards.'
		else
			self.description = 'The statue makes you feel ~uneasy.~ You walk past and continue onward.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	elseif self.screen == 'purge' then
		removeCardFromDeck(1)
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

WorldOfGoop = TextEvent:new{name='World of Goop',screen='intro',hpLoss=11,goldLoss=11,goldGain=75}
function WorldOfGoop:init()
	self.random = makeRand(act.id,room.id,1)
	self.goldLoss = math.min(gold,ascension >= 15 and self.random:randInt(35,75) or self.random:randInt(20,50))
	self.description = 'You fall into a puddle. @IT\'S@ @MADE@ @OF@ @#5#SLIME@ @GOOP!!#12#@ NL Frantically, you claw yourself out over several minutes as you feel the goop starting to burn. NL You can feel goop in your ears, goop in your nose, goop everywhere. NL Climbing out, you notice that some of your #4#gold#12# is missing. Looking back to the puddle you see your missing coins combined with #4#gold#12# from unfortunate adventurers mixed together in the puddle.'
	self.options = {
		{description='[Gather Gold] #5#Gain '..self.goldGain..' Gold. #3#Loss '..self.hpLoss..' HP.'},
		{description='[Leave It] #3#Lose '..self.goldLoss..' Gold.'},
	}
end

function WorldOfGoop:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:damage(player,self.hpLoss)
			gainGold(self.goldGain)
			self.description = 'Feeling the sting of the goop as the prolonged exposure starts to melt away at your skin, you manage to fish out the #4#gold.'
		elseif selection == 2 then
			loseGold(self.goldLoss)
			self.description = 'You decide that mess is not worth it.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheSsssserpent = TextEvent:new{name='The Ssssserpent',screen='intro',goldReward=175}
function TheSsssserpent:init()
	self.goldReward = ascension >= 15 and 150 or 175
	self.description = 'You walk into a room to find a large hole in the ground. As you approach the hole, an enormous serpent creature appears from within. NL NL ~\"Ho~ ~hooo!~ ~Hello~ ~hello!~ ~what~ ~have~ ~we~ ~got~ ~here?~ Hello adventurer, I ask a simple question. NL The most fulfilling of lives is that in which you can ~#4#buy~ ~anything!#12#~ NL Do you agree?\"'
	self.options = {
		{description='[Agree] #5#Gain '..self.goldReward..' Gold. #3#Become Cursed - Doubt.',cardItem=CardItem:new{card=Doubt:new()}},
		{description='[Disagree]'},
	}
end

function TheSsssserpent:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			self.description = '~\"Yeeeeeeessssssssssessss!~ NL ~Thisss~ ~will~ ~all~ ~be~ ~worthhh~ ~it.~ NL ~..ssSSs.....~ ~ss...~ ~sssss....!\"~'
			self.screen = 'agree'
			self.options = {{description='[Continue]'}}
		elseif selection == 2 then
			self.description = 'The serpent stares at you with a look of extreme disappointment.'
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		end
	elseif self.screen == 'agree' then
		gainGold(self.goldReward)

		obtainCardWithEffect(Doubt:new())

		self.description = 'The serpent rears its head and blasts a stream of #4#gold#12# upwards! NL It is amazing and terrifying simultaneously. NL You gather all the #4#gold#12#, thank the snake, and get going.'
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

LivingWall = TextEvent:new{name='Living Wall',screen='intro'}
function LivingWall:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'As you come to a dead-end and begin to turn around, walls @slam@ @down@ from the ceiling, trapping you! NL NL Three faces materialize from the walls and speak. NL #10#\"Forget what you know, and I\'ll let you go.\" NL #8#\"I require change to see a new space.\" NL #4#\"If you want to pass me, then you must grow.\"'
	self.options = {
		{description='[Forget] #5#Remove a card from your deck.'},
		{description='[Change] #5#Transform a card from your deck.'},
		{description='[Grow] #5#Upgrade a card from your deck.'},
	}
	if table.allMatch(deck,function(c) return not c:canUpgrade() end) then
		self.options[3] = {description='[Locked] Requires: Upgradeable Cards',locked=true}
	end
end

function LivingWall:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			removeCardFromDeck(1,false,function ()
				self:completeOption()
			end)
		elseif selection == 2 then
			transformCardFromDeck(1,self.random,false,function ()
				self:completeOption()
			end)
		elseif selection == 3 then
			upgradeCardFromDeck(1,false,function ()
				self:completeOption()
			end)
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function LivingWall:completeOption()
	self.screen = 'leave'
	self.description = 'Satisfied, the walls in front of you merge back into the ceiling, leaving a path forward.'
	self.options = {{description='[Leave]'}}
end

ScrapOoze = TextEvent:new{name='Scrap Ooze',screen='intro',hpLoss=3,chance=25}
function ScrapOoze:init()
	self.random = makeRand(act.id,room.id,1)
	self.hpLoss = ascension >= 15 and 5 or 3
	self.description = 'As you walk into the room you hear a ~gurgling~ and the @grinding@ of metals. Before you is a slime-like creature that ate too much scrap for its own good. From the center of the creature you see glints of strange light, perhaps something magical? It looks like you can get some #4#treasure#12# if you just reach inside its... opening. However, the acid and sharp objects may #2#hurt.'
	self.options = {
		{description='[Reach Inside] #3#Lose '..self.hpLoss..' HP. #5#'..self.chance..'%: Find a Relic.'},
		{description='[Leave]'},
	}
end

function ScrapOoze:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:damage(player,self.hpLoss)
			if self.random:randInt(0,99) < self.chance then
				local relic = getRandomNonBottleRelic(self.random)
				obtainRelic(relic)

				self.description = '#5#Success!#12# NL After rummaging through the metal and burning acid, you finally grab hold of a #4#relic#12# and yank it out. NL You pull your way out of the ooze #rdamaged but rewarded.'
				self.options = {self.options[2]}
				self.screen = 'leave'
			else
				self.description = '@#2#Ouch!#12#@ NL All you find is corroded metal and a bit of @#2#burning@ @pain.#12#@ NL However, you\'re still convinced there\'s a #4#relic...'
				self.hpLoss = self.hpLoss + 1
				self.chance = self.chance + 10
				self.options[1].description = '[Deeper] #3#Lose '..self.hpLoss..' HP. #5#'..self.chance..'%: Find a Relic.'
			end
		elseif selection == 2 then
			self.description = 'You decide to leave the area. NL The slime pays no attention, content with its meal.'
			self.options = {self.options[2]}
			self.screen = 'leave'
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

ShiningLight = TextEvent:new{name='Shining Light',screen='intro',hpLoss=0}
function ShiningLight:init()
	self.random = makeRand(act.id,room.id,1)
	self.hpLoss = math.floor((ascension >= 15 and 0.3 or 0.2) * player.maxHp)
	self.description = 'You find a shimmering #4#mass of light#12# encompassing the center of the room. NL NL Its ~warm~ ~glow~ and ~enchanting~ ~patterns~ invite you in.'
	self.options = {
		{description='[Enter] #5#Upgrade 2 random cards. #3#Lose '..self.hpLoss..' HP.'},
		{description='[Leave]'},
	}
	if table.allMatch(deck,function(c) return not c:canUpgrade() end) then
		self.options[1] = {description='[Locked] Requires: Upgradeable Cards',locked=true}
	end
end

function ShiningLight:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:damage(player,self.hpLoss)
			local cards = shallowcopy(deck)
			table.retainIf(cards,function(c) return c:canUpgrade() end)
			self.random:shuffle(cards)
			local toBeUpgraded = table.map({cards[1],cards[2]},function (card)
				return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
			end)
			upgradeCardsWithEffect(toBeUpgraded)
			self.description = 'As you walk through the light, you notice that the light is absorbed into you. NL It\'s @#2#scorching@ @hot#12#@ ! However, the pain quickly recedes. NL You feel #10#invigorated#12#, as though you received a well deserved slap.'
		elseif selection == 2 then
			self.description = 'You walk around it, wondering what could have been.'
		end
		self.options = {self.options[2]}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

GoldenIdolEvent = TextEvent:new{name='Golden Idol',screen='intro',hpLoss=0,maxHpLoss=0}
function GoldenIdolEvent:init()
	self.random = makeRand(act.id,room.id,1)
	self.hpLoss = math.floor((ascension >= 15 and 0.35 or 0.25) * player.maxHp)
	self.maxHpLoss = math.max(1,math.floor((ascension >= 15 and 0.1 or 0.08) * player.maxHp))
	self.description = 'You come across an inconspicuous pedestal with a #4#shining gold idol#12# sitting peacefully atop. It looks incredibly valuable. NL NL You sure don\'t see any traps nearby.'
	self.options = {
		{description='[Take] #5#Obtain Golden Idol. #3#Trigger a trap.',item=GoldenIdol},
		{description='[Leave]'},
	}
end

function GoldenIdolEvent:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			obtainRelic(GoldenIdol:new())
			self.description = 'As you grab the Idol and stow it away, a giant boulder smashes through the ceiling into the ground next to you. NL You realize that the floor is slanted downwards as the boulder starts to roll towards you.'
			self.options = {
				{description='[Outrun] #3#Become Cursed - Injury.',cardItem=CardItem:new{card=Injury:new()}},
				{description='[Smash] #3#Take '..self.hpLoss..' Damage.'},
				{description='[Hide] #3#Lose '..self.maxHpLoss..' Max HP.'},
			}
			self.screen = 'escape'
		elseif selection == 2 then
			self.description = 'If there was ever an obvious trap, this would be it. NL You decide not to interfere with objects placed upon pedestals.'
			self.options = {self.options[2]}
			self.screen = 'leave'
		end
	elseif self.screen == 'escape' then
		if selection == 1 then
			obtainCardWithEffect(Injury:new())
			self.description = '@RUUUUUUUUUUN!@ NL You barely leap into a side passageway as the boulder rushes by. Unfortunately it feels like you sprained something however.'
		elseif selection == 2 then
			player:damage(player,self.hpLoss)
			self.description = 'You throw yourself at the boulder with everything you have. When the dust clears, you can make a safe way out.'
		elseif selection == 3 then
			player:decreaseMaxHp(self.maxHpLoss)
			self.description = '@SQUISH!@ NL The boulder flattens you a little as it passes by, but otherwise you can get out of here.'
		end
		self.options = {{description='[Leave]'}}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

DeadAdventurer = CombatTextEvent:new{screen='intro',spriteBank=3,encounter=nil,encounterChance=25,rewards=nil,numRewards=0,relicReward=nil}
local deadAdventurerEncounters = {ThreeSentryEncounter,GremlinNobEventEncounter,LagavulinStrongEncounter}
local deadAdventurerDescriptions = {
	'the armor and face appear to be @#3#scoured@ @by@ @flames.@ ',
	'it looks as though he\'s been @#3#gouged@ @and@ @trampled#12#@ by a horned beast. ',
	'he looks to have been @#3#eviscerated@ @and@ @chopped#12#@ by giant claws. ',
}
local deadAdventurerRewards = {
	{description='You found some #4#gold!#12# NL Continue searching?',action='gold'},
	{description='Hmm, couldn\'t find anything... NL Continue searching?'},
	{description='You found a #4#relic!#12# NL Continue searching?',action='relic'},
}
function DeadAdventurer:init()
	self.random = makeRand(act.id,room.id,1)
	self.rewardRandom = makeRand(act.id,room.id,2)
	local roll = self.random:randInt(1,3)
	self.encounter = deadAdventurerEncounters[roll]
	self.encounterChance = ascension >= 15 and 35 or 25
	self.description = 'You come across a #3#dead adventurer#12# on the floor. NL His #11#pants#12# have been stolen! Also, '..
		deadAdventurerDescriptions[roll]..'NL Though his #4#possessions are still intact,#12# you\'re in no mind to find out what happened here...'
	self.options = {
		{description='[Search] #5#Find Loot. #3#'..self.encounterChance..'%: monster returns.'},
		{description='[Leave]'},
	}
	self.rewards = shallowcopy(deadAdventurerRewards)
	self.relicReward = getRandomNonBottleRelic(self.random)
	self.random:shuffle(self.rewards)
end

function DeadAdventurer:isAvailable()
	return floor > 6
end

function DeadAdventurer:drawForeground()
	local x = 70
	local y = 73
	sprmap(43,17,2,2,x,y+4,0)
	sprmap(45,17,3,3,x+16,y,0)
	if self.screen ~= 'fight' then
		player:drawImage()
	end
	if self.screen == 'beforeFight' then
		for _, enemy in ipairs(enemies) do
			enemy:drawImage()
		end
	end
end

function DeadAdventurer:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			local roll = self.random:randInt(0,99)
			if roll < self.encounterChance then
				self.screen = 'beforeFight'
				self.description = 'While searching the adventurer you are caught off guard!'
				self.options = {{description='[Fight]'}}
				setupEnemies(self.encounter)
			else
				self.numRewards = self.numRewards + 1
				self.encounterChance = self.encounterChance + 25
				self.description = self.rewards[self.numRewards].description
				if self.rewards[self.numRewards].action then
					self[self.rewards[self.numRewards].action](self)
				end
				if self.numRewards == 3 then
					self.description = 'Looks like you searched all his belongings without a hitch!'
					self.options = {self.options[2]}
					self.screen = 'leave'
				else
					self.options[1].description = '[Continue] #5#Find Loot. #3#'..self.encounterChance..'%: monster returns.'
				end
			end
		elseif selection == 2 then
			self.description = 'You exit without a sound.'
			self.options = {self.options[2]}
			self.screen = 'leave'
		end
	elseif self.screen == 'beforeFight' then
		roomActionType = 'eventCombat'
		self.screen = 'fight'
		startCombat(self.encounter)
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function DeadAdventurer:gold()
	gainGold(30)
end

function DeadAdventurer:relic()
	obtainRelic(self.relicReward)
end

function DeadAdventurer:onCombatEnd(escaped)
	if escaped then
		self.numRewards = 20
	end
	saveGame(true,self.numRewards)
	self:load(self.numRewards)
end

function DeadAdventurer:load(eventMeta)
	self.screen = 'leave'
	self.description = ''
	self.options = {}
	completeRoom()

	self.numRewards = eventMeta
	if self.numRewards >= 20 then
		--escaped
		openWindowAbove(RewardWindow:new{rewards={},title='Fled...'})
	else
		local random = self.rewardRandom
		local rewards = {}
		local eventGold = random:randInt(25,35)
		local hasRelic = false
		for i = self.numRewards+1,#self.rewards do
			local reward = self.rewards[i]
			if reward.action == 'gold' then
				eventGold = eventGold + 30
			elseif reward.action == 'relic' then
				hasRelic = true
			end
		end
		addGoldReward(rewards,eventGold)
		generateCardRewards(rewards,random)
		if hasRelic then
			addRelicReward(rewards,self.relicReward)
		end
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end

Mushrooms = CombatTextEvent:new{screen='intro',spriteBank=1,healAmt=0,encounter=ThreeFungiBeastEncounter}
function Mushrooms:init()
	self.random = makeRand(act.id,room.id,1)
	self.rewardRandom = makeRand(act.id,room.id,2)
	self.healAmt = math.floor(player.maxHp*0.25)
	self.description = 'You enter a corridor full of ~#11#hypnotizing~ ~colored~ ~mushrooms.#12#~ NL Due to your lack of specialization in mycology you are unable to identify the specimens. NL You want to escape, but feel oddly compelled to eat a ~#10#mushroom...~'
	self.options = {
		{description='[Stomp] #3#Anger the Mushrooms.'},
		{description='[Eat] #5#Heal '..self.healAmt..' HP. #3#Become Cursed - Parasite.',cardItem=CardItem:new{card=Parasite:new()}},
	}
end

function Mushrooms:isAvailable()
	return floor > 6
end

function Mushrooms:drawForeground()
	spr(449,208,60,0,1)
	spr(449,98,66,0,1,1)
	spr(449,65,98,0,1,1)
	spr(449,182,102,0,1)
	mapColors(0,1,6,5,4,4,2,3)
	spr(26,134,62,0,1,1)
	spr(26,185,57,0,1)
	spr(26,102,104,0,1)
	spr(26,154,99,0,1,1)
	spr(26,233,89,0,1,1)
	resetColors()
	if self.screen ~= 'fight' then
		player:drawImage()
	end
	if self.screen == 'beforeFight' then
		for _, enemy in ipairs(enemies) do
			enemy:drawImage()
		end
	end
end

function Mushrooms:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			self.screen = 'beforeFight'
			self.description = '@#3#Ambushed!!#12#@ NL Rodents infested by the mushrooms appear out of nowhere!'
			self.options = {{description='[Fight]'}}
			setupEnemies(self.encounter)
		elseif selection == 2 then
			player:heal(self.healAmt)
			obtainCardWithEffect(Parasite:new())
			self.description = 'You give in to the unnatural desire to eat. As you consume mushroom after mushroom, you feel yourself entering into a daze and pass out. As you awake, you feel very odd. NL You #5#Heal #11#25%#12# of your HP, but you also get #3#infected.'
			self.options = {{description='[Leave]'}}
			self.screen = 'leave'
		end
	elseif self.screen == 'beforeFight' then
		roomActionType = 'eventCombat'
		self.screen = 'fight'
		startCombat(self.encounter)
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function Mushrooms:onCombatEnd(escaped)
	saveGame(true,escaped and 1 or 0)
	self:load(escaped and 1 or 0)
end

function Mushrooms:load(escaped)
	self.screen = 'leave'
	self.description = ''
	self.options = {}
	completeRoom()

	if escaped == 1 then
		--escaped
		openWindowAbove(RewardWindow:new{rewards={},title='Fled...'})
	else
		local random = self.rewardRandom
		local rewards = {}
		addGoldReward(rewards,random:randInt(20,30))
		generateCardRewards(rewards,random)
		addRelicReward(rewards,OddMushroom:new())
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end
