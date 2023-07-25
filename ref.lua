-- defines functions that tic-80 supports

function btn(id)
    return false
end

function btnp(id)
    return false
end

function circ(x, y, radius, color)
end

function circb(x, y, radius, color)
end

function clip(x, y, width, height)
end

function cls(color)
end

function elli(x, y, a, b, color)
end

function ellib(x, y, a, b, color)
end

function exit()
end

function fget(sprite_id, flag)
    return false
end

function fset(sprite_id, flag, bool)
end

function font(text, x, y, transcolor, char_width, char_height, fixed, scale)
    return 0
end

function key(code)
    return false
end

function keyp(code)
    return false
end

function line(x0, y0, x1, y1, color)
end

function map(x, y, w, h, sx, sy, colorkey, scale, remap)
end

function memcpy(to, from, length)
end

function memset(addr, value, length)
end

function mget(x, y)
    return 0
end

function mset(x, y, tile_id)
end

function mouse()
    return 0,0,false,false,false,0,0
end

function music(track, frame, row, loop, sustain, tempo, speed)
end

function peek(addr, bits)
    return 0
end

function peek1(bitaddr)
    return 0
end

function peek2(addr2)
    return 0
end

function peek4(addr4)
    return 0
end

function pix(x, y, color)
    return 0
end

function pmem(index, val32)
    return 0
end

function poke(addr, val, bits)
end

function poke1(bitaddr, bitval)
end

function poke2(addr2, val2)
end

function poke4(addr4, val4)
end

function print(text, x, y, color, fixed, scale, smallfont)
    return 0
end

function rect(x, y, width, height, color)
end

function rectb(x, y, width, height, color)
end

function reset()
end

function sfx(id, note, duration, channel, volume, speed)
end

function spr(id, x, y, colorkey, scale, flip, rotate, w, h)
end

function sync(mask, bank, tocart)
end

function ttri(x1, y1, x2, y2, x3, y3, u1, v1, u2, v2, u3, v3, texsrc, chromakey, z1, z2, z3)
end

function time()
    return 0
end

function trace(message, color)
end

function tri(x1, y1, x2, y2, x3, y3, color)
end

function trib(x1, y1, x2, y2, x3, y3, color)
end

function tstamp()
    return 0
end

function vbank(index)
end
