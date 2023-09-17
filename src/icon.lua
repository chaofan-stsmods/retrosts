-- icon
---@diagnostic disable: lowercase-global

local rainbow =  {8,2,3,4,5,11,10}
local rainbow2 = {1,1,2,3,6,10,9}

---@class Icon : Object
Icon = {image=0,colorMap={},transparentColor=0,flip=false,typeIcon=nil,isRainbow=false,rainbowLength=#rainbow}
Object:new(Icon)

function Icon:draw(x,y,o)
	local rainbowTimer = o and o.rainbowTimer
	local noMapColor = o and o.noMapColor
	if not noMapColor then
		for key, value in pairs(self.colorMap) do
			if value == -1 then
				mapColor(key,rainbow[rainbowTimer])
			elseif value == -2 then
				mapColor(key,rainbow2[rainbowTimer])
			else
				mapColor(key,value)
			end
		end
	end
	spr(self.image,x,y,self.transparentColor,1,self.flip and 1 or 0)
	if not noMapColor then
		for key, _ in pairs(self.colorMap) do
			resetColor(key)
		end
	end
end

function drawIcon(icon,x,y,o)
	local typeIcon = o and o.typeIcon
	local noMapColor = o and o.noMapColor
	if type(icon) == 'number' then
		spr(icon,x,y,0)
	elseif getmetatable(icon) == Icon then
		if icon.typeIcon and typeIcon then
			if type(icon.typeIcon) == 'number' then
				if not noMapColor then
					mapColor(icon.typeIcon,typeIcon)
				end
				icon:draw(x,y,o)
				if not noMapColor then
					resetColor(icon.typeIcon)
				end
			elseif type(icon.typeIcon) == 'table' then
				if not noMapColor then
					for _,c in ipairs(icon.typeIcon) do
						mapColor(c,typeIcon)
					end
				end
				icon:draw(x,y,o)
				if not noMapColor then
					resetColors(icon.typeIcon)
				end
			end
		elseif icon.isRainbow then
			icon:draw(x,y,o)
		else
			icon:draw(x,y,o)
		end
	end
end

icons = {
	Damage = Icon:new{image=57},
	Block = Icon:new{image=47,colorMap={[5]=10}},
	Energy = Icon:new{image=204},

	Attack = Icon:new{image=57,typeIcon={12,13,14},transparentColor={0,15}},
	Skill = Icon:new{image=58,typeIcon=3},
	Power = Icon:new{image=59,typeIcon={3,4},transparentColor={0,1}},
	Status = Icon:new{image=55,typeIcon=3},
	Curse = Icon:new{image=56,typeIcon=7,transparentColor={0,5,6}},

	DrawPile = Icon:new{image=16,colorMap={[5]=4,[6]=3},flip=true,transparentColor={0,15}},
	DiscardPile = Icon:new{image=16,colorMap={[4]=10,[5]=10,[3]=9,[6]=9,[2]=15},transparentColor={0,15}},
	Deck = Icon:new{image=16,colorMap={[5]=15,[6]=15,[12]=15}},

	Vulnerable = Icon:new{image=60},
	Weak = Icon:new{image=61},
	Frail = Icon:new{image=75},
	Strength = Icon:new{image=57,colorMap={[12]=3,[13]=2,[14]=2,[15]=1}},
	Dexterity = Icon:new{image=47,colorMap={[9]=5,[10]=6,[11]=6,[15]=7}},
	Metallicize = Icon:new{image=46,colorMap={[13]=12,[14]=13,[15]=14}},
	Poison = Icon:new{image=56},
	DrawCardNextTurn = Icon:new{image=52,colorMap={[14]=12,[1]=12}},
	DrawCardEveryTurn = Icon:new{image=52,colorMap={[1]=15}},
	Focus = Icon:new{image=198,colorMap={[5]=11,[6]=10}},
	Bias = Icon:new{image=198,colorMap={[5]=2,[6]=4,[9]=2,[10]=3,[11]=4}},
	Mantra = Icon:new{image=195,colorMap={8,8,0,8,0,8,0,8},transparentColor={0,3,5,7}},
	MantraCard = Icon:new{image=195,colorMap={1,1,0,1,0,1,0,1},transparentColor={0,3,5,7}},

	OrbSlot = Icon:new{image=195,colorMap={[2]=12,[3]=13,[5]=13},transparentColor={0,1,4,6,7,10,11,12}},
	Lightning = Icon:new{image=195,colorMap={[1]=4,[2]=4,[3]=4,[4]=4,[7]=4,[5]=12,[6]=12,[10]=4,[11]=12}},
	Frost = Icon:new{image=196},
	Dark = Icon:new{image=197},
	Plasma = Icon:new{image=195,colorMap={[1]=3,[2]=3,[5]=3,[7]=6,[10]=11,[12]=4}},

	AttackIntent = Icon:new{image=57,colorMap={[12]=3,[13]=2,[14]=2,[15]=1},flip=true},

	BottledFlame = Icon:new{image=119,colorMap={[9]=2,[10]=3,[11]=4,[6]=15},transparentColor={0,5}},
	BottledLightning = Icon:new{image=119,colorMap={[9]=5,[10]=5,[11]=5,[6]=5},transparentColor={0,2,3,4}},
	BottledTornado = Icon:new{image=120},
}
