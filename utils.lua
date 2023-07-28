-- utils
---@diagnostic disable: lowercase-global

function strWidth(str,fixed,small,scale)
	scale = scale or 1
	return print(str,0,-8*scale,0,fixed,scale,small)
end

function printColorStr(str,x,y,small,lockColor)
	local color = lockColor or 12
	local lastStart = 1
	local findStart,findEnd,findStr = str:find('(#%d+#)',lastStart)
	while findStart and findEnd and findStr do
		x = x + print(str:sub(lastStart,findStart-1),x,y,color,false,1,small)
		if lockColor == nil then
			color = tonumber(findStr:sub(2,#findStr-1)) or color
		end
		lastStart = findEnd+1
		findStart,findEnd,findStr = str:find('(#%d+#)',lastStart)
	end
	x = x + print(str:sub(lastStart),x,y,color,false,1,small)
	return x
end

function printShadowed(str,x,y,color,shadowColor,scale)
	scale = scale or 1
	print(str,x+1,y+1,shadowColor or 15,false,scale)
	print(str,x,y,color,false,scale)
end

function printGlowed(str,x,y,color,glowColor,scale)
	scale = scale or 1
	print(str,x+1,y,glowColor or 15,false,scale)
	print(str,x-1,y,glowColor or 15,false,scale)
	print(str,x,y-1,glowColor or 15,false,scale)
	print(str,x,y+1,glowColor or 15,false,scale)
	print(str,x,y,color,false,scale)
end

function limit(num,min,max)
	if min > max then return nil end
	if num < min then return min end
	if num > max then return max end
	return num
end

function shallowcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key,orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number,string,boolean,etc
		copy = orig
	end
	return copy
end

function lerp(from,to,progress)
	if math.abs(from - to) < 1 then
		return to
	end
	return from * (1 - progress) + to * progress
end

function drawSelectionBox(x,y,w,h,color,l)
	color = color or 4
	l = l or 3
	line(x,y,x+l,y,color)
	line(x,y,x,y+l,color)
	line(x+w-1,y,x+w-l-1,y,color)
	line(x+w-1,y,x+w-1,y+l,color)
	line(x+w-1,y+h-1,x+w-l-1,y+h-1,color)
	line(x+w-1,y+h-1,x+w-1,y+h-l-1,color)
	line(x,y+h-1,x+l,y+h-1,color)
	line(x,y+h-1,x,y+h-l-1,color)
end

function drawBezier(count,x0,y0,x1,y1,x2,y2)
	for i = 1,count-1 do
		local t = i / count
		local a = (1-t)^2
		local b = 2*t*(1-t)
		local c = t^2
		local x = math.floor(a*x0 + b*x1 + c*x2 + 0.5)
		local y = math.floor(a*y0 + b*y1 + c*y2 + 0.5)
		rect(x-2,y-2,4,4,2)
		rectb(x-2,y-2,4,4,1)
	end
end

function sprmap(x, y, w, h, sx, sy, colorkey, scale, remap)
	scale = scale or 1
	for cx = x,x+w-1 do
		for cy = y,y+h-1 do
			local tile, flip, rotate = mget(cx,cy), 0, 0
			if remap then
				local t,f,r = remap(tile,cx,cy)
				tile, flip, rotate = t or tile, f or flip, r or rotate
			end
			spr(tile+256,sx+(cx-x)*8*scale,sy+(cy-y)*8*scale,colorkey,scale,flip,rotate)
		end
	end
end

function mapColor(from,to)
	poke4(PALETTE_MAP * 2 + from, to)
end

function darkenColors()
	poke(PALETTE_MAP+0,0)
	poke(PALETTE_MAP+1,14*16+15)
	poke(PALETTE_MAP+2,13*16+13)
	poke(PALETTE_MAP+3,15*16+14)
	poke(PALETTE_MAP+4,15*16)
	poke(PALETTE_MAP+5,13*16+14)
	poke(PALETTE_MAP+6,14*16+13)
	poke(PALETTE_MAP+7,15)
end

function resetColor(color)
	mapColor(color,color)
end

function resetColors(colors)
	if colors == nil then
		for i = 0,8 do
			poke(PALETTE_MAP+i,i*2+(i*2+1)*16)
		end
	else
		for _, color in ipairs(colors) do
			resetColor(color)
		end
	end
end

local syncQueue = {}
local hasSync = false
function queueSync(mask,bank)
	if not hasSync then
		sync(mask,bank)
		hasSync = true
		return
	end
	table.insert(syncQueue,table.pack(mask,bank))
end

function doSync()
	if #syncQueue > 0 then
		sync(table.unpack(table.remove(syncQueue,1)))
	end
	hasSync = #syncQueue > 0
end

function table:indexOf(item)
	for index, value in ipairs(self) do
		if value == item then
			return index
		end
	end
	return nil
end

function makeRand(act,room,index)
	act = act or 0
	room = room or 0
	index = index or 0
	return Random:new(seed+10000*act+20*room+2*index)
end

function noop() end

-- selection

function previousOrOtherIndexInTableIf(table,currentIndex,condition)
	local previous = previousIndexInTableIf(table,currentIndex,condition)
	if previous == 0 then
		return nextIndexInTableIf(table,currentIndex,condition)
	end
	return previous
end

function nextOrOtherIndexInTableIf(table,currentIndex,condition)
	local next = nextIndexInTableIf(table,currentIndex,condition)
	if next == 0 then
		return previousIndexInTableIf(table,currentIndex,condition)
	end
	return next
end

function previousIndexInTableIf(table,currentIndex,condition)
	currentIndex = limit(currentIndex,1,#table)
	if currentIndex == nil then
		return 0
	end
	local condition = condition or function () return true end
	local previousIndex = currentIndex
	repeat
		previousIndex = previousIndex - 1
	until previousIndex < 1 or condition(previousIndex)
	if previousIndex < 1 then
		if not condition(currentIndex) then
			return 0
		end
		return currentIndex
	end
	return previousIndex
end

function nextIndexInTableIf(table,currentIndex,condition)
	if currentIndex == 0 and #table > 0 and condition(1) then
		return 1
	end
	currentIndex = limit(currentIndex,1,#table)
	if currentIndex == nil then
		return 0
	end
	local condition = condition or function () return true end
	local nextIndex = currentIndex
	repeat
		nextIndex = nextIndex + 1
	until nextIndex > #table or condition(nextIndex)
	if nextIndex > #table then
		if not condition(currentIndex) then
			return 0
		end
		return currentIndex
	end
	return nextIndex
end

-- objects

Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- random
local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40

Random = Object:new{x1=0,x2=1}
function Random:new(seed,x2)
	seed = math.floor(seed or tstamp())
	local x1 = seed
	if x2 == nil then
		x1 = math.floor(seed/D20)
		x2 = seed - x1*D20
	end
	x1 = x1 % D20
	x2 = x2 % D20
	x2 = math.floor(x2/2)*2+1
	return Object.new(self,{x1=x1,x2=x2})
end

function Random:randRaw()
	local x1 = self.x1
	local x2 = self.x2
	local u = x2*A2
	local v = (x1*A2 + x2*A1) % D20
	v = (v*D20 + u) % D40
	self.x1 = math.floor(v/D20)
	self.x2 = v - self.x1*D20
	return v
end

function Random:rand()
	return self:randRaw()/D40
end

function Random:randInt(from,to)
	if to == nil then
		to = from
		from = 1
	end
	return math.floor(self:rand() * (to-from+1)) + from
end

function Random:randBool()
	return self:rand() > 0.5
end

function Random:shuffle(array)
	for i = #array,1,-1 do
		local j = self:randInt(i)
		array[i],array[j] = array[j],array[i]
	end
end
