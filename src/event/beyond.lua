-- beyond events
---@diagnostic disable: lowercase-global

Falling = TextEvent:new{name='Falling',screen='intro',attack=nil,skill=nil,power=nil}
function Falling:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'As you head upwards hopping from one floating shape to another, you slip. NL NL You begin to fall.'
	self.options = {
		{description='[Continue]'},
	}
	self.attack = self:getCardByType('attack')
	self.skill = self:getCardByType('skill')
	self.power = self:getCardByType('power')
end

function Falling:onOption(selection)
	if self.screen == 'intro' then
		self.description = 'While in free fall you consider your options: NL Land safely with your greatest techniques. NL Channel a Power to survive the fall. NL Strike at the wall to hang on to it.'
		if not self.attack and not self.skill and not self.power then
			self.options = {{description='[Land]'}}
			self.screen = 'emptyLand'
		else
			if self.skill then
				self.options[1] = {description='[Land] #3#Lose '..self.skill.name..'.',cardItem=CardItem:new{card=self.skill}}
			else
				self.options[1] = {description='[Locked] Requires: Skill Card',locked=true}
			end
			if self.power then
				self.options[2] = {description='[Channel] #3#Lose '..self.power.name..'.',cardItem=CardItem:new{card=self.power}}
			else
				self.options[2] = {description='[Locked] Requires: Power Card',locked=true}
			end
			if self.attack then
				self.options[3] = {description='[Strike] #3#Lose '..self.attack.name..'.',cardItem=CardItem:new{card=self.attack}}
			else
				self.options[3] = {description='[Locked] Requires: Attack Card',locked=true}
			end
			self.screen = 'land'
		end
	elseif self.screen == 'emptyLand' then
		self.description = 'You seem to fall as slow as a feather, reaching the bottom without a scratch.'
		self.options[1].description = '[Leave]'
		self.screen = 'leave'
		return
	elseif self.screen == 'land' then
		if selection == 1 then
			removeCardsWithEffect({CardItem:new{card=self.skill,x=240,y=0,isNotInHand=true}},30)
			self.description = 'You land with extreme grace before continuing on.'
		elseif selection == 2 then
			removeCardsWithEffect({CardItem:new{card=self.power,x=240,y=0,isNotInHand=true}},30)
			self.description = 'Harnessing and expending some of your raw power, you manage to land unhurt.'
		elseif selection == 3 then
			removeCardsWithEffect({CardItem:new{card=self.attack,x=240,y=0,isNotInHand=true}},30)
			self.description = 'You are able to latch on to the wall, and manage to make a short hop onto another stable platform.'
		end
		self.options = {{description='[Leave]'}}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

---@return Card|false
function Falling:getCardByType(type)
	local cards = shallowcopy(deck)
	table.retainIf(cards,function(card) return card.type == type and card.canRemove end)
	return #cards > 0 and cards[self.random:randInt(#cards)]
end

TheMoaiHead = TextEvent:new{name='The Moai Head',screen='intro',maxHpLoss=0}
function TheMoaiHead:init()
	self.random = makeRand(act.id,room.id,1)
	self.maxHpLoss = ascension >= 15 and math.floor(player.maxHp*0.18+0.5) or math.floor(player.maxHp*0.125+0.5)
	self.description = 'You stumble across something that feels *very* out of place. Before you, an enormous stony head emerges from a large wall segment that does not shift and change like the rest of this area. NL The head\'s mouth is wide open, and it reveals large intimidating teeth stained red with blood. The surface of the statue is riddled with pictographs that seem to indicate people throwing themselves into the mouth of this head and being devoured. Why would anyone do that?'
	self.options = {
		{description='[Jump Inside] #5#Heal to full HP. #3#Lose '..self.maxHpLoss..' Max HP.'},
		{description='[Offer: Golden Idol] #5#Gain 333 Gold. #3#Lose Golden Idol.'},
		{description='[Leave]'},
	}
	if not hasRelic(GoldenIdol) then
		self.options[2] = {description='[Locked] Requires: Golden Idol.',locked=true}
	end
end

