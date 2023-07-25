-- utils
---@diagnostic disable: lowercase-global

function strWidth(str,fixed,small,scale)
	scale = scale or 1
	return print(str,0,-8*scale,0,fixed,scale,small)
end

function printShadowed(str,x,y,color,shadowColor,scale)
	scale = scale or 1
	print(str,x+1,y+1,shadowColor or 15,false,scale)
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

math.randomseed(tstamp())
function shuffle(tInput)
	for i = #tInput,1,-1 do
		local j = math.random(i)
		tInput[i],tInput[j] = tInput[j],tInput[i]
	end
end

function lerp(from,to,progress)
	if math.abs(from - to) < 1 then
		return to
	end
	return from * (1 - progress) + to * progress
end

function drawSelectionBox(x,y,w,h)
	line(x,y,x+3,y,4)
	line(x,y,x,y+3,4)
	line(x+w,y,x+w-3,y,4)
	line(x+w,y,x+w,y+3,4)
	line(x+w,y+h,x+w-3,y+h,4)
	line(x+w,y+h,x+w,y+h-3,4)
	line(x,y+h,x+3,y+h,4)
	line(x,y+h,x,y+h-3,4)
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

function resetColor(color)
	mapColor(color,color)
end

function resetColors(colors)
	for _, color in ipairs(colors) do
		resetColor(color)
	end
end

function noop() end

-- objects

Object = {}
function Object:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end
