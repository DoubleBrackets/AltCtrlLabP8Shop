pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- made for mini jam 103
-- by camden pettijohn
-- and grant gelardi

-- general
g_coroutines = {}
g_smallest = 1000
g_gravity = 0.04
g_behinds = {}
g_objects = {}
g_shadows = {}
g_level = 1
g_count = 0
g_x = 0
g_o = 0
g_c = 0
g_y = 0

-- ui
g_rt = 3
g_bt = 3
g_near = nil
g_lock = false
g_pause = false
g_zdown = false
g_xdown = false
g_meter = 100
g_ui = -12

-- intro
g_lid = nil
g_vamp = nil
g_coffin = nil
g_slant = false
g_start = "intro"
g_status = "repeat"

-- typer
g_message = ""
g_string = ""
g_default_w = 6
g_default_c = 7
g_waiter = -1
g_old_c = -1
g_color = -1
g_talk = 0

-- dialogue box
g_finished = false
g_point_y = 28
g_box_y = -39
g_show = false

-- go box
g_go_s = 104
g_go_x = 435
g_go = false

-- enemies
skull = {
  name = "skull",
  on = true,
  s = 45,
  t = 1,
  w = 1,
  h = 2
}

pinky = {
  name = "pinky",
  s = 64,
  t = 20,
  w = 2,
  h = 2
}

squid = {
  name = "squid",
  s = 68,
  t = 30,
  w = 2,
  h = 3
}

ducky = {
  name = "ducky",
  dy = 2,
  s = 72,
  t = 4,
  w = 2,
  h = 2
}

-- debug
placer = false
debug = false
error = ""

-- death message
g_d_s = ""
g_d_o = -1

-- other
g_w_overlay = false
g_reboot = false
g_w_o = -1
w_y = 494
w_x = 0

function die()
  g_lock = true
  for i = 1,34 do
    g_d_o += 2
    wait(1)
  end
  my_sfx("fail")
		if g_level == 1 then
		  level_1(true)
		elseif g_level == 2 then
		  level_2(true)
		elseif g_level == 3 then
		  level_3(true)
		end
		g_d_s = "hunger destroyed allowen."
  for shadow in all(g_shadows) do
    shadow.x = g_x
  end
		g_rt = 3
		g_bt = 3
  wait(50)
  for i = 1,34 do
    if i == 10 then
      g_d_s = ""
    elseif i == 20 then
      g_lock = false
    end
    g_d_o -= 2
    wait(1)
  end
end

function win()
  if not g_lock then
    g_lock = true
    wait(50)
    music(8, 300, 12)
    wait(50)
    g_w_overlay = true
    for i = 1,34 do
      g_w_o += 2
      wait(1)
    end
    wait(10)
    g_shadows = {}
    g_objects = {}
    g_start = "done"
    g_w_overlay = false
    g_string = " ~bwhile allowen never found a\nhuman,~9%~3eating donuts defeated\nthe one force that could kill\n       him~9... ~3his hunger.\n\n\n\n\n\n\n\n\n\n\n\n\n\n     ~1thanks for playing!~9%%%\n\n   ~1press ~r❎ ~bto play again."
    animate(typer)
    local cs = {8, 11, 12, 14}
    while true do
      local x = rnd(90)+20
      local y = rnd(90)+20
      local r = rnd(4)\1+1
      local c = cs[r]
      explode(
        10,
        10,
        g_c+x,
        g_y+y,
        6,
        12,
        false,
        c
      )
      wait(20)
    end
  end
end

-- debug stuff
-- ignore it
function _init()
  -- other colors
  poke(0x5f5f, 0x10)
  local mode = 1
  if mode == -1 then
    animate(win)
  elseif mode == -2 then
    level_1()
    g_start = "game"
    g_status = "game"
    animate(loop)
    g_x = 384
    g_c = 384
    g_ui = 1
    animate(hunger, 50)
  elseif mode == -3 then
    -- jump
    level_2()
    g_start = "game"
    g_status = "game"
    animate(loop)
    g_x = 0
    g_c = 0
    g_ui = 128
    animate(hunger, 50)
  elseif mode == 0 then
    level_3()
    g_talk = 8
    g_level = 3
    g_x = 800
    g_c = 800
    g_ui = 385
    g_start = "game"
    g_status = "game"
    animate(loop)
    animate(go_bounce)
    animate(hunger, 500)
  elseif mode == 1 then
    level_1()
    animate(intro)
  end
end

function clear()
  g_objects = {}
  if g_level == 1 then
    together()
  end
end

-- level 1
function level_1(died)
  clear()
  if died then
    animate(character, {-1, pinky, 488, 104})
    g_x = 389
    g_y = 0
    g_c = 384
  else
    animate(two_pinky)
  end
  animate(character, {30, pinky, 600, 104})
  animate(character, {30, ducky, 647, 64})
  animate(character, {30, ducky, 685, 24})
  animate(character, {00, skull, 956, 57})
end

-- level 2
function level_2(died)
  clear()
  if not died then
    music(12)
    g_x = 128
  else
    g_x = 0
  end
  g_y = 128
  g_c = 0
  animate(character, {40, squid, 14, 181})
  animate(character, {20, pinky, 760, 232})
  animate(character, {00, skull, 956, 185})
end

-- level 3
function level_3(died)
  clear()
  if not died then
    animate(go_wave_x)
    animate(go_wave_y)
    music(14, 300, 12)
    g_x = 128
  else
    g_x = 0
  end
  g_y = 384
  g_c = 0
  for i = 0,2 do
    animate(character, {30, ducky, 68+i*20, 464})
  end
  animate(character, {41, squid, 760, 438})
end

function two_pinky()
  animate(character, {31, pinky, 440, 104})
  wait(10)
  animate(character, {-1, pinky, 488, 104})
end

function float()
  local o = 0
  g_vamp = create(15, 132, 51, 84, 2, 2, true)
  local y = g_vamp.y
  while g_vamp do
    if not g_slant then
      if o == 0 then
        o = 1
      else
        o = 0
      end
      g_vamp.y = y+o
    else
      y = g_vamp.y-1
      o = 1
    end
    wait(20)
  end
end

function go_vamp()
  while g_vamp do
    if g_status == "repeat"
    and g_c > 255 then
      g_vamp.x -= 128
      g_c -= 128
    end
    if g_status != "hunger"
    and g_status != "game" then
      g_vamp.x += 1
      g_c += 1
    end
    wait(1)
  end
end

function feast()
  local old = #g_objects
  g_slant = true
  for i = 50,1,-1 do
    wait(1)
    g_vamp.x += i/38
    g_vamp.y += i/30
    g_x = g_vamp.x+4
    if i == 1 then
				  explode(
				    20,
				    10,
				    g_vamp.x+10,
				    g_vamp.y+10,
				    10,
				    16
				  )
				end
  end
  my_sfx("explosion")
  wait(70)
  for i = 50,1,-1 do
    wait(1)
    g_vamp.x -= i/38
    g_vamp.y -= i/30
  end
  g_slant = false
end

function puffs(value)
  for i = 0,14 do
    explode(
      6,
      30,
      value,
      g_y+i*10,
      14,
      14
    )
  end
end

function go_bounce()
  g_go = true
  while g_x < 465 do
    if g_go_s == 107 then
      g_go_s = 104
    else
      g_go_s = 107
    end
    wait(12)
  end
  g_go = false
end

function go_back()
  g_x = 370
  g_status = "game"
  for i = 30,1,-1 do
    g_vamp.x -= i/24
    wait(1)
  end
  animate(loop)
  local old = g_x+2
  puffs(old)
  my_sfx("darkness")
  wait(10)
  for i = 1,19 do
    g_x += 1
    wait(2)
  end
  wait(20)
  puffs(old)
  wait(50)
  g_start = "game"
  animate(go_ui)
  animate(hunger, 125)
  animate(go_bounce)
  del(g_objects, g_vamp)
  g_vamp = nil
