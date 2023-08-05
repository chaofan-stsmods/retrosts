-- act
---@diagnostic disable: lowercase-global

Act = Object:new{id=0,title='',smallTitle='',cardUpgradedChance=0,drawBackground=noop}
function Act:playEntryEffect()
	addEffect(TextEffect:new{duration=120,color=11,text=self.smallTitle,x=120,y=17,small=false,shadow=15})
	addEffect(TextEffect:new{duration=120,color=4,text=self.title,x=120,y=24,small=false,scale=3,shadow=15})
end

Exordium = Act:new{id=1,title='Exordium',smallTitle='Act 1',cardUpgradedChance=0}
function Exordium:drawBackground()
	map(30,0,30,17,0,0)
end

TheCity = Act:new{id=2,title='The City',smallTitle='Act 2',cardUpgradedChance=0.25}

TheBeyond = Act:new{id=3,title='The Beyond',smallTitle='Act 3',cardUpgradedChance=0.5}

TheEnding = Act:new{id=4,title='The Ending',smallTitle='Final Act',cardUpgradedChance=0.5}

acts = { Exordium,TheCity,TheBeyond,TheEnding }
