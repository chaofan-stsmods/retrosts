-- campfire
---@diagnostic disable: lowercase-global

CampfireEvent = Event:new{screen='intro',spriteBank=2,random=nil}
function CampfireEvent:init()
	self.random = self.random or makeRand(act.id,room.id,1)
	table.insert(self.options,{name='Rest',description=function () return self:getRestDescription() end,icon=320,onSelect=function() self:rest() end})
	table.insert(self.options,{name='Smith',description='Upgrade a card in your deck.',icon=292,onSelect=function() self:smith() end})
	if not rubyKeyObtained then
		table.insert(self.options,{name='Recall',description='Obtain the ruby key.',icon=340,onSelect=function() self:recall() end})
	end
	player:triggerEvent('onModifyCampfireOptions',self.options)
	self.healAmt = math.floor(player.maxHp*0.3)
	self.additionalHealAmt = hasRelic(RegalPillow) and 15 or 0
end

function CampfireEvent:drawBackground()
	act:drawBackground()
	player:drawImage()
	if self.screen == 'intro' then
		sprmap(12,37,4,4,64,58,0)
	else
		sprmap(12,41,4,2,64,73,8)
	end
end

function CampfireEvent:drawOptions()
	if self.screen ~= 'intro' then
		Event.drawOptions(self)
		return
	end

	local x = 120
	local stepX = 60
	local stepY = 36
	local y = 68 - (math.floor((#self.options+1)/2)*stepY-12)/2
	local isOdd = #self.options%2 == 1
	for i, option in ipairs(self.options) do
		if option.locked then
			greyColors()
		end

		if isOdd and i == #self.options then
			spr(option.icon,x+stepX/2,y+stepY*math.floor((i-1)/2),0,1,0,0,4,3)
			if self.selectedOption == i then
				drawSelectionBox(x+stepX/2,y+stepY*math.floor((i-1)/2),34,24)
			end
		else
			spr(option.icon,x+(1-i%2)*stepX,y+stepY*math.floor((i-1)/2),0,1,0,0,4,3)
			if self.selectedOption == i then
				drawSelectionBox(x-1+(1-i%2)*stepX,y+stepY*math.floor((i-1)/2),34,24)
			end
		end

		if option.locked then
			resetColors()
		end
	end

	if self.selectedOption > 0 and self.selectedOption <= #self.options then
		local option = self.options[self.selectedOption]
		local description = type(option.description) == 'function' and option.description() or option.description
		printShadowed(option.name..': '..description,2,129,12)
	end
end

function CampfireEvent:eventControls()
	if self.screen ~= 'intro' then
		Event.eventControls(self)
		return
	end

	if cursorOnTopBar then
		self.selectedOption = 0
		return
	end

	local function validOption(i) return not self.options[i].locked end
	if self.selectedOption == 0 then
		self.selectedOption = nextOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
	end

	if btnp(0) then
		if self.selectedOption > 2 then
			self.selectedOption = previousIndexInTableIf(self.options,self.selectedOption-1,validOption)
		end
	elseif btnp(1) then
		if self.selectedOption+2 <= #self.options then
			self.selectedOption = nextOrOtherIndexInTableIf(self.options,self.selectedOption+1,validOption)
		elseif #self.options%2 == 1 and self.selectedOption < #self.options then
			self.selectedOption = nextOrOtherIndexInTableIf(self.options,#self.options,validOption)
		end
	elseif btnp(2) then
		if self.selectedOption%2 == 0 and self.selectedOption > 1 then
			self.selectedOption = previousOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
		end
	elseif btnp(3) then
		if self.selectedOption%2 == 1 and self.selectedOption < #self.options and validOption(self.selectedOption+1) then
			self.selectedOption = nextOrOtherIndexInTableIf(self.options,self.selectedOption,validOption)
		end
	elseif btnp(4) then
		if table.allMatch(self.options, function (option) return option.locked end) then
			self:completeCampfire()
		else
			self:onOption(self.selectedOption)
		end
	end
end


function CampfireEvent:getRestDescription()
	return ('Heal for 30% of your max HP ({#}).'):gsub('{#}',tostring(self.healAmt)..(self.additionalHealAmt > 0 and '+'..tostring(self.additionalHealAmt) or ''))
end

function CampfireEvent:onOption(selection)
	if self.screen ~= 'intro' then
		completeRoom()
		openWindowAbove(MapWindow:new())
		return
	end
	local option = self.options[selection]
	if not option or option.locked then
		return
	end
	option.onSelect()
end

function CampfireEvent:rest()
	player:heal(self.healAmt+self.additionalHealAmt)
	self:completeCampfire()
	player:triggerEvent('onRest',self)
end

function CampfireEvent:smith()
	upgradeCardFromDeck(1,true,function (completed)
		if completed then
			self:completeCampfire()
		end
	end)
end

function CampfireEvent:recall()
	rubyKeyObtained = true
	self:completeCampfire()
end

function CampfireEvent:completeCampfire()
	self.screen = 'leave'
	self.options = {{description='[Leave]'}}
	self.selectedOption = 1
end