end

function go_ui()
  for i = 1,13 do
    g_ui += 1
    wait(1)
  end
end

function back_box()
  for i = 1,15 do
    g_point_y -= 1
    wait(1)
  end
  for i = 1,41 do
    g_point_y -= 1
    g_box_y -= 1
    wait(1)
  end
  g_show = false
  animate(go_back)
end

function typer()
  g_waiter = g_default_w
  g_color = g_default_c
  g_message = ""
  g_old_c = -1 
  local skip = false
  local tilda = false
  local string = g_string
  local list = split(string, "")
  for i = 1,#list do
    local char = list[i]
    if char == "~" then
      tilda = true
      skip = true
    elseif tilda then
      local value = tonum(char)
      if char == "w" then
        g_color = 7
      elseif char == "r" then
        g_color = 8
      elseif char == "b" then
        g_color = 0
      elseif value then
        g_waiter = value*2
      end
      tilda = false
      skip = true
    end
    if not skip then
      if not (i == 1 or char == " " or char == "\n"
      or (list[1] == "~" and i == 3)) then
        wait(g_waiter)
      end
      local convert = ""
      if g_old_c != g_color then
        convert = "\f"..tostr(g_color)
        g_old_c = g_color
      end
      if char == "%" then
        char = " "
      end
      local top = 3
      local r = rnd(top)\1+1
      if g_level != 3 then
        sfx(50, 1, r-1, 1)
      end
      g_message = g_message..convert..char
    end
    skip = false
  end
  if g_start == "done" then
    g_reboot = true
  end
  wait(100)
  local old = g_string
  if g_talk == 0 then
    animate(go_vamp)
    wait(20)
    g_string = ""
    animate(typer)
  elseif g_talk == 1 then
    g_string = "hmmm~9... ~3how i hunger for\nhuman ~rblood~w~9...\n~1alas, ~3there are no humans to\ndine upon since i ate them a\ncentury ago."
    animate(typer)
    for i = 0,3 do
      poke(0x5f70+9+i, 0x00)
    end
  elseif g_talk == 2 then
    wait(20)
    g_string = ""
    animate(typer)
    g_status = nil
  elseif g_talk == 3 then
    g_string = "~1ah! ~3but what do we have here?~9%\n\n~1it seems that my castle has\nbeen infested with ~rmonsters~w!"
    animate(typer)
    wait(103)
    g_status = "hunger"
  elseif g_talk == 4 then
    g_string = "this will have to do for now.~9%%%\n\n~r~1blegh! monster blood is vile!"
    animate(typer)
    wait(30)
    animate(feast)
  elseif g_talk == 5 then
    g_string = "~1*gurgle*~3%~9...~3%~1*gurgle*~3%~9...\n\n~3though i must eat them or\nsurely ~rdie of starvation~w~9%~0:("
    animate(typer)
  elseif g_talk == 6 then
    g_string = "~rmy darkness shall spread!"
    animate(typer)
  elseif g_talk == 7 then
    g_string = ""
    animate(typer)
    animate(back_box)
  end
  if old != g_string then
    g_talk += 1
  end
end

function go_box()
  for i = 1,41 do
    g_box_y += 1
    wait(1)
  end
  g_show = true
  for i = 1,13 do
    g_point_y += 1
    wait(1)
  end
  g_string = "~1~rallowen~w:\n\n~5finally~9... ~3i have risen from\nmy hundred-year slumber."
  animate(typer)
end

function my_sfx(string)
  if string == "consume" then
    sfx(1, 0)
    sfx(2, 3)
  elseif string == "z"
  or string == "rise" then
    sfx(3, 0)
  elseif string == "x" then
    sfx(5, 0)
    sfx(6, 3)
  elseif string == "complete" then
    sfx(4, 0)
  elseif string == "fail" then
    sfx(7, 0)
    sfx(7, 3)
  elseif string == "shake" then
    sfx(8, 0)
  elseif string == "open" then
    sfx(9, 0)
  elseif string == "explosion" then
    sfx(10, 0)
  elseif string == "darkness" then
    sfx(11, 0)
  end
end


function go_slant()
  g_slant = true
  g_vamp.z = 30
  sort()
  if g_c < 100 then
    my_sfx("rise")
    music(9, 300, 12)
  end
  for i = 40,1,-1 do
    local o = i/24
    g_vamp.x -= o
    g_vamp.y -= o/1.2
    wait(2)
  end
  g_vamp.flip = false
  g_slant = false
  g_vamp.x += 5
  wait(10)
  animate(go_box)
end

function go_lid()
  my_sfx("open")
  for i = 1,14 do
    g_lid.x -= 1
    wait(5)
  end
  wait(20)
  animate(go_slant)
end

function c_l(value)
  g_lid.x -= value
  g_coffin.x -= value
  g_lid.y -= value
  g_coffin.y -= value
end

function c_r(value)
  g_lid.x += value
  g_coffin.x += value
  g_lid.y -= value
  g_coffin.y -= value
end

function bounce(args)
  local times = {40, 20, 10}
  my_sfx("shake")
  local j = 4
  wait(10)
  for i = 1,2 do
    c_l(2)
    wait(j)
    c_r(2)
    wait(j)
    c_l(-2)
    c_r(-2)
    wait(j)
    c_r(2)
    wait(j)
    c_l(2)
    wait(j)
    c_r(-2)
    c_l(-2)
    if i != 2 then
      wait(110)
    end
  end
  wait(50)
  animate(float)
  animate(go_lid)
end

function intro()
  animate(bounce)
end

function together()
  g_lid = create(20, 134, 56, 81, 2, 3)
  g_coffin = create(10, 136, 56, 81, 2, 3)
end

function chomp(skull)
  local o = 1
  while skull.on do
    if skull.s != 47 then
      skull.s += 1
    else
      skull.s = 45
    end
    skull.y += o
    o *= -1
    wait(20)
  end
end

function back(skull)
  while skull.on do
    explode(
      5,
      10,
      skull.x+4,
      skull.y+4,
      8,
      8
    )
    wait(20)
  end
end

function flicker(skull)
  skull.eyes = true
  while skull.on do
    if rnd(1) < 0.2 then
      skull.eyes = false
      wait(6)
      skull.eyes = true
    end
    wait(10)
  end
end

function hunger(delay)
  if not placer then
		  wait(delay)
		  g_meter = 100
		  while g_meter > -1
		  and not g_lock do
		    local old = nil
		    local continue = true
		    if g_meter >= 100 then
		      while continue do
		        old = g_meter
		        for i = 1,50 do
		          if old != g_meter then
		            break
		          elseif i == 50 then
		            continue = false
		          end
		          wait(1)
		        end
		        wait(1)
		      end
		    end
		    if not g_pause then
		      g_meter -= 1
		    end
		    wait(2)
		  end
		  if not g_lock then
		    g_pause = false
		    g_near = nil
		    animate(die)
		  end
		  animate(hunger, 45)
  end
  -- lose condition
end

function transition()
  if not g_lock then
    my_sfx("complete")
		  g_lock = true
		  g_x = 956
		  g_rt = 3
		  g_bt = 3
		  for i = 1,64 do
		    g_x += 1
		    g_o = 1
		    wait(1)
		  end
		  -- weird bug fix
		  g_level += 1
		  if g_level > 3 then
		    g_level = 3
		  end
		  wait(10)
		  if g_level == 2 then
		    level_2()
		  elseif g_level == 3 then
		    level_3()
		  end
		  g_ui = g_y+1
		  for i = 1,64 do
		    g_x -= 2
		    g_o = -2
		    wait(1)
		  end
		  g_lock = false
  end
end

