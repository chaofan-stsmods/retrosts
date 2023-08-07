-- exordium-monsters
---@diagnostic disable: lowercase-global

Cultist = Monster:new{ maxHp=51,width=4,height=4,ritual=3 }
function Cultist:init(random)
    if ascension >= 7 then
        self.maxHp = random:randInt(50,56)
    else
        self.maxHp = random:randInt(48,54)
    end
    if ascension >= 17 then
        self.ritual = 5
    elseif ascension >= 2 then
        self.ritual = 4
    end
end

function Cultist:drawImage()
	sprmap(5,17,self.width,self.height,self.x,self.y,0)
end

function Cultist:buff()
	local power = RitualPower:new(self,self.ritual)
	power.skipFirst = true
	addAction(ApplyPowerAction:new(power))
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(SetIntentAction:new(self,'attack','attack',6,1))
end

function Cultist:nextIntent()
	self:setIntent('buff','buff')
end

LouseNormal = Monster:new{ maxHp=10,width=4,height=2,curlUp=4,attackDamage=7 }
function LouseNormal:init(random)
    if ascension >= 7 then
        self.maxHp = random:randInt(11,16)
    else
        self.maxHp = random:randInt(10,15)
    end
    if ascension >= 17 then
        self.attackDamage = random:randInt(6,8)
        self.curlUp = random:randInt(9,12)
    elseif ascension >= 2 then
        self.attackDamage = random:randInt(6,8)
        self.curlUp = random:randInt(4,8)
    else
        self.attackDamage = random:randInt(5,7)
        self.curlUp = random:randInt(3,7)
    end
end

function LouseNormal:onCombatStart()
    addAction(ApplyPowerAction:new(CurlUpPower:new(self,self.curlUp)))
    Monster.onCombatStart(self)
end

function LouseNormal:drawImage()
	sprmap(9,17,2,self.height,self.x+8,self.y,0)
end

function LouseNormal:buff()
	addAction(ApplyPowerAction:new(StrengthPower:new(self,ascension >= 17 and 4 or 3)))
    addAction(NextIntentAction:new(self))
end

function LouseNormal:attack()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
    addAction(NextIntentAction:new(self))
end

function LouseNormal:nextIntent()
    local roll = aiRand:randInt(0,99)
    if roll < 25 then
        if self:lastIntentIs('buff') and (ascension >= 17 or self:lastTwoIntentsAre('buff')) then
            self:setIntent('attack','attack',self.attackDamage)
        else
            self:setIntent('buff','buff')
        end
    else
        if self:lastTwoIntentsAre('attack') then
            self:setIntent('buff','buff')
        else
            self:setIntent('attack','attack',self.attackDamage)
        end
    end
end

LouseDefensive = LouseNormal:new{ maxHp=10,width=4,height=2,curlUp=4,attackDamage=7 }
function LouseDefensive:init(random)
    LouseNormal.init(self,random)
    if ascension >= 7 then
        self.maxHp = random:randInt(12,18)
    else
        self.maxHp = random:randInt(11,17)
    end
end

function LouseDefensive:drawImage()
	sprmap(9,19,1,1,self.x+8,self.y+8,0)
    mapColor(4,5)
    mapColor(2,6)
	sprmap(10,19,1,1,self.x+16,self.y+8,0)
    resetColors{2,4}
end

function LouseDefensive:debuff()
	addAction(ApplyPowerAction:new(WeakPower:new(player,2,true)))
    addAction(NextIntentAction:new(self))
end

function LouseDefensive:nextIntent()
    local roll = aiRand:randInt(0,99)
    if roll < 25 then
        if self:lastIntentIs('debuff') and (ascension >= 17 or self:lastTwoIntentsAre('debuff')) then
            self:setIntent('attack','attack',self.attackDamage)
        else
            self:setIntent('debuff','debuff')
        end
    else
        if self:lastTwoIntentsAre('attack') then
            self:setIntent('debuff','debuff')
        else
            self:setIntent('attack','attack',self.attackDamage)
        end
    end
end

CurlUpPower = Power:new{icon=448}
function CurlUpPower:onHpLoss()
    addAction(GainBlockAction:new{target=self.owner,value=self.amount})
    addAction(ReducePowerAction:new(self,self.amount))
end
