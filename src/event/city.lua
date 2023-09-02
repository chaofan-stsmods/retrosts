-- city events
---@diagnostic disable: lowercase-global

PleadingVagrant = TextEvent:new{name='Pleading Vagrant',screen='intro',goldAmt=85}
function PleadingVagrant:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'While sneaking past a group of shrouded figures, one of them approaches you. NL \"Got anything for me friend? Please... maybe some #4#Coin#12#?\" NL \"I just need somewhere to stay, I have treasures I can trade...\" NL He seems delusional, but harmless.'
	self.options = {
		{description='[Offer Gold] #4#'..self.goldAmt..' Gold: #5#Obtain a Relic.'},
		{description='[Rob] #5#Obtain a Relic. #3#Become Cursed - Shame.',cardItem=CardItem:new{card=Shame:new()}},
		{description='[Leave]'},
	}
	if gold < self.goldAmt then
		self.options[1] = {description='[Locked] Requires: '..self.goldAmt..' Gold.',locked=true}
	end
end

function PleadingVagrant:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			loseGold(self.goldAmt)
			local relic = getRandomNonBottleRelic(self.random)
			obtainRelic(relic)
			self.description = '\"Oh yes, ~yes!~ Here here, a fair trade!\"'
		elseif selection == 2 then
			obtainCardWithEffect(Shame:new())
			local relic = getRandomNonBottleRelic(self.random)
			obtainRelic(relic)
			self.description = 'You snatch the precious #4#relic#12# from his clutches and walk away. NL From behind you hear, NL \"Have you no shame? ~HAVE~ ~YOU~ ~NO~ ~SHAAAAAME?!\"~ NL You have some #8#shame.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
		if selection == 3 then
			completeRoom()
			openWindowAbove(MapWindow:new())
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

AncientWriting = TextEvent:new{name='Ancient Writing',screen='intro'}
function AncientWriting:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'Scaling the city, you notice a wall covered in the writing of ~#4#Ancients.#12#~ As you try to wrap your head around what the puzzling symbols and glyphs could mean, the writing begins to ~#10#glow.#12#~ NL Suddenly, the message becomes clear...'
	self.options = {
		{description='[Elegance] #5#Remove a card from your deck.'},
		{description='[Simplicity] #5#Upgrade all Strikes and Defends.'},
	}
end

function AncientWriting:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			removeCardFromDeck(1,false,function ()
				self.description = 'The answer was elegance. NL Of course.'
			end)
		elseif selection == 2 then
			local cards = shallowcopy(deck)
			table.retainIf(cards,function(c)
				return c:canUpgrade() and table.anyMatch(c.tags, function (tag) return tag == 'basicStrike' or tag == 'basicDefend' end)
			end)
			local toBeUpgraded = table.map(cards,function (card)
				return CardItem:new{card=card,x=240,y=0,isNotInHand=true}
			end)
			upgradeCardsWithEffect(toBeUpgraded)
			self.description = 'The truth is always simple.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

OldBeggar = TextEvent:new{name='Old Beggar',screen='intro',goldAmt=75}
function OldBeggar:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'An old beggar cloaked in fur reaches his hands out towards you as you pass. \"Spare some coin, child?\"'
	self.options = {
		{description='[Offer Gold] #4#'..self.goldAmt..' Gold: #5#Remove a card from your deck.'},
		{description='[Leave]'},
	}
	if gold < self.goldAmt then
		self.options[1] = {description='[Locked] Requires: '..self.goldAmt..' Gold.',locked=true}
	end
end

function OldBeggar:isAvailable()
	return gold >= 75
end

function OldBeggar:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			loseGold(self.goldAmt)
			self.description = 'The beggar takes off its cloak to reveal that he is #10#Cleric!#12# NL @\"You@ @are@ @a@ @kind@ @soul.@ @Receive@ @my@ @purification!\"@ he screams. NL You are unsure if he is grateful or mad.'
			self.screen = 'cleric'
			self.options = {{description='[Continue]'}}
		else
			self.description = 'The beggar looks to the floor as you pass. NL \"You will never make a difference... You never do.\"'
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		end
	elseif self.screen == 'cleric' then
		removeCardFromDeck(1,false,function ()
			self.description = '@\"I@ @hope@ @you@ @do@ @better@ @this@ @time,@ @friend!\"@ he shouts. NL Wondering what was implied by this, you push forward.'
		end)
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

