-- defines functions that tic-80 supports
---@diagnostic disable: lowercase-global
---@meta

---@param id integer
---@return boolean
function btn(id)
end

---@param id integer
---@return boolean
function btnp(id)
end

---@param x number
---@param y number
---@param radius number
---@param color integer
function circ(x, y, radius, color)
end

---@param x number
---@param y number
---@param radius number
---@param color integer
function circb(x, y, radius, color)
end

---@param x number
---@param y number
---@param width number
---@param height number
---@overload fun()
function clip(x, y, width, height)
end

---@param color integer
function cls(color)
end

---@param x number
---@param y number
---@param a number
---@param b number
---@param color integer
function elli(x, y, a, b, color)
end

---@param x number
---@param y number
---@param a number
---@param b number
---@param color integer
function ellib(x, y, a, b, color)
end

function exit()
end

---@param sprite_id integer
---@param flag integer
---@return boolean
function fget(sprite_id, flag)
end

---@param sprite_id integer
---@param flag integer
---@param bool boolean
function fset(sprite_id, flag, bool)
end

---@param text string
---@param x number
---@param y number
---@param transcolor integer
---@param char_width integer
---@param char_height integer
---@param fixed boolean?
---@param scale boolean?
---@return integer
function font(text, x, y, transcolor, char_width, char_height, fixed, scale)
end

---@param code integer
---@return boolean
function key(code)
end

---@param code integer
---@return boolean
function keyp(code)
end

---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@param color integer
function line(x0, y0, x1, y1, color)
end

---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param sx number
---@param sy number
---@param colorkey integer?
---@param scale integer?
---@param remap (fun(integer,integer,integer): integer,integer?,integer?)?
function map(x, y, w, h, sx, sy, colorkey, scale, remap)
end

---@param to integer
---@param from integer
---@param length integer
function memcpy(to, from, length)
end

---@param addr integer
---@param value integer
---@param length integer
function memset(addr, value, length)
end

---@param x integer
---@param y integer
---@return integer
function mget(x, y)
end

---@param x integer
---@param y integer
---@param tile_id integer
function mset(x, y, tile_id)
end

---@return integer x
---@return integer y
---@return boolean left
---@return boolean middle
---@return boolean right
---@return integer scrollx
---@return integer scrolly
function mouse()
	return 0,0,false,false,false,0,0
end

---@param track integer
---@param frame integer?
---@param row integer?
---@param loop boolean?
---@param sustain boolean?
---@param tempo integer?
---@param speed integer?
---@overload fun()
function music(track, frame, row, loop, sustain, tempo, speed)
end

---@param addr integer
---@param bits integer?
---@return integer
function peek(addr, bits)
end

---@param bitaddr integer
---@return integer
function peek1(bitaddr)
end

---@param addr2 integer
---@return integer
function peek2(addr2)
end

---@param addr4 integer
---@return integer
function peek4(addr4)
end

---@param x number
---@param y number
---@param color integer
function pix(x, y, color)
end

---@param index integer
---@param val32 integer
---@overload fun(index: integer): integer
function pmem(index, val32)
end

---@param addr integer
---@param val integer
---@param bits integer?
function poke(addr, val, bits)
end

---@param bitaddr integer
---@param bitval integer
function poke1(bitaddr, bitval)
end

---@param addr2 integer
---@param val2 integer
function poke2(addr2, val2)
end

---@param addr4 integer
---@param val4 integer
function poke4(addr4, val4)
end

---@param text string
---@param x number
---@param y number
---@param color integer?
---@param fixed boolean?
---@param scale integer?
---@param smallfont boolean?
---@return integer
function print(text, x, y, color, fixed, scale, smallfont)
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param color integer
function rect(x, y, width, height, color)
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param color integer
function rectb(x, y, width, height, color)
end

function reset()
end

---@param id integer
---@param note integer
---@param duration integer
---@param channel integer?
---@param volume integer?
---@param speed integer?
function sfx(id, note, duration, channel, volume, speed)
end

---@param id integer
---@param x number
---@param y number
---@param colorkey integer?
---@param scale integer?
---@param flip integer?
---@param rotate integer?
---@param w integer?
---@param h integer?
function spr(id, x, y, colorkey, scale, flip, rotate, w, h)
end

---@param mask integer
---@param bank integer
---@param tocart boolean?
function sync(mask, bank, tocart)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param u1 number
---@param v1 number
---@param u2 number
---@param v2 number
---@param u3 number
---@param v3 number
---@param texsrc (0 | 1)?
---@param chromakey integer?
---@param z1 number?
---@param z2 number?
---@param z3 number?
function ttri(x1, y1, x2, y2, x3, y3, u1, v1, u2, v2, u3, v3, texsrc, chromakey, z1, z2, z3)
end

---@return number
function time()
	return 0
end

---@param message string
---@param color integer?
function trace(message, color)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param color integer
function tri(x1, y1, x2, y2, x3, y3, color)
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
---@param color integer
function trib(x1, y1, x2, y2, x3, y3, color)
end

---@return number
function tstamp()
end

---@param index 0 | 1
function vbank(index)
end
