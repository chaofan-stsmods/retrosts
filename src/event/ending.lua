-- ending
---@diagnostic disable: lowercase-global

local function exp5(from,to,progress)
	local y = progress < 0.5 and ((progress*2)^5/2) or (1-((1-progress)*2)^5/2)
	return from + (to-from) * y
end

local function linear(from,to,progress)
	return from + (to-from) * progress
end

IroncladEnding = Event:new{spriteBank=5,screen='scene1',timer=0,items={},controlTopBar=false}
function IroncladEnding:tick()
	self.timer = self.timer + 1
	local timer = self.timer
	if self.screen == 'scene1' then
		act:drawBackground()
		if timer > 60 and timer <= 100 then
			player.x = exp5(30,200,(timer-60)/40)
		end
		player:drawImage()
		local y1 = 4
		local y2 = 4 + math.max(0,(timer-150)*0.3)
		if timer <= 150 or (timer <= 230 and timer % 2 == 0) then
			sprmap(62,17,9,7,136,y1,0)
			sprmap(62,24,9,3,136,y2+56,0)
		end
		if timer > 150 and timer <= 230 and timer % 5 == 0 then
			addEffect(HitParticleEffect:new{colors={4,4,3},x=172+effectRandom:randInt(-16,16),y=63+effectRandom:randInt(-16,16)})
		end
		if timer == 83 then
			addEffect(HitParticleEffect:new{color={4,4,3},x=172,y=63})
		end
		if timer > 83 and timer <= 93 then
			local height = math.max(1,math.floor(10/(timer-82)))
			rect(100,63-height/2,130,height,12)
		end
		if timer >= 250 then
			player.x = player.x + 0.5
		end
		if timer >= 350 then
			self.screen = 'scene2'
			self.timer = 0
			self.spriteBank = 1
			self.items = {}
			queueSync(2,1)
			queueSync(1,5)
		end
	elseif self.screen == 'scene2' then
		if timer <= 280 then
			TheEnding:drawBackground()
		elseif timer <= 380 then
			TheBeyond:drawBackground()
		elseif timer <= 480 then
			TheCity:drawBackground()
		else
			Exordium:drawBackground()
		end
		if timer > 280 and timer < 580 and timer % 100 == 81 then
			self.items = {}
			for _=1,30 do
				table.insert(self.items,{type='fire',x=effectRandom:randInt(232),y=effectRandom:randInt(76,136),phase=effectRandom:randInt(0,3)})
			end
			for _=1,5 do
				table.insert(self.items,{type='monster',x=effectRandom:randInt(240-32),y=effectRandom:randInt(76,136),faceLeft=effectRandom:randBool(),speed=effectRandom:rand()*0.4+1})
			end
			table.sort(self.items,function(a,b) return a.y < b.y end)
			TheBeyond:randomizeBackground()
			TheCity:randomizeBackground()
			Exordium:randomizeBackground()
		end
		if ((timer <= 120 and timer % 8 == 0) or (timer <= 180 and timer % 4 == 0) or timer % 32 == 0) and timer < 580 then
			table.insert(self.items,{type='fire',x=effectRandom:randInt(232),y=effectRandom:randInt(76,136),phase=effectRandom:randInt(0,3)})
			table.sort(self.items,function(a,b) return a.y < b.y end)
		end
		if timer > 180 then
			for i=0,232,8 do
				map(60+((math.floor(timer/4)+i/8*17)%4),0,1,2,i,60,0)
			end
		end
		for _,item in ipairs(self.items) do
			if item.type == 'fire' then
				map(60+((math.floor(timer/4)+item.phase)%4),2,1,2,item.x,item.y-16,0)
			elseif item.type == 'monster' then
				sprmap(5,17,4,4,item.x,item.y-32,0,1,(not item.faceLeft) and flipRemap(5,4) or nil)
				item.x = item.x + (item.faceLeft and -1 or 1) * item.speed
			end
		end
		if timer > 180 then
			for i=0,232,8 do
				map(60+((math.floor(timer/4)+i/8*17)%4),0,1,2,i,120,0)
			end
		end
		if timer == 580 then
			clearSavedGame()
			switchWindow(VictoryWindow:new())
		end
	elseif self.screen == 'scene3' then
		cls(0)
		for i=0,232,8 do
			map(60+((math.floor(timer/4)+i/8*17)%4),0,1,2,i,120,0)
		end
	end
end

