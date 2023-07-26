-- card
---@diagnostic disable: lowercase-global

Card = Object:new{
	name='',description='',cost=0,type='attack',rarity='common',color='red',
	damage=0,baseDamage=0,block=0,baseBlock=0,magic=0,baseMagic=0,
	enemyTarget=false,playerTarget=false,toAllEnemy=false
}

function Card:copy()
	local result = shallowcopy(self)
	setmetatable(result,getmetatable(self))
	return result
end

function Card:use()
	return {}
end

function Card:canUse()
	return self.cost <= energy and not inEnemyTurn
end

function Card:applyPowers(target)
	local damage = self.baseDamage
	local block = self.baseBlock

	for _, power in ipairs(player.powers) do
		damage = power:onAttack(damage,target,self)
	end

	if target ~= nil then
		for _, power in ipairs(target.powers) do
			damage = power:onAttacked(damage,player,self)
		end
	end

	self.damage = math.floor(damage)
	self.block = math.floor(block)
end

function Card:resetPower()
	self.damage = self.baseDamage
	self.block = self.baseBlock
end

CardItem = Object:new{ x=0,y=136,tx=0,ty=136,card=nil,large=false,isNotInHand=false }
cardTypeToSprIndex = {attack=57,skill=58,power=59}
cardFaceColor = {2,1}
cardRarityColor = {basic={14,15},common={14,15},special={14,15},uncommon={10,9},rare={4,3}}
function CardItem:tick()
	self.x = lerp(self.x,self.tx,0.2)
	self.y = lerp(self.y,self.ty,0.2)
	local colorless = self.card.color == 'colorless'
	local l,t
	if self.large then
		l = self.x-28
		t = self.y-28
	else
		l = self.x-16
		t = self.y-20
	end
	drawCardBack(self.card,self.large,colorless,l,t)
	drawCost(self.card,colorless,l,t)
	drawTitle(self.card,self.large,l,t)
	drawDescription(self.card,self.card.description,l+3,t+10,self.large and 51 or 27,self.large and 999 or 4)
end

function drawCardBack(card,large,colorless,l,t)
	if not colorless then
		mapColor(14,cardFaceColor[1])
		mapColor(15,cardFaceColor[2])
	end
	mapColor(10,cardRarityColor[card.rarity][1])
	mapColor(9,cardRarityColor[card.rarity][2])
	if large then
		map(3,2,7,7,l,t,0)
		--spr(cardTypeToSprIndex[card.type],l+48,t,0)
	else
		map(10,2,4,5,l,t,0)
	end
	local typeLeft = card.cost >= -1 and l+8 or l
	spr(29,typeLeft,t-6,0)
	spr(cardTypeToSprIndex[card.type],typeLeft,t-6,0)
	if not colorless then
		resetColors{14,15}
	end
	resetColors{9,10}
end

function drawCost(card,colorless,l,t)
	t = t-5
	if card.cost >= -1 then
		spr(colorless and 46 or 45,l,t,0)
		local costStr = card.cost == -1 and 'X' or tostring(card.cost)
		local txtWidth = strWidth(costStr)
		local color = card:canUse() and 12 or 1
		printShadowed(costStr,l+4-txtWidth//2,t+1,color)
	end
end

function drawTitle(card,large,l,t)
	local titleStart = l+2
	local cardName = card.name
	if #cardName > 8 and not large then
		cardName = cardName:sub(1,8)
	end
	print(cardName,titleStart,t+2,card.rarity == 'rare' and 0 or 12,false,1,true)
end

function drawDescription(card,description,x,y,lineWidth,maxLine)
	maxLine = maxLine or 999
	local currentX = x
	local currentY = y
	local maxY = y+8*(maxLine-1)
	for word in description:gmatch('([^ ]+)') do
		if word == 'NL' then
			currentX = x
			currentY = currentY + 8
			if currentY > maxY then
				return
			end
		else
			local lastStart = 1
			local findStart,findEnd,findStr = findMinimal(word,{'({%d+})','(!%w!)'},lastStart)
			while findStart and findEnd and findStr do
				local strBeforeFind = word:sub(lastStart,findStart-1)
				if #strBeforeFind > 0 then
					currentX,currentY = moveLimitLineWidthAndPrint(strBeforeFind,currentX,currentY,x,lineWidth,maxY,12)
					if currentY > maxY then
						return
					end
				end
				if findStr:sub(1,1) == '{' then
					local sprId = tonumber(findStr:sub(2,#findStr-1))
					if sprId then
						currentX,currentY = moveLimitLineWidth(currentX,currentY,x,8,lineWidth)
						if currentY > maxY then
							return
						end
						spr(sprId,currentX,currentY-2,0)
						currentX = currentX + 8
					end
				elseif findStr:sub(1,1) == '!' then
					local type = findStr:sub(2,2)
					local base = 0
					local value = 0
					if type == 'D' then
						base = card.baseDamage
						value = card.damage
					elseif type == 'B' then
						base = card.baseBlock
						value = card.block
					elseif type == 'M' then
						base = card.baseMagic
						value = card.magic
					end
					local color = base > value and 5 or (base < value and type ~= 'M' and 3 or 12)
					currentX,currentY = moveLimitLineWidthAndPrint(tostring(value),currentX,currentY,x,lineWidth,maxY,color)
					if currentY > maxY then
						return
					end
				end
				lastStart = findEnd + 1
				findStart,findEnd,findStr = findMinimal(word,{'({%d+})','(!%w!)'},lastStart)
			end
			local strAfterFind = word:sub(lastStart,#word)
			if #strAfterFind > 0 then
				currentX,currentY = moveLimitLineWidthAndPrint(strAfterFind,currentX,currentY,x,lineWidth,maxY,12)
				if currentY > maxY then
					return
				end
			end
			currentX = currentX + 3
		end
	end
end

function findMinimal(str, patterns, init)
	local minimal = {nil}
	for i = 1, #patterns do
		local result = {string.find(str, patterns[i], init)}
		if minimal[1] == nil or (result[1] and result[1] < minimal[1]) then
			minimal = result
		end
	end
	return table.unpack(minimal)
end

function moveLimitLineWidth(currentX,currentY,x,width,lineWidth)
	if currentX == x and width > lineWidth then
		return currentX,currentY
	end
	if currentX - x + width > lineWidth then
		currentY = currentY + 8
		currentX = x
	end
	return currentX,currentY
end

function moveLimitLineWidthAndPrint(str,currentX,currentY,x,lineWidth,maxY,color)
	color = color or 12
	local strWidth = strWidth(str,false,true)
	currentX,currentY = moveLimitLineWidth(currentX,currentY,x,strWidth,lineWidth)
	if currentY > maxY then
		return currentX,currentY
	end
	print(str,currentX,currentY,color,false,1,true)
	currentX = currentX + strWidth
	return currentX,currentY
end
