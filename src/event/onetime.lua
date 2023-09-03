-- one time events
---@diagnostic disable: lowercase-global

local oneTimeEvents

function getOneTimeEvents()
	return oneTimeEvents
end

OminousForge = TextEvent:new{name='Ominous Forge', screen='intro'}
function OminousForge:init()
	self.description = 'You duck into a small hut. Inside, you find what appears to be a forge. The smithing tools are covered with dust, yet a fire roars inside the furnace. You feel on edge...'
	self.options = {
		{description='[Forge] #5#Upgrade a card in your deck.'},
		{description='[Rummage] #5#Obtain a special Relic. #3#Become Cursed - Pain.',cardItem=CardItem:new{card=Pain:new()},item=WarpedTongs},
		{description='[Leave]'},
	}
	if table.allMatch(deck,function(c) return not c:canUpgrade() end) then
		self.options[1] = {description='[Locked] Requires: Upgradeable Cards',locked=true}
	end
end

function OminousForge:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			upgradeCardFromDeck(1,false,function ()
				self.screen = 'leave'
				self.description = 'You decide to put the forge to use and... NL @#4#CLANG@ @CLAAANG@ @CLANG!#12#@ NL ...improve your arsenal!'
				self.options = {{description='[Leave]'}}
			end)
		elseif selection == 2 then
			obtainRelic(WarpedTongs:new())
			obtainCardWithEffect(Pain:new())

			self.screen = 'leave'
			self.description = 'You decide to see if you can find anything of use. After uncovering tarps, looking through boxes, and checking nooks and crannies, you find a dust covered ~#4#relic!#12#~ ' ..
				'NL NL Taking the relic, you can\'t shake a sudden feeling of ~#2#sharp~ ~pain#12#~ as you exit the hut. Maybe you disturbed some sort of spirit?'
			self.options = {{description='[Leave]'}}
		else
			self.screen = 'leave'
			self.description = 'There doesn\'t seem to be anything of use. You exit the way you came, the flames of the furnace casting ~#8#eerie~ ~shadows#12#~ on the walls inside the hut...'
			self.options = {{description='[Leave]'}}
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

BonfireSpirits = TextEvent:new{name='Bonfire Spirits',screen='intro'}
function BonfireSpirits:init()
	self.description = 'You happen upon a group of what looks like #8#purple fire spirits#12# ~dancing~ around a large bonfire. NL '
	self.options = {
		{description='[Continue]'},
	}
end

function BonfireSpirits:onOption()
	if self.screen == 'intro' then
		self.screen = 'choose'
		self.description = 'The spirits toss small bones and fragments into the fire, which ~brilliantly~ ~erupts~ each time. NL As you approach, the spirits all turn to you, expectantly...'
		self.options[1].description = '[Offer] Receive a reward based on the offer.'
	elseif self.screen == 'choose' then
		removeCardFromDeck(1,false,function(completed,cardItems)
			if not completed then
				self.description = 'Nothing happens... NL The spirits seem to be ignoring you now. Disappointing...'
				self.options[1].description = '[Leave]'
				self.screen = 'leave'
			else
				local card = cardItems[1].card
				self:provideCardReward(card)
				self.options[1].description = '[Leave]'
				self.screen = 'leave'
			end
		end,'Select a Card to Offer')
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function BonfireSpirits:provideCardReward(card)
	self.description = 'You toss an offering into the bonfire. NL NL '
	if card.type == 'curse' then
		self.description = self.description..'However, the spirits aren\'t happy that you offered a #8#Curse...#12# The card fizzles a meek black smoke. You receive a... ~#8#something#12#~ in return.'
		obtainRelic(SpiritPoop:new())
	elseif card.rarity == 'common' or card.rarity == 'special' then
		self.description = self.description..'The flames grow slightly brighter. NL The spirits continue dancing. You feel slightly warmer from their presence.. NL You #5#heal #10#5 #12#HP.'
		player:heal(5)
	elseif card.rarity == 'uncommon' then
		self.description = self.description..'The flames erupt, growing significantly stronger! NL The spirits dance around you excitedly, filling you with a ~sense~ ~of~ ~warmth.~ NL You are #5#healed#12# to full HP.'
		player:heal(player.maxHp - player.hp)
	elseif card.rarity == 'rare' then
		self.description = self.description..'The flames @burst, @ nearly knocking you off your feet, as the fire @doubles@ in strength. NL The spirits dance around you excitedly before ~merging~ ~into~ ~your~ ~form,~ filling you with warmth and strength. NL Your Max HP increases by #10#10#12# and you are #5#healed to full HP.'
		player:heal(player.maxHp - player.hp)
		player:increaseMaxHp(10)
	else --if card.rarity == 'basic' then
		self.description = self.description..'Nothing happens... NL The spirits seem to be ignoring you now. Disappointing...'
	end