function TheMoaiHead:isAvailable()
	return hasRelic(GoldenIdol) or player.hp < player.maxHp / 2
end

function TheMoaiHead:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:decreaseMaxHp(self.maxHpLoss)
			player:heal(player.maxHp)
			-- TODO description is too long
			self.description = 'At first when you step up into the mouth of the statue, nothing happens. As you start to feel more than a little foolish, the huge molars slam down from above, crushing you whole. NL @Darkness.@ NL Sometime later from within the dark, you see a sliver of light, and hear what you now realize is the sound of stony teeth slowly rising upwards. NL NL You leave confused.'
		elseif selection == 2 then
			loseRelic(getRelic(GoldenIdol))
			gainGold(333)
			self.description = 'You jump back a little as the gigantic molars smash down on the idol, smashing it into dust. As the teeth start to rise up again, #4#gold#12# pours forth in a torrent from the opening, flooding you with riches.'
		else
			self.description = 'You leave, wondering what could have been.'
		end
		self.options = {{description='[Leave]'}}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

SensoryStone = TextEvent:new{name='Sensory Stone',screen='intro'}
function SensoryStone:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'Navigating through the Beyond, you discover a #10#glowing tesseract#12# @spinning@ and ~shifting~ gently in the air.'
	self.options = {
		{description='[Interact]'},
	}
end

