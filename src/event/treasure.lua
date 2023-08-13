-- campfire
---@diagnostic disable: lowercase-global

TreasureEvent = Event:new{screen='entry',spritebank=2,chestType='small',random=nil}
function TreasureEvent:new()
	local o = Event.new(self)
	o.random = makeRand(act.id,room.id,1)
	local roll = o.random:randInt(0,99)
	if roll < 50 then
		o.type = 'small'
	elseif roll < 83 then
		o.type = 'medium'
	else
		o.type = 'large'
	end
	table.insert(o.options,{description='[Open]'})
	table.insert(o.options,{description='[Leave]'})
	return o
end

function TreasureEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	if self.type == 'small' then
		sprmap(12,46,4,3,150,64,0)
	elseif self.type == 'medium' then
		sprmap(16,45,4,4,150,56,0)
	elseif self.type == 'large' then
		sprmap(20,46,5,3,150,64,8)
	end
end

function TreasureEvent:onOption(selection)
	if selection == 1 then
		self:showRewards()
	elseif selection == 2 then
		completeRoom()
		openWindowAbove(MapWindow:new())
	end
end

function TreasureEvent:showRewards()
	local goldAmount,goldChance = 0,0;
	local commonChance,uncommonChance = 0,0;

	if self.type == 'small' then
		goldAmount,goldChance = 25,50
		commonChance,uncommonChance = 75,25
	elseif self.type == 'medium' then
		goldAmount,goldChance = 50,35
		commonChance,uncommonChance = 35,50
	elseif self.type == 'large' then
		goldAmount,goldChance = 75,50
		commonChance,uncommonChance = 0,75
	end

	local rewards = {}
	local roll = self.random:randInt(0,99)
	if roll < goldChance then
		addGoldReward(rewards,self.random:randInt(math.floor(goldAmount*0.9),math.floor(goldAmount*1.1)))
	end

	local tier = 'rare'
	if roll < commonChance then
		tier = 'common'
	elseif roll < commonChance + uncommonChance then
		tier = 'uncommon'
	end
	addRelicReward(rewards,getRelicTypeByTier(tier):new())

	if not sapphireKeyObtained then
		table.insert(rewards,{title='Sapphire key',icon=468,type='key',value='sapphireKeyObtained',link=rewards[#rewards],showLink=true})
		rewards[#rewards-1].link = rewards[#rewards]
	end

	openWindowAbove(RewardWindow:new{rewards=rewards})
	completeRoom()
end