function character(args)
  local mob = args[2]
  local name = mob.name
  local actor = create(args[1], mob.s, args[3], args[4], mob.w, mob.h)
  actor.move = false
  actor.dy = mob.dy
  actor.og = mob.s
  actor.on = true
  if g_start == "intro"
  and actor.og == 64 then
    actor.move = true
  end
  if not placer then
    if name == "skull" then
      animate(back, actor)
      animate(chomp, actor)
      animate(flicker, actor)
    elseif name == "pinky" then
      local r = rnd(2)\1*2
      actor.hat = create(29, r+116, args[3], args[4], 2, 1)
    elseif name == "ducky" then
      animate(ducky_move, actor)
    elseif name == "squid" then
      animate(squid_move, actor)
    end
    if name == "pinky"
    or name == "ducky"
    or name == "squid" then
      actor.button = create(actor.z-5, 40, -10, 0, 2, 2)
      actor.button.show = false
    end
    local lock = false
    while actor do
      local off = -2
      if actor.og == 68 then
        off = 6
      end
      off = 0
      -- jump
      local bool = actor.x > g_x+255
      and (actor.move or (not actor.move
      and actor.flip))
      if g_start != "game" then
        bool = false
      end
      if (g_x+off > actor.x
      or bool) and not g_lock then
        local target = actor.target
        local z = actor.z
        actor.on = false
        if actor.og == 45
        and g_x > 400
        and not g_lock then
          animate(transition)
        end
        if actor.hat then
          del(g_objects, actor.hat)
        end
        if actor.button then
          del(g_objects, actor.button)
        end
        del(g_objects, actor)
        -- lazy fix
        if not bool and g_y+106 > actor.y then
          if not target
          and actor.z != 31 then
            my_sfx("consume")
          end
          if g_meter < 100 then
            g_meter = 100
          else
            g_meter += 0.01
          end
        end
        actor = nil
      end
      if actor.on and actor.move
      and name != "skull" then
        if name == "pinky"
        or name == "squid" then
          if g_x+70 > actor.x then
            if not lock then
              if name == "pinky"
              and actor.s == actor.og then
                lock = true
                actor.s += 32
                actor.og += 32
                actor.hat.y -= 3
              elseif name == "squid" then
                lock = true
                actor.eyes = true
              end
            end
          elseif lock and actor.z != -1 then
            lock = false
            if name == "pinky" then
              actor.s -= 32
              actor.og -= 32
              actor.hat.y += 3
            elseif name == "squid" then
              actor.eyes = false
            end
          end
        end
        if name == "ducky"
        and actor.dy > 0 then
          actor.s = 76
        else
          local hat = actor.hat
          if actor.s == actor.og then
            actor.s += 2
            if hat then
              hat.y += 1
            end
          else
            actor.s -= 2
            if hat then
              hat.y -= 1
            end
          end
        end
      end
      wait(mob.t)
    end
  end
end

function ducky_move(actor)
  while actor.on do
    -- lazy fix for drowing bird
    if actor.y > 500 then
      actor.on = false
      del(g_objects, actor)
      del(g_objects, actor.hat)
      del(g_objects, actor.button)
    end
    if actor.move then
      if fget(mget(actor.x/8+2, actor.y/8), 0) then
        actor.move = false
        actor.flip = true
        actor.s = 74
        wait(4)
        actor.s = 72
      end
      actor.x += 1
    end
    wait(2)
  end
end

function squid_move(actor)
  local x = 0
  local y = 0
  local angle = 0
  local old = actor.y
  local o = 1
  if actor.z == 41 then
    o = 0.5
  end
  while actor.on do
    if actor.move then
      actor.x += o
      angle += 0.005
      y += cos(angle)*1.25
      actor.y = old+y
    end
    wait(1)
  end
end

function sort()
  for i = 2,#g_objects do
    local j = i
    while j > 1 and g_objects[j-1].z > g_objects[j].z do
      g_objects[j],g_objects[j-1] = g_objects[j-1],g_objects[j]
      j -= 1
    end
  end
end

function create(z, s, x, y, w, h, flip)
  local object = {
    z = z,
    s = s,
    x = x,
    y = y,
    w = w,
    h = h,
    show = true,
    flip = flip
  }
  if not object.w then
    object.w = 1
  end
  if not object.h then
    object.h = 1
  end
  add(g_objects, object)
  sort()
  return object
end

function loop()
  for i = 0,14 do
    explode(
      10,
      30,
      0,
      i*10,
      7,
      12,
      true
    )
  end
end

function new_spark(n, z, i_x, i_y, min_r, max_r, shadow)
  local spark = {
    z = z,
    x = i_x,
    y = i_y,
    i_x = i_x,
    i_y = i_y,
    r = rnd(max_r),
    min_r = min_r,
    max_r = max_r,
    shadow = shadow
  }
  if shadow then
    spark.x += g_x
    spark.y += g_y
    spark.velx = rnd(0.5)
    spark.vely = rnd(0.7)-0.35
  else
    spark.velx = rnd(1)-0.5
    spark.vely = rnd(1)-0.5
  end
  if spark.r < min_r then
    spark.r = min_r
  end
  spark.mass = 15/spark.r
  return spark
end

function explode(n, z, i_x, i_y, min_r, max_r, shadow, c)
  for i = 1,n do
    local s = new_spark(n, z, i_x, i_y, min_r, max_r, shadow)
    if shadow then
      s.c = 0
      add(g_shadows, s)
    else
      if not c then
        s.c = 0
      else
        s.c = c
      end
      add(g_behinds, s)
    end
  end
end

function _update60()
  local bool = g_start == "game"
  if bool then
    controller()
  end
  if g_reboot and (btn(4)
  or btn(5)) then
    extcmd("reset")
  end
  updater()
  if bool then
    buttons()
  end
  draw()
end

function go_shadow(to)
  local old = g_near
  g_lock = true
  for i = 1,to do
    g_x += 6
    g_o = 6
    wait(1)
  end
  -- lazy fix to not
  -- always deleting
  -- in time
  del(g_objects, old.button)
  del(g_objects, old)
  my_sfx("consume")
  for i = 1,to do
    g_c += 6
    wait(1)
  end
  g_lock = false
end

function pause_meter()
  g_pause = true
  local old = nil
  local continue = true
  while continue do
    old = g_meter
    for i = 1,120 do
      if old != g_meter then
        break
      elseif i == 120 then
        continue = false
      end
      wait(1)
    end
    wait(1)
  end
  g_pause = false
end

function controller()
  g_o = 0
  if g_lock then
    return
  end
  if g_level == 3
  and g_x > 920 then
    animate(win)
  end
  if btn(1) and not btn(0) then
    g_x += 1
    g_o = 1
    if g_x > g_c+5
    and g_x < 902 then
      g_c += 1
    end
  elseif btn(0) and not btn(1) then
    if g_x > -10 then
      g_x -= 1
      g_o = -1
      if g_x < -10 then
        g_x = -10
      end
      if g_x <= g_c-10 then
        g_c -= 1
        if g_c < 0 then
          g_c = 0
        end
      end
    end
  end
  if not btn(4) then
    g_zdown = false
  end
  if btn(4) and not g_zdown then
    if g_rt != 0 and g_near then
      my_sfx("z")
    end
    g_zdown = true
    -- may need to add back g_smallest < 127
    if g_near and g_rt != 0 then
      local x = g_near.x-g_x
      local off = 0
      if g_near.og == 68 then
        off = 1
      end 
      x = x/6\1+4+off
      animate(go_shadow, x)
      g_near.target = true
      g_rt -= 1
    end
  end
  if not btn(5) then
    g_xdown = false
  end
  if btn(5) and not g_xdown
  and g_bt != 0 and not g_pause then
    if g_bt != 0 then
      my_sfx("x")
    end
    g_xdown = true
    animate(pause_meter)
    g_bt -= 1
  end
end

function wait(duration)
  for i = 1,duration do
    yield()
  end
end

function animate(call, args)
  local co = cocreate(function() call(args) end)
  add(g_coroutines, co)
end

