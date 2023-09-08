-- ending
---@diagnostic disable: lowercase-global

local function exp5(from,to,progress)
	local y = progress < 0.5 and ((progress*2)^5/2) or (1-((1-progress)*2)^5/2)
	return from + (to-from)*y
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
			self.spriteBank = 7
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
		elseif timer <= 580 then
			Exordium:drawBackground()
		end
		if timer > 280 and timer % 100 == 81 then
			self.items = {}
			for _=1,30 do
				table.insert(self.items,{type='fire',x=effectRandom:randInt(232),y=effectRandom:randInt(76,136),phase=effectRandom:randInt(0,3)})
			end
			for _=1,5 do
				table.insert(self.items,{type='monster',x=effectRandom:randInt(240-32),y=effectRandom:randInt(76,136),faceLeft=effectRandom:randBool(),speed=effectRandom:rand()*0.4+1})
			end
			table.sort(self.items,function(a,b) return a.y < b.y end)
		end
		if (timer <= 120 and timer % 8 == 0) or (timer <= 180 and timer % 4 == 0) or timer % 32 == 0 then
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
			self.screen = 'scene3'
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
