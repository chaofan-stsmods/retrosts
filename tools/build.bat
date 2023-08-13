if not exist out mkdir out

"%~dp0lua\lua54.exe" "%~dp0lua\luacc.lua" -o %~dp0..\out\out.lua -p 10 -i %~dp0..\src sts utils creature card action power player ironclad combat map topbar reward window effect colorless relic act potion event.event event.neow event.all event.campfire event.treasure event.merchant encounter monster.all monster.monster monster.exordium monster.city

java -jar %~dp0compress\target\compress-1.0-SNAPSHOT.jar %~dp0..\out
