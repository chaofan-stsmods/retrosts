-- city-monsters
---@diagnostic disable: lowercase-global

CorruptHeart = Monster:new{ maxHp=750,width=8,height=7,bashDmg=40,bloodHitCount=12,numAttacked=0,numBuffed=0,type='boss' }
function CorruptHeart:init()
	self.maxHp = ascension >= 9 and 800 or 750
	if ascension >= 4 then
		self.bashDmg = 45
		self.bloodHitCount = 15
	end
end

function CorruptHeart:drawImage()
	sprmap(62,17,9,10,self.x+2,self.y-24,0)
end

function CorruptHeart:drawIntent()
	self.y = self.y + 8
	Monster.drawIntent(self)
	self.y = self.y - 8
end

function CorruptHeart:onCombatStart()
	addAction(ApplyPowerAction:new(self,InvinciblePower:new(self,ascension>=19 and 200 or 300)))
	addAction(ApplyPowerAction:new(self,BeatOfDeathPower:new(self,ascension>=19 and 2 or 1)))
	Monster.onCombatStart(self)
end

function CorruptHeart:debuff()
	addAction(ApplyPowerAction:new(self,VulnerablePower:new(player,2,true)))
	addAction(ApplyPowerAction:new(self,WeakPower:new(player,2,true)))
	addAction(ApplyPowerAction:new(self,FrailPower:new(player,2,true)))
	addAction(MakeTempCardToDrawPileAction:new(Dazed:new(),1,{pauseDuration=40,cardPosition=4}))
	addAction(MakeTempCardToDrawPileAction:new(Slimed:new(),1,{pauseDuration=35,cardPosition=2}))
	addAction(MakeTempCardToDrawPileAction:new(Wound:new(),1,{pauseDuration=30,cardPosition=1}))
	addAction(MakeTempCardToDrawPileAction:new(Burn:new(),1,{pauseDuration=25,cardPosition=3}))
	addAction(MakeTempCardToDrawPileAction:new(Void:new(),1,{pauseDuration=20,cardPosition=5}))
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:bash()
	self.numAttacked = self.numAttacked + 1
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:bloodHit()
	self.numAttacked = self.numAttacked + 1
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:buff()
	self.numAttacked = 0
	self.numBuffed = self.numBuffed + 1
	local strPower = self:getPower(StrengthPower)
	local strAmt = 2 + (strPower and strPower.amount < 0 and -strPower.amount or 0)
	addAction(ApplyPowerAction:new(self,StrengthPower:new(self,strAmt)))
	if self.numBuffed == 1 then
		addAction(ApplyPowerAction:new(self,ArtifactPower:new(self,2)))
	elseif self.numBuffed == 2 then
		addAction(ApplyPowerAction:new(self,BeatOfDeathPower:new(self,1)))
	elseif self.numBuffed == 3 then
		addAction(ApplyPowerAction:new(self,PainfulStabsPower:new(self)))
	elseif self.numBuffed == 4 then
		addAction(ApplyPowerAction:new(self,StrengthPower:new(self,10)))
	else
		addAction(ApplyPowerAction:new(self,StrengthPower:new(self,50)))
	end
	addAction(NextIntentAction:new(self))
end

function CorruptHeart:nextIntent(first)
	if first then
		self:setIntent('debuff','strongDebuff')
		return
	end
	if self.numAttacked == 0 then
		self:rollIntent{
			{'bash','attack',self.bashDmg,power=50},
			{'bloodHit','attack',2,self.bloodHitCount,power=50},
		}
	elseif self.numAttacked == 1 then
		if self:lastIntentIs('bash') then
			self:setIntent('bloodHit','attack',2,self.bloodHitCount)
		else
			self:setIntent('bash','attack',self.bashDmg)
		end
	else
		self:setIntent('buff','buff')
	end
end

function CorruptHeart:die()
	Monster.die(self)
	self.visible = true
end

