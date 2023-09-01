-- encounter
---@diagnostic disable: lowercase-global

currentEncounter = nil

Encounter = Object:new{spriteBank=0,enemyInfo=nil,name='',type='monster'}
function Encounter:new(o)
	local r = Object.new(self,o)
	o.enemyInfo = o.enemyInfo or {}
	return r
end

function Encounter:setupEnemies(random)
	currentEncounter = self
	enemies = {}
	for i, enemyInfo in ipairs(self.enemyInfo) do
		enemies[i] = enemyInfo.type:new{x=enemyInfo.x,y=enemyInfo.y,createRandom=random}
		if enemyInfo.additionalProperties then
			for key, value in pairs(enemyInfo.additionalProperties) do
				enemies[i][key] = value
			end
		end
	end
end

MonsterSlot = Monster:new{alive=false,visible=false}

function encItem(monsterType,xOffset,yOffset,additional)
	xOffset = xOffset or 0
	yOffset = yOffset or 0
	return {type=monsterType,x=166+xOffset-monsterType.width*4,y=80+yOffset-monsterType.height*8,additionalProperties=additional}
end
