-- encounter
---@diagnostic disable: lowercase-global

Encounter = Object:new{spriteBank=0,enemyInfo=nil,name=''}
function Encounter:new(o)
	local r = Object.new(self,o)
	o.enemyInfo = o.enemyInfo or {}
	return r
end

function Encounter:setupEnemies(random)
	enemies = {}
	for i, enemyInfo in ipairs(self.enemyInfo) do
		enemies[i] = enemyInfo.type:new{x=enemyInfo.x,y=enemyInfo.y,createRandom=random}
	end
end

function encItem(monsterType,xOffset,yOffset)
	return {type=monsterType,x=166+xOffset-monsterType.width*4,y=80+yOffset-monsterType.height*8}
end