InvinciblePower = Power:new{icon=430,description='Can only lose #11#!A!#12# more HP this turn.'}
function InvinciblePower:new(owner,amount)
	local result = Power.new(self,owner,amount)
	result.initialAmount = amount
	return result
end

function InvinciblePower:onTurnStart()
	self.amount = self.initialAmount
end

function InvinciblePower:onBeforeHpLoss(value)
	if self.amount > value then
		self.amount = self.amount - value
		return value
	else
		value = math.min(value,self.amount)
		self.amount = 0
		if value == 0 then
			addEffect(TextEffect:new{x=self.owner.x+self.owner.width*4,y=self.owner.y,text='Blocked',color=12,ySpeed=-0.5})
		end
		return value
	end
end

BeatOfDeathPower = Power:new{icon=431,description='Whenever you play a card, take #11#!A!#12# damage.'}
function BeatOfDeathPower:onUseCard()
	addAction(DamageAction:new{target=player,source=self.owner,value=self.amount,type='power'})
end

SpireShield = Monster:new{ maxHp=110,width=6,height=4,bashDmg=12,smashDmg=34,numTurn=1,type='elite' }
function SpireShield:init()
	self.maxHp = ascension >= 8 and 125 or 110
	if ascension >= 3 then
		self.bashDmg = 14
		self.smashDmg = 38
	end
end

function SpireShield:drawImage()
	sprmap(84,17,5,4,self.x+6,self.y,0)
end

function SpireShield:onCombatStart()
	addAction(ApplyPowerAction:new(self,SurroundedPower:new(player)))
	addAction(ApplyPowerAction:new(self,BackAttackPower:new(self)))
	addAction(ApplyPowerAction:new(self,ArtifactPower:new(self,ascension >= 18 and 2 or 1)))
	Monster.onCombatStart(self)
end

function SpireShield:enemyTurn()
	self.numTurn = self.numTurn + 1
	if self.numTurn == 4 then
		self.numTurn = 1
	end
	Monster.enemyTurn(self)
end