function updater()
  for co in all(g_coroutines) do
    if costatus(co) == "dead" then
      del(g_coroutines, co)
    else
      coresume(co)
    end
  end
end

function x_distance(o)
  local x1 = g_x
  local x2 = o.x+o.w*4-1
  local dx = (x1-x2)/64
  local squared = dx^2
  if squared < 0 then return 32767 end
  return (sqrt(squared)*64)\1
end

function buttons()
  g_near = nil
  g_smallest = 1000
  for o in all(g_objects) do
    if o and o.x < g_x+129
    and not (o.dy and o.flip) then
      o.move = true
    end
    if o and o.button then
      o.button.x = o.x+o.w*4-5
      o.button.y = o.y-10
      if o.s >= 96 and o.s <= 99 then
        o.button.y -= 3
      end
      local value = x_distance(o)
      if g_rt != 0 and value > 20 then
        if value < g_smallest
        and value < 122 then
          g_smallest = value
          g_near = o
        end
      end
    end
  end
  for o in all(g_objects) do
    if o and o.button then
      if g_near == o then
        o.button.show = true
      else
        o.button.show = false
      end
    end
  end
end

function physics(o)
  o.dy += g_gravity
  if o.dy > 0 then
    if fget(mget(o.x/8+0.2, o.y/8+2), 0) then
      o.dy = 0
    end
  end
  bc = o
  bc.y += mid(-3, bc.dy, 3)
  for i = 1,3 do
    if not fget(mget(bc.x/8+0.2, bc.y/8+2), 0) then
      bc.y += 1
      break
    end
    bc.y -= 1
  end
  o = bc
end

function colors(o)
  while o.on do
    if o.button.show
    and g_rt != 0 then
      explode(
        10,
        3,
        o.button.x+o.w*4-4,
        o.button.y+4,
        2,
        4,
        false,
        8
      )
    end
    wait(10)
  end
end