CursedTome = TextEvent:new{name='Cursed Tome',screen='intro',hpLoss=10}
function CursedTome:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'In an abandoned temple, you find a giant book, open, riddled with @#8#cryptic@ @writings.#12#@ NL NL As you try to interpret the elaborate script, it begins to ~#10#shift#12#~ and ~#10#morph#12#~ into writing you are familiar with.'
	self.options = {
		{description='[Read]'},
		{description='[Leave]'},
	}
	self.hpLoss = ascension >= 15 and 15 or 10
end

function CursedTome:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			self.description = 'Odd. The book seems to be about an #4#Ancient#12# named #4#Neow#12#. NL NL This piques your interest, but you have a general feeling of ~#8#malaise.~'
			self.screen = 'page1'
			self.options = {{description='[Continue] #3#Lose 1 HP.'}}
		else
			self.description = 'You exit, feeling a ~#8#dark~ ~energy~ ~emanating#12#~ from the book on the pedestal.'
			self.screen = 'leave'
			self.options = {{description='[Leave]'}}
		end
	elseif self.screen == 'page1' then
		player:damage(player,1,'hpLoss')
		self.description = 'The Ancient of Resurrection, #4#Neow#12#, was exiled to the bottom of the Spire. NL NL You feel compelled to read more, but your body begins to ~#2#ache.~'
		self.screen = 'page2'
		self.options = {{description='[Continue] #3#Lose 2 HP.'}}
	elseif self.screen == 'page2' then
		player:damage(player,2,'hpLoss')
		self.description = 'Seeking vengeance, #4#Neow#12# blesses outsiders, using them for her own purposes. NL NL You are starting to feel very ~#2#weak~ ~and~ ~tired...~'
		self.screen = 'page3'
		self.options = {{description='[Continue] #3#Lose 3 HP.'}}
	elseif self.screen == 'page3' then
		player:damage(player,3,'hpLoss')
		self.description = 'Those resurrected by #4#Neow#12# remember only fragments of their past selves, cursed to fight for eternity. NL NL As you near the final page, your @#2#old@ @wounds@ @begin@ @to@ @reopen!@'
		self.screen = 'lastpage'
		self.options = {
			{description='[Take] #5#Obtain the Book. #3#Lose '..self.hpLoss..' HP.'},
			{description='[Stop] #3#Lose 3 HP.'},
		}
	elseif self.screen == 'lastpage' then
		if selection == 1 then
			player:damage(player,self.hpLoss,'hpLoss')
			local relic = ({Necronomicon,Enchiridion,NilrysCodex})[self.random:randInt(1,3)]:new()
			local rewards = {}
			addRelicReward(rewards,relic)
			local rewardWindow = RewardWindow:new{rewards=rewards,canClose=true,onProceed=function(self) self:close() end}
			openWindowAbove(rewardWindow,function ()
				self.description = 'Upon finishing the tome, you decide to take it with you. With proof in hand, will you retain your memories?'
			end)
		else
			player:damage(player,3,'hpLoss')
			self.description = 'With incredible strain and willpower, you resist the trance of the tome and @SLAM@ it shut. NL You turn and exit the temple, feeling ~#10#drained...~'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Augmenter = TextEvent:new{name='Augmenter',screen='intro'}
function Augmenter:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'A man with an eyepatch and a devilish grin strides up to you. NL \"Hey there, stranger. Interested in advancing science? I can make you stronger than any training or blessing. You\'re gonna need it if you\'re one of those heroes with a death wish.\" NL NL ~\"Whad\'ya~ ~say?\"~'
	self.options = {
		{description='[Test J.A.X.] #5#Get JAXXED.',cardItem=CardItem:new{card=JAX:new()}},
		{description='[Become Test Subject] #5#Transform 2 cards.'},
		{description='[Ingest Mutagens] #5#Obtain a special relic.',item=MutagenicStrength},
	}
	if table.count(deck,function(card) return card.canRemove end) < 2 then
		self.options[2] = {description='[Locked] Requires: 2 or more cards in deck.',locked=true}
	end