function SpireShield:smash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	if ascension >= 18 then
		addAction(GainBlockAction:new{target=self,value=99})
	else
		addAction(GainBlockAction:new{target=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function SpireShield:bash()
	addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	if player.maxOrbs > 0 and aiRand:randBool() then
		addAction(ApplyPowerAction:new(self,FocusPower:new(player,-1)))
	else
		addAction(ApplyPowerAction:new(self,StrengthPower:new(player,-1)))
	end
	addAction(NextIntentAction:new(self))
end

function SpireShield:defend()
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(GainBlockAction:new{target=enemy,value=30})
		end
	end
	addAction(NextIntentAction:new(self))
end

function SpireShield:nextIntent()
	if self.numTurn == 1 then
		if aiRand:randBool() then
			self:setIntent('bash','attackDebuff',self.bashDmg)
		else
			self:setIntent('defend','defend')
		end
	elseif self.numTurn == 2 then
		if self:lastIntentIs('bash') then
			self:setIntent('defend','defend')
		else
			self:setIntent('bash','attackDebuff',self.bashDmg)
		end
	else
		self:setIntent('smash','attackDefend',self.smashDmg)
	end
end

function SpireShield:die()
	Monster.die(self)
	player.flipped = false
	addAction(RemovePowerByTypeAction:new(player,SurroundedPower))
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(RemovePowerByTypeAction:new(enemy,BackAttackRightPower))
		end
	end
end

SpireSpear = Monster:new{ maxHp=160,width=6,height=4,burnDmg=5,skewerCount=3,numTurn=1,type='elite' }
function SpireSpear:init()
	self.maxHp = ascension >= 8 and 180 or 160
	if ascension >= 3 then
		self.burnDmg = 6
		self.skewerCount = 4
	end
end

function SpireSpear:drawImage()
	sprmap(79,22,7,4,self.x-12,self.y,0)
end

function SpireSpear:onCombatStart()
	addAction(ApplyPowerAction:new(self,ArtifactPower:new(self,ascension >= 18 and 2 or 1)))
	Monster.onCombatStart(self)
end

function SpireSpear:enemyTurn()
	self.numTurn = self.numTurn + 1
	if self.numTurn == 4 then
		self.numTurn = 1
	end
	Monster.enemyTurn(self)
end

function SpireSpear:skewer()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	addAction(NextIntentAction:new(self))
end

function SpireSpear:burn()
	for _=1,self.intentAttackCount do
		addAction(DamageAction:new{target=player,source=self,value=self.intentDamage})
	end
	if ascension >= 18 then
		addAction(MakeTempCardToDrawPileAction:new(Burn:new(),2,{putOnTop=true}))
	else
		addAction(MakeTempCardToDiscardPileAction:new(Burn:new(),2))
	end
	addAction(NextIntentAction:new(self))
end

function SpireSpear:buff()
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			addAction(ApplyPowerAction:new(self,StrengthPower:new(enemy,2)))
		end
	end
	addAction(NextIntentAction:new(self))
end

function SpireSpear:nextIntent()
	if self.numTurn == 1 then
		if self:lastIntentIs('burn') then
			self:setIntent('buff','buff')
		else
			self:setIntent('burn','attackDebuff',self.burnDmg,2)
		end
	elseif self.numTurn == 2 then
		self:setIntent('skewer','attack',10,self.skewerCount)
	else
		if aiRand:randBool() then
			self:setIntent('buff','buff')
		else
			self:setIntent('burn','attackDebuff',self.burnDmg,2)
		end
	end
end

function SpireSpear:die()
	Monster.die(self)
	addAction(RemovePowerByTypeAction:new(player,SurroundedPower))
	for _,enemy in ipairs(enemies) do
		if enemy.alive then
			player.flipped = true
			addAction(RemovePowerByTypeAction:new(enemy,BackAttackPower))
		end
	end
end

SurroundedPower = Power:new{icon=416,faceLeft=false,stackable=false,description='Receive #11#50%#12# more damage if attacked from behind. Use targeting cards or potions to change your orientation.'}
function SurroundedPower:onUseCard(_,target)
	self:changeTarget(target)
end

function SurroundedPower:onUsePotion(_,_,target)
	self:changeTarget(target)
end

function SurroundedPower:changeTarget(target)
	if target == nil then
		return
	end
	local newFaceLeft = target.x < self.owner.x
	if newFaceLeft ~= self.faceLeft then
		self.faceLeft = newFaceLeft
		self.owner.flipped = self.faceLeft
		for _, enemy in ipairs(enemies) do
			if enemy.alive then
				if newFaceLeft then
					if enemy.x > self.owner.x then
						addAction(ApplyPowerAction:new(self.owner,BackAttackRightPower:new(enemy)))
					else
						addAction(RemovePowerByTypeAction:new(enemy,BackAttackPower))
					end
				else
					if enemy.x > self.owner.x then
						addAction(RemovePowerByTypeAction:new(enemy,BackAttackRightPower))
					else
						addAction(ApplyPowerAction:new(self.owner,BackAttackPower:new(enemy)))
					end
				end
			end
		end
	end
end

BackAttackPower = Power:new{icon=353,priority=150,stackable=false,description='Deals #11#50%#12# more damage as it is attacking you from behind.'}
function BackAttackPower:onAttack(damage)
	return damage * 1.5
end

BackAttackRightPower = BackAttackPower:new{icon=Icon:new{image=353,flip=true}}

-- encounters
CorruptHeartEncounter = Encounter:new{spriteBank=5,name='CorruptHeart',type='boss',enemyInfo={encItem(CorruptHeart,0,4)},mapIcon=332}
ShieldAndSpearEncounter = Encounter:new{spriteBank=6,name='ShieldAndSpear',type='elite',enemyInfo={encItem(SpireShield,-116,1),encItem(SpireSpear,26,1)}}
function ShieldAndSpearEncounter:setupEnemies(random)
	player.x = 120-player.width*4
	Encounter.setupEnemies(self,random)
end
