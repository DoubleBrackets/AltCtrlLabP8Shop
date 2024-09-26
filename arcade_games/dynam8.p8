pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- globals & utils

-- lil' ecosystem
-- plants regrow on tic
-- more frogs can spawn


_g = {
  id = 0,  -- entity id
  show = false,
  debug = nil,
  
  players = {},
  actors = {},
  boxes = {},
  
  max_cpu = -1
}


_c = {
  black = 0,
  purple = 2,
  red = 8,
  yellow = 10,
  l_green = 11,
  l_purple = 13,
  pink = 14,
  
  left = "left",
  right = "right",
  top = "top",
  bottom = "bottom",
  
  screen_dim = 127,
  big_margin = 100,
  small_margin = 10,
  
  pretty = false,
  spawn = "spawn",
  
  gravity = 0.12,
  friction = 0.85,
  accel = 0.12,
  
  rain = {
    dx = 3,
    var = 100,  -- variance
    delay = 1.2,
    splash = 4,
    height = 100,
    combos = {
      {8, 2},
      {10, 9},
      {11, 3},
      {12, 1}
    }
  },
  
  stats = {
    idle = "idle",
    moving = "moving"
  },
  
  f = {  -- flags
    solid = 0,
    flower = 1
  }
}


local utils = {}
function utils.add_actor(class, props)
  local instance = class.new(props)
  if instance.spawn == false then
    instance:_del()  -- just in case...
    return
  end
  
  _g.id += 1
  instance.id = _g.id
  
  if instance.z then
    add(_g.actors, instance, instance.z)
  else
    add(_g.actors, instance)
  end
end


function utils.deep_join(t1, t2)
  if t2 == nil then
    return t1
  end
  for k, v in pairs(t2) do
    if type(v) == "table" and
    type(t1[k]) == "table" then
      utils.deep_join(t1[k], v)
    else
      t1[k] = v
    end
  end
  return t1
end


function utils.to_list(item)
  if type(item) == "string" then
    return split(item)
  end
  return item
end