function SensoryStone:onOption(selection)
	if self.screen == 'intro' then
		self.description = 'You touch it. NL NL A @#2#sharp@ @pain#12#@ flows through you, followed by vivid flashes of a distant memory. NL ...whose memories are these?'
		self.options = {
			{description='[Recall] #5#Add 1 Colorless card to your deck.'},
			{description='[Recall] #5#Add 2 Colorless card to your deck. #3#Lose 5 HP.'},
			{description='[Recall] #5#Add 3 Colorless card to your deck. #3#Lose 10 HP.'},
		}
		self.screen = 'touch'
	elseif self.screen == 'touch' then
		if selection == 2 then
			player:damage(player,5,'hpLoss')
		elseif selection == 3 then
			player:damage(player,10,'hpLoss')
		end
		local rewards = {}
		for _=1,selection do
			generateCardRewards(rewards,self.random,true)
		end
		openWindowAbove(RewardWindow:new{rewards=rewards,canClose=true,onProceed=function(self) self:close() end},function ()
			local words = {
				'~#2#FEAR.#12#~ NL NL A demonic creature towers above you, wings spread wide as it howls with laughter. Dead bodies of a tribe surround you while the village is engulfed in terrible ~#8#dark~ ~flames#12#.~ NL The demon calls out, taunting you. NL \" @#2#YOU@ @REALLY@ @ARE@ @THE@ @STRONGEST@ @NOW!@ @Haha..@ @HEHE...@ @HAHAHAAAAH!!#12#@ \" NL NL This laughter echoes forever... ',
				'~#5#TRIUMPH.#12#~ NL NL The remains of a ~#8#ghostly~ ~creature#12#~ sink slowly into the mud before you, barely visible in the moonlight. You have proven yourself amongst your sisters. NL Standing victoriously, you wait in silence as the others ceremoniously place the #4#creature\'s skull#12# atop your head. The ritual has concluded. NL NL You head towards the Spire...',
				'~#10#CONFUSION.#12#~ NL NL #4#[OBJECTIVE] #5#BALANCE must be ENFORCED NL #4#[DEFINE] #5#BALANCE NL #4#[ERROR] #5#BALANCE NOT FOUND NL #4#[DEFINE] #5#BALANCE NL #4#[ERROR] #5#BALANCE NOT FOUND NL #4#[WARNING] #2#Large object approaching NL NL ~\"I...~ ~..am~ ~....Neow..\"~',
				'~#8#SERENITY.#12#~ NL NL Two primitive creatures fight over a carcass on the side of the road. You observe, devoid of emotion. NL #4#Watch. Remember. Live.#12# This is the Watcher\'s mission. NL Recently, one of your peers had stopped reporting on their assignment: a Spire of unknown origin. NL NL As the fight ends, you continue onward, unfazed by the bloody scene that took place.'
			}
			self.description = words[self.random:randInt(#words)]
			self.options = {{description='[Leave]'}}
			self.screen = 'leave'
		end)
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TombOfLordRedMask = TextEvent:new{name='Tomb of Lord Red Mask',screen='intro',hasRedMask=false}
function TombOfLordRedMask:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'A highly ornamented tomb can be seen on the other side of a floating path. Upon reaching the tomb, you notice a slot for #4#gold#12# coins with a scratched out inscription above it.'
	self.hasRedMask = hasRelic(RedMask)
	if self.hasRedMask then
		self.options = {
			{description='[Don the Red Mask] #5#Gain 222 Gold.'},
			{description='[Leave]'},
		}
	else
		self.options = {
			{description='[Locked] Requires: Red Mask.',locked=true},
			{description='[Offer: '..gold..' Gold] #3#Lose all Gold. #5#Obtain a Relic.',item=RedMask},
			{description='[Leave]'},
		}
	end
end

function TombOfLordRedMask:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			gainGold(222)
			self.description = 'You don the mask and the tomb starts to ~flake~ ~away...~ a secret passage! NL NL The passage is lined with countless stolen goods and mounds of #4#gold#12#!'
		elseif selection == 2 and not self.hasRedMask then
			loseGold(gold)
			obtainRelic(RedMask:new())
			self.description = 'An opening appears in the tomb and out slides a small red mask with a note attached. \"Take from others as I have taken from you!\"'
		else
			completeRoom()
			openWindowAbove(MapWindow:new())
		end
		self.options = {{description='[Leave]'}}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

WindingHalls = TextEvent:new{name='Winding Halls',screen='intro',hpLoss=0,hpHeal=0,maxHpLoss=0}
function WindingHalls:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'As you slowly make your way up the twisting pathways, you constantly find yourself losing your way as the walls and ground seem to inexplicably shift before your eyes. NL NL The constant ~#8#whispering~ ~voices#12#~ in the back of your head aren\'t helping things either.'
	self.options = {
		{description='...'},
	}
	if ascension >= 15 then
		self.hpLoss = math.floor(0.18*player.maxHp+0.5)
		self.hpHeal = math.floor(0.2*player.maxHp+0.5)
	else
		self.hpLoss = math.floor(0.125*player.maxHp+0.5)
		self.hpHeal = math.floor(0.25*player.maxHp+0.5)
	end
	self.maxHpLoss = math.floor(0.05*player.maxHp+0.5)
end

function WindingHalls:onOption(selection)
	if self.screen == 'intro' then
		self.description = 'Passing by a structure you are certain you have previously seen you start to question if you are going insane, or if the impossible geography of this place is starting to get to you. You need to change something, and soon. NL NL That\'s what the ~#8#voices#12#~ say anyway, and why would they lie?'
		self.screen = 'select'
		self.options = {
			{description='[Embrace Madness] #5#Receive 2 #12#Madness. #3#Lose '..self.hpLoss..' HP.',cardItem=CardItem:new{card=Madness:new()}},
			{description='[Focus] #3#Become Cursed - Writhe. #5#Heal '..self.hpHeal..' HP.',cardItem=CardItem:new{card=Writhe:new()}},
			{description='[Retrace Your Steps] #3#Lose '..self.maxHpLoss..' Max HP.'},
		}
	elseif self.screen == 'select' then
		if selection == 1 then
			player:damage(player,self.hpLoss,'hpLoss')
			local startX,stepX = placeCardsInARow(2)
			obtainCardWithEffect(Madness:new(),startX+stepX)
			obtainCardWithEffect(Madness:new(),startX+stepX*2)
			self.description = 'Something in you cracks. NL NL Only the truly mad can understand a place like this, so you give into the chattering voices and continue on with a ~#8#\"new\"#12#~ perspective. NL Things do seem to make so much more sense now.'
		elseif selection == 2 then
			player:heal(self.hpHeal)
			obtainCardWithEffect(Writhe:new())
			self.description = 'As you take a moment to stop and carefully observe the undulating landscape around you, the hint of a pattern starts to emerge from within the randomness. Whenever the demented noises begin to interrupt your thoughts, you struggle through the mental pain and ignore it. NL NL Eventually you successfully map out a path forward, and continue on, now resistant to the nefarious nature of this alien place.'
		else
			player:decreaseMaxHp(self.maxHpLoss)
			self.description = 'You spend what seems like an eternity lost in the maze. Slowly but surely, you are able to retrace your steps, reorient yourself, and make it out of the twisting passages. NL NL You feel ~#2#drained#12#~ from the experience.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

MindBloom = TextEvent:new{name='Mind Bloom',screen='intro',isRich=false}
function MindBloom:init()
	self.random = makeRand(act.id,room.id,1)
	self.rewardRandom = makeRand(act.id,room.id,1)
	self.description = 'While walking and traversing through the chaos of the Spire, your thoughts suddenly begin to feel very... ~#8#real...#12#~ NL NL Imaginings of #2#monsters#12# and #4#riches#12# begin to manifest themselves into reality. NL The sensation is quickly fleeting. What do you do?'
	self.options = {
		{description='[I am War] #3#Fight a Boss from Act 1. #5#Obtain a Rare Relic.'},
		{description='[I am Awake] #5#Upgrade all Cards. #3#You can no longer heal.'},
	}
	self.isRich = floor <= 40
	if self.isRich then
		self.options[3] = {description='[I am Rich] #5#Gain 999 Gold. #3#Cursed - 2 Normality.',cardItem=CardItem:new{card=Normality:new()}}
	else
		self.options[3] = {description='[I am Healthy] #5#Heal to full HP. #3#Cursed - Doubt.',cardItem=CardItem:new{card=Doubt:new()}}
	end
end

function MindBloom:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			local bossEncounter = ({TheGuardianEncounter,HexaghostEncounter,SlimeBossEncounter})[self.random:randInt(3)]
			roomActionType = 'eventCombat'
			self.screen = 'fight'
			self.spriteBank = bossEncounter.spriteBank
			startCombat(bossEncounter)
		elseif selection == 2 then
			local cards = shallowcopy(deck)
			table.retainIf(cards,function(c) return c:canUpgrade() end)
			local toBeUpgraded = table.map(cards,function (card)
				return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
			end)
			upgradeCardsWithEffect(toBeUpgraded)
			obtainRelic(MarkOfTheBloom:new())
			self.description = 'Everything makes sense now. NL The lack of memories, the ascent, the #4#Ancient One#12#. NL NL This is the way it always was. NL This is the way it always will be. NL All will be forgotten again soon...'
		else
			if self.isRich then
				gainGold(999)
				local startX,stepX = placeCardsInARow(2)
				obtainCardWithEffect(Normality:new(),startX+stepX)
				obtainCardWithEffect(Normality:new(),startX+stepX*2)
			else
				player:heal(player.maxHp)
				obtainCardWithEffect(Doubt:new())
			end
			self.description = 'Can it really be this easy?'
		end

		if selection ~= 1 then
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function MindBloom:onCombatEnd(escaped)
	saveGame(true,escaped and 1 or 0)
	self:load(escaped and 1 or 0)
end

function MindBloom:load(escaped)
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
		addGoldReward(rewards,ascension >= 13 and 25 or 50)
		generateCardRewards(rewards,random)
		addRelicReward(rewards,getRandomRelic(random,'rare'))
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end

MysteriousSphere = CombatTextEvent:new{name='Mysterious Sphere',spriteBank=6,screen='intro',enemyKilled=false,sphereOpened=false}
function MysteriousSphere:init()
	self.rewardRandom = makeRand(act.id,room.id,1)
	self.description = 'Jutting from the chaotic terrain around you, a bony sphere surrounds a mysterious glowing object within. NL While you are curious what lies inside, you notice some sentries keeping an eye on it.'
	self.options = {
		{description='[Open Sphere] #3#Fight. #5#Reward: Rare Relic.'},
		{description='[Leave]'},
	}
	setupEnemies(TwoOrbWalkersEncounter)
end

function MysteriousSphere:drawForeground()
	local x,y = 156,40
	if self.sphereOpened then
		sprmap(79,17,3,5,x,y,0)
		sprmap(82,19,2,1,x+4,y+16,0)
	else
		sprmap(79,17,3,2,x,y,0)
		sprmap(82,17,2,2,x+4,y+16,0)
	end
	if self.screen ~= 'fight' then
		player:drawImage()
	end
	if self.screen ~= 'fight' and not self.enemyKilled then
		for _, enemy in ipairs(enemies) do
			enemy:drawImage()
		end
	end
end

function MysteriousSphere:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			self.sphereOpened = true
			self.description = 'As soon as you strike the sphere, the sentries spring to life around you!'
			self.screen = 'beforeFight'
			self.options = {{description='[Fight]'}}
		else
			self.description = 'No need to be greedy.'
			self.options = {self.options[2]}
			self.screen = 'leave'
		end
	elseif self.screen == 'beforeFight' then
		roomActionType = 'eventCombat'
		self.screen = 'fight'
		startCombat(TwoOrbWalkersEncounter)
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function MysteriousSphere:onCombatEnd(escaped)
	saveGame(true,escaped and 1 or 0)
	self:load(escaped and 1 or 0)
end

function MysteriousSphere:load(escaped)
	self.enemyKilled = true
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
		addGoldReward(rewards,random:randInt(45,55))
		generateCardRewards(rewards,random)
		addRelicReward(rewards,getRandomRelic(random,'rare'))
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end

CorruptHeartEvent = CombatTextEvent:new{name='Corrupt Heart',spriteBank=5,screen='intro',heartEscaping=false,heartY=4}
function CorruptHeartEvent:init()
	self.description = '@tu-thump@ ... @tu-thump@ ... @tu-thump@ ... NL A deep pulsing dread can be felt throughout the room... NL Is this the ~#3#heart#12#~ of the Spire? The source of this evil?'
	self.options = {{description='[Continue]'}}
	setupEnemies(CorruptHeartEncounter)
end

function CorruptHeartEvent:drawForeground()
	player:drawImage()
	if self.heartEscaping and self.heartY > -100 then
		self.heartY = self.heartY - 0.8
	end
	sprmap(62,17,9,10,136,self.heartY,0)
end

function CorruptHeartEvent:onOption()
	if self.screen == 'intro' then
		self.description = player:getSpireHeartText()
		self.options = {{description='[Attack] #11#???'}}
		self.screen = 'attack'
	elseif self.screen == 'attack' then
		self.description = 'You deal #11#'..tostring(999)..'#12# damage! NL The heart @#3#squirms#12#@ and ~#3#bleeds#12#~ ...but is ultimately still pounding. NL Are your mightiest attacks not enough?'
		self.options = {{description='[Continue]'}}
		self.screen = 'postAttack'
	elseif self.screen == 'postAttack' then
		if rubyKeyObtained and emeraldKeyObtained and sapphireKeyObtained then
			self.description = 'You ask yourself, ~\"Have~ ~I~ ~been~ ~here~ ~before?\"~'..
				' NL The heart pulses louder and louder as your ~#8#consciousness~ ~begins~ ~to~ ~fade...#12#~'..
				' NL A sudden burst of @#4#energy#12#@ emanates from inside you, @#11#jolting#12#@ you awake.'..
				' NL The heart #5#retreats#12# upwards! A large door is revealed in its place.'
			self.options = {{description='[Approach Door]'}}
			self.screen = 'goToEnding'
			self.heartEscaping = true
		else
			self.description = 'You ask yourself, ~\"Have~ ~I~ ~been~ ~here~ ~before?\"~ NL You feel that you have dealt a total of #11#'..tostring(9999)..'#12# damage to the heart. NL The heart pulses louder and louder as your ~#4#consciousness~ ~fades...~'
			self.options = {{description='[Sleep]'}}
			self.screen = 'victory?'
		end
	elseif self.screen == 'goToEnding' then
		startAct(act.id+1)
		room.completed = true
		prepareMapSelection()
		openWindowAbove(MapWindow:new{canClose=false})
	elseif self.screen == 'victory?' then
		clearSavedGame()
		switchWindow(LoseWindow:new{title='Victory?'})
	end
end
