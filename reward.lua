-- reward
---@diagnostic disable: lowercase-global

rewards = {}
selectedReward = 0
function reward()
    cls(0)
    sprmap(0,36,12,13,72,24,0)
    sprmap(0,34,16,2,56,16,0)
    local title = 'Rewards'
    local width = strWidth(title)
    printGlowed(title,120-width/2,19,12)
    drawRewards()
    rewardControls()
    tickEffects()
    tickTopBar(true)
end

function drawRewards()
    for i, reward in ipairs(rewards) do
        local y = 16+i*18
        if selectedReward == i then
            mapColor(14,13)
        end
        sprmap(0,49,11,2,76,y,0)
        if selectedReward == i then
            resetColor(14)
        end
        spr(reward.icon,79,y+4,0)
        print(reward.title,90,y+5,12,false,1,true)
    end
end

function rewardControls()
    if cursorOnTopBar then
        selectedReward = 0
        return
    end

    if selectedReward == 0 and #rewards > 0 then
        selectedReward = limit(selectedReward,1,#rewards)
    end
    
    if #rewards > 0 then
        if btnp(0) then
            selectedReward = limit(selectedReward-1,1,#rewards)
        elseif btnp(1) then
            selectedReward = limit(selectedReward+1,1,#rewards)
        end
    end

    if btnp(4) then
        collectReward()
    elseif btnp(5) then
        if room.completed then
            transferScreen('mapScreen')
        else
            backToRoom()
        end
    end
end

function collectReward()
    if selectedReward == 0 then
        return
    end

    local reward = rewards[selectedReward]
    if reward.type == 'gold' then
        gold = gold + reward.value
    elseif reward.type == 'key' then
        _G[reward.value] = true
    end

    table.remove(rewards,selectedReward)
    if #rewards == 0 then
        selectedReward = 0
    else
        selectedReward = limit(selectedReward,1,#rewards)
    end
end

-- generate

function generateRewards(random)
    rewards = {}
    table.insert(rewards,{title='100 G',icon=478,type='gold',value=100})
    table.insert(rewards,{title='Add a card to deck',icon=431,type='card'})
    table.insert(rewards,{title='Add a card to deck',icon=447,type='rareCard'})
    table.insert(rewards,{title='Emerald key',icon=462,type='key',value='emeraldKeyObtained'})
    table.insert(rewards,{title='Sapphire key',icon=463,type='key',value='sapphireKeyObtained'})
end