end

function Augmenter:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			obtainCardWithEffect(JAX:new())
			self.description = '~\"Excellent.\"~ NL The man hands over a dangerous looking syringe filled with a ~#10#glowing~ ~liquid#12#~ before skulking off into a shadowy alleyway.'
		elseif selection == 2 then
			transformCardFromDeck(2,self.random,false,function ()
				self.description = '~\"Superb.\"~ NL The man injects you with three unknown substances and pulls out a notepad. As you begin to feel light-headed, he starts to frantically write down notes. NL Losing track of time completely, by the time you regain your senses, the shady character has disappeared.'
			end)
		else
			obtainRelic(MutagenicStrength:new())
			self.description = '~\"Marvelous.\"~ NL You quaff the mysterious substance. Immediately, you are invigorated and feel your muscle fibers @twitch.@'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

ForgottenAltar = TextEvent:new{name='Forgotten Altar',screen='intro',hpLoss=0}
function ForgottenAltar:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'In front of you sits an altar to a forgotten god. NL Atop the altar sits an ornate female statue with arms outstretched. NL She calls out to you, demanding sacrifice.'
	self.hpLoss = ascension >= 15 and math.floor(player.maxHp*0.35+0.5) or math.floor(player.maxHp*0.25+0.5)
	self.options = {
		{description='[Offer: Golden Idol] #5#Obtain a special Relic. #3#Lose Golden Idol.',item=BloodyIdol},
		{description='[Sacrifice] #5#Gain 5 Max HP. #3#Lose '..self.hpLoss..' HP.'},
		{description='[Desecrate] #3#Become Cursed - Decay.',cardItem=CardItem:new{card=Decay:new()}},
	}
	if not hasRelic(GoldenIdol) then
		self.options[1] = {description='[Locked] Requires: Golden Idol.',locked=true}
	end
end

function ForgottenAltar:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			loseRelic(getRelic(GoldenIdol))
			obtainRelic(BloodyIdol:new())
			self.description = 'As you gently set the idol onto the altar a #10#cold#12# wind swirls throughout the room. NL The arms of the statue begin to discolor and crumble. NL NL Your #4#golden idol#12# begins to dull in color and begins bleeding from its eyes. NL The bleeding never ceases.'
		elseif selection == 2 then
			player:increaseMaxHp(5)
			player:damage(player,self.hpLoss)
			self.description = 'You stand on the altar and cut your wrists. NL As the #2#blood#12# spills out in sacrifice, the arms of the statue reach out and close around your eyes. NL Everything goes dark. NL You wake up a short time later feeling a new potential surging through you.'
		else
			obtainCardWithEffect(Decay:new())
			self.description = 'You lash out and smash the statue in front of you, breaking the magical hold the room had placed upon you. NL A dark wail echoes all around you, and you can feel the ~#8#cursed~ ~magic#12#~ seep into your bones.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

CouncilOfGhosts = TextEvent:new{name='Council of Ghosts',screen='intro',cardAmt=5,maxHpLoss=0}
function CouncilOfGhosts:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'As you continue your ascent, ~#8#thick~ ~black~ ~smoke#12#~ begins to billow out of the ground and walls around you, coalescing into three masked forms that start to speak. NL NL ~\"Another~ ~puppet~ ~of~ ~#4#Neow#12#~ ~I~ ~think.\"~ NL @#2#\"AGREED!@ @SHE@ @ALWAYS@ @MAKES@ @THE@ @FUNNEST@ @TOYS!\"#12#@ NL NL You notice an over-sized grin as the third addresses you. NL \"Ignore the others... Would you like a taste of our ~#4#power?\"~'
	self.cardAmt = ascension >= 15 and 3 or 5
	self.maxHpLoss = math.min(math.ceil(player.maxHp / 2), player.maxHp - 1)
	self.options = {
		{description='[Accept] #5#Receive '..self.cardAmt..' Apparition. #3#Lose '..self.maxHpLoss..' Max HP.',cardItem=CardItem:new{card=Apparition:new()}},
		{description='[Refuse]'},
	}