end

DesignerInSpire = TextEvent:new{name='Designer In-Spire',screen='intro',adjustCost=40,cleanCost=60,fullCost=90,hpLoss=3,adjustUpgradeTwo=false,cleanTransformTwo=false}
function DesignerInSpire:isAvailable()
	return (act == TheCity or act == TheBeyond) and gold >= 75
end

function DesignerInSpire:init()
	self.random = makeRand(act.id,room.id,1)
	self.adjustUpgradeTwo = self.random:randBool()
	self.cleanTransformTwo = self.random:randBool()
	if ascension >= 15 then
		self.adjustCost = 50
		self.cleanCost = 75
		self.fullCost = 110
		self.hpLoss = 5
	end
	self.description = 'You discover a ~#5#colorful#12#~ shop with the banner \"IN-SPIRE\" and walk in to see what\'s inside. NL \"No, no way. Nope. Can\'t let you in!\" NL NL A man with ridiculous clothing appears at the entrance to bar you.'
	self.options = {
		{description='[Continue]'},
	}
end

function DesignerInSpire:onOption(selection)
	if self.screen == 'intro' then
		self.description = '\"This will not do, no no. What is this style? @Disgusting!@ Are you #2#bleeeeding? ~#8#Groooss.#12#~ @Business??@ You a customer? Fine. ~Whaaatever.\"~ NL '..
			'He lets out an exaggerated sigh and points at a list of services. NL The services seem fine, but you would rather punch this smug man in his smug face.'
		self.options = {}
		self.screen = 'service'
		local cards = shallowcopy(deck)
		table.retainIf(cards,function(c) return c:canUpgrade() end)
		local numUpgradableCards = #cards
		cards = shallowcopy(deck)
		table.retainIf(cards,function(c) return c.canRemove end)
		local numRemovableCards = #cards

		if self.adjustUpgradeTwo then
			self.options[1] = {description='[Adjustments] #3#Lose '..self.adjustCost..' Gold. #5#Upgrade 2 random cards.',locked=gold<self.adjustCost or numUpgradableCards==0}
		else
			self.options[1] = {description='[Adjustments] #3#Lose '..self.adjustCost..' Gold. #5#Upgrade a card.',locked=gold<self.adjustCost or numUpgradableCards==0}
		end
		if self.cleanTransformTwo then
			self.options[2] = {description='[Clean Up] #3#Lose '..self.cleanCost..' Gold. #5#Transform 2 cards.', locked=gold<self.cleanCost or numRemovableCards<2}
		else
			self.options[2] = {description='[Clean Up] #3#Lose '..self.cleanCost..' Gold. #5#Remove a card.',locked=gold<self.cleanCost or numRemovableCards == 0}
		end
		self.options[3] = {description='[Full Service] #3#Lose '..self.fullCost..' Gold. #5#Remove a card and upgrade a random card.',locked=gold<self.fullCost or numRemovableCards == 0}
		self.options[4] = {description='[Punch] #3#Lose '..self.hpLoss..' HP.'}
	elseif self.screen == 'service' then
		if selection == 1 then
			loseGold(self.adjustCost)
			if self.adjustUpgradeTwo then
				local cards = shallowcopy(deck)
				table.retainIf(cards,function(c) return c:canUpgrade() end)
				self.random:shuffle(cards)
				local toBeUpgraded = table.map({cards[1],cards[2]},function (card)
					return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
				end)
				upgradeCardsWithEffect(toBeUpgraded)
				self:bye()
			else
				upgradeCardFromDeck(1,false,function ()
					self:bye()
				end)
			end
		elseif selection == 2 then
			loseGold(self.cleanCost)
			if self.cleanTransformTwo then
				transformCardFromDeck(2,self.random,false, function ()
					self:bye()
				end)
			else
				removeCardFromDeck(1,false,function ()
					self:bye()
				end)
			end
		elseif selection == 3 then
			loseGold(self.fullCost)
			removeCardFromDeck(1,false,function ()
				local cards = shallowcopy(deck)
				table.retainIf(cards,function(c) return c:canUpgrade() end)
				if #cards > 0 then
					local card = cards[self.random:randInt(#cards)]
					upgradeCardsWithEffect({CardItem:new{card=card,x=240,y=0,isNotInHand=true}})
				end
				self:bye()
			end)
		else
			player:damage(player,self.hpLoss,'hpLoss')
			self.description = 'You punch him so hard your fist hurts. NL \"My @FACE!!@ Now I\'ll have to-\" NL NL He fainted. Who\'s ~#8#groooss#12#~ and #2#bleeeeding#12# now?'
			self.options = {{description='[Leave]'}}
			self.screen = 'leave'
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function DesignerInSpire:bye()
	self.description = '\"Okay, bye bye now.\" NL NL ...should\'ve punched him.'
	self.options = {{description='[Leave]'}}
	self.screen = 'leave'
end

Duplicator = TextEvent:new{name='Duplicator',screen='intro'}
function Duplicator:isAvailable()
	return act == TheCity or act == TheBeyond
end

function Duplicator:init()
	self.description = 'Before you lies a decorated altar to some ancient entity.'
	self.options = {
		{description='[Pray] #5#Duplicate a card in your deck.'},
		{description='[Leave]'},
	}
end

function Duplicator:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			duplicateCardFromDeck(1,false,function ()
				self.description = 'You kneel respectfully. A ghastly mirror image appears from the shrine and collides into you.'
			end)
		else
			self.description = 'You ignore the shrine, confident in your choice.'
		end
		self.screen = 'leave'
		self.options = {self.options[2]}
		self.selectedOption = 0
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

FaceTrader = TextEvent:new{name='Face Trader',screen='intro',hpLoss=0,goldAmt=75}
function FaceTrader:isAvailable()
	return act == Exordium or act == TheCity
end

function FaceTrader:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'You walk by an eerie statue holding several masks... NL Something behind you softly whispers, NL ~\"Stop.\"~'
	self.options = {
		{description='[Continue]'},
	}
	if ascension >= 15 then
		self.goldAmt = 50
	end
	self.hpLoss = math.max(1,math.floor(player.maxHp/10))
end

function FaceTrader:onOption(selection)
	if self.screen == 'intro' then
		self.screen = 'trade'
		self.description = 'You swerve around to face the statue which is now facing you! NL On closer inspection, it\'s not a statue but a statuesque, gaunt man. Is he even breathing? NL NL ~\"Face.~ ~Let~ ~me~ ~touch?~ ~Maybe~ ~trade?\"~'
		self.options = {
			{description='[Touch] #3#Lose '..self.hpLoss..' HP, #5#gain '..self.goldAmt..' Gold.'},
			{description='[Trade] #5#50%: Good Face. #3#50%: Bad Face.'},
			{description='[Leave]'},
		}
	elseif self.screen == 'trade' then
		if selection == 1 then
			player:damage(player,self.hpLoss)
			gainGold(self.goldAmt)
			self.description = '~\"Compensation?~ ~Compensation.\"~ NL Mechanically, he cranes out a neat stack of #4#gold#12# and places it into your pouch. NL ~\"What~ ~a~ ~nice~ ~face.~ ~Nice~ ~face.\"~ NL While he touches your face, you begin to feel your life drain out of it! NL During this, his mask falls off and shatters. Screaming, he quickly covers his face with all six arms dropping even more masks! Amidst all the screaming and shattering, you escape. NL His face was completely blank.'
		elseif selection == 2 then
			local relics = {CultistMask,FaceOfCleric,GremlinMask,NlothsMask,SsserpentHead}
			obtainRelic(relics[self.random:randInt(#relics)]:new())
			self.description = '~\"For~ ~me?~ @FOR@ @ME?@ ~Oh~ ~yes..~ ~Yes.~ ~Yes..~ ~mmm...\"~ NL NL You see one of his arms flicker, and your face is in its hand! Your face has been swapped. NL NL ~\"Nice~ ~face.~ ~Nice~ ~face.\"~'
		else
			self.description = '~\"Stop.~ ~Stop.~ ~Stop.~ ~Stop.~ ~Stop.\"~ NL NL This was probably the right call.'
		end
		self.screen = 'leave'
		self.options = {self.options[3]}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheDivineFountain = TextEvent:new{name='The Divine Fountain',screen='intro'}
function TheDivineFountain:isAvailable()
	return table.anyMatch(deck,function(card) return card.type == 'curse' and card.canRemove end)
end

function TheDivineFountain:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'You come across ~#10#shimmering~ ~water#12#~ flowing endlessly from a fountain on a nearby wall.'
	self.options = {
		{description='[Drink] #5#Remove all Curses from your deck.'},
		{description='[Leave]'},
	}
end

function TheDivineFountain:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			local cards = shallowcopy(deck)
			table.retainIf(cards,function(c) return c.type == 'curse' and c.canRemove end)
			self.random:shuffle(cards)
			local toBeRemoved = table.map(cards,function (card)
				return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
			end)
			removeCardsWithEffect(toBeRemoved,30)

			self.description = 'As you drink the ~#10#water, #12#~ you feel a #8#dark grasp#12# loosen.'
		else
			self.description = 'Unsure of the nature of this water, you continue on your way, parched.'
		end
		self.screen = 'leave'
		self.options = {self.options[2]}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Lab = TextEvent:new{name='Lab',screen='intro'}
function Lab:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'You find yourself in a room filled with racks of test tubes, beakers, flasks, forceps, pinch clamps, stirring rods, tongs, goggles, funnels, pipets, cylinders, condensers, and even a rare spiral tube of glass. NL NL Why do you know the name of all these tools? It doesn\'t matter, you take a look around.'
	self.options = {
		{description='[Search] #5#Find some Potions!'},
	}
end

function Lab:onOption()
	if self.screen == 'intro' then
		local rewards = {}
		addPotionReward(rewards,getTrueRandomPotionType(self.random):new())
		addPotionReward(rewards,getTrueRandomPotionType(self.random):new())
		if ascension < 15 then
			addPotionReward(rewards,getTrueRandomPotionType(self.random):new())
		end
		openWindowAbove(RewardWindow:new{rewards=rewards})
		completeRoom()
	end
end

KnowingSkull = TextEvent:new{name='Knowing Skull',screen='intro',potionCost=6,goldCost=6,cardCost=6,leaveCost=6}
function KnowingSkull:isAvailable()
	return act == TheCity and player.hp > 12
end

function KnowingSkull:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'You find yourself in an old, decorated chamber. In the center of the room, a large skull sits atop an ornate pedestal. As you approach, the skull @#4#bursts@ @into@ @flames#12#@ and turns to face you.'
	self.options = {
		{description='[Continue]'},
	}
end

function KnowingSkull:onOption(selection)
	if self.screen == 'intro' then
		self.screen = 'ask'
		self.description = '\"WHAT IS IT YOU SEEK? WHAT IS IT YOU OFFER?\" NL In sync with its final words, the door behind you @slams@ @shut.@'
		self.options = {
			{description='[A Pick Me Up?] #5#Get a Potion. #3#Lose '..self.potionCost..' HP.'},
			{description='[Riches?] #5#Gain 90 Gold. #3#Lose '..self.goldCost..' HP.'},
			{description='[Success?] #5#Get a Colorless Card. #3#Lose '..self.cardCost..' HP.'},
			{description='[How do I leave?] #3#Lose '..self.leaveCost..' HP.'},
		}
	elseif self.screen == 'ask' then
		if selection == 1 then
			obtainPotion(getTrueRandomPotionType(self.random):new())
			player:damage(player,self.potionCost,'hpLoss')
			self.potionCost = self.potionCost+1
			self.options[1].description = '[A Pick Me Up?] #5#Get a Potion. #3#Lose '..self.potionCost..' HP.'
			self.description = '\"DRINK UP!\" NL You obtain a potion.'
		elseif selection == 2 then
			gainGold(90)
			player:damage(player,self.goldCost,'hpLoss')
			self.goldCost = self.goldCost+1
			self.options[2].description = '[Riches?] #5#Gain 90 Gold. #3#Lose '..self.goldCost..' HP.'
			self.description = '\"YOU MORTALS NEVER CHANGE. IT IS DONE.\" NL #4#Gold#12# rains down on you!'
		elseif selection == 3 then
			local card = getColorlessCardType(self.random,'uncommon'):new()
			obtainCardWithEffect(card)
			player:damage(player,self.cardCost,'hpLoss')
			self.cardCost = self.cardCost+1
			self.options[3].description = '[Success?] #5#Get a Colorless Card. #3#Lose '..self.cardCost..' HP.'
			self.description = '\"PERHAPS THIS WILL HELP?\" NL You obtain a card.'
		else
			player:damage(player,self.leaveCost,'hpLoss')
			self.description = '\"BEHIND YOU, MORTAL.\" NL You peek behind the skull. Surely enough, there is a door.'
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		end
		if selection <= 3 then
			self.description = self.description..' NL NL \"ANYTHING ELSE?\"'
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Nloth = TextEvent:new{name='N\'loth',screen='intro',relics=nil}
function Nloth:isAvailable()
	return act == TheCity and #relics >= 2
end

function Nloth:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'An odd creature with a hunched back sprouting several tentacles is scrounging through a pile of trash and debris in front of you. As you approach, he shuffles towards you in a non-threatening manner. NL \"N\'loth hungry. Feed N\'loth.\"'
	self.relics = shallowcopy(relics)
	self.random:shuffle(self.relics)
	self.options = {
		{description='[Offer: '..self.relics[1].name..'] #3#Lose this relic. #5#Obtain a special relic.',item=NlothsGift},
		{description='[Offer: '..self.relics[2].name..'] #3#Lose this relic. #5#Obtain a special relic.',item=NlothsGift},
		{description='[Leave]'},
	}
end

function Nloth:onOption(selection)
	if self.screen == 'intro' then
		if selection <= 2 then
			loseRelic(self.relics[selection])
			obtainRelic(NlothsGift:new())
			self.description = 'Holding the #4#relic#12# out towards him, N\'loth snatches it out of your hand with his tentacles, dislocates his jaw, and slurps down your offer in one quick gulp. NL He gives you a large, toothy grin as more tentacles appear from behind his cloak, these ones brandishing an impossibly neat looking box. He pushes it towards you until you take it.'
		else
			self.description = 'You shake your head. N\'loth hunches even further and sighs, then scuttles away.'
		end
		self.options = {self.options[3]}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

NoteForYourself = TextEvent:new{name='A Note For Yourself',screen='intro', card=nil}
function NoteForYourself:isAvailable()
	return ascension < 15
end

function NoteForYourself:init()
	self.description = 'You spot a loose brick within a pillar that catches your eye.'
	self.options = {{description='[Continue]'}}
	self.card = loadNoteForYourselfCard()
end

function NoteForYourself:onOption(selection)
	if self.screen == 'intro' then
		self.description = 'You find a folded note and a #4#card#12# inside. It reads, NL \"The Heart awaits.\" NL NL This is your handwriting.'
		self.options = {
			{description='[Take and Give] #5#Receive '..self.card.name..' and Store a Card.',cardItem=CardItem:new{card=self.card}},
			{description='[Ignore]'}
		}
		self.screen = 'choose'
	elseif self.screen == 'choose' then
		if selection == 1 then
			obtainCardWithEffect(self.card)
			removeCardFromDeck(1,false,function (completed,cardItems)
				self.description = 'What is going on?'
				if completed then
					saveNoteForYourselfCard(cardItems[1].card)
				end
			end,'Choose a Card to Store')
		else
			self.description = 'What is going on?'
		end
		self.options = {{description='[Leave]'}}
		self.screen = 'leave'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

SecretPortal = TextEvent:new{name='Secret Portal',screen='intro'}
function SecretPortal:isAvailable()
	return act.id == TheBeyond
end

function SecretPortal:init()
	self.description = 'Before you is a sight that seems out of place in the alien landscape around you. Strangely placed into one of the living walls of the Beyond is an enclosed stone entrance filled with a ~#8#swirling~ ~magical~ ~portal.#12#~ NL NL You aren\'t sure where it leads, but maybe it could speed your journey through the Spire.'
	self.options = {
		{description='[Enter the Portal] IMMEDIATELY travel to the boss.'},
		{description='[Leave]'},
	}
end

function SecretPortal:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			self.description = 'Jumping through the portal, your sense of time and space is completely torn apart. NL NL As you reorient yourself to the new surroundings, you realize that right before you is a fearsome battle.'
			self.screen = 'enter'
			self.options = {self.options[2]}
		else
			self.description = 'Careful and cautious seems the better approach for reaching the top of the Spire. Ignoring the portal you continue on.'
			self.screen = 'leave'
			self.options = {self.options[2]}
		end
	elseif self.screen == 'enter' then
		completeRoom()
		mapScreenSelectionMode = false
		floor = floor+1
		room = specialRooms[1]
		currentRoomX = room.x
		currentRoomY = room.y
		mapScreenY = currentRoomY
		saveGame()
		prepareRoom()
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheJoust = TextEvent:new{name='The Joust',screen='intro'}
function TheJoust:isAvailable()
	return act == TheCity and gold >= 50
end

function TheJoust:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'As you make your way through the large buildings you come across a long narrow bridge and spot knights on either side, facing one another. You approach... NL @\"Halt!\"@ NL NL A knight forcefully gestures you to stop with its giant lance.'
	self.options = {
		{description='[Continue]'},
	}
end

function TheJoust:onOption(selection)
	if self.screen == 'intro' then
		self.description = '\"Today is the day I must settle the score with the #2#murderer#12# of my beloved pet, #4#Noodles.#12# Until then, you may not pass. NL NL Fellow witness, why don\'t you #10#bet#12# on who you think will emerge victorious?\"'
		self.screen = 'bet'
		self.options = {
			{description='[Murderer] #4#Bet 50 Gold #12#- #5#70%: Win 100 Gold.'},
			{description='[Owner] #4#Bet 50 Gold #12#- #5#30%: Win 250 Gold.'},
		}
	elseif self.screen == 'bet' then
		loseGold(50)
		if selection == 1 then
			self.description = '\"I can\'t believe you\'re betting against #yNoodles!\" NL NL Furious, he clamps down his helmet and rushes towards his nemesis.'
		else
			self.description = '\"Give me strength, #4#Noodles!#12#\" NL NL Clamping down his helmet, the knight charges forward.'
		end
		self.betOwner = selection ~= 1
		self.screen = 'fight'
		self.options = {{description='[Watch]'}}
	elseif self.screen == 'fight' then
		self.description = 'NL @#4#*CRASH!!!*#12#@ @#2#*KLAAAANG!*#12#@ NL NL @#5#*POW!*@'
		self.screen = 'postFight'
		self.ownerWins = self.random:rand() < 0.3
	elseif self.screen == 'postFight' then
		if self.ownerWins then
			self.description = 'The nemesis was slain. NL NL '
		else
			self.description = 'The owner died. NL NL '
		end
		if self.betOwner == self.ownerWins then
			self.description = self.description..'You #5#win#12# the bet. Unsure what to think, you grab your winnings and leave.'
			if self.betOwner then
				gainGold(250)
			else
				gainGold(100)
			end
		else
			self.description = self.description..'You #2#lost#12# the bet, but at least you weren\'t gouged by a lance.'
		end
		self.screen = 'leave'
		self.options[1].description = '[Leave]'
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

WeMeetAgain = TextEvent:new{name='We Meet Again!',screen='intro',canOperatePotion=false}
function WeMeetAgain:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = '\"We meet again!\" NL A cheery disheveled fellow approaches you gleefully. You do not know this man. NL NL \"It\'s me, #4#Ranwid!#12# Have any goods for me today? The usual? A fella like me can\'t make it alone, you know?\" NL You eye him suspiciously and consider your options...'
	self.options = {}

	local potionCandidates = shallowcopy(potions)
	table.retainIf(potionCandidates,function (p) return p ~= PotionSlot end)
	if #potionCandidates > 0 then
		self.potion = potionCandidates[self.random:randInt(#potionCandidates)]
		self.options[1] = {description='[Give Potion] #3#Lose '..self.potion.name..'. #5#Obtain a Relic.'}
	else
		self.options[1] = {description='[Locked] Requires: Potion.',locked=true}
	end

	self.goldAmt = gold >= 50 and self.random:randInt(50,math.min(150,gold)) or nil
	if self.goldAmt then
		self.options[2] = {description='[Give Potion] #3#Lose '..self.goldAmt..' Gold. #5#Obtain a Relic.'}
	else
		self.options[2] = {description='[Locked] Requires: At least 50 Gold.',locked=true}
	end

	local cardCandidates = shallowcopy(deck)
	table.retainIf(cardCandidates,function (c) return c.rarity ~= 'basic' and c.type ~= 'curse' end)
	if #cardCandidates > 0 then
		self.card = cardCandidates[self.random:randInt(#cardCandidates)]
		self.options[3] = {description='[Give Card] #3#Lose '..self.card.name..'. #5#Obtain a Relic.',cardItem=CardItem:new{card=self.card}}
	else
		self.options[3] = {description='[Locked] Requires: Card.',locked=true}
	end

	self.options[4] = {description='[Attack]'}
end

function WeMeetAgain:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			losePotion(self.potion)
			self.description = '\"Exquisite! Was feeling parched.\" NL ~#10#Glup~ ~glup~ ~glup#12#~ NL NL He downs the potion in one go and lets out a satisfied @burp.@'
		elseif selection == 2 then
			loseGold(self.goldAmt)
			self.description = '\"Magnificent! This will be quite handy if I run into those #2#mask wearing hoodlums#12# again.\"'
		elseif selection == 3 then
			removeCardsWithEffect({CardItem:new{card=self.card,x=240,y=0,isNotInHand=true}},30)
			self.description = '\"Exemplary! I shall study this further in my chambers.\"'
		end
		if selection ~= 4 then
			local relic = getRandomNonBottleRelic(self.random)
			obtainRelic(relic)
			self.description = self.description..' NL NL He rummages around his various pockets... NL \"Here, look what I\'ve got for you today! Take it take it!\"'
		else
			self.description = '\" @Aaaaagghh!!@ What a jerk you are sometimes!\" NL He runs away.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheWomanInBlue = TextEvent:new{name='The Woman in Blue',screen='intro',hpLoss=0}
function TheWomanInBlue:isAvailable()
	return gold >= 50
end

function TheWomanInBlue:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'From the darkness, an arm pulls you into a small shop. As your eyes adjust, you see a pale woman in sharp clothes gesturing towards a wall of potions. NL \"Buy a potion. Now!\" she states.'
	self.options = {
		{description='[Buy 1 Potion] #4#20 Gold.'},
		{description='[Buy 2 Potions] #4#30 Gold.'},
		{description='[Buy 3 Potions] #4#40 Gold.'},
		{description='[Leave]'},
	}
	if ascension >= 15 then
		self.hpLoss = math.ceil(player.maxHp * 0.05)
		self.options[4].description = '[Leave] #3#Take '..self.hpLoss..' Damage.'
	end
end

function TheWomanInBlue:onOption(selection)
	if self.screen == 'intro' then
		if selection == 4 then
			if self.hpLoss > 0 then
				player:damage(player,self.hpLoss,'hpLoss')
			end
			self.description = '@#2#WHAM#12#@ NL Her gloved fist collides with your face, nearly knocking you off your feet. NL \"Get out before I litter the floor with your guts.\" You take her word and exit with your guts still safely in your body.'
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		else
			loseGold(selection*10+10)
			local rewards = {}
			for _=1,selection do
				addPotionReward(rewards,getTrueRandomPotionType(self.random):new())
			end
			local rewardWindow = RewardWindow:new{rewards=rewards,canClose=true,onProceed=function(self) self:close() end}
			openWindowAbove(rewardWindow,function ()
				self.description = '\"Good. Now leave.\" NL You exit the shop cautiously.'
				self.screen = 'leave'
				self.options = {{description='[Leave]'}}
			end)
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

oneTimeEvents = {
	OminousForge,BonfireSpirits,DesignerInSpire,Duplicator,FaceTrader,TheDivineFountain,Lab,
	KnowingSkull,Nloth,NoteForYourself,SecretPortal,TheJoust,WeMeetAgain,TheWomanInBlue,
}
