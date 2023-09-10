-- effect
---@diagnostic disable: lowercase-global

---@type Effect[]
effects = {}
---@type Effect[]
pendingEffects = {}
local tickingEffect = false
function tickEffects()
	tickingEffect = true
	for i=#effects,1,-1 do
		effects[i]:tick()
		if effects[i].isDone then
			table.remove(effects,i)
		end
	end
	tickingEffect = false
	for i=#pendingEffects,1,-1 do
		table.insert(effects,pendingEffects[i])
		table.remove(pendingEffects,i)
	end
end

function addEffect(effect)
	if tickingEffect then
		table.insert(pendingEffects,effect)
	else
		table.insert(effects,effect)
	end
end

---@class Effect : Action
Effect = Action:new()

TextEffect = Effect:new{duration=120,color=2,xSpeed=0,ySpeed=0,text='',x=120,y=68,small=true,scale=1,shadow=nil}
function TextEffect:tick()
	if self.shadow then
		printShadowed(self.text,self.x-strWidth(self.text,false,self.small,self.scale)/2,self.y,self.color,self.shadow,self.scale,self.small)
	else
		print(self.text,self.x-strWidth(self.text,false,self.small,self.scale)/2,self.y,self.color,false,self.scale,self.small)
	end
	self.x = self.x + self.xSpeed
	self.y = self.y + self.ySpeed
	Effect.tick(self)
end

CardEffect = Effect:new{duration=50,cardItem=nil,tx=0,ty=0,pauseDuration=30}
function CardEffect:tick()
	self.pauseDuration = self.pauseDuration - 1
	if self.pauseDuration == 0 then
		self.cardItem.tx = self.tx
		self.cardItem.ty = self.ty
	end
	self.cardItem:tick()
	Effect.tick(self)
	if math.abs(self.tx - self.cardItem.x) < 2 and math.abs(self.ty - self.cardItem.y) < 2 then
		self.isDone = true
	end
end

CreatureEffect = Effect:new{target=nil,duration=120,xSpeed=0,ySpeed=0,x=120,y=68}
function CreatureEffect:tick()
	self.target.x = self.x
	self.target.y = self.y
	self.target:drawImage()
	self.x = self.x + self.xSpeed
	self.y = self.y + self.ySpeed
	Effect.tick(self)
end

AnonymousEffect = Effect:new{duration=30,callback=nil}
function AnonymousEffect:tick()
	local result = nil
	if self.callback then
		result = self.callback(self.duration)
	end
	if result == nil then
		Effect.tick(self)
	else
		self.isDone = result
	end
end

HitParticleEffect = Effect:new{duration=50,x=0,y=0,colors=nil,particles=nil}
function HitParticleEffect:new(o)
	o = o or {}
	o.colors = o.colors or {4}
	o.particles = {}
	for i=1,30 do
		local r = effectRandom:rand() * math.pi * 2
		local s = effectRandom:rand() * 1.6 + 1.6
		table.insert(o.particles,{x=o.x,y=o.y,xSpeed=math.sin(r)*s,ySpeed=math.cos(r)*s,color=o.colors[effectRandom:randInt(#o.colors)],timer=effectRandom:randInt(13,20)})
	end
	return Effect.new(self,o)
end

function HitParticleEffect:tick()
	for _,p in ipairs(self.particles) do
		p.x = p.x + p.xSpeed
		p.y = p.y + p.ySpeed
		p.timer = p.timer - 1
		if p.timer > 0 then
			pix(p.x,p.y,p.color)
		end
	end
	Effect.tick(self)
end
