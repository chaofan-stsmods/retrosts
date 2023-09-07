-- creature
---@diagnostic disable: lowercase-global

---@class Creature : Object
---@field visible boolean
Creature = {
	hp=100,maxHp=100,x=0,y=0,width=3,height=3,block=0,powerIndex=0,powers={},alive=true,visible=true,flipped=false,canInteract=true,color=nil,
	animations=nil,
	applyPowers=noop,
	onCombatStart=noop,
	drawImage=noop,
}
Object:new(Creature)
function Creature:new(o)
	o = o or {}
	o.powers = {}
	o.animations = {}
	if o.maxHp and not o.hp then
		o.hp = o.maxHp
	elseif o.hp and not o.maxHp then
		o.maxHp = o.hp
	end
	return Object.new(self,o)
end

function Creature:tick()
	if self.visible then
		local x,y = self.x,self.y
		local color = nil
		for _,animation in ipairs(self.animations) do
			self.x,self.y,color = animation(self.x,self.y,color)
		end
		if color ~= nil then
			self.color = color
			mapColors(color,color,color,color,color,color,color,color,color,color,color,color,color,color,color,color)
		end
		self:drawImage(self.x,self.y)
		if color ~= nil then
			self.color = nil
			resetColors{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
		end
		self.x,self.y = x,y
		if self.canInteract then
			self:drawHealthBar()
			self:drawPowers()
		end
	end
end

function Creature:drawHealthBar()
	local width = math.max(5,self.width)
	local x = self.x-(width-self.width)*4
	local y = self.y+1
	local healthWidth = self.hp*(width*8-2)//self.maxHp
	rect(x+1,y+8*self.height+1,healthWidth,6,2)
	local damageWidth = width*8-2-healthWidth
	rect(x+1+healthWidth,y+8*self.height+1,damageWidth,6,0)

	if self.block > 0 then
		mapColor(1,10)
	end
	mapColor(4,3)
	spr(37,x,y+8*self.height,0,1,1)
	resetColor(4)
	rect(x+8,y+8*self.height,8*(width-2),1,1)
	rect(x+8,y+8*self.height+1,8*(width-2),1,3)
	rect(x+8,y+8*self.height+7,8*(width-2),1,1)
	spr(37,x+8*width-8,y+8*self.height,0)
	pix(x+8*width-3,y+8*self.height+2,4)
	if self.block > 0 then
		resetColor(1)
		drawIcon(icons.Block,x-4,y+8*self.height)
		local blockStr = tostring(self.block)
		local strWidth = strWidth(blockStr)
		printShadowed(blockStr,x-strWidth/2+1,y+8*self.height-7,11)
	end

	local hpStr = self.hp .. '/' .. self.maxHp
	local strWidth = strWidth(hpStr)
	printShadowed(hpStr,x+4*width-strWidth/2,y+8*self.height+1,12)
end

function Creature:drawPowers()
	local width = math.max(5,self.width)
	local startX = self.x-(width-self.width)*4
	local x = startX
	local y = self.y+8*self.height+9
	for _, power in ipairs(self.powers) do
		x = x + power:drawImage(x,y)
		if x>self.x+width*8 then
			x = startX
			y = y + 9
		end
	end
end

function Creature:increaseMaxHp(value)
	self.maxHp = self.maxHp + value
	self:heal(value)
end

function Creature:decreaseMaxHp(value)
	self.maxHp = self.maxHp - value
	if self.hp > self.maxHp then
		self.hp = self.maxHp
	end
	if self.maxHp < 0 then
		self.maxHp = 0
		self:die()
	end
end

function Creature:heal(value)
	value = self:triggerReducerEvent('onBeforeHeal',value)
	value = math.floor(value)
	local oldHp = self.hp
	self.hp = math.min(self.hp+value,self.maxHp)
	if value > 0 then
		addEffect(TextEffect:new{x=self.x+self.width*4,y=self.y+self.height*2-30,duration=60,text=tostring(value),color=5,ySpeed=0.5})
	end
	self:triggerEvent('onHealed',value,self.hp-oldHp)
end

function Creature:damage(source,value,type,action)
	type = type or 'attack'
	if (not source.alive and type == 'attack') or not self.canInteract then
		return
	end
	value = self:triggerReducerEvent('onBeforeDamaged',value,source,type,action)
	if type ~= 'hpLoss' then
		if self.block > 0 then
			local blocked = math.min(value,self.block)
			self.block = self.block - blocked
			value = value - blocked
			if self.block == 0 then
				source:triggerEvent('onBreakBlock',self)
			end
			if value == 0 then
				addEffect(TextEffect:new{x=self.x+self.width*4,y=self.y,text='Blocked',color=11,ySpeed=-0.5})
				addEffect(HitParticleEffect:new{x=self.x+self.width*4,y=self.y+self.height*4,colors={11,11,10}})
			end
		end
	end
	value = self:triggerReducerEvent('onBeforeHpLoss',value,source,type,action)
	value = source:triggerReducerEvent('onBeforeReduceHp',value,self,type,action)
	if value > 0 then
		addEffect(TextEffect:new{x=self.x+self.width*4,y=self.y,text=tostring(value),color=3,ySpeed=-0.5})
		if type ~= 'hpLoss' then
			addEffect(HitParticleEffect:new{x=self.x+self.width*4,y=self.y+self.height*4,colors={4,4,3}})
		end
		self:addDamagedAnimation(source)
		if action then
			action.damageDealt = (action.damageDealt or 0) + value
		end
		self.hp = self.hp - value
		if self.hp <= 0 then
			self.hp = 0
			self:die()
			if action then
				action.numKilled = (action.numKilled or 0) + 1
			end
		end
	end
	self:triggerEvent('onDamaged',value,source,type,action)
	source:triggerEvent('onDamageDealt',value,self,type,action)
end

function Creature:die()
	self.alive = false
	self.visible = false
	self.canInteract = false
	self:triggerEvent('onDeath',self)
end

function Creature:triggerEvent(name,...)
	for _, power in ipairs(self.powers) do
		if power[name] then
			power[name](power,...)
		end
	end
end

function Creature:triggerReducerEvent(name,value,...)
	for _, power in ipairs(self.powers) do
		if power[name] then
			value = power[name](power,value,...) or value
		end
	end
	return value
end

function Creature:triggerConditionEvent(name,default,...)
	for _, power in ipairs(self.powers) do
		if power[name] then
			local b = power[name](power,...)
			if b ~= nil then
				return b
			end
		end
	end
	return default
end

function Creature:onTurnStart(turn)
	addAction(AnonymousAction:new(function ()
		self.block = self.block - self:triggerReducerEvent('onBeforeTurnStartLoseBlock',self.block)
	end))
	self:triggerEvent('onTurnStart',turn)
end

function Creature:onTurnEnd()
	self:triggerEvent('onTurnEnd')
end

function Creature:addPower(power)
	self.powerIndex = self.powerIndex + 1
	power.powerIndex = self.powerIndex
	table.insert(self.powers,power)
	table.sort(self.powers,function (a, b)
		return a.priority == b.priority and a.powerIndex < b.powerIndex or a.priority < b.priority
	end)
end

function Creature:getPower(powerType)
	for i = #self.powers,1,-1 do
		if getmetatable(self.powers[i]) == powerType then
			return self.powers[i]
		end
	end
	return nil
end

function Creature:removePower(power)
	for i = #self.powers,1,-1 do
		if self.powers[i] == power or getmetatable(self.powers[i]) == power then
			table.remove(self.powers,i)
			return
		end
	end
end

function Creature:addDamagedAnimation(source)
	local timer = 0
	local xOffset = source.x < self.x and 6 or -6
	local animation
	animation = function (x,y,c)
		timer = timer + 1
		x = x + xOffset
		xOffset = lerp(xOffset,0,0.2)
		if math.abs(xOffset) < 0.5 then
			table.remove(self.animations,table.indexOf(self.animations,animation))
		end
		return x,y,timer % 2 == 0 and 2 or c
	end
	table.insert(self.animations,animation)
end

function Creature:addDebuffAnimation()
	local timer = 60
	local animation
	animation = function (x,y,c)
		local xOffset = math.sin((60-timer)*0.2)*(timer/10)
		timer = timer - 1
		if timer == 0 then
			table.remove(self.animations,table.indexOf(self.animations,animation))
		end
		return x+xOffset,y,c
	end
	table.insert(self.animations,animation)
end

function Creature:addJumpAnimation()
	local timer = 60
	local animation
	animation = function (x,y,c)
		local yOffset = timer * (timer - 60) / 90
		timer = timer - 1
		if timer == 0 then
			table.remove(self.animations,table.indexOf(self.animations,animation))
		end
		return x,y+yOffset,c
	end
	table.insert(self.animations,animation)
end