end

function CouncilOfGhosts:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:decreaseMaxHp(self.maxHpLoss)
			local startX,stepX = placeCardsInARow(self.cardAmt)
			for i=1,self.cardAmt do
				obtainCardWithEffect(Apparition:new(),startX+stepX*i)
			end
			self.description = '#4#\"Excellent!\"#12# NL As the ghostly shape speaks, you notice its large mouth opening wider and wider. ~#8#Thick~ ~black~ ~smoke#12#~ spews forth and envelops the room. You cannot see or breathe... NL NL Just before you lose consciousness, the sensation stops. NL NL Whatever those things were, they are gone now. You continue on, feeling rather #10#hollow.'
		else
			self.description = '\"How disappointing...\" NL ~\"You~ ~will~ ~join~ ~us~ ~sooner~ ~or~ ~later.\"~ NL @#2#\"HA@ @HA@ @HA@ @HAHAHA!\"#12#@ NL NL The shapes fade away, leaving only the unnerving laughter ringing in your ears.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheNest = TextEvent:new{name='The Nest',screen='intro',goldAmt=99}
function TheNest:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'A long line of ~#10#hooded~ ~figures#12#~ can be seen entering NL an #8#unassuming cathedral.'
	self.goldAmt = ascension >= 15 and 50 or 99
	self.options = {
		{description='[Continue]'},
	}
end

function TheNest:onOption(selection)
	if self.screen == 'intro' then
		self.description = 'Naturally, you join the line and are quickly surrounded by #2#Cultists!#12# NL They ignore you as they gleefully @chant@ and ~wave~ their weapons around. NL @#2#\"MURDER!!@ @MURDER@ @MURDER!!\"#12#@ NL ~#10#\"CAW~ ~CAW~ ~CAAAAAWWW!\"#12#~ NL @\"#2#MURDER!@ @MURDER@ @MUURDER!!\"#12#@ NL ~#10#\"CAAW~ ~CAW~ ~CAAAAAAWW!!\"#12#~ NL You eye a #4#Donation Box...'
		self.screen = 'donationbox'
		self.options = {
			{description='[Smash and Grab] #5#Obtain '..self.goldAmt..' Gold.'},
			{description='[Stay in Line] #5#Obtain #12#Ritual Dagger. #3#Lose 6 HP.',cardItem=CardItem:new{card=RitualDagger:new()}},
		}
	elseif self.screen == 'donationbox' then
		if selection == 1 then
			gainGold(self.goldAmt)
			self.description = 'They didn\'t even notice.'
		else
			player:damage(player,6)
			obtainCardWithEffect(RitualDagger:new())
			self.description = 'You decide to stay in line (out of fear) to see what will happen. NL Eventually, you are face-to-face with the leader. A well-dressed cultist hands you an #4#Ornate Dagger#12#. Like the others before you, you slash your forearm and let the blood drip into a misshapen bowl. NL NL The cultists @chant@ and @holler@ for you! NL ~#10#\"CAAW~ ~CAW~ ~CAAAAAAWW!!\"#12#~ NL You chant, too. Why not?'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheLibrary = TextEvent:new{name='The Library',screen='intro',healAmt=0}
function TheLibrary:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'You come across an ornate building which appears abandoned. NL A plaque that has been torn free from a wall is on the floor. It reads, #10#\"THE LIBRARY\"#12#. NL Inside, you find countless rows of scrolls, manuscripts, and books. NL You pick one and cozy yourself into a chair for some quiet time.'
	self.healAmt = ascension >= 15 and math.floor(player.maxHp*0.2+0.5) or math.floor(player.maxHp*0.33+0.5)
	self.options = {
		{description='[Read] #5#Choose 1 of 20 cards to add to your deck.'},
		{description='[Sleep] #5#Heal '..self.healAmt..' HP.'},
	}
end

