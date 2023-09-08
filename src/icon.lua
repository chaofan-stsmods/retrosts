-- icon
---@diagnostic disable: lowercase-global

local rainbow =  {8,2,3,4,5,11,10}
local rainbow2 = {1,1,2,3,6,10,9}

---@class Icon : Object
Icon = {image=0,colorMap={},transparentColor=0,flip=false,typeIcon=nil,isRainbow=false,rainbowLength=#rainbow}
Object:new(Icon)

function Icon:draw(x,y,rainbowTimer)
	for key, value in pairs(self.colorMap) do
		if value == -1 then
			mapColor(key,rainbow[rainbowTimer])
		elseif value == -2 then
			mapColor(key,rainbow2[rainbowTimer])
		else
			mapColor(key,value)
		end
	end
	spr(self.image,x,y,self.transparentColor,1,self.flip and 1 or 0)
	for key, _ in pairs(self.colorMap) do
		resetColor(key)
	end
end

function drawIcon(icon,x,y,typeIcon)
	if type(icon) == 'number' then
		if icon >= 55 and icon <= 59 then
			mapColor(3,typeIcon)
			spr(icon,x,y,0)
			resetColor(3)
		else
			spr(icon,x,y,0)
		end
	elseif getmetatable(icon) == Icon then
		if icon.typeIcon and typeIcon then
			if type(icon.typeIcon) == 'number' then
				mapColor(icon.typeIcon,typeIcon)
				icon:draw(x,y)
				resetColor(icon.typeIcon)
			elseif type(icon.typeIcon) == 'table' then
				for _,c in ipairs(icon.typeIcon) do
					mapColor(c,typeIcon)
				end
				icon:draw(x,y)
				resetColors(icon.typeIcon)
			end
		elseif icon.isRainbow then
			icon:draw(x,y,typeIcon)
		else
			icon:draw(x,y)
		end
	end
end

icons = {
	Damage = Icon:new{image=57},
	Block = Icon:new{image=47,colorMap={[5]=10}},
	Energy = Icon:new{image=202},

	Attack = Icon:new{image=57,typeIcon={12,13,14},transparentColor={0,15}},
	Skill = Icon:new{image=58,typeIcon=3},
	Power = Icon:new{image=59,typeIcon={3,4},transparentColor={0,1}},
	Status = Icon:new{image=55,typeIcon=3},
	Curse = Icon:new{image=56,typeIcon=7,transparentColor={0,5,6}},

	DrawPile = Icon:new{image=38,colorMap={[5]=4,[6]=3},flip=true,transparentColor={0,15}},
	DiscardPile = Icon:new{image=38,colorMap={[4]=10,[5]=10,[3]=9,[6]=9,[2]=15},transparentColor={0,15}},
	Deck = Icon:new{image=38,colorMap={[5]=15,[6]=15,[12]=15}},

	Vulnerable = Icon:new{image=60},
	Weak = Icon:new{image=61},
	Frail = Icon:new{image=75},
	Strength = Icon:new{image=57,colorMap={[12]=3,[13]=2,[14]=2,[15]=1}},
	Dexterity = Icon:new{image=47,colorMap={[9]=5,[10]=6,[11]=6,[15]=7}},
	Metallicize = Icon:new{image=46,colorMap={[13]=12,[14]=13,[15]=14}},
	Poison = Icon:new{image=56},

	AttackIntent = Icon:new{image=57,colorMap={[12]=3,[13]=2,[14]=2,[15]=1},flip=true},
}
