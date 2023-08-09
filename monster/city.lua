-- city-monsters
---@diagnostic disable: lowercase-global

Mugger = Looter:new{ blockAmt=11,swipeDmg=10,lungeDmg=16 }
function Mugger:init(random)
	self.maxHp = ascension >= 7 and random:randInt(50,54) or random:randInt(48,52)
	if ascension >= 2 then
		self.swipeDmg,self.lungeDmg = 11,18
	end
	self.goldAmt = ascension >= 17 and 20 or 15
end

function Mugger:drawImage()
	if self.flipped then
		sprmap(3,25,3,2,self.x+8,self.y,0,1,function(t) return t,1 end)
		mapColors(0,1,14,15,14,5,6,7,8,3,4,11,15,13,14,1)
		sprmap(3,27,3,2,self.x+8,self.y+16,0,1,function(t) return t,1 end)
		mapColor(2,11)
		sprmap(5,27,3,2,self.x+24,self.y+16,0,1,function(t) return t,1 end)
		resetColors()
	else
		sprmap(0,25,3,2,self.x,self.y,0)
		mapColors(0,1,14,15,14,5,6,7,8,3,4,11,15,13,14,1)
		sprmap(1,27,2,2,self.x+8,self.y+16,0)
		mapColor(2,11)
		sprmap(0,27,1,2,self.x,self.y+16,0)
		resetColors()
	end
end

TwoThievesEncounter = Encounter:new{spriteBank=1,name='TwoThieves',enemyInfo={encItem(Looter,-24,0),encItem(Mugger,24,0)}}
