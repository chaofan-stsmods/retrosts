-- creature
---@diagnostic disable: lowercase-global

Creature = Object:new{
	hp=100,maxHp=100,x=0,y=0,width=3,height=3,block=0,powerIndex=0,powers={},alive=true,visible=true,
	applyPowers=noop,
	onCombatStart=noop,
	onTurnEnd=noop,
	drawImage=noop,
}
function Creature:new(o)
	o = o or {}
	o.powers={}
	if o.maxHp then
		o.hp = o.maxHp
	elseif o.hp then
		o.maxHp = o.hp
	end
	return Object.new(self,o)
end

function Creature:tick()
	if self.visible then
		self:drawImage()
		self:drawHealthBar()
		self:drawPowers()
	end
end

function Creature:drawHealthBar()
	local healthWidth = self.hp*(self.width*8-2)//self.maxHp
	rect(self.x+1,self.y+8*self.height+1,healthWidth,6,2)
	local damageWidth = self.width*8-2-healthWidth
	rect(self.x+1+healthWidth,self.y+8*self.height+1,damageWidth,6,0)

	if self.block > 0 then
		mapColor(1,10)
	end
	spr(35,self.x,self.y+8*self.height,0)
	for i = 1,self.width-2 do
		spr(36,self.x+8*i,self.y+8*self.height,0)
	end
	spr(37,self.x+8*self.width-8,self.y+8*self.height,0)
	if self.block > 0 then
		resetColor(1)
		spr(47,self.x-4,self.y+8*self.height,0)
		local blockStr = tostring(self.block)
		local strWidth = strWidth(blockStr)
		printShadowed(blockStr,self.x-4-strWidth,self.y+8*self.height+1,11)
	end

	local hpStr = self.hp .. '/' .. self.maxHp
	local strWidth = strWidth(hpStr)
	printShadowed(hpStr,self.x+4*self.width-strWidth/2,self.y+8*self.height+1,12)
end

function Creature:drawPowers()
	local x = self.x
	local y = self.y+8*self.height+8
	for _, power in ipairs(self.powers) do
		spr(power.icon,x,y,0)
		if power.stackable and power.amount ~= 0 then
			local color = power.turnBased and 12 or (power.amount > 0 and 5 or 2)
			local left = power.amount > 0 and x+5 or x+1
			local width = print(tostring(power.amount),left,y+3,color,false,1,true)
			x = x+5+width
		else
			x = x+8
		end
		if x>self.x+self.width*8 then
			x = self.x
			y = y + 9
		end
	end
end

function Creature:damage(source,value,type)
	type = type or 'attack'
	if type ~= 'hploss' then
		if self.block > 0 then
			local blocked = math.min(value,self.block)
			self.block = self.block - blocked
			value = value - blocked
		end
	end
	self.hp = self.hp - value
	if self.hp < 0 then
		self.hp = 0
		self:die()
	end
end

function Creature:die()
	self.alive = false
	self.visible = false
end

function Creature:onTurnStart()
	self.block = 0
	for _, power in ipairs(self.powers) do
		power:onTurnStart()
	end
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
end

function Creature:removePower(power)
	for i = #self.powers,1,-1 do
		if self.powers[i] == power or getmetatable(self.powers[i]) == power then
			table.remove(self.powers,i)
			return
		end
	end
end
