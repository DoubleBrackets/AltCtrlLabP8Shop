pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
_c = {
  up = 1,
  down = 2,
  up_on = 3,
  down_on = 4,
  file_name = "labopen.txt"
}

button = {
  s = _c.up,
  x = 56,
  y = 56,
  press_time = 0,
  cooldown = 0.75
}

mouse = {
  x = 0,
  y = 0
}

is_depressed = false
is_toggled = false
debug = false

function _init()
  -- enable mouse
  poke(0x5f2d, 1)
  
  local b = button
  b.box = {
    x_1 = b.x-4,
    y_1 = b.y-4,
    x_2 = b.x+11,
    y_2 = b.y+10,
  }
end

function _update60()
  cls(13)

  ?"press button!",36,44,0 

		local now = time() 
  if is_depressed then
    if now - button.press_time
    > button.cooldown then
    		if is_toggled then
    			button.s = _c.up_on
    		else
    			button.s = _c.up
    		end  
    		is_depressed = false   
    end
  end

  local m = mouse
  local b = button.box

  -- get mouse x & y
  m.x = stat(32)-1
  m.y = stat(33)-1
  
  local in_box =
    m.x >= b.x_1-1 and
    m.y >= b.y_1 and
    m.x < b.x_2 and
    m.y <= b.y_2
  
  local pressed =
    stat(34) == 1 or
    stat(34) == 2
  
  local c = 1
  if in_box then
    c = 2
    if pressed and
    	not is_depressed then
    		is_depressed = true
    		c = 7
    		button.press_time = time()
    		if is_toggled then
    			button.s = _c.down
    			utils.update_file(0)
    			is_toggled = false
    		else 
    			button.s = _c.down_on
    			utils.update_file(1)
    			is_toggled = true
    		end
     
    end
  end

  if debug then
    rect(
      b.x_1,
      b.y_1,
      b.x_2,
      b.y_2,
      c
    )
  end
  
  -- draw button
  spr(
    button.s,
    button.x,
    button.y
  )
  
  -- draw mouse
  spr(0, m.x, m.y)
end

utils = {}
function utils.update_file(val)
  printh(
    val,
    _c.file_name,
    true
  )
end

__gfx__
0010000008888880000000000bbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
017100008888888800000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
017710008888888808888880bbbbbbbb0bbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0177710078888888888888887bbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01777710277778828888888837777bb3bbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
017711002222222278888888333333337bbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011710002222220077778800333333007777bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