function utils.rand_elem(list)
  list = utils.to_list(list)
  local i = rnd(#list)\1 + 1
  return list[i]
end


function utils.get_but_elem(elem, elems)
  local list = {}
  for _elem in all(elems) do
    if _elem != elem then
      add(list, _elem)
    end
  end
  return list
end


function utils.ternary(cond, t, f)
  if cond then
    return t
  end
  return f
end


function utils.is_type(inst, mt)
  return getmetatable(inst) == mt
end


function utils.get_cam_pos()
  return peek2(0x5f28), peek2(0x5f2a)
end


function utils.get_sx_sy(s)
  return s % 16 * 8, s \ 16 * 8
end


menu = {}
function menu.add_debug()
  local status = _g.show and
    "on" or "off"

  menuitem(1, "debug "..status,
    function()
      _g.show = not _g.show
      menu.add_debug()
    end
  )
end
-->8
-- boilerplate


-- base class
local base = {
  x = 0,
  y = 0,
  c = _c.yellow
}

function base:update() end

function base:draw()
  pset(self.x, self.y, self.c)
end

function base:_del()
  del(_g.actors, self)
end


-- sprite class
local sprite = setmetatable({
  s = 0,  -- sprite
  s_w = 8,  -- width
  s_h = 8,  -- height
  fl = false  -- flipped
}, base)
sprite.__index = sprite

function sprite:update() end

function sprite:draw()
  local _ENV = self
  spr(
    s, x, y,
    1, 1, fl
  )
  self:_draw_box()
end

function sprite:super_draw()
  self:draw()
end

function sprite:_create_box(margins)
  margins = utils.to_list(margins)
  if not margins or #margins != 4 then
    margins = split"-4,-4,4,4"
  end
  
  local names = self.box_names
  if not names then
    self.box_names = {}
    names = self.box_names
  end
  
  local name = #names > 0 and
    "box_"..tostr(#names + 1) or
    "box"
  
  local s_w,s_h = ceil(self.s_w/2),ceil(self.s_h/2)
  
  self[name] = {
    id = #self.box_names + 1,
    x_0 = self.x + s_w + margins[1],
    y_0 = self.y + s_h + margins[2],
    x_1 = self.x + s_w + margins[3] - 1,
    y_1 = self.y + s_h + margins[4] - 1,
    margins = margins,
    parent = self
  }
  
  add(names, name)
  add(_g.boxes, self[name])
  
  return self[name]
end

function sprite:_draw_box(box, c)
  box = box or self.box
  if not _g.show or not box then
    return
  end
  
  rect(
    box.x_0, box.y_0,
    box.x_1, box.y_1, c or _c.red
  )
end

function sprite:_for_box_name(func)
  local names = self.box_names
                or {"box"}
  results = {}
  for name in all(names) do
    add(results, func(self[name]))
  end
  return results
end

function sprite:_get_mid()
  return self.x + self.s_w\2,
         self.y + self.s_h\2
end

function sprite:_del()
  self:_for_box_name(
    function(box)
      del(_g.boxes, box)
    end
  )
  del(_g.actors, self)
end


-- physics sprite class
local physics = setmetatable({
  dx = 0,
  dy = 0,
  max_dx = 1.5,
  max_dy = 2,
  left = false,
  right = false,
  top = false,
  bottom = false,
  friction = 1,
  air_friction = 1,
  up_gravity = _c.gravity,
  super_draw = sprite.draw,
  physics = true},
  {__index = sprite}
)
physics.__index = physics

function physics:_setup()
  self:_create_box()
  self:_create_colliders()
end

function physics:update()
  self:_before_update()

  if not self.physics then
    return
  end

  -- dx
  local dx = utils.ternary(
    self.bottom, _c.friction/self.friction,
    _c.friction/self.air_friction
  )
  self.dx *= dx
  
  -- dy
  local dy = utils.ternary(
    self.dy < 0, self.up_gravity,
    _c.gravity
  )
  self.dy += dy
  
  self:_inter_update()
  
  if abs(self.dx) < _c.accel then
    self.dx = 0
  end
  
  self.dx = mid(-self.max_dx,
                self.dx, self.max_dx)
  self:_update_pos_x(self.dx)
  
  self.left = false
  self.right = false
  
  self:_check_collide(_c.left)
  self:_check_collide(_c.right)
  
  self.dy = mid(-self.max_dy,
                self.dy, self.max_dy)
  
  self:_update_pos_y(self.dy)
  
  self.top = false
  self.bottom = false
  
  self:_check_collide(_c.top)
  self:_check_collide(_c.bottom)

  self:_after_update()
end

function physics:_before_update() end

function physics:_inter_update() end

function physics:_after_update() end

function physics:_create_colliders()
  local box_names = self.box_names
  if not box_names then
    return
  end
  
  local name = box_names[#box_names]
  local box = self[name]
  
  local x_0, x_1 = box.x_0, box.x_1
  local y_0, y_1 = box.y_0, box.y_1
  
  box.colliders = {
    {{x_0 - 1, y_0}, _c.left},
    {{x_0 - 1, y_1}, _c.left},
    {{x_1 + 1, y_0}, _c.right},
    {{x_1 + 1, y_1}, _c.right},
    {{x_0, y_0 - 1}, _c.top},
    {{x_1, y_0 - 1}, _c.top},
    {{x_0, y_1 + 1}, _c.bottom},
    {{x_1, y_1 + 1}, _c.bottom}
  }
  
  local function add_colliders(extras)
    for collider in all(extras) do
      add(box.colliders, collider)
    end
  end
  
  local y_half = (y_1 - y_0)\2
  local y_mod = y_half\2
  
  local x_half = (x_1 - x_0)\2
  local x_mod = x_half\2
  
  -- if large add colliders
  local extras = {}
  if y_1 - y_0 >= 11 then
    add_colliders({
      {{x_0 - 1, y_0 + y_mod + 1}, _c.left},
      {{x_0 - 1, y_1 - y_mod - 1}, _c.left},
      {{x_1 + 1, y_0 + y_mod + 1}, _c.right},
      {{x_1 + 1, y_1 - y_mod - 1}, _c.right},
    })
  end
  
  if x_1 - x_0 >= 11 then
    add_colliders({
      {{x_0 + x_half - x_mod + 1, y_1 + 1}, _c.bottom},
      {{x_0 + x_half + x_mod, y_1 + 1}, _c.bottom},
      {{x_0 + x_half - x_mod + 1, y_0 - 1}, _c.top},
      {{x_0 + x_half + x_mod, y_0 - 1}, _c.top},
    })
  end
  
  -- organize by box/dirs
  box.dirs = {}
  for pos_dir in all(box.colliders) do
    local pos = pos_dir[1]
    local dir = pos_dir[2]
    
    local tbl = box.dirs[dir]
    if not tbl then
      box.dirs[dir] = {pos}
    else
      -- order by x or y,
      -- small to large
      local index =
        (dir == _c.left or
        dir == _c.right) and
        2 or 1
        
      -- binary insert
      local low,high = 1,#tbl
      while low <= high do
        local med = (low + high)\2
        if tbl[med][index] < pos[index] then
          low = med + 1
        else
          high = med - 1
        end
      end
      
      add(box.dirs[dir], pos, low)
    end
  end
end

function physics:_check_collide(dir)
  local pos, delta, mult, updater

  if dir == _c.left or dir == _c.right then
    pos = "x"
    delta = "dx"
    mult = (dir == _c.left) and 1 or -1
    updater = function(offset) self:_update_xs(offset) end
  else
    pos = "y"
    delta = "dy"
    mult = (dir == _c.top) and 1 or -1
    updater = function(offset) self:_update_ys(offset) end
  end

  local touch = self:_collide(dir)
  local offset = 0

  if touch then
    while self:_collide(dir, {[pos] = offset}) do
      offset += mult
    end
    offset -= mult

    self[pos] += offset
    updater(offset)
    self[delta] = 0
    self[dir] = true
  end
end

function physics:_collide(dir, props)
  props = props or {}
  props.x = props.x or 0
  props.y = props.y or 0
  props.flag = props.flag or _c.f.solid

  local results = self:_for_box_name(
    function(box)
      if not box.dirs then
        return false
      end
    
      for pos in all(box.dirs[dir]) do
        local t_x = (pos[1] + props.x)/8
        local t_y = (pos[2] + props.y)/8
        local tile = mget(t_x, t_y)
        if fget(tile, props.flag) then
          return true
        end
      end
      
      return false
    end
  )

  for result in all(results) do
    if result then
      return true
    end
  end
  return false
end

function physics:_update_colliders(box, i, o)
  for pos_dir in all(box.colliders) do
    local pos = pos_dir[1]
    pos[i] += o
  end
end

-- update box & collider xs
function physics:_update_xs(x_o)
  self:_for_box_name(
    function(box)
      box.x_0 += x_o
      box.x_1 += x_o
      self:_update_colliders(box, 1, x_o)
    end
  )
end

-- update box & collider ys
function physics:_update_ys(y_o)
  self:_for_box_name(
    function(box)
      box.y_0 += y_o
      box.y_1 += y_o
      self:_update_colliders(box, 2, y_o)
    end
  )
end

function physics:_update_pos_x(x_o, dx)
  self.x += x_o
  self:_update_xs(x_o)
end

function physics:_update_pos_y(y_o, dy)
  self.y += y_o
  self:_update_ys(y_o)
end

function physics:_draw_box_colliders(box)
  box = box or self.box
  if not _g.show then
    return
  end
  
  for pos_dir in all(box.colliders) do
    local pos = pos_dir[1]
    pset(pos[1], pos[2], _c.yellow)
  end
end

function physics:_draw_colliders()
  self:_for_box_name(
    function(box)
      self:_draw_box_colliders(box)
    end
  )
end
-->8
-- event-driven architecture


local event = {}
event.__index = event
function event.new(props)
  if not props then
    return
  end
  
  local last = props[#props]
  if type(last) != "string" then
    return
  end
  
  local instance = setmetatable({
    -- the instances
    insts = {},
    -- after event funcs
    funcs = {},
    -- trigger funcs?
    act = {}
  }, event)
  utils.deep_join(instance, props)
  
  local func = instance[last]
  if not func then
    return
  end
  
  -- run event code
  for name,inst in pairs(instance.insts) do
    instance[name] = inst
  end
  func(instance)
  
  -- stop a spawn...
  local sep = split(last, "_", false)
  if sep[2] == _c.spawn then
    local act = instance.act
    if act then
      for name,_act in pairs(act) do
        if _act == false then
          local inst = instance.insts[name]
          inst.spawn = false
        end
      end
    end
  end
  
  -- run event after code
  if not instance.funcs then
    return
  end
  instance:_act_funcs()
end

function event:_act_funcs()
  for allowed,func in pairs(self.funcs) do
    local act = self.act
    if act then
      if act[allowed] == nil or
      act[allowed] then
        func()
      end
    end
  end
end

function event:rain_spawn()
  local rain = self.rain
  
  if not _c.pretty then
    return
  end
  
  local combos = {
    {8, 2},
    {10, 9},
    {11, 3},
    {12, 1}
  }
  
  local combo = utils.rand_elem(combos)
  
  rain.c = combo[1]
  rain.splash_c = combo[2]
end

function event:frog_spawn()
--  self.act.frog = false
end

-- vars: _dx & _dy
function event:frog_jump()
--  local frog = self.frog
--  frog._dx *= 10
--  frog._dy *= 10
end
-->8
-- particles & items


local pop = setmetatable(
  {}, {__index = base}
)
pop.__index = pop
function pop.new(props)
  local instance = setmetatable({
    c = utils.rand_elem("1,12"),
    d_x = (rnd(0.3) + 0.2) *
      utils.rand_elem("-1,1"),
    d_y = rnd(0.3) + 0.2 *
      utils.rand_elem("-1,1"),
    s_t = time(),  -- start time
    l_t = rnd(0.1) + 0.05 -- life time
  }, pop)
  utils.deep_join(instance, props)
  return instance
end

function pop:update()
  local _ENV = self
  x += d_x 
  y += d_y
  
  if time() - s_t > l_t then
    self:_del()
  end
end
-->8
-- classes


-- fly class
local fly = setmetatable({
  r = 12,
  delay_1=1,
  delay_2=0.1}, {__index = base}
)
fly.__index = fly
function fly.new(props)
  local i_time = time()
  local instance = setmetatable({
    c = utils.rand_elem("5,10"),
    c_queue = {},    -- color queue
    a_t_1 = i_time,  -- act timer 1
    a_t_2 = i_time   -- act timer 2
  }, fly)
  utils.deep_join(instance, props)
  local _ENV = instance
  o_x = x  -- origin
  o_y = y  -- origin
  l_x = x  -- last x
  l_y = y  -- last y
  return instance
end

function fly:update()
  local i_time = time()
  self:_flicker(i_time)
  self:_wander(i_time)
end

function fly:_flicker(i_time)
  if #self.c_queue == 0 then
    if i_time - self.a_t_1
    > self.delay_1 then
      self.a_t_1 = i_time
      if self.c == 10 then
        self.c = 5
      elseif self.c == 5 then
        local c = utils.rand_elem(
          "5,9,10"
        )
        if c == 9 then
          self.c_queue =
          split"10,9,10,5,5"
        end
        self.c = c
      end
    end
  elseif i_time - self.a_t_1
  > self.delay_2 then
    self.a_t_1 = i_time
    self.c = self.c_queue[1]
    deli(self.c_queue, 1)
  end
end

function fly:_wander(i_time)
  local r_time = utils.rand_elem(
    "0.1,0.3,0.5"
  )
  
  if i_time - self.a_t_2 < r_time then
    return
  end
  
  self.a_t_2 = i_time
  local d_x = self.x +
    utils.rand_elem("-1,0,1")
  local d_y = self.y +
    utils.rand_elem("-1,0,1")
    
  local dis = sqrt(
    (d_x - self.o_x)^2 +
    (d_y - self.o_y)^2
  )
  
  local _ENV = self
  if dis <= r then
    l_x = self.x
    l_y = self.y
    x = d_x
    y = d_y
  else
    x = l_x
    y = l_y
  end
end


-- rain class
local rain = setmetatable({
  c = _c.l_purple,
  splash_c = _c.l_purple,
  hide = 0,  -- increase hide all
  m_i = nil, -- missing pixel index
  a_t = 0,   -- timer
  splash = false,
  hit = false,
  triggers = true}, {__index = base}
)
rain.__index = rain
function rain.new(props)
  local instance = setmetatable({}, rain)
  utils.deep_join(instance, props)
  instance:_setup()
  -- create event
  event.new({
    insts = {rain = instance},
    "rain_spawn"
  })
  return instance
end

function rain:update()
  local y_o = 2  -- offset
  
  if not self.hit then
    if fget(
      mget(
        self.x/8,
        (self.y + _c.rain.dx
        - y_o - self.hide)/8
      ),
    _c.f.solid) then
      self:_splash()
    end
  end
  
  if self.splash then
    self.splash = false
    
    for i = 1,_c.rain.splash do
      utils.add_actor(
        pop, {
          x = self.x,
          y = self.y - self.hide - 1,
          c = self.splash_c
        }
      )
    end
  end
  
  local i_time = time()
  if self.hit and
  time() - self.a_t > 0.01 then
    self.a_t = i_time
    self.hide += 3
    if self.hide >= self.l then
      self:_del()
      return
    end
  end
  
  self.y += _c.rain.dx
  
--  -- edge-case; goes off-screen
--  local _,cam_y = utils.get_cam_pos()
--  if self.y > cam_y + _c.screen_dim + _c.small_margin then
--    self:_del()
--  end
end

function rain:draw()
  -- draw vertical line
  for i = 0,self.l - 1 do
    if not self.m_i
    or (self.m_i and
    i != self.m_i - 1) then
      if self.hide == 0 or
      i >= self.hide then
        pset(self.x, self.y - i, self.c)
      end
    end
  end
end

function rain:_setup()
  -- rain threshold for being
  -- considered big
  local r_thresh = 10
  self.l = utils.rand_elem({
    6, 8, r_thresh, 12
  })
  
  -- missing pixel index
  if self.l >= r_thresh or
  rnd(1) < 0.5 then
    self.m_i = utils.rand_elem(
      "2,3,5"
    )
  end
  
  -- flip or not to flip
  if self.m_i and
  rnd(1) < 0.5 then
    self.m_i = self.l - self.m_i + 1
  end
end

function rain:_splash()
  self.splash = true
  self.hit = true
end


-- rain machine class
local rain_machine = setmetatable(
  {}, {__index = base}
)
rain_machine.__index = rain_machine
function rain_machine.new(props)
  local instance = setmetatable({
    a_t = time()
  }, rain_machine)
  utils.deep_join(instance, props)
  return instance
end

function rain_machine:update()
  local i_time = time()
  if i_time - self.a_t
  < _c.rain.delay then
    return
  end
  
  local x_o_1 = 2  -- offset
  self.a_t = i_time
  for i = 0,31 do
    local x_o_2 = utils.rand_elem(
      "-1,0,1"
    )
    local y_o = rnd(_c.rain.var * 2)\1
      - _c.rain.var  -- variance
    utils.add_actor(
      rain, {
        x = self.x + i * 4 + x_o_1 + x_o_2,
        y = -_c.rain.height + y_o
      }
    )
  end
end

-- hide it
function rain_machine:draw() end


-- flower class
local flower = setmetatable({
  s_i = 1,  -- sprite list index
  s_w = 7,  -- sprite width
  s_h = 7,  -- sprint height
  a_t = 0,  -- timer
  delay = 0.5,
  fast_mult = 0.35,  -- frames increment faster
  hit = false}, {__index = sprite}
)
flower.__index = flower
function flower.new(props)
  local instance = setmetatable({
    s_list = split"48,49,50,49,48",
    pals = {},
  }, flower)
  utils.deep_join(instance, props)
  instance:_create_box("-3,-4,2,4")
  instance.o_x = instance.x
  return instance
end

function flower:update()
  if self.hit then
    self:_sway()
  end
end

function flower:draw()
  local _ENV = self
  spr(
    s_list[s_i], x, y,
    1, 1, fl
  )
  
  self:_draw_box()
end

function flower:_hit(fl)
  self.hit = true
  
  -- choose dir if none given
  if fl == nil then
    self.fl = rnd(1) < 0.5
  else
    self.fl = fl
  end
  
  if self.fl then
    self.x -= 1
  end
end

function flower:_sway()
  local fast = self.s_i\#self.s_list
  fast *= self.fast_mult

  local i_time = time()
  if i_time - self.a_t + fast
  < self.delay then
    return
  end
  
  local _ENV = self
  a_t = i_time
  if s_i != #s_list then
    s_i += 1
  else
    -- reset
    s_i = 1
    a_t = 0
    fl = false
    x = o_x
    hit = false
  end
end


-- grass class
local grass = setmetatable({
  s = 52,
  a_t = 0,  -- timer
  height = 0,
  delay = 1}, {__index = sprite}
)
grass.__index = grass
function grass.new(props)
  local instance = setmetatable({}, grass)
  utils.deep_join(instance, props)
  return instance
end

function grass:update()
  local i_time = time()
  if i_time - self.a_t
  < self.delay then
    return
  end
  
  self.a_t = i_time
  self.height ^^= 1  -- bxor
end

function grass:draw()
  local m = 3  -- multiply factor
  local s_x,s_y = utils.get_sx_sy(self.s)
  sspr(s_x, s_y, 8, 8,
       self.x, self.y - self.height * m,
       8, self.height * m + 8)
end
-->8
-- mobs


-- player class
local player = setmetatable({
  z = 5,
  s = 11,
  s_w = 6,
  c_2 = _c.l_green,
  item = nil,
  -- not in hands yet...
  nearby_item = nil,
  -- just picked up...
  got_item = false,
  holding_x = false,
  stand = 11,
  sit = 12,
  jumping = 13,
  land = 14,
  jump_dy = 1,
  moving = false,
  landed = false,
  status = _c.stats.idle,
  l_status = _c.stats.idle,
  before_bottom = false,
  bob_delay = 0.085,
  stand_delay = 0.5,
  triggers = true},
  {__index = physics}
)
player.__index = player
function player.new(props)
  local instance = setmetatable({
    a_t = time()
  }, player)
  utils.deep_join(instance, props)
  instance:_create_box("-2,-3,4,4")
  instance:_create_colliders()
  instance:_check_collide(_c.bottom)
  local _ENV = instance
  last_dx = dx
  last_dy = dy
  before_bottom = bottom
  return instance
end

function player:_inter_update()
  local moving = false
  
  -- controls
  if btn(0) and not btn(1) then
    if self.left then
      self.dx = 0
    else
      self.dx -= _c.accel
      moving = true
    end
    self.fl = true
    
  elseif btn(1) and not btn(0) then
    if self.right then
      self.dx = 0
    else
      self.dx += _c.accel
      moving = true
    end
    self.fl = false
  end
  
  if btn(4) and self.bottom then
    self.dy -= self.jump_dy
  end
  
  if btn(3) and self.item then
    self:drop_item()
  end
  
  if btn(5) then
    -- throw item
    if self.item and
    not self.holding_x then
      local dx = self.fl and -1 or 1
      self.item.dx += dx + self.dx * 0.75
      
      local dy = btn(2) and 1.75 or 1
      self.item.dy -= dy
      
      self:drop_item()
    end
  
    -- grab item
    if self.nearby_item and
    not self.holding_x then
      self.item = self.nearby_item
      self.item.physics = false
      self.nearby_item = nil
      self.got_item = true
      
      local borders = split(self.item.borders)
      
      -- center item box
      local o_x = self.item.s_w >= 8
        and 1 or 0
      
      local o_y = self.item.s_h >= 16
        and 12 or 8
      
      borders[1] += o_x
      borders[3] += o_x
      borders[2] -= o_y
      borders[4] -= o_y
      
      local box = self:_create_box(borders)
      self:_create_colliders()
      
      -- make bottom of item box
      -- collide with walls
      local length = #box.dirs[_c.bottom]
      for i = 1,length do
        local dir = i <= length/2 and
          _c.left or _c.right
        add(box.dirs[dir], box.dirs[_c.bottom][i])
      end
      box.dirs[_c.bottom] = {}
    end
    
    self.holding_x = true
  else
    self.holding_x = false
  end
  
  -- item direction
  if self.item then
    self.item.fl = self.fl
  end
  
  -- animations
  local i_time = time()
  
  -- land animation
  if not self.before_bottom
  and self.bottom then
    self.s = self.land
    self.a_t = i_time
  end
  
  local diff = i_time - self.a_t
  
  if moving then
    -- bobbing animation
    if self.bottom then
      -- after idle or on delay...
      local from_idle = self.status == _c.stats.idle
      if from_idle or diff
      > self.bob_delay then
        self:_alternate()
        self.a_t = i_time
      end
      self.status = _c.stats.moving
    end
  else
    self.status = _c.stats.idle
  end
  
  if self.l_status != self.status then
    if self.status == _c.stats.idle then
      -- just stopped moving
      self.s = self.sit
    end
    self.l_status = self.status
  end
  
  -- idle animation
  if not moving
  and self.bottom then
    if diff > self.stand_delay then
      self:_alternate()
      self.a_t = i_time
    end
  end
  
  self.before_bottom = self.bottom
end

function player:_after_update()
  -- fall animation
  if not self.bottom then
    self.s = self.jumping
  end
  
  -- center item on pickup
  local item = self.item
  if item then
    local o_x = 0
    if item.s_w == 16 then
      o_x = 4
    elseif item.s_w == 13 then
      o_x = 3
    elseif item.s_w == 12 then
      o_x = 2
    end
    
    local x_diff = self.x - item.x - o_x
    item:_update_pos_x(x_diff)
    
    local y_diff = self.y - item.y
    item:_update_pos_y(y_diff - item.s_h)
  end
  
  local _ENV = self
  last_dx = dx
  last_dy = dy
  nearby_item = nil
  got_item = false
end

function player:_alternate()
  local _ENV = self
  if s == sit then
    s = stand
  else
    s = sit
  end
end

function player:drop_item()
  self.item.physics = true
  self.item = nil
    
  del(self.box_names, "box_2")
  del(_g.boxes, self.box_2)
  self.box_2 = nil
end

function player:draw()
  pal(_c.pink, _c.black)
  
  local _ENV = self
  spr(
    s, x, y,
    1, 1, fl
  )
  
  self:_draw_box()
  self:_draw_box_colliders()
  
  if self.box_2 then
    self:_draw_box(box_2, c_2)
    self:_draw_box_colliders(box_2)
  end
  
  pal()
end

-- frog class
local frog = setmetatable({
  z = 3,
  c_2 = _c.pink,
  s_x = 80,
  s_y = 8,
  s_w = 10,
  s_h = 10,
  -- anims
  sit = 80,
  stand = 90,
  air = 110,
  bounce = 100,
  -- physics
  last_dx = 0,
  last_dy = 0,
  jump_dy = 1.5,
  max_dy = 3,  -- higher terminal
  jump_delay = 1.2,
  jump_friction = 0.85,
  ribbit_thresh = 0.65,  -- chance to ribbit
  up_gravity = 0.06,  -- lower jump gravity
  -- trackers
  lands = 0,  -- reduces bounce
  ready = false,  -- to jump
  extra_bounce = false,
  before_bottom = false,
  -- triggers
  triggers = true,
  force_pl = nil,  -- player, bool
  force_fl = false}, -- frog
  {__index = physics}
)
frog.__index = frog
function frog.new(props)
  local instance = setmetatable({
    a_t = time()
  }, frog)
  utils.deep_join(instance, props)
  instance.og_ribbit_thresh = instance.ribbit_thresh
  instance:_create_box("-5,-4,4,4")
  instance:_create_colliders()
  instance:_create_box("-18,-6,18,6")
  -- create event
  event.new({
    insts = {frog = instance},
    "frog_spawn"
  })
  return instance
end

function frog:_jump()
  local _ENV = self
  self:_update_pos_y(-1)
  dy = _dy
  dx = _dx
end

function frog:_inter_update()
  if not self.before_bottom
  and self.bottom then
    self.a_t = time()
    self.ready = true
    self.rand_delay = rnd(1)
    
    local thresh = 0.5  -- looks good
    local val = (self.lands + 1) * thresh
    local diff = abs(self.last_dy) - val
    local bool = diff >= 1
    
    -- extra bounce back
    if not bool and self.extra_bounce then
      self.extra_bounce = false
      bool = not bool
      diff = thresh
    end
    
    -- reduce bounce back
    if bool then
      self:_update_pos_y(-1)
      self.dy = -diff
      self.air_friction *= 1.03
      self.lands += 1
    else
      self.dy = 0
      self.lands = 0
    end
  end
  
  -- sit animation
  do
  local _ENV = self
  if bottom then
    s_x = sit
    
    -- bounce animation
    if lands > 0 then
      s_x = bounce
    end
  else
    ready = false
  end
  
  before_bottom = bottom
  
  -- jump when timer elapses
  if not ready then
    return
  end
  end
  
  local i_time = time()
  local diff = i_time - self.a_t
  local delay = self.jump_delay
              + self.rand_delay
  
  -- ribbit animation
  local o = 0.2
  if diff > delay - o then
    self.s_x = self.stand
  end
  
  if diff > delay then
    if self.force_pl != nil then
      self.fl = self.force_pl
    elseif self.force_fl then
      self.fl = not self.fl
    end
  
    -- ribbit only, no jump
    if rnd(1) < self.ribbit_thresh then
      self.a_t = i_time
      return
    end
    
    self.ready = false
    self.extra_bounce = true
    self.air_friction = self.jump_friction
    
    -- dx
    local dir = self.fl and -1 or 1
    local dx = utils.rand_elem(
      "0.5,0.5,0.75,1"
    )
    
    -- dy
    local dy = -self.jump_dy
    if dx <= 0.5 then
      dy /= 2
    end
    
    self._dy = dy
    self._dx = dx * dir
    
    -- event
    event.new({
      funcs = {
        frog = function() self:_jump() end
      },
      insts = {frog = self},
      "frog_jump"
    })
  end
  
  -- reset
  self.force_pl = nil
  self.force_fl = false
  self.ribbit_thresh = self.og_ribbit_thresh
end

function frog:_after_update()
  -- save dx
  if self.dx != 0 then
    self.last_dx = self.dx
  end

  -- save dy
  if self.dy != 0 then
    self.last_dy = self.dy
  end
  
  -- bounce off wall
  if self.left or self.right then
    self.fl = not self.fl
    local o = self.fl and -1 or 1
    
    local dx = max(
      0.75, abs(self.last_dx)
    )
    self.dx = o * dx
  end
  
  -- fall animation
  if not self.bottom
  and self.lands == 0 then
    self.s_x = self.air
  end
end

function frog:draw()
  local _ENV = self
  sspr(s_x, s_y, s_w, s_h,
       x, y, s_w, s_h, fl)
  self:_draw_box()
  self:_draw_colliders()
  self:_draw_box(box_2, c_2)
end


local bug = setmetatable({
  z = 5,
  s = 58,
  s_w = 6,
  s_i = 0,
  a_t = 0,
  s_d = 8,  -- dist to next frame
  borders="-2,-3,4,4",
  air_friction = 0.86,
  delay = 0.8},
  {__index = physics}
)
bug.__index = bug
function bug.new(props)
  local instance = setmetatable({}, bug)
  utils.deep_join(instance, props)
  instance:_create_box(instance.borders)
  instance:_create_colliders()
  if instance.s_w < 12 then
    instance:_create_box("-6,-3,8,4")
  end
  return instance
end

function bug:_before_update()
  local i_time = time()
  if i_time - self.a_t
  < self.delay then
    return
  end
  
  self.a_t = i_time
  self.s_i ^^= 1
end

function bug:draw()
  local s_x,s_y = utils.get_sx_sy(self.s)

  -- assuming sprite in middle...
  local s_o = self.s_w < 8 and 1 or 0

  do
  local _ENV = self
  sspr(
    s_x + s_i * s_d, s_y,
    s_w + s_o, s_h,
    x, y, s_w + s_o, s_h, fl
  )
  end
  
  if self.physics then
    self:_draw_box()
    self:_draw_colliders()
    if self.box_2 then
      self:_draw_box(self.box_2, _c.l_green)
    end
  end
end


local spider = {}
function spider.new(props)
  do
  local _ENV = props
  s = 68
  s_w = 16
  s_h = 16
  s_d = 16
  borders = "-8,-7,8,8"
  end
  return bug.new(props)
end


local snail = {}
function snail.new(props)
  do
  local _ENV = props
  s = 64
  s_w = 13
  s_d = 16
  borders = "-7,-4,6,4"
  end
  return bug.new(props)
end
-->8
-- triggers


local trigger = {}
function trigger.find(actor_1, actor_2, id)
  local is_type = utils.is_type
  
  -- rain
  local is_rain = is_type(actor_1, rain)
  if is_rain then
    if is_type(actor_2, flower) then
      -- rain & flower
      trigger._rain_hit_flower(actor_1, actor_2)
    elseif is_type(actor_2, player)
    and id == 1 then
      -- rain & player
      trigger._rain_hit_helper(actor_1, actor_2, 1)
    elseif is_type(actor_2, frog)
    and id == 1 then
      -- rain & frog
      trigger._rain_hit_helper(actor_1, actor_2)
    end
  end
  
  local is_player = is_type(actor_1, player)
  if is_player then
    if is_type(actor_2, flower) then
      -- player & flower
      trigger._player_hit_flower(actor_1, actor_2)
    elseif is_type(actor_2, bug)
    or is_type(actor_2, spider) then
      -- player & bug
      trigger._player_pick_up(actor_1, actor_2)
    elseif is_type(actor_2, frog)
    and id == 2 then
      -- player & frog
      trigger._player_by_frog(actor_1, actor_2)
    end
  end
  
  local is_frog = is_type(actor_1, frog)
  if is_frog then
    if is_type(actor_2, flower) then
      -- frog & flower
      trigger._frog_hit_flower(actor_1, actor_2)
    elseif is_type(actor_2, frog)
    and actor_1.id < actor_2.id
    and id == 2 then
      -- frog & frog
      trigger._frog_by_frog(actor_1, actor_2)
    end
  end
end


function trigger._rain_hit_flower(rain, flower)
  local o = 1
  if rain.y >= flower.y + o then
    trigger._rain_hit(rain)
    
    if not flower.hit then
      flower:_hit()
    end
  end
end


function trigger._player_hit_flower(player, flower)
  if not flower.hit and (
  abs(player.dx) > 0.25 or
  abs(player.dy) > 0.25 ) then
    local fl = nil
    if player.dx < 0 then
      fl = true
    elseif player.dx > 0 then
      fl = false
    end
    flower:_hit(fl)
  end
end


function trigger._frog_hit_flower(frog, flower)
  if not flower.hit and
  frog.dy < -0.25 then
    local fl = nil
    if frog.dx > 0 then
      fl = false
    elseif frog.dx < 0 then
      fl = true
    end
    flower:_hit(fl)
  end
end


function trigger._rain_hit(rain)
  if not rain.hit then
    rain:_splash()
  end
end


function trigger._rain_hit_helper(
  rain, other, o)
  o = o or 0
  if rain.y >= other.y + o then
    trigger._rain_hit(rain)
  end
end


function trigger.frog_helper(frog)
  frog.ribbit_thresh = -1
  frog.force_fl = rnd(0.5) < 1
end


function trigger._player_by_frog(
  player, frog)
  local p_m_x,_ = player:_get_mid()
  local f_m_x,_ = frog:_get_mid()
  
  frog.ribbit_thresh = -1
  frog.force_pl = p_m_x > f_m_x
  frog.a_t -= 0.1
end


function trigger._frog_by_frog(
  frog_1, frog_2)
  trigger.frog_helper(frog_1)
  trigger.frog_helper(frog_2)
end


function trigger._player_pick_up(player, item)
  if not player.item then
    player.nearby_item = item
  end
end
-->8
-- game loop


function _init()
  menu.add_debug()
  
  local add_actor = utils.add_actor
  
  -- fireflies
  for i = 1,9 do
    local x = 72
    local y = 74
    local r = 12
    
    local x_o = 0
    local y_o = 0
    
    if i <= 6 then
      x_o = rnd(6)\1 + 1
      x_o *= utils.rand_elem({-1, 1})
      y_o = rnd(6)\1 + 1
      y_o *= utils.rand_elem({-1, 1})
    else
      x = 108
      y = 110
      r = 4
    end
    
    add_actor(
      fly, {
        x = x + x_o,
        y = y + y_o,
        r = r
      }
    )
  end
  
  -- rain machine
  add_actor(
    rain_machine
  )

  -- flowers
  local flowers = {
    split"32,112",
    split"24,112",
    split"14,112",
    split"48,32",
    split"68,32",
    split"53,112"
  }
  for props in all(flowers) do
    add_actor(
      flower, {
        x = props[1], y = props[2]
      }
    )
  end
  
  -- grass
  for i = 0,1 do
    add_actor(
      grass, {
        s = 52 + i,
        x = 72 + i * 8,
        y = 112,
        a_t = rnd(1)
      }
    )
  end
  
  -- player
  add_actor(
    player, {
      x = 96, y = 88,
      fl = true
    }
  )
  
  -- frog 1
  add_actor(
    frog, {
      x = 40, y = 111
    }
  )
  
  -- frog 2
  add_actor(
    frog, {
      x = 80, y = 31,
      fl = true,
      c_2 = _c.l_green
    }
  )
  
  add_actor(
    bug, {
      x = 64, y = 90
    }
  )

--  add_actor(
--    snail, {
--      x = 10, y = 80
--    }
--  )

  add_actor(
    spider, {
      x = 92, y = 50
    }
  )
end


function _update60()
  for actor in all(_g.actors) do
    actor:update()
    
    -- triggerable events
    if actor.triggers then
      local m_x = actor.x      
      local m_y = actor.y
      if actor.s_w != nil then
        m_x,m_y = actor:_get_mid()
      end
      
      for box in all(_g.boxes) do
        if m_x >= box.x_0 and
        m_x <= box.x_1 and
        m_y >= box.y_0 and
        m_y <= box.y_1 
        and actor != box.parent then
          trigger.find(
            actor, box.parent, box.id
          )
        end
      end
    end
  end
end


function _draw()
  camera(8)
  cls(_c.black)
  
  for actor in all(_g.actors) do
    actor:draw()
  end
  
  color(10)
  if _g.show then
    local cpu = stat(1)
    if cpu > _g.max_cpu then
      _g.max_cpu = cpu
    end
    
    local x,_ = utils.get_cam_pos()
    ?"cpu usage: "..cpu, x + 2, 2
    ?"max usage: ".._g.max_cpu
    ?"obj count: "..#_g.actors
    ?"box count: "..#_g.boxes
    if _g.debug != nil then
      ?_g.debug
    end
  end
  
  map()
end
__gfx__
77000077ddd0d0dd0000000000000000ddddddddddddddddddd11111ddddddddddd11111ddd11111000000000000000000000000000000000000000000000000
700000070dd000dd0000000000000000d1d000000000000000d11111d1d0000000d11111d1d00000000000000011110000000000001111000000000000000000
00700700000000000000000000000000ddddddddddddddddddd11111ddddddddddd11111ddd111110000000001d1ddd00011110001d1ddd00011110000000000
00077000000001100000000000000000000000000000000000000000000000000000000000000000000000000111111001d1ddd00111111001d1111000000000
0007700000dd01100000000000000000d0d111110000000000000000d0d11111ddd11111d0d1111100000000001ddd0001111110001ddd000111ddd000000000
0070070000dd00000000000000000000d0d111110000000000000000d0d11111d0d11111d0d1111100000000001ede00001ddd00001ede000011111000000000
70000007000001000000000000000000d0d111110000000000000000ddd11111d0d11111ddd1111100000000001ddd00001ede00001ddd00001ede0000000000
77000077000000000000000000000000d0d11111000000000000000000000000d0d11111000000000000000000100100001ddd0000010100001ddd0000000000
00000000dddddddd1d1ddddd00000000d0d11111000000000000000000000000d0d1111100000000000000000000111011000011101100001110110000000000
00000000111111111111111100000000d0d11111000000000000000000000000d0d11111000000000011101100001d11d110001d11d110001d11d11000000000
00000000000000000000000000000000d0d11111000000000000000000000000d0d1111100000000001d11d11001111111100111111110011111111000000000
00000000000001100000011000000000d0d11111000000000000000000000000d0d111110000000001111111100111ddddd00111dddd000111dddd0000000000
0000000000dd011000dd011000000000d0d11111000000000000000000000000d0d11111000000000111dddd001111ddddd01111ddd0001111ddd00000000000
0000000000dd000000dd000000000000d0d11111000000000000000000000000d0d11111000000001111ddd0001111dddd00111111100011d1111d0000000000
00000000000001000000010000000000d0d11111000000000000000000000000d0d11111000000001dd11110001ddd11100011d1111d00111111100000000000
00000000000000000000000000000000d0d11111000000000000000000000000000000000000000011dd111d0001dd111d001111111000011111100000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000dddd11dd00dddd0ddd001dd11dd0011100dd00000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001d000d000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddd00000000000000000000000000011000000000000000000000000000
000d000000000000000000000000000000000000000000000000000000000000dddddddd0000000000d00d000d0000d000111100000110000000000000000000
00d0d0000000d000000000000000000000000000000000000000000000000000dddddddd000000000d0000d00d0000d000111100001111000000000000000000
000d0000000d0d000000d0000000000000000000000000000000000000000000dddddddd0000000001d00d1001d00d1000011000001111000000000000000000
000d00000000d000000d0d0000000000000d0000000000000000000000000000dddddddd000000000d1dd1d0001dd100000dd000000110000000000000000000
000d00000000d0000000d000000000000d0d0000000d00000000000000000000dddddddd00000000001111000d1111d000011000000dd0000000000000000000
d00d00d0d00d00d0d00d00d0000000000d0d0d00000d0d000000000000000000dddddddd000000000d1111d000111100000dd0d00d1110000000000000000000
0d0d0d000d0d0d000d0d0d00000000000d0d0d000d0d0d0d0000000000000000dddddddd00000000001111000d1111d00000dd0000dd00000000000000000000
000000000d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000100100000000000d00d00000000000d00d00000000d00d0000d00d000000000000111100000000000011110000000000000000000000000000000000
00dddd101ddd000000dddd1010010000000d0d0000d0d00000d00d0000d00d000000000001d1ddd00011110001d1ddd000111100000000000000000000000000
0dd11ddd11d100000dd11ddd1ddd00000d0d01d00d10d0d0d01d01d00d10d10d000000000111111001d1ddd00111111001d11110000000000000000000000000
0d1ddd1d1ddd00000d1ddd1d11d100000d01d01dd10d10d0d00d001dd100d00d00000000001ddd0001111110001ddd000111ddd0000000000000000000000000
0dd111dd111000000dd111dd1ddd000001d01d1111d10d101d001d1111d100d100000000001ede00001ddd00001ede0000111110000000000000000000000000
10ddddd11dd0000000ddddd111100000001100dddd001100011100dddd00111000000000001ddd00001ede00001ddd00001ede00000000000000000000000000
011111111100000011111111dd00000000011dddddd1100000011dddddd110000000000000100100001ddd0000010100001ddd00000000000000000000000000
000000000000000000000000000000000000001dd10000000000001dd10000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000dd111111dd000000dd111111dd0000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000d11d1dd1d11d000dd11d1dd1d11dd00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000d10d1dddd1d01d0d100d1dddd1d001d0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000011d11dddd11d110d10d11dddd11d01d0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000d001dd100d00000dd001dd100dd000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000001d001100d1000001d00011000d1000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000001100001100000001d000000d10000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111511111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111115111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111a1111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111115111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111a111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0001000001010101010100000000000000010100010000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000101010101010000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000040508000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000180018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000070505090014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3800000000000000000000090000000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001010101010101010101121111111101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