SilentEnding = Event:new{spriteBank=5,screen='scene1',timer=0,items={},controlTopBar=false}
function SilentEnding:addCloud(clouds,x,y,flipped)
	local image = clouds[effectRandom:randInt(#clouds)]
	if not flipped then
		x = x-image[3]*8
	end
	local d = limit((y-32-image[4]*8+16)/(88-32),0,1)
	if flipped then
		d = -d
	end
	table.insert(self.items,{type='cloud',image=image,x=x,y=y,speed=-0.1*d,flipped=flipped})
end

function SilentEnding:addClouds(clouds,row,numCloud,startY,stepY,flipped)
	for j=-(row-1),0 do
		for i=1,numCloud do
			local x = (120//numCloud)*i + effectRandom:randInt(-stepY//2,stepY//2)
			if flipped then
				x = 240 - x
			end
			local y = startY+j*stepY
			if j ~= 0 then
				y = y + effectRandom:randInt(-stepY//2,stepY//2)
			end
			self:addCloud(clouds,x,y,flipped)
		end
	end
end

function SilentEnding:tick()
	self.timer = self.timer + 1
	local timer = self.timer
	if self.screen == 'scene1' then
		act:drawBackground()
		player:drawImage()

		if timer == 30 or timer == 45 then
			table.insert(self.items,{type='line',x=player.x+player.width*8-12,y=player.y+player.height*4-6,sx=10,sy=-2.5,length=3,color=4,timer=20})
			table.insert(self.items,{type='line',x=player.x+player.width*8-12,y=player.y+player.height*4-6,sx=10,sy=0,length=3,color=4,timer=20})
			table.insert(self.items,{type='line',x=player.x+player.width*8-12,y=player.y+player.height*4-6,sx=10,sy=2.5,length=3,color=4,timer=20})
		end
		if timer == 40 or timer == 55 then
			addEffect(HitParticleEffect:new{colors={4,4,3},x=172,y=63})
		end
		if timer == 60 or timer == 80 or timer == 100 then
			table.insert(self.items,{type='potion',x=player.x+player.width*8-12,y=player.y+player.height*4-6,sx=6,sy=-1.5+effectRandom:randFloat(-0.2,0.2),timer=20})
		end
		if timer > 120 and timer <= 150 then
			player.x = math.floor(exp5(30,112,(timer-120)/30)+0.5)
		end
		if timer > 150 and timer <= 200 and timer % 3 == 0 then
			addEffect(HitParticleEffect:new{colors={4,4,3},x=148+effectRandom:randInt(-3,3),y=68+effectRandom:randInt(-3,3)})
		end
		if timer > 200 and timer <= 240 then
			player.x = math.floor(exp5(112,30,(timer-200)/40)+0.5)
		end
		if timer <= 220 or (timer <= 300 and timer % 2 == 0) then
			if timer > 120 or (timer > 80 and timer % 2 == 0) then
				mapColors(0,7,7,6,5,5,6,7,6,7,6,5,12,5,6,7)
			end
			sprmap(62,17,9,10,136,4,0)
			if timer > 120 or (timer > 80 and timer % 2 == 0) then
				resetColors{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
			end
		end
		if timer > 220 and timer <= 300 and timer % 5 == 0 then
			addEffect(HitParticleEffect:new{colors={5,5,6},x=172+effectRandom:randInt(-16,16),y=63+effectRandom:randInt(-16,16)})
		end
		if timer > 330 then
			self.screen = 'scene2'
			self.timer = 0
			self.items = {}
		end

		for _,item in ipairs(self.items) do
			if item.type == 'line' then
				local x,y = item.x,item.y
				item.x = x + item.sx
				item.y = y + item.sy
				item.timer = item.timer - 1
				line(x,y,x+item.sx*item.length,y+item.sy*item.length,4)
			elseif item.type == 'potion' then
				local x,y = item.x,item.y
				item.x = x + item.sx
				item.y = y + item.sy
				item.sy = item.sy + 0.1
				if item.x > 172 then
					item.timer = 0
					addEffect(HitParticleEffect:new{colors={5,5,6},x=x,y=y})
				end
				PoisonPotion:drawImage(x-4,y-4)
			end
		end

		table.retainIf(self.items,function(item) return item.timer > 0 end)

	elseif self.screen == 'scene2' then
		act:drawBackground()

		local ropeNodeLen = 3
		if timer == 1 then
			for i=1,60 do
				local item = {x=player.x+player.width*8-18,y=player.y+player.height*4-4}
				item.px = item.x
				item.py = item.y
				self.items[i] = item
			end
		end

		local firstRope = self.items[1]
		if firstRope.x < 120 then
			firstRope.x = firstRope.x + 2
			firstRope.y = firstRope.y - 5
		end

		for i=2,#self.items do
			local item = self.items[i]
			item.x, item.px = item.x * 2 - item.px, item.x
			item.y, item.py = item.y * 2 - item.py + 0.1, item.y
			if self.playerOnRope == i then
				item.y = item.y + 0.5
			end
			if item.y > 84 then
				item.y = 84
			end
		end

		for _=1,10 do
			for i=2,#self.items do
				local item = self.items[i]
				local prev = self.items[i-1]
				local distance = math.sqrt((item.x-prev.x)^2+(item.y-prev.y)^2)
				local err = distance - ropeNodeLen
				local nx,ny
				if distance == 0 then
					local rad = effectRandom:randFloat(math.pi*2)
					nx,ny = math.sin(rad),math.cos(rad)
				else
					nx,ny = (item.x-prev.x)/distance,(item.y-prev.y)/distance
				end
				if i == 2 then
					item.x = item.x - nx * err
					item.y = item.y - ny * err
				else
					item.x = item.x - nx * err * 0.5
					item.y = item.y - ny * err * 0.5
					prev.x = prev.x + nx * err * 0.5
					prev.y = prev.y + ny * err * 0.5
				end
			end
		end

		if timer <= 80 then
			local ropeEnd = self.items[#self.items]
			ropeEnd.x = player.x+player.width*8-18
			ropeEnd.y = player.y+player.height*4-4
			self.playerOnRope = #self.items
		end
		if timer > 80 then
			if timer % 5 == 0 then
				self.playerOnRope = math.max(1,self.playerOnRope-2)
			end
			local ropeEnd = self.items[self.playerOnRope]
			player.x = ropeEnd.x - player.width*8+18
			player.y = ropeEnd.y - player.height*4+4
			if player.y > 52 then
				player.y = 52
			end
		end
		if timer > 300 then
			self.screen = 'scene3'
			self.timer = 0
			self.items = {}
			self.spriteBank = 7
			queueSync(2,7)
			queueSync(1,5)
		end

		for i=2,#self.items do
			local item = self.items[i]
			local prev = self.items[i-1]
			line(item.x,item.y,prev.x,prev.y,4)
		end

		player:drawImage()

	elseif self.screen == 'scene3' then
		sprmap(90,0,30,17,0,0)
		if timer == 1 then
			queueSync(1,5)
			local bigClouds = {{64,0,4,3},{64,3,6,3}}
			local smallClouds = {{68,0,3,1},{68,1,2,1}}
			self:addClouds(smallClouds,3,10,88-44,6)
			self:addClouds(smallClouds,3,10,88-44,6,true)
			self:addClouds(bigClouds,3,6,88,12)
			self:addClouds(bigClouds,3,6,88,12,true)
			table.sort(self.items,function(a,b)
				if a.y == b.y then
					if a.x <= 120 and b.x <= 120 then
						return a.x < b.x
					else
						return a.x > b.x
					end
				end
				return a.y < b.y
			end)
		end
		for i,item in ipairs(self.items) do
			if item.type == 'cloud' then
				if item.flipped then
					map(item.image[1],item.image[2],item.image[3],item.image[4],item.x,item.y-item.image[4]*8,8,1,flipRemap(item.image[1],item.image[3]))
				else
					map(item.image[1],item.image[2],item.image[3],item.image[4],item.x,item.y-item.image[4]*8,8)
				end
				if timer < 720 then
					item.x = item.x + item.speed
				else
					local v = (timer + i * 31) % 120
					if v < 60 then
						item.x = item.x + item.speed * 0.3
					else
						item.x = item.x - item.speed * 0.3
					end
				end
			end
		end
		local silentY = math.max(72,152-timer*0.3+2*math.sin(timer*0.15-0.70))
		map(60,4,3,5,104,silentY,0)
		if timer == 360 then
			clearSavedGame()
			switchWindow(VictoryWindow:new())
		end
	end
end

DefectEnding = Event:new{spriteBank=5,screen='scene1',timer=0,items={},controlTopBar=false}
function DefectEnding:tick()
	self.timer = self.timer + 1
	local timer = self.timer
	if self.screen == 'scene1' then
		act:drawBackground()
		player:drawImage()
		if timer <= 180 or (timer <= 260 and timer % 2 == 0) then
			sprmap(62,17,9,10,136,4,0)
		end
		if timer > 60 and timer <= 150 and timer % 5 == 0 then
			addEffect(HitParticleEffect:new{colors={11,11,12},x=172+effectRandom:randInt(-16,16),y=63+effectRandom:randInt(-4,4)})
		end
		if timer > 180 and timer <= 260 and timer % 5 == 0 then
			addEffect(HitParticleEffect:new{colors={4,4,3},x=172+effectRandom:randInt(-16,16),y=63+effectRandom:randInt(-16,16)})
		end
		if timer > 60 and timer <= 150 then
			local th = limit(effectRandom:randInt(9,11),0,math.min(timer-60,150-timer))
			local ty = effectRandom:randInt(49,51)
			local sh = effectRandom:randInt(2,3)
			local sx = player.x+player.width*4
			local sy = player.y+player.height*4
			tri(sx,sy-sh/2,240,ty-th/2,240,ty+th/2,11)
			tri(sx,sy-sh/2,sx,sy+sh/2,240,ty+th/2,11)
			tri(sx,sy,240,ty-th/2+1,240,ty+th/2-1,12)
		end
		if timer > 300 then
			self.screen = 'scene2'
			self.timer = 0
			self.items = {}
		end
	elseif self.screen == 'scene2' then
		local function pow2(progress)
			return progress * (1 - progress) * 4
		end

		act:drawBackground()
		player:drawImage()

		if timer < 30 then
			local p = timer/30
			player.flipped = false
			player.y = linear(52,32,p) - pow2(p)*10
			player.x = linear(30,112,p)
		end
		if timer >= 40 and timer < 70 then
			local p = (timer-40)/30
			player.flipped = true
			player.y = linear(32,12,p) - pow2(p)*10
			player.x = linear(112,45,p)
		end
		if timer >= 80 and timer < 110 then
			local p = (timer-80)/30
			player.flipped = false
			player.y = linear(12,-8,p) - pow2(p)*10
			player.x = linear(45,132,p)
		end
		if timer >= 120 and timer < 140 then
			local p = (timer-120)/30
			player.flipped = true
			player.y = linear(-8,-28,p) - pow2(p)*10
			player.x = linear(112,45,p)
		end
		if timer > 150 then
			self.screen = 'scene3'
			self.timer = 0
			self.items = {}
		end
	elseif self.screen == 'scene3' or self.screen == 'scene4' then
		if self.screen == 'scene3' then
			if timer <= 120 then
				Exordium:drawBackground()
			elseif timer <= 240 then
				TheCity:drawBackground()
			elseif timer <= 360 then
				TheBeyond:drawBackground()
			else
				TheBeyond:drawBackground()
				self.screen = 'scene4'
				self.timer = 0
				self.spriteBank=5
				queueSync(1,5)
			end
			if timer % 120 == 1 then
				TheBeyond:randomizeBackground()
				TheCity:randomizeBackground()
				Exordium:randomizeBackground()
			end
		else
			cls(0)
		end
		if timer % 5 == 0 and table.count(self.items,function (item) return item.type == 'word' end) < 30 then
			table.insert(self.items,{
				type='word',x=effectRandom:randInt(-60,240),y=effectRandom:randInt(8,128),text=tostring(effectRandom:randInt(0,1)),
				small=effectRandom:randBool(),speedX=0,color=effectRandom:randInt(9,12),textLimit=effectRandom:randInt(5,10),timer=240,
			})
		end
		if timer % 3 == 0 and self.screen == 'scene4' then
			table.insert(self.items,{
				type='line',rad=effectRandom:randFloat(0,math.pi*2),r1=80,r2=80,color=effectRandom:randInt(11,12),timer=20,
			})
		end
		for i,item in ipairs(self.items) do
			if item.type == 'word' then
				local x,y = item.x,item.y
				item.x = x + item.speedX
				item.timer = item.timer - 1
				if item.x > 240 or item.timer < 0 then
					table.remove(self.items,i)
				end
				printDarken(item.text,x,y,item.color,true,1,item.small)
				if effectRandom:randInt(60) == 1 and #item.text < item.textLimit then
					item.text = item.text .. tostring(effectRandom:randInt(0,1))
				end
			elseif item.type == 'line' then
				local rad = item.rad
				local r1,r2 = item.r1,item.r2
				local x1,y1 = 120+math.sin(rad)*r1,66+math.cos(rad)*r1
				local x2,y2 = 120+math.sin(rad)*r2,66+math.cos(rad)*r2
				item.r1 = r1 - 5
				item.r2 = r2 - 4
				item.timer = item.timer - 1
				if item.timer < 0 or item.r1 < 0 then
					table.remove(self.items,i)
				end
				line(x1,y1,x2,y2,item.color)
			end
		end
		if self.screen == 'scene4' then
			map(71,0,5,5,98,48+math.sin(timer*0.05)*2,0)
			if timer == 240 then
				clearSavedGame()
				switchWindow(VictoryWindow:new())
			end
		end
	end
end
