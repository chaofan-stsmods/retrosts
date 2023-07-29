-- colorless
---@diagnostic disable: lowercase-global

ColorlessCard = Card:new{color={14,15},costIcon=46,typeIconColor=13}

Wound = ColorlessCard:new{ name='Wound',description='Unplayable.',rarity='special',cost=-2,type='status',canUse=false,canUpgrade=false }

Dazed = ColorlessCard:new{ name='Dazed',description='Unplayable. NL Ethereal.',rarity='special',cost=-2,type='status',canUse=false,canUpgrade=false,ethereal=true }