function TheLibrary:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			local cardTypes = {}
			for i=1,20 do
				local cardType
				repeat
					cardType = getPlayerCardType(self.random,generateCardRarity(self.random))
				until table.indexOf(cardTypes,cardType) == nil
				cardTypes[i] = cardType
			end
			local cardItems = table.map(cardTypes,function (cardType)
				return CardItem:new{card=cardType:new(),isNotInHand=true,x=0,y=168}
			end)
			openWindowAbove(CardGridSelectWindow:new{cardItems=cardItems,title='Add a card to your deck',max=1},function (cardItems)
				for _, cardItem in ipairs(cardItems) do
					cardItem.large = false
					addEffect(CardEffect:new{cardItem=cardItem,pauseDuration=1,duration=20,tx=240,ty=0})
					obtainCard(cardItem.card)
				end
				local words = {
					'The story is about an insect-controlling teenage girl who aspires to become a hero. The book is filled with creative uses of powers, combat strategies, and varying perspectives. NL Satisfying.',
					'The story is about a man who journeyed beyond the stars and found himself stuck on a desolate foreign planet. Ingenuity, luck, perseverance, and humor to retain his sanity were his tools to return home. NL Fascinating.',
					'The story takes place in a giant isolated building underground as the outside conditions have become unbearable. The novel is mired with conspiracies, propaganda, and injustice. You ponder if similar dynamics are at play within the Spire. NL Unsettling.',
				}
				self.description = words[self.random:randInt(#words)]
			end)
		else
			player:heal(self.healAmt)
			self.description = 'Reading is for chumps. NL You doze off in a comfy chair instead. NL ~Zzz...~ ~zzz...~ ~..Zz....~ NL You wake up feeling refreshed.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

TheMausoleum = TextEvent:new{name='The Mausoleum',screen='intro',alwaysCurse=false}
function TheMausoleum:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'Venturing through a series of tombs, you are faced with a large sarcophagus ~studded~ ~with~ ~gems~ in the center of a circular room. NL You cannot make out the writing on the coffin, however, you do notice ~#8#black~ ~fog#12#~ seeping out from the sides.'
	self.alwaysCurse = ascension >= 15
	self.options = {
		{description='[Open Coffin] #5#Obtain a Relic. #3#'..(self.alwaysCurse and '100' or '50')..'%: Become Cursed - Writhe.',cardItem=CardItem:new{card=Writhe:new()}},
		{description='[Leave]'},
	}
end

function TheMausoleum:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			local relic = getRandomNonBottleRelic(self.random)
			obtainRelic(relic)
			if self.alwaysCurse or self.random:rand() < 0.5 then
				obtainCardWithEffect(Writhe:new())
				self.description = 'You push open the coffin. As you do, ~#8#black~ ~fog#12#~ spews forth and covers the entire room! Inside, you find no body, only a ~#4#relic#12#.~ You take it and move onwards, @#2#coughing@ @violently.@'
			else
				self.description = 'You push open the coffin. The fog dissipates harmlessly. Inside, you find the mortal remains of a decorated soldier grasping an old #yrelic. You pilfer it and move on.'
			end
		else
			self.description = 'You continue along your way, leaving the forgotten dead undisturbed.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

Vampires = TextEvent:new{name='Vampires(?)',screen='intro',hasVial=false,maxHpLoss=0}
function Vampires:init()
	self.random = makeRand(act.id,room.id,1)
	self.description = 'Navigating an unlit street, you come across several hooded figures in the midst of some dark ritual. As you approach, they turn to you in eerie unison. The tallest among them bares fanged teeth and extends a long, pale hand towards you. NL ~\"Join~ ~us~ ~'..player:getPronouns().vampires:gsub(' ','~ ~')..',~ ~and~ ~feel~ ~the~ ~warmth~ ~of~ ~the~ ~Spire.\"~'
	self.maxHpLoss = math.min(math.ceil(player.maxHp * 0.3), player.maxHp - 1)
	self.options = {
		{description='[Accept] #5#Remove all Strikes. Receive 5 Bites. #3#Lose '..self.maxHpLoss..' Max HP.',cardItem=CardItem:new{card=Bite:new()}},
		{description='[Refuse]'},
	}
	if hasRelic(BloodVial) then
		self.hasVial = true
		table.insert(self.options,2,{description='[Lose '..BloodVial.name..'] #5#Remove all Strikes. Receive 5 Bites.',cardItem=CardItem:new{card=Bite:new()}})
	end
end

function Vampires:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			player:decreaseMaxHp(self.maxHpLoss)
			for i=#deck,1,-1 do
				if table.anyMatch(deck[i].tags,function (tag) return tag == 'basicStrike' end) then
					removeCardByIndex(i)
				end
			end
			local startX,stepX = placeCardsInARow(5)
			for i=1,5 do
				obtainCardWithEffect(Bite:new(),startX+stepX*i)
			end
			self.description = 'The tall figure grabs your arm, pulls you forward, and sinks his fangs into your neck. You feel a @dark@ @force@ pour into your neck and @course@ through your body. NL ... NL You wake up some time later, alone. An intense ~hunger~ passes through your belly. You #2#must feed...'
		elseif selection == 2 and self.hasVial then
			loseRelic(getRelic(BloodVial))
			local startX,stepX = placeCardsInARow(5)
			local x = startX
			for i=1,5 do
				obtainCardWithEffect(Bite:new(),startX+stepX*i)
				x = x + stepX
			end
			self.description = 'The pale figures gasp as you take out the #4#Blood Vial#12#. NL ~\"The~ ~master\'s~ ~blood...~ ~the~ ~master\'s~ ~blood!~ @THE@ @MASTER\'S@ @BLOOD!\"@ NL They all chant fervently as the tall one bows before you. \"Drink from His blood, and become one with ~#4#Him#12#.\"~ NL The chant growing louder, you consume the contents of the vial. Your vision immediately ~warps~ and fades to darkness. NL NL You wake up some time later, alone. An intense ~hunger~ passes through your belly. You #2#must feed.'
		else
			self.description = 'You step back and raise your weapon in defiance. The tall figure sighs. \"Very well.\" The entire group of hooded figures morph into a thick black fog that flows away from you. NL You are alone once more.'
		end
		self.screen = 'leave'
		self.options = {{description='[Leave]'}}
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

MaskedBandits = CombatTextEvent:new{name='Masked Bandits',spriteBank=5,screen='intro',encounter=BanditsEncounter,enemyKilled=false}
function MaskedBandits:init()
	self.rewardRandom = makeRand(act.id,room.id,1)
	self.description = 'You encounter a group of bandits wearing large #2#red masks#12#. NL \"Hello, pay up to pass... a reasonable fee of @ALL@ your #4#gold#12# will do! Heh heh!\"'
	self.options = {
		{description='[Pay] #3#Lose ALL#12# of your #4#Gold.'},
		{description='[Fight!]'},
	}
	setupEnemies(self.encounter)
end

function MaskedBandits:drawForeground()
	if self.screen ~= 'fight' then
		player:drawImage()
	end
	if self.screen ~= 'fight' and not self.enemyKilled then
		for _, enemy in ipairs(enemies) do
			enemy:drawImage()
		end
	end
end

function MaskedBandits:onOption(selection)
	if self.screen == 'intro' then
		if selection == 1 then
			loseGold(gold)
			self.description = 'Hehehe.. Thanks for the #4#gold#12#! NL Oh, I love #4#gold#12#. It\'s so nice. NL ~#4#shiny~ ~shiny#12#~ chits they are!'
			self.screen = 'paid1'
			self.options = {{description='[Continue]'}}
		else
			roomActionType = 'eventCombat'
			self.screen = 'fight'
			startCombat(self.encounter)
		end
	elseif self.screen == 'paid1' then
		self.description = 'Hey #10#Bear#12#, hey! NL This guy gave us all his #4#gold#12#! What a sucker, right? NL Get this, I just had to ask nicely. Who knew?! NL I certainly didn\'t! What a chump!'
		self.screen = 'paid2'
		self.options = {{description='[Continue]'}}
	elseif self.screen == 'paid2' then
		self.description = 'Gang, let\'s all have a laugh for this wondrous occasion! NL @Hahaah@ NL @Ho@ @HOH@ ~hoho!~ NL ~Hoh!~'
		self.screen = 'paid3'
		self.options = {{description='[Leave]'}}
	elseif self.screen == 'paid3' then
		self.description = 'Oh? You\'re still here? NL Did you overhear something? Didn\'t think so. NL @#2#*snerk*#12#@ ~...loser....~ @Hahaha@ ~haaah~'
		self.screen = 'leave'
		completeRoom()
		openWindowAbove(MapWindow:new())
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function MaskedBandits:onCombatEnd(escaped)
	saveGame(true,escaped and 1 or 0)
	self:load(escaped and 1 or 0)
end

function MaskedBandits:load(escaped)
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
		addGoldReward(rewards,random:randInt(25,35))
		generateCardRewards(rewards,random)
		addRelicReward(rewards,RedMask:new())
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end

TheColosseum = TextEvent:new{name='The Colosseum',screen='intro'}
function TheColosseum:init()
	self.rewardRandom = makeRand(act.id,room.id,1)
	self.description = '@Thwack!!!@ NL .. NL ...... NL ... NL ~You~ ~were~ ~knocked~ ~unconscious...~'
	self.options = {
		{description='[Continue]'},
	}
end

function TheColosseum:isAvailable()
	return currentRoomY-1 > #stsMap/2
end

function TheColosseum:onOption(selection)
	if self.screen == 'intro' then
		self.description = '~Groggy~ and with a @throbbing@ head, you awaken to find yourself thrown in the center of a massive stadium with an overflowing audience of #10#Slavers#12#, #8#Cultists#12#, and other denizens of the City! NL ' ..
				' NL An armored giant with a #4#golden crown#12# bellows at you from atop, NL @\"WE@ @NOW@ @BEGIN@ @THE@ @4200TH@ @COMBAT!!!!\"@ NL A gate on the opposite side opens...'
		self.screen = 'beforeFight1'
		self.options = {{description='[Fight]'}}
	elseif self.screen == 'beforeFight1' then
		roomActionType = 'eventCombat'
		self.screen = 'fight1'
		self.spriteBank = 1
		startCombat(ColosseumSlaversEncounter)
	elseif self.screen == 'beforeFight2' then
		if selection == 1 then
			self.screen = 'leave'
			self.options = {self.options[1]}
			completeRoom()
			openWindowAbove(MapWindow:new())
		else
			roomActionType = 'eventCombat'
			self.screen = 'fight2'
			self.spriteBank = 1
			startCombat(ColosseumNobsEncounter)
		end
	else
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function TheColosseum:onCombatEnd(escaped)
	if self.screen == 'fight1' then
		roomActionType = 'event'
		self.spriteBank = 0
		nearestWindow:onWindowOpen()
		self.screen = 'beforeFight2'
		self.description = '@\"WELL@ @DONE,@ @WEAKLING!\"@ NL The giant mock claps whilst he riles up the crowd with exaggerated gestures. NL ~#4#Gold#12#~ ~and~ ~#4#confetti#12#~ ~shower~ ~you!~ NL @\"TIME@ @FOR@ @THE@ @REAL@ @CHALLENGE!!\"@ NL The last battle left a small opening in the Colosseum\'s wall, you can easily escape through there while everyone is distracted. NL Do you stay and fight?'
		self.options = {
			{description='[COWARDICE] Escape.'},
			{description='[VICTORY] A powerful fight with many rewards.'},
		}
	else
		saveGame(true,escaped and 1 or 0)
		self:load(escaped and 1 or 0)
	end
end

function TheColosseum:load(escaped)
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
		addGoldReward(rewards,100)
		generateCardRewards(rewards,random)
		addRelicReward(rewards,getRandomRelic(random,'uncommon'))
		addRelicReward(rewards,getRandomRelic(random,'rare'))
		generatePotionRewards(rewards,random)
		openWindowAbove(RewardWindow:new{rewards=rewards})
	end
end