function draw()
  cls()
  camera(g_c, g_y)
  local last = g_level == 3
  and g_start != "done"
  for i = 0,7 do
    if not last then
      map(0, 32, i*127+i, g_y, 16, 16)
    end
  end
  if last then
    rectfill(124, 384, g_c+127, 511, 1)
    map(0, 32, -4, 384, 16, 16)
    wave_1()
  end
  map()
  if last then
    donut()
  end
  -- go
  if g_go then
    local y = 50
    spr(94, g_go_x+17, y, 2, 3)
    spr(g_go_s, g_go_x, y+8, 3, 2)
  end
  -- draw vampire early
  if g_status == "hunger"
  or g_status == "game" then
    local o = g_vamp
    if o then
      spr(o.s, o.x, o.y, o.w, o.h, o.flip)
    end
  end
  -- move orange background back
  if g_w_o == 67 then
    rectfill(g_c+63-g_w_o, g_y+63-g_w_o,
    g_c+63+g_w_o, g_y+63+g_w_o, 9)
  end
  -- behind particles
  for s in all(g_behinds) do
    if s.r > 1 then
      s.x += s.velx/s.mass
      s.y += s.vely/s.mass
      s.r -= 0.05
    else
      del(g_behinds, s)
    end
    circfill(s.x, s.y, s.r, s.c)
  end
  -- objects
  for o in all(g_objects) do
    if not (o == g_vamp
    and (g_status == "hunger"
    or g_status == "game")) then
      if o.dy and not placer then
        physics(o)
      end
      if o.s >= 17 and o.s <= 19
      and not o.eyes then
        pal(8, 0)
      end
      if o.s >= 40 and o.s <= 41 then
        palt(0, false)
        palt(15, true)
      end
      if (o.s >= 64 and o.s <= 71)
      or (o.s >= 96 and o.s <= 99) then
        palt(0, false)
        palt(15, true)
      end
      if o.s >= 68 and o.s <= 71 then
        if not o.eyes then
          pal(8, 12)
        else
          pal(8, 0)
        end
      end
      if o.s >= 72 and o.s <= 77 then
        if not o.flip then
          pal(15, 8)
          pal(14, 2)
        else
          pal(15, 2)
          pal(14, 8)
        end
      end
      if o.show then
        spr(o.s, o.x, o.y, o.w, o.h, o.flip)
        -- lazy fix
        if o.button and o.button.show
        and not o.button.setup then
          o.button.setup = true
          animate(colors, o)
        end
      end
      pal()
    end
  end
  -- drowning duck
  if last then
    wave_2()
  end
  -- vampire shadows
  for s in all(g_shadows) do
    if s.r > 1 then
      s.x += s.velx/s.mass
      if s.shadow then
        s.x += g_o
      end
      s.y += s.vely/s.mass
      s.r -= 0.05
    else
      local new = new_spark(s.n, s.z, s.i_x, s.i_y, s.min_r, s.max_r, s.shadow)
      add(g_shadows, new)
      del(g_shadows, s)
    end
    circfill(s.x, s.y, s.r, 0)
  end
  -- ui and shadow base
  if g_status == "game"
  and g_start != "done" then
    rectfill(-1, g_y, g_x+4, g_y+127, 0)
  end
  if g_start == "game" then
    rectfill(g_c+8, g_ui, g_c+119, g_ui+10, 0)
    rect(g_c+7, g_ui, g_c+36, g_ui+11, 7)
    rect(g_c+36, g_ui, g_c+65, g_ui+11, 7)
    -- tokens
    for i = 0,g_bt-1 do
      spr(25, g_c+i*9+38, g_ui+2)
    end
    for i = 0,g_rt-1 do
      spr(24, g_c+i*9+9, g_ui+2)
    end
    local x1 = g_c+70
    local x2 = g_c+124
    rect(x1-5, g_ui, x2-5, g_ui+11, 7)
    local c = 2
    if g_pause then
      c = 1
    end
    -- draw back of bar
    rectfill(x1-3, g_ui+2, x2-7, g_ui+9, c)
    -- draw actual bar
    if g_meter >= 0 then
      c = 8
      if g_pause then
        c = 12
      end
      rectfill(x1-3, g_ui+2, x2+g_meter\1/2-57, g_ui+9, c)
    end
  end
  -- box
  if g_start != "game" then
    if g_show then
      palt(0, false)
      palt(15, true)
      spr(164, g_c+34, g_point_y, 1, 2)
      pal()
    end
    rectfill(g_c+2, g_box_y, g_c+125, g_box_y+38, 0)
    rect(g_c+2, g_box_y, g_c+125, g_box_y+38, 7)
    if g_point_y > 28 then
      line(g_c+35, 40, g_c+38, 40, 0)
    end
    ?g_message,g_c+7,g_y+7,7
  end
  if g_c < 73 and g_level == 1 then
    -- colors sort of work
    pal(2, 130, 2)
    pal(4, 132, 2)
    pal(8, 136, 2)
    for i = 0,3 do
      poke(0x5f79+i, 0x77)
    end
  end
  -- lose and win boxes
  local o = g_d_o
  if o != -1 then
    rectfill(g_c+63-o, g_y+63-o,
    g_c+63+o, g_y+63+o, 0)
    ?g_d_s, g_c+15, g_y+61, 8
  end
  -- jump
  o = g_w_o
  if o != -1 then
    if g_w_overlay then
      rectfill(g_c+63-o, g_y+63-o,
      g_c+63+o, g_y+63+o, 9)
    end
    -- win donuts
    if o == 67 then
      rectfill(g_c+39, g_y+39,
      g_c+87, g_y+87, 7)
      rect(g_c+39, g_y+39,
      g_c+87, g_y+87, 0)
      pal()
      palt(0, false)
      palt(13, true)
      sspr(80, 64, 16, 13, g_c+63+7, g_y+61)
      pal(2, 1)
      pal(14, 12)
      sspr(80, 64, 16, 13, g_c+63-22, g_y+63+10, 16, 12, true)
      pal(2, 3)
      pal(14, 11)
      sspr(80, 64, 16, 13, g_c+50, g_y+42, 16, 14, true)
      pset(g_c+56, g_y+49, 11)
    end
  end
  -- debug
  if debug then
    color(10)
    print("g_c: "..g_c.." g_x: "..g_x, g_c+7, g_y+14)
    print("# objs: "..#g_objects)
    print("# co.s: "..#g_coroutines)
    print("cpu: ".. stat(1))
    print(error)
  end
end

function wave_1()
  pset(192, 480, 4)
  palt(0, false)
  spr(16, 304, 488)
  spr(16, 312, 488)
  for i = 0,5 do
    spr(32, 296+i*8, 496)
    spr(48, 296+i*8, 504)
  end
  spr(16, 960, 480)
  spr(16, 968, 480)
  spr(32, 960, 488)
  spr(32, 968, 488)
  spr(48, 968, 496)
  pal()
  for i = 0,8 do
    spr(187, 120+i*8+w_x, w_y)
  end
  rectfill(120+w_x, w_y+8, 191+w_x, 511, 13)
end

function wave_2()
  spr(49, 248, 495)
  spr(50, 352, 487)
  for i = 0,73 do
    spr(187, 432+i*8+w_x, w_y)
  end
  rectfill(432+w_x, w_y+8, 1023+w_x, 511, 13)
  spr(59, 432, 496)
  spr(55, 432, 504)
end

function donut()
  local x = 947
  local y = 440
  palt(0, false)
  palt(13, true)
  spr(140, x, y, 4, 4)
  spr(138, x+8, y-14, 2, 2)
  pal()
  spr(78, x+9, y+10, 2, 1)
  line(x-1, y+7, x-1, y+5, 2)
  line(x+32, y+6, x+32, y+3, 2)
end

function go_wave_x()
  local o = 1
  while g_start == "game" do
    w_x += 2*o
    o *= -1
    wait(30)
  end
end

function go_wave_y()
  while g_start == "game" do
    for i = 8,1,-1 do
      w_y += i/5
      wait(4)
    end
    wait(10)
    for i = 8,1,-1 do
      w_y -= i/5
      wait(4)
    end
    wait(10)
  end
end
__gfx__
000000006666666d666666666666666d6666666d6666666d6666666d0033330003bbbbb024422222224444444444444444444444000000000000000000000000
0000000066ddd6d566ddd6ddd6ddd6d56dddddd566ddd6d56dddddd5033bb3303bbbbbbb44444442224000000000022400000000000000000000000000000000
000000006d5ddd556d5ddd5ddd5ddd556d6666d56d5ddd556dddddd503bbbb302223bbbb44442244224000000000022400000000000000000000000000000000
000000006dddddd56dddddddddddddd56d6dd5d56dddddd56dddddd5333bbb33222223bb4444224422433b28011c022400000000000000000000000000000000
000000006dddddd56dddddddddddddd56d6dd5d56dddddd56dddddd53bbbb33324444222444444442243372701170224000000000000000000000000000b0000
0000000066ddd6d566ddd6ddd6ddd6d56d5555d566ddd6d56dddddd53bbbbbb3244244424224444222433b28011c02240000000000000000000b00000000b000
000000006d5ddd556d5ddd5ddd5ddd556dddddd56d5ddd556dddddd533bbbb33244444424224424222433b28011c02240000000000000b0000030b000b303030
00000000655555556555555555555555655555556dddddd56dddddd5033333302222222244444442224444444444444444444444000303000b0b030000b3b300
111011116666666d66666666666666666666666d6dddddd56dddddd503333330088888200ccccc1022400000000002240000000003bbbbbbbbbbbbbbbbbbbbb0
111011116dddddd56dddddddddddddddddddddd566ddd6d56dddddd533bb3b3388222882cc1c1cc1224000000000022400000000333bbbbbbbbbbbbbbbbbbbbb
000000006dddddd56dddddddddddddddddddddd56d5ddd556dddddd53bbbbbb388882882cc1c1cc12240000033b0022400000000333bbbbbb223bbbbbbb23bbb
111110116dddddd56dddddddddddddddddddddd56dddddd56dddddd53bbbbbb388828882ccc1ccc1224055d0337002240000000022223bbb222223bb22222222
111110116dddddd56dddddddddddddddddddddd56dddddd56dddddd533bbbb3388288882cc1c1cc12240557033b0022400000000222422224444422244444442
000000006dddddd56dddddddddddddddddddddd566ddd6d56dddddd50333333088222882cc1c1cc1224055d033b0022400000000222444444444444444444442
101111116dddddd56dddddddddddddddddddddd56d5ddd556dddddd500024000288888221ccccc11224055d033b0022400000000222444444444444444444442
1011111165555555655555555555555555555555655555556dddddd5000240000222222001111110224444444444444444444444222444444444444444444442
0000000024444444244444444444444444444444022444406dddddd500000000f2222222ffffffff224000000000022400000000067766600677666006776660
1110111124444444244444444444444444444444555566666dddddd500008200220000022fffffff224000000000022400000000777777767777777677777776
1110111124400000000000000000000000000244222244446dddddd500082200200888002fffffff224000000000022400228000666667776666677766666777
0000000000000000000000000000000000000000222244446dddddd50000b000200008002fffffff22411c280000022400227000086708770867087708670877
1111101100000000000000000000000000000000222244446dddddd500303000200080002fffffff224117270000022400228000660666776606667766066677
1111101100000000000000000000000000000000222244446dddddd5000b0000200800002fffffff22411c280000022400228000666667676666676766666767
0000000000000000000000000000000000000000555566666dddddd500032000200888002fffffff22411c280000022400228000060600600606007006060070
1011111100000000000000000000000000000000022444406555555500422200220000022fffffff224444444444444444444444707076600000000600000006
10111111000000000000000009aaaaa0009aaa00000000007777777844444444f2222222ffffffff222222222222222222222222066666000707076600000076
0000000000000000000000000009a0000009a000009999007788878542444444ffffffffffffffff444444424444444224444442000000000066666000707660
1111101100dddd0000dddd009aa9a9aa0009a0000aaaaa907858885544444444ffffffffffffffff444444424422444224444442000000000000000000066600
11111011055655d00d5565509a0aaa0a099aaaa0000a00907888888544422244ffffffffffffffff442244424422444224444442000000000000000000000000
00000000000600d00d0060009aaaaaaa99aaaaaa0a99aa907888888544422244ffffffffffffffff442244424444444224444442000000000000000000000000
1011111106dd66d00d66dd60009aaa0099aaaaaa00aa00907788878544422244ffffffffffffffff444444424444444224444442000000000000000000000000
10111111075575d00d07557000056000099aaaa0090090907858885544444444ffffffffffffffff444442424444444224444442000000000000000000000000
000000000666660000666660009aaa000099aa00099999007555555544444444ffffffffffffffff444444422222222224444442000000000000000000000000
ffffffffffffffffffffffffffffffffffffffdddfffffffffffffffffffffff0007067660000000000000000000000000070676600000000000066760600000
fffffffffffffffffffffffffffffffffffffdcccdffffffffffffdddfffffff0000677776000900000706766000000000006fe7fe0009009000677776000000
ffffffffffffffffffffffffffffffffffffdccc7ccffffffffffdc77dffffff00006fe7fe099000000067777600090000006fe7fe0990000990827826000000
ffffffffffffffffffffffffffffffffffffc77ccccfffffffffdcc77ccfffff000067779990000000006fe7fe09900000006777999000000009997776000000
feeeee2ee2eeeeeffffffffffffffffffffdc77cccccffffffffcccccccfffff000006790000a000000067779990000000000679000000000000009760000000
feeeee2222eeeeeffeeeee2ee2eeeeefffdccccccccccffffffdc7ccccccffff00000067999a00000000067900000000077600679999a00000a9997600000000
ee270722227072eefeeeee2222eeeeefffdc7ccc77cccfffffdccccc777ccfff0006777760000000000000679900a00007776677600000000000007600000000
ee277799997772eeee270722227072eeffdccccc77cccfffffdc77cc777ccfff006777777600000000667777609a000006777777760000000000000000000000
ee222279992222eeee277799997772eefffdccccccccffffffdc77cc777ccfff0067767777700000067777777600000000666777777000000000000000000000
eeee22999922eeeeee222279992222eeffffdddddc7ffffffffdccccccccffff0067767777760000077766777770000000000067777600a90000000000000000
2eeeeee22eeeeee2eeee22999922eeeefffdcc7cccccffffffffdddddc7fffff006770677766000007776067777600a900000067777600a90000000000000000
efeee067760eeefe2eeeeee22eeeeee2ffdc88ccc88ccffffffdcc7cccccffff000670666660000000760067777600a900000069666a9a990000000000000000
efffeeeeeeeefffeefee06777760eefeffdc00ccc00ccfffffdc88ccc88ccfff000000900090000000000069666a9a9900000000a000000033b0000000000000
ee2ffe2ff2eff2eeefffeeeeeeeefffefffcccc0ccccffffffdc00ccc00ccfff00000a0000a0000000a99a9000000000000000000a00000033bb000000000000
eeffffeffeffffeeee2ffe2ff2eff2eeffffdcccccdffffffffcccc0ccccffff0000999a00999a0000a90000000000000000000009aa000033bbb00000000000
fffeee2ff2eeefffeefee2effe2eefeeffffcfcfcfcfffffffffdcccccdfffff0000aaaa00aaaa0000a9000000000000000000000999000033bbbb0000000000
fffffffffffffffffffffffffffffffffffcffcfcffcffffffffcfcfcfcfffff0033bbbbbbbbbbbbbbbbbbbb0033bbbbbbbbbbbbbbbbbbbbbbbbbbb000000000
fffeeeeeeeeeeffffffffffffffffffffdfcdfffffdcfdfffffcffcfcffcffff0033bb677777bbb6777777bb0033bb77777bbbb777777bbbbbbbbbbb00000000
feeeee2ee2eeeeeffffeeeeeeeeeefffdfffcfffffcfffdffffcfffffffcffff0033b67777777b677777777b0033b7777777bb77777777bbbbbbbbbbb0000000
fe277722227772effee7772ee2777eefcfffcfffffcfffcffdfcfffffffcfdff0033b677bb677b677bbb677b0033b77bbb77bb77bbbb77bbbbbbbbbbbb000000
ee270722227072eefe777722227777effcfdfffffffcfcffdfffdfffffdfffdf0033b677bbbbbb677bbb677b0033b77bbbbbbb77bbbb77bbbbbbbbbbbbb00000
ee277799997772eeee770722227077eeffdfffffffffdfffcfffcfffffcfffcf0033b677b6777b677bbb677b0033b77bb777bb77bbbb77bbbbbbbbbbbbbb0000
ee222279992222eeee777999999777eefffffffffffffffffcfdfffffffcfcff0033b677b6777b677bbb677b0033b77bb777bb77bbbb77bbbbbbbbbbbbb00000
eeee22999922eeeeee227979999722eeffffffffffffffffffdfffffffffdfff0033b677bb677b677bbb677b0033b77bbb77bb77bbbb77bbbbbbbbbbbb000000
2eeeeee22eeeeee2eeee29999992eeee0000009aa9000000000000d6660000000033b67777777b677777777b0033b7777777bb77777777bbbbbbbbbbb0000000
efee06777760eefe2eeeeee22eeeeee200009779999900000a00d676666d00900033bb677777bbb6777777bb0033bb77777bbbb777777bbbbbbbbbbb00000000
effe00000000effeefe0067777600efe0009aaaaaaaa90e0009a67666666a9000033bbbbbbbbbbbbbbbbbbbb0033bbbbbbbbbbbbbbbbbbbbbbbbbbb000000000
effe06888860effeefe0000000000efe00e9999999999e00000d56655665600000000000000000000000000000000000000000000000000033bbbb0000000000
efffeeeeeeeefffeefe0068888600efe00e0000000000e00000000000000000000000000000000000000000000000000000000000000000033bbb00000000000
ee2ffe2ff2eff2eeeffeeeeeeeeeeffe0000000000000000000000000000000000000000000000000000000000000000000000000000000033bb000000000000
eeffffeffeffffeeee2ffe2ff2eff2ee0000000000000000000000000000000000000000000000000000000000000000000000000000000033b0000000000000
fffeee2ff2eeefffeefee2effe2eefee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03030303030303030303030303030303000056660000000000004444420000000000444442220000dddddeebeeeddddddddd22222266666222222666662222dd
00000000000000000000000000000000005666666000000000044444442000000004222224222000dddeeeeeeeeeedddddd2888827777628888277776288882d
01010101010101010101010101010101005666f86000000000044444442000000004222884222000dde8ee2222eeaedddd288882777762888827777628888282
000000000000000000000000000000000055ffff0000000000444444444200000042228888422200d2eee200002eee2dd2888867777628888677776288882228
020202020202020202020202020202020055ffff0000000000444474444200000042228888422200d42eee2222eee24d2888867777628888677776288882d228
00000000000000000000000000000000005557755000000004444474444420000422288888842220d42e9eeeeeeee2fd888867777628888677776288882dd228
03030303030303030303030303030303552288688500000004444474444420000422288888842220df42eeeeecee244d888867777628888677776288882dd228
00000000000000000000000000000000522288688200000044444474444442004222888888884222d4e422eeee224f4d888867777628888677776288882dd222
01010101010101010101010101010101522828782800000044444777444442004222888888884222d4ff442222e4ff4d2222266666d2222d66666d2222ddd22d
00000000000000000000000000000000022828882800000044444474444442004222888888884222ddfff24444ffff4dd2442ddd22ddddddddddddd442ddd22d
020202020202020202020202020202020ff02888f000000044444474444442004222888888884222dd4ffffff4fff4ddd2442ddd22ddddddddddddd442ddd22d
0000000000000000000000000000000000f0dd9dd000000004444444444420000422288888842220ddd44ffff4f44dddd2442ddd22ddddddddddddd442ddd22d
03030303030303030303030303030303000550055000000004444444444420000422288888842220ddddd444444dddddd2442ddd22ddddddddddddd442ddd22d
00000000000000000000000000000000005600560000000004444444444420000422288888842220ddddddd22dddddddd2442ddd22ddddddddddddd442ddd22d
0101010101010101010101010101010100f000f00000000004444444444420000422288888842220ddddddd42dddddddd2442ddd22222222222222244222222d
00000000000000000000000000000000000000000000000000444444444200000042228888422200ddddddd42dddddddd2442dd200000000000000044200022d
02020202020202020202020202020202f70007ff0000000000444444444200000042228888422200b224444444444442d2442d2000000000000000044200222d
00000000000000000000000000000000f70007ff0000000000444444444200000042228888422200bb24444444444442d244220000000000000000044202222d
03030303030303030303030303030303f70007ff0000000000444444444200000042228888422200b224444444444442d244222222222222222222244222222d
00000000000000000000000000000000f70007ff00000000000444444420000000042228842220002244444444444442d244444244444444444442444222222d
01010101010101010101010101010101f70007ff00000000000444444420000000042228842220004444444444444444d244477777777777777764444222222d
00000000000000000000000000000000f70007ff00000000000444444420000000042222242220004444444444444444d244470707070700070764444222222d
02020202020202020202020202020202f70007ff00000000000044444200000000004444422200004444444444444444d244470007070700070764444222222d
00000000000000000000000000000000f70007ff00000000000000000000000000000000000000004444444444444444d244477707070707077764444222222d
03030303030303030303030303030303f70007ff0000000000000000000000004424444200044000bbbbbbbb00000000d24447000770070707076444422222dd
00000000000000000000000000000000f70077ff0000000000000000000000004424424200044000bbbbbbbb00000000d2424777777777777777644442222ddd
01010101010101010101010101010101f7007fff0000000000000000000000000224444000044000bbb23bbb00000000d244444444442444444444244222dddd
0000000000000000000000000000000077007fff00000000000000000000000005566660000440002222222277dddd77d22222222222222222222222222ddddd
0202020202020202020202020202020270077fff000000000000000000000000022444400004400044444444dd7777dddddddddddddddddddddddddddddddddd
000000000000000000000000000000007777ffff0000000000000000000000000224444000044000444444441cccccc1dddddddddddddddddddddddddddddddd
03030303030303030303030303030303ffffffff00000000000000000000000002242440000440004444444411111111dddddddddddddddddddddddddddddddd
00000000000000000000000000000000ffffffff000000000000000000000000022444400004400044444444dddddddddddddddddddddddddddddddddddddddd
00000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000520062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43000063630000000000330052525210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43430063630053520033333352525260000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
32323232323232323232323232324261000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000022203011101111101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000223210306032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000050000000000000000000000000000000000000000000005200000000000000000000000000700000000000000000000000
00000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000052000000000000000062000000000000000000000000000000000000007000005252e00000000000000000000000700000000000000000000000
00000000000000005100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000000005252000000000000009b0000000000000000000000700000000000000071e0d1e1e1e1f100000000000000000000700000000000000000000000
00000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0e0f0000000000000
4333000000525252520000000052009b00000000000000000000007000700000000000d1e1aa7390c390d000700000000000d0d0710000000000000000000000
00d0710000000000610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f0d1e1e1e1f1d000000000
4343d000005252525200f0005252529b000000000000000000e000710071d0f0e05bd1aa7390a3b3a3baf1d071d072e0f0d1f1e1e1f1f0000000000000000000
00d1f100f00072006200000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1e1aa90214190f100000000
102080402131411011118030203141113232323232323232d1e1e1e1e1e1e1e1e1abaa90c3c32130b390bae1e1f1e1e1abaaa3b390bae1123200000022324260
9010a3d1f100804010000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1aac37340010150a3d0000000
90101111a310213141b31090a34090730000000000000000b37390c373c37390a373c3a3b31000001040a37390b3a37390739073c37390000000000000000061
10c340c3a31090601012323232328b32323232328b3232000000000000000000000000000000000000000000000000000000f0907390901002025190f1000000
73a31090b37340109010a31040b373a30000000000000000c37373a3a3b3a37390a3a3b360000000000050a3739090c37390a3a390a3b3000000000000000061
00b390b390b360620000000000008b00000000008b0000000000520000000000000000000052520000000000000000000000d1aaa373a3b310036073c3000052
b39073b37310a390b3a373a3b39011b30000000000000000a3b3a390a37390a373c3a37362000000000051b390a3c3b3b3a3b3c3a3b373000000000000000062
00007390001062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111111011111110111111101111
111011111110111111101111111011111110111111101111111011111110kkkkkiii111111101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000000kkkkkkkiii00000000000000000000000000000000000000000000000000000000000
11111011111110111111101111111011111110111111101111111011111444444422201111111011111110111111101111111011111110111111101111111011
1111101111111011111110111111101111111011111110111111101111kkkkkkkkkiii1111111011111110111111101111111011111110111111101111111011
0000000000000000000000000000000000000000000000000000000000kkkk7kkkkiii0000000000000000000000000000000000000000000000000000000000
101111111011111110111111101111111011111110111111101111111kkkkk7kkkkkiii110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111144444744444222110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000kkkkkk7kkkkkkiii00000000000000000000000000000000000000000000000000000000
11101111111011111110111111101111111011111110111111101111kkkkk777kkkkkiii11101111111011111110111111101111111011111110111111101111
11101111111011111110111111101111111011111110111111101111kkkkkk7kkkkkkiii11101111111011111110111111101111111011111110111111101111
00000000000000000000000000000000000000000000000000000000444444744444422200000000000000000000000000000000000000000000000000000000
111110111111101111111011111110111111101111111011111110111kkkkkkkkkkkiii111111011111110111111101111111011111110111111101111111011
111110111111101111111011111110111111101111111011111110111kkkkkkkkkkkiii111111011111110111111101111111011111110111111101111111011
000000000000000000000000000000000000000000000000000000000kkkkkkkkkkkiii000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111144444444444222110111111101111111011111110111111101111111011111110111111
1011111110111111101111111011111110111111101111111011111110kkkkkkkkkiii1110111111101111111011111110111111101111111011111110111111
0000000000000000000000000000000000000000000000000000000000kkkkkkkkkiii0000000000000000000000000000000000000000000000000000000000
1111101111111011111110111111101111111011111110111111101111kkkkkkkkkiii1111111011111110111111101111111011111110111111101111111011
11111011111110111111101111111011111110111111101111111011114444444442221111111011111110111111101111111011111110111111101111111011
00000000000000000000000000000000000000000000000000000000000kkkkkkkiii00000000000000000000000000000000000000000000000000000000000
10111111101111111011111110111111101111111011111110111111101kkkkkkkiii11110111111101111111011111110111111101111111011111110111111
10111111101111111011111110111111101111111011111110111111101kkkkkkkiii11110111111101111111011111110111111101111111011111110111111
00000000000000000000000000000000000000000000000000000000000044444222000000000000000000000000000000000000000000000000000000000000
11101111111011111224444111101111111011116666666d666666666666666666666666666666666666666d1110111111101111111011111110111111101111
111011111110111155556666111011111199991166ddd6d566ddd6ddddddddddddddddddddddddddd6ddd6d51110111111101111111011111110111111101111
000000000000000022224444000000000aaaaa906d5ddd556d5ddd5ddddddddddddddddddddddddddd5ddd5500000000000000000000000000dddd0000000000
11111011111110112222444411111011111a10916dddddd56dddddddddddddddddddddddddddddddddddddd51111101111111011111110111d55655111111011
111110111111101122224444111110111a99aa916dddddd56dddddddddddddddddddddddddddddddddddddd51111101111111011111110111d11601111111011
0000000000000000222244440000000000aa009066ddd6d566ddd6ddddddddddddddddddddddddddd6ddd6d50000000000000000000000000d66dd6000000000
10111111101111115555666610111111191191916d5ddd556d5ddd5ddddddddddddddddddddddddddd5ddd551011111110111111101111111d17557110111111
10111111101111111224444110111111199999116555555565555555555555555555555555555555555555551011111110111111101111111066666110111111
00000000022444400224444009aaaaa0666666666666666d6666666d6666666d6666666d6666666d6666666d6666666d009aaa00000000000224444000000000
1110111155556666555566661119a1116dddddddddddddd566ddd6d56dddddd566ddd6d56dddddd566ddd6d566ddd6d51119a111111011115555666611101111
1110111122224444222244449aa9a9aa6dddddddddddddd56d5ddd556d6666d56d5ddd556dddddd56d5ddd556d5ddd551119a111111011112222444411101111
0000000022224444222244449a0aaa0a6dddddddddddddd56dddddd56d6dd5d56dddddd56dddddd56dddddd56dddddd5099aaaa0000000002222444400000000
1111101122224444222244449aaaaaaa6dddddddddddddd56dddddd56d6dd5d56dddddd56dddddd56dddddd56dddddd599aaaaaa111110112222444411111011
111110112222444422224444119aaa116dddddddddddddd566ddd6d56d5555d566ddd6d56dddddd566ddd6d566ddd6d599aaaaaa111110112222444411111011
000000005555666655556666000560006dddddddddddddd56d5ddd556dddddd56d5ddd556dddddd56d5ddd556d5ddd55099aaaa0000000005555666600000000
101111111224444112244441109aaa11655555555555555565555555655555556555555565555555655555556dddddd51099aa11101111111224444110111111
6666666d6666666d6666666d666666666666666d6666666d6666666d6666666d66666666666666666666666d6dddddd5666666666666666d6666666d66666666
66ddd6d56dddddd566ddd6d56dddddddddddddd566ddd6d56dddddd566ddd6d56dddddddddddddddddddddd566ddd6d56dddddddddddddd566ddd6d566ddd6dd
6d5ddd556dddddd56d5ddd556dddddddddddddd56d5ddd556dddddd56d5ddd556dddddddddddddddddddddd56d5ddd556dddddddddddddd56d5ddd556d5ddd5d
6dddddd56dddddd56dddddd56dddddddddddddd56dddddd56dddddd56dddddd56dddddddddddddddddddddd56dddddd56dddddddddddddd56dddddd56ddddddd
6dddddd56dddddd56dddddd56dddddddddddddd56dddddd56dddddd56dddddd56dddddddddddddddddddddd56dddddd56dddddddddddddd56dddddd56ddddddd
66ddd6d56dddddd566ddd6d56dddddddddddddd566ddd6d56dddddd566ddd6d56dddddddddddddddddddddd566ddd6d56dddddddddddddd566ddd6d566ddd6dd
6d5ddd556dddddd56d5ddd556dddddddddddddd56d5ddd556dddddd56d5ddd556dddddddddddddddddddddd56d5ddd556dddddddddddddd56d5ddd556d5ddd5d
65555555655555556555555565555555555555556555555565555555655555556555555555555555555555556555555565555555555555556555555565555555

__gff__
0001010101010100010100000000000000010101010101000000000000010101000101010100010000000000000000000000000000000001000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000010000010001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000250000000000000000000000000000000011
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003125252500000000000000000000000000000011
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002123232324000000000000000000000000000026
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002010103000000000000000000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022232323000000000000000000000000000000000000000000000000000000000000000000000000000011
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010203021314041101000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222323232323062323000000000000000000000000000000000000000000000000000000000015
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000000005
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000212323232324000000000000000000050000000000000000000000000000000000000000000000000000000000000026
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000150000000000000000000000000000000000000000000000000000000000003504
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000363600000000000000000000000000000000000000000000000000000000000000000000000033000000000000110000000000000a0b000000000000000000000000000000000000000000003406
0000250035010213131303000000320000002500000a0b000a0b0000000a0b0000002500000a0b000a0b0000000a0b000036363600000000000000000000000000000000000000000000000000000000000000000000002525000000000000062500000000001a1b000a0b000a0b000000310000000000000000000000333316
0025253312140104011101053400250000252500001a1b002a2b0025001a1b0000252500001a1b002a2b0025001a1b000036363636000000000000000000000000000000000000000000000000000000000000000000332525253325340000262525000025002a2b001a1b002a2b000031250000000000000000000033343426
0111011214011101121314151214010213130304111214011203010102031111131303041112140112030101020311110112140212140102031104021303020301121303010102031104120114110111011214021214010203110402130302030112130301010203110412011401121411121401020311040213131401011111
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002534000000000000000000000011
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002525250000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000252525252500000000000000000006
0000000000000000000000000000000000000000000000000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000212323232400000000000000000016
0000000000000000000000000000000000000000000000000000000000000000000000000035343433000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026
0000000000000000000000000000000000003100000000000000000000000000000000000021232324000000000000000000000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005
00000000000000000000000000000000000a0c0b000000000000000000000000000000000000000000000000000000000000000000000000000000252500000000000000000000000000000000000000000000000000000000000000000000000000000a0c0b0000000000000000000000000000000000000000000000000015
00000000000000000000000000000000001a2c1b000000000000000000000000000000000000000000000000000000000000000000000000000021232324000000000000000000000000000000000000000000000000000000000000000000000000001a1c1b0000000000000000000000000000000000000000000000000011
00000000000000000000000000000000002a1c2b000000000000000000000000250000000000000000000000000000000000000000000000000000000000000000000033000000000000000000000000003500000000000000003636000000000000312a1c2b0000000000000000000000000000000000000000000000002506
000000000000000000000000000000000a0b000a0b0000000000000000000025252535000000000000000000000a0b000025000000000000000000000000000000000a0c0c0b000000000000000000000025250000000000000036363600000000000a0b000a0b00000000350000000000000000000000000000000000252516
000000000000000000000000000000001a1b001a1b0025340000000000000025252525000000000000000000001a1b000a0c0b0000000025000000000000000000001a2c1c1b000000000000000000000025252500000000003636363600000000001a1b001a1b00000000343300000033000000000000000000000000252516
000000000000000000000000003200002a2b002a2b3425250000000000002525252525340033000000000025002a2b002a2c2b0000002525002500000000000000342a1c2c2b3300002500000027000025252525000000003636363636000e0000002a2b002a2b000000333434330034340000000d070f000000000025252526
14110111011214021214010203110402130302030112130301010203110412011401121411121401020311040213131402131313140112140101111213110402130302030112130301010203120814021303010401121402121401020311080213030203011213031214020311121401111112141d1e1f120814111214011104
__sfx__
010c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
510b00000013118511245210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
990b000011410154111d4210020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b090000050510605106051070510a0510d0511205114051000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000028755247552b75530755000003c7350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011100001175529755000002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000024125000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
650f00000033500335000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b1200000013001150001200000000000000000000000000000000000000000000000000000000001400116000150011700000000000000000000000000000000000000000000000000000000000000000000000
451200002005014050130501305013050130500c0000c0000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000003310d6510e6310262102611026010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1410000016051120510d0510a051070510705107051070510d0000a00007000060000600005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
032000001f0341d0311d0311f0321b0351b0351b035130331d03424031240311d0321b0351f0351b0321f0331f0341d0311d0311f0321b0351b0351b035130331d03424031240311d0321b0351f0351b0321b032
011000080c04300000000000c0430c043000002461500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
711000080f025000000f025000000f025000000f02500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013000000e5000e5000e5000e5000f5000000021500000000f5000f5000f5000f5000e5000000015500000000e5000e5000e5000e5000f5000e50000000000000f5000f5000f5000f5000e5000f5000f5000f500
011000080c00000000000000c00000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001170011700117001170011700117001170011700127001270012700127001270012700127001270000000000000000000000000000000000000000000000000000000000000000000000000000000000
a13000000e5140e5120e5120e5120f5140000021514000000f5140f5120f5120f5120e5140000015514000000e5140e5120e5120e5120f5140e51200000000000f5140f5120f5120f5120e5140f5120f5120f516
513000000e5140e5120e5120e5120f5140000021514000000f5140f5120f5120f5120e5140000015514000000e5140e5120e5120e5120e5140f51200000000000f5140f5120f5120f5120e5140f5120f5120f516
513000000e5140e5120e5120e5120f5140000021514000000f5140f5120f5120f5120e5140000015514000000e5140e5120e5120e5120f5140e51200000000000f5140f5120f5120f5120e5140f5120f5120f516
031800000e5240e5220e5220e5220f5240000021524000000f5240f5220f5220f5220e5240000015524000000e5240e5220e5220e5220f5240e52200000000000f5240f5220f5220f5220e5240f5220f5220f526
031800000e5240e5220e5220e5220f5240000021524000000f5240f5220f5220f5220e5240000015524000000e5240e5220e5220e5220e5240f5220f500000000f5240f5220f5220f5220e5240f5220f5220f526
010c00080c04300000000000c04300000000000c04300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110c00101172511725117251172511725117251172511725127251272512725127251272512725127251272500000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171000000474505745077450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
04 41424344
04 43424344
04 45464344
04 44424344
04 47474344
04 48424344
04 49424344
04 4a424344
03 14151644
00 1a555644
01 1b585744
02 1c424344
01 1d206044
02 1e206044
01 1d1f2044
02 1e1f2044

