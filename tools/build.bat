if not exist out mkdir out

"%~dp0lua\lua54.exe" "%~dp0lua\luacc.lua" -o %~dp0..\out\out.lua -p 10 -i %~dp0..\src sts utils creature card action power player ironclad combat map topbar reward window effect colorless relic act potion event.event event.neow event.all event.campfire event.treasure event.merchant event.ending monster.encounter monster.all monster.monster monster.exordium monster.ending monster.city monster.beyond event.common event.onetime event.exordium event.bosstreasure event.city event.beyond save icon

java -jar %~dp0compress\target\compress-1.0-SNAPSHOT.jar %~dp0..\out

del %~dp0..\out\cart.tic
D:\\Games\\tic80-1.1.2268-win\\tic80.exe --fs=%~dp0..\out --skip "--cmd=load compressed.lua & save cart.tic & exit"
