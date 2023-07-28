-- reward
---@diagnostic disable: lowercase-global

RewardWindow = Window:new{rewards={},selection=0,name='RewardWindow'}
function RewardWindow:new(rewards)
    o = {rewards=rewards}
    return Window.new(self,o)
end

function RewardWindow:onOpen()
    queueSync(2,0)
    queueSync(1|4,1)
end

function RewardWindow:tick()
    sprmap(0,36,12,13,72,24,0)
    sprmap(0,34,16,2,56,16,0)
    local title = 'Rewards'
    local width = strWidth(title)
    printGlowed(title,120-width/2,19,12)
    self:drawRewards()
    self:rewardControls()
    tickEffects()
    tickTopBar(true)
end

function RewardWindow:drawRewards()
    for i, reward in ipairs(self.rewards) do
        local y = 16+i*18
        if self.selection == i then
            mapColor(14,13)
        end
        sprmap(0,49,11,2,76,y,0)
        if self.selection == i then
            resetColor(14)
        end
        spr(reward.icon,79,y+4,0)
        print(reward.title,90,y+5,12,false,1,true)
    end
end

function RewardWindow:rewardControls()
    if cursorOnTopBar then
        self.selection = 0
        return
    end

    if self.selection == 0 and #self.rewards > 0 then
        self.selection = limit(self.selection,1,#self.rewards)
    end

    if #self.rewards > 0 then
        if btnp(0) then
            self.selection = limit(self.selection-1,1,#self.rewards)
        elseif btnp(1) then
            self.selection = limit(self.selection+1,1,#self.rewards)
        end
    end

    if btnp(4) then
        self:collectReward()
    elseif btnp(7) then
        openWindowAbove(MapWindow:new())
    end
end

function RewardWindow:collectReward()
    if self.selection == 0 then
        return
    end

    local reward = self.rewards[self.selection]
    if reward.type == 'gold' then
        gold = gold + reward.value
        self:collectRewardComplete()
    elseif reward.type == 'key' then
        _G[reward.value] = true
        self:collectRewardComplete()
    elseif reward.type == 'card' then
        openWindowAbove(CardRewardWindow:new{cards=reward.value},function (card)
            if card then
                table.insert(deck,card)
                self:collectRewardComplete()
            end
        end)
    end
end

function RewardWindow:collectRewardComplete()
    table.remove(self.rewards,self.selection)
    if #self.rewards == 0 then
        self.selection = 0
        openWindowAbove(MapWindow:new())
    else
        self.selection = limit(self.selection,1,#self.rewards)
    end
end

-- generate

function generateRewards(random)
    local rewards = {}
    table.insert(rewards,{title='100 G',icon=478,type='gold',value=100})
    table.insert(rewards,{title='Add a card to deck',icon=431,type='card',value={Strike:new(),Defend:new(),Bash:new()}})
    table.insert(rewards,{title='Add a card to deck',icon=447,type='card',value={Strike:new(),Defend:new(),Bash:new()}})
    table.insert(rewards,{title='Emerald key',icon=462,type='key',value='emeraldKeyObtained'})
    table.insert(rewards,{title='Sapphire key',icon=463,type='key',value='sapphireKeyObtained'})
    return rewards
end

-- cardselect
CardRewardWindow = Window:new{name='CardRewardWindow',cards={},selection=0,single=false}
function CardRewardWindow:onOpen()
    queueSync(2,0)
    queueSync(1|4,1)
    local replace = false
    for i, card in ipairs(self.cards) do
        if getmetatable(card) ~= CardItem then
            if not replace then
                replace = true
                self.cards = shallowcopy(self.cards)
            end
            self.cards[i] = CardItem:new{x=120,y=68,tx=120,ty=68,card=card,isNotInHand=true}
        end
    end
end

function CardRewardWindow:tick()
    sprmap(0,34,16,2,56,16,0)
    local title = 'Choose a Card'
    local width = strWidth(title)
    printGlowed(title,120-width/2,19,12)
    self:drawCards()
    self:cardRewardControls()
    tickEffects()
    tickTopBar(true)
end

function CardRewardWindow:drawCards()
    local startX = 120-(48*#self.cards-48)/2
    for i, cardItem in ipairs(self.cards) do
        local x = startX-48+i*48
        cardItem.tx = x
        cardItem.large = self.selection==i
        cardItem:tick()
    end
end

function CardRewardWindow:cardRewardControls()
    if cursorOnTopBar then
        self.selection = 0
        return
    end

    if self.selection == 0 and #self.cards > 0 then
        self.selection = limit(self.selection,1,#self.cards)
    end

    if #self.cards > 0 then
        if btnp(2) then
            self.selection = limit(self.selection-1,1,#self.cards)
        elseif btnp(3) then
            self.selection = limit(self.selection+1,1,#self.cards)
        end
    end

    if btnp(4) then
        self:close(self.cards[self.selection].card)
    elseif btnp(5) then
        self:close(nil)
    end
end
