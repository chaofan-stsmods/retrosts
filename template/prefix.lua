-- title:	8-bit sts
-- author:	Chaofan
-- desc:	Slay the Spire 8-bit version
-- site:	website link
-- license:	MIT License (change this to your license of choice)
-- version:	0.1
-- script:	lua
-- input:	gamepad
-- saveid:	sts
---@diagnostic disable: lowercase-global

function loadDecode(base64,tree)
local r,p = {},tree
for i = 1,#base64 do
	local b,v = base64:byte(i),0
	if b>=65 and b<=90 then
		v=b-65
	elseif b>=97 and b<=122 then
		v=b-97+26
	elseif b>=48 and b<=57 then
		v=b-48+52
	elseif b==43 then
		v=62
	else
		v=63
	end
	for _=1,6 do
		p=p[((v>>5)&1)+1]
		if type(p)=='string'then
			table.insert(r,p)
			p=tree
		end
		v=v<<1
	end
end
load(table.concat(r,''))()
end
