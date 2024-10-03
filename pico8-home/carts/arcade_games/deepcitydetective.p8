pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
--initial
function _init()

//menu
scene = "menu" 
loaded = false
f = 0
timer = 0
//player
	player = {
	
	sprite = 1,
	x = 1000,
	y = 200,
	w = 8,
	h = 8,
	v = 123, //camera variable
	dx = 0, //how much change in x
	dy = 0, //how much change in y
	max_dx = 1, //limit speed
	max_dy = 2, //limit speed
	acc = 0.09, //fowards force
	boost = 5, //upwards force
	moving = false,
	interaction = false,
	interaction3 = false,
	interaction4 = false,
	interaction5 = false,
	interaction6 = false,
	interaction7 = false,
	jumping = false,
	falling = false,
	landed = false,
	talking = true, //display sprite is hes talking
	headr = true
	}

//player animation
	playeranir = {
		1, 16
	}

	playeranil = {
		17, 18
	}
	
//gravity things
	gravity = 0.3 //move things downwards
	friction = 0.85 //slows moving things down
	
//camera stuff
  cam_x = 0 //camera x position
  cam_y = 0 //camera y position
  map_start = 0 //start of level camera
  map_end = 1024 //end of level camera
 

end

//////
function dtb_init(numlines)
    dtb_queu={}
    dtb_queuf={}
    dtb_numlines=3
    if numlines then
        dtb_numlines=numlines
    end
    _dtb_clean()
end
///////

///menu states
function _update60()

//menu state
	if scene == "menu"
	then 
	update_menu()
	draw_menu()
	music(2)
	//game state
	elseif scene == "game"
	then
	update_game()
	draw_game()
	draw_interaction_2()
	draw_interaction_3()
	draw_interaction_4()
	draw_interaction_5()
	draw_interaction_6()
	draw_interaction_7()

	//level 1
	elseif scene == "cutscene_1"
	then
	draw_cutscene_1()
	update_cutscene_1()
	
	elseif scene == "cutscene_2"
	then
	draw_cutscene_2()
	update_cutscene_2()
	
	elseif scene == "cutscene_3"
	then
	draw_cutscene_3()
	update_cutscene_3()
	
	
	//level 2
	elseif scene == "cutscene_4"
	then
	draw_cutscene_4()
	update_cutscene_4()
	
	elseif scene == "cutscene_5"
	then
	draw_cutscene_5()
	update_cutscene_5()
	
	//level 3
	elseif scene == "cutscene_6"
	then
	draw_cutscene_6()
	update_cutscene_6()
	
	elseif scene == "cutscene_7"
	then
	draw_cutscene_7()
	update_cutscene_7()
	
	elseif scene == "cutscene_8"
	then
	draw_cutscene_8()
	update_cutscene_8()
	
	elseif scene == "cutscene_9"
	then
	draw_cutscene_9()
	update_cutscene_9()
	
	////title cards
	elseif scene == "part_1"
	then
	draw_part_1()
	update_part_1()
	
	elseif scene == "part_2"
	then
	draw_part_2()
	update_part_2()
	
	elseif scene == "part_3"
	then
	draw_part_3()
	update_part_3()
	
	elseif scene == "part_4"
	then
	draw_part_4()
	update_part_4()
	
	//credits
 elseif scene == "credits"
	then
	draw_credits()
	end
	
end


///////

//tutorials/demos used
//https://nerdyteachers.com/explain/platformer/
//https://www.lexaloffle.com/bbs/?tid=28465
-->8
-- collisions

function map_collision(obj, dir, flg)
	
	// object needs x,y,w,h
	local x = obj.x
	local y = obj.y
	local w = obj.w
	local h = obj.h
	
	//invisible collision geometry
	local x1 = 0
	local x2 = 0
	local y1 = 0
	local y2 = 0
	
	//hitboxes
	if dir == "left"
	then
	 x1 = x - 1
		x2 = x
		y1 = y
		y2 = y + h - 1
		
	elseif dir == "right"
	then
	 x1 = x + w - 1
		x2 = x + w 
		y1 = y
		y2 = y + h - 1
		
	elseif dir == "up"
	then
	 x1 = x + 2
		x2 = x + w - 3
		y1 = y - 1
		y2 = y 
		
	elseif dir == "down"
	then
	 x1 = x + 2
		x2 = x + w - 3 
		y1 = y + h
		y2 = y + h
	end
	
	//convert pixels into tiles
	//map tiles instead of pixels
	x1 /= 8
	x2 /= 8
	y1 /= 8
	y2 /= 8

	//checks if sprite and collision flag
	//are interacting
	if fget(mget(x1,y1), flg)
	or fget(mget(x1,y2), flg)
	or fget(mget(x2,y1), flg)
	or fget(mget(x2,y2), flg)
	then
	return true
	else
	return false
	end
	
end
-->8
-- movement


function player_update()
	
	//speed up/slow down movement 
	player.dy += gravity
	player.dx *= friction
	
	f+=1
	

	//movement
	if btn(⬅️)
	then
		player.dx -= player.acc
		player.moving = true
		
		player.headr = false
		
	end
	

	if btn(➡️)
	then
		player.dx += player.acc
		player.moving = true
		
		player.headr = true
		
	end

	//jump/gravity
	if btnp(❎) 
	and player.landed
	then
		player.dy -= player.boost
		player.landed = false
		//jump noise
		sfx(1)
	end
	
	//checking collisions
	
	//check falling
if player.dy > 0 
	then
	player.falling = true
	player.landed = false
	player.jumping = false

	if map_collision(player, "down",0)
		then
		player.landed = true
		player.falling = false
		player.dy = 0
		player.y -= ((player.y + player.h+1)%8)-1
		end
	
	//if player is jumping
	elseif player.dy < 0 
		then
		player.jumping = true
			if map_collision(player, "up", 1) //check if jumping up into tile
			then
			player.dy = 0
			end
		end
	
	//left and right collision checking
	if player.dx < 0 
	then
		if map_collision(player, "left", 1)
		then	
			player.dx = 0
		end
		
	elseif player.dx > 0 
	then
		if map_collision(player, "right", 1)
		then	
		player.dx = 0
	 end
end
		
		
	player.x += player.dx
	player.y += player.dy

	
end

-->8
--camera

function camera_stuff()
//camera x position
 cam_x = player.x - 64 + (player.w/2)

  if cam_x < map_start 
  then
     cam_x = map_start
  end
  
  if cam_x > map_end - 128 
  then
     cam_x = map_end - 128
  end
  
//camera y position
 cam_y = player.v + (player.h/2)
	if cam_y < map_start 
		then
     cam_y = map_start
  end
  
   
  
//camera 
  camera(cam_x,cam_y)
  
end

//note to self, can just 
// change map start and end
//if want level to be on another
//part of the pico 8 screen thing

-->8
--menu state/titlecards
function draw_menu()

  cls()
  print("\f8deep city detective:",26,50,9)
	 print("\f8vigilante days",35,56,9)
	 print("press z to start",29,65,10)
end

function update_menu()

	if btnp(4) 
	then
	//game starts at level 1 title card
	start_dialogue()
 scene = "part_1"
 end

end

//title card for level 1
function draw_part_1()

  cls()
  print("\f8part 1:",26,50)
  print("the market district",26,56)
end
  
function update_part_1()
	if (time() > 3) 
	then
	//game starts at cutscene 1
	start_dialogue()
 scene = "cutscene_1"
 end

end

//title card for level 2
function draw_part_2()

  cls()
  camera(0,0) //line up camera
  print("\f8part 2:",26,50)
  print("a murder in heaven",26,56)
  print("press z to continue",29,65,10)
end
  
function update_part_2()

	if btnp(4) 
	then
	fset(4,4, true)
	start_dialogue()
 scene = "cutscene_4"
 end
end
//title card for level 3
function draw_part_3()

  cls()
  camera(0,0) //line up camera
  print("\f8part 3:",26,50)
  print("the escape",26,56)
  print("press z to continue",29,65,10)
end
  
function update_part_3()

	if btnp(4) 
	then
	start_dialogue()
 scene = "cutscene_6"
 end
end

//title card for level 4
function draw_part_4()

  cls()
  camera(0,0) //line up camera
  print("\f8part 4:",26,50)
  print("the detective rises",26,56)
  print("press z to continue",29,65,10)
end
  
function update_part_4()

	if btnp(4) 
	then
	fset(64,7, true)
	start_dialogue()
 scene = "cutscene_8"
 end
end

//credits screen
//title card for level 4
function draw_credits()

  cls()
  camera(0,0) //line up camera
  print("credits\n") 
  print("programmers: sarah crowe,\nbohua zhao\n")
  print("writers: yiyu,nathan\n")
  print("art team: katlyn, julia shin,\nmakai\n")
  print("level designer: makai\n")
  print("sound design: makai, aron\n")
  print("special thanks to the game 1\nteam and their invaluable help!")
end
  

-->8
-- state/cutscenes

function draw_game()

	cls()
	map(0, 0)
		//music(0)

	//still head left
	if player.moving == false and player.headr == false then
		spr(playeranil[1], player.x, player.y)
	end
	//still head right
	if player.moving == false and player.headr == true then
		spr(playeranir[1], player.x, player.y)
	end
	//moving head left
	if player.moving == true and player.headr == false then
		spr(playeranil[flr(f/8)%2+1], player.x, player.y)
	end
	//moving head right
	if player.moving == true and player.headr == true then
		spr(playeranir[flr(f/8)%2+1], player.x, player.y)
	end
		
	
	print(player.sprite, 1, 1)
end


function update_game()

 player_update()
 interaction_2()
 interaction_3()
 interaction_4()
 interaction_5()
 interaction_6()
 interaction_7()
 camera_stuff()
end

//note to self
//switch states to switch levels!

dialogue_1 ={
	"\f2 shrike:\f7 scott, can you hear me?",
	"\f1 scott:\f7 loud and clear.",
	"\f2 shrike:\f7 good, the call is secure and you're clear to proceed.",
	"\f1 scott:\f7 tonight, this city gets a little cleaner. \f5richard pierson \f7has convinced this city he's the good guy-philanthropist, all that.it's all a cover, the real money comes from his \f8human trafficking \f8circle. it ends tonight. he's going to be at the market district soon, and he's about to get more than he bargained for"
	}
dialogue_2 = 
{
	"\f5 richard:\f7 wait, stop! i have money, i can give you whatever you want! just let me go!",
	"\f1 scott:\f7 only your life matters to me.",
	"\f5 richard:\f7 why, why are you doing this?",
	"\f1 scott:\f7 because of the \f8sins \f8you've done."
}
dialogue_3 = 
{
 "\f1 scott:\f7 neo sacramento… this city is a damn gutter. one piece of trash cleaned out will only do so much. there's more work to do.", 
 "\f2 shrike:\f7 absolutely, scott. we've almost pinned down the next target's routine. he should be at the made in heaven nightclub next wednesday. you'll be waiting for him.",
 "\f1 scott:\f7 who is it?",
 "\f2 shrike:\f3 kole yorbin.\f7 he's a drug dealer that extorts people into buying his product. don't know why he doesn't just take their money…",
 "\f1 scott:\f7 this way they get addicted. we'll get the bastard."
}
dialogue_4 = 
{
 "the next wednesday......",
 "\f2 shrike:\f7 tonight's the night scott, are you ready?",
 "\f1 scott:\f7 what's the plan?",
 "\f2 shrike:\f7 there's a spot on the roof of the building where yorbin is known to go out and smoke. you have to get up there. should get you past most of the security - you'll be right on top of yorbin.",
 "\f1 scott:\f7 perfect. let's go."
}
dialogue_5 = 
{
 "\f1 scott:\f8 target eliminated",
 "\f2 shrike:\f7 confirmed, now get back scott. the cops have set up some sort of bio scan, we don't know what that will do but it definitely won't help us achieve our goals.",
 "\f1 scott:\f7 damn, i am on my way back.",
 "\f2 shrike:\f7 head for the mirror district. *click*"
}
dialogue_6 = 
{
 "\f2 shrike:\f7 we are shutting down the bio scan … done, go now!",
 "\f1 scott:\f7 roger that."
}
dialogue_7 = 
{
 "\f1 scott:\f7 i am clear. what exactly is a bio scan anyway?",
 "\f2 shrike:\f7 i don't know for sure, but i think the police figured out how to track all our bio signatures, you know, the marker they put on you when you were born. or maybe they were just searching for any suspicious radar blips. either way, it's not good for us.",
 "\f1 scott:\f7 they shouldn't have any information about us, though.",
 "\f2 shrike:\f7 they don't, but if you get scanned that could change.\f8just \f8stay \f8low.", 
 "\f1 scott:\f7 what was that?",
 "\f2 shrike:\f7 shit! the scanner went farther than i thought. they got your location!",
 "\f1 scott:\f7 any suggestions?",
 "\f2 shrike:\f7 duck into the crowd, blend in.",
 "\f1 scott:\f7 got it.",
}
dialogue_8 =
{
 "two days later........",
 "\f1 scott:\f7 i'm closing in on the good preacher's office.",
 "\f2 shrike:\f7 be careful, scott. security is tight there.",
 "\f1 scott:\f7 yeah, i got it.",
 "\f2 shrike:\f7 i'm serious, scott. we don't know what they got from that last scan. you may have escaped arrest last time but…",
 "\f1 scott:\f7 shrike, this has to be done.\f4 mistel\f7 uses his power to force people down, convince them that they belong in poverty. we have to stop him from putting on another show."
}
dialogue_9 =
{
 "\f1 scott:\f7 wait, what the hell?",
 "\f6 police captain:\f7 put your hands up, we have you surrounded!",
 "\f2 shrike:\f7 sco- ! ge- o-t- of- the-!",
 "\f1 scott:\f7 you can kill me, but you can't stop what i've started. the revolution-",
 "\f6 police captain:\f7 kill you? ohoho! we're not going to kill you, scott. we're going to have some fun with your brain!",
 "\f1 scott:\f7 what?!",
 "\f6 police captain:\f7 we're going to have a little talk back in the station, and then, you will come out as good as new, just like other \f8law abiding citizens…"
}

loaded = false
function start_dialogue()
	loaded = false
end

//level 1 intro
function draw_cutscene_1()
	cls()
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike		
	if loaded == false then
		for message in all(dialogue_1) do
			dtb_disp(message)
		end
		loaded = true
	end
	dtb_draw()	
end

function update_cutscene_1()
	dtb_update()
	
end

//scott interacts with robert
function draw_cutscene_2()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4)//scott
	spr(200, 100, 60, 4, 4) //robert	
	if loaded == false then
		for message in all(dialogue_2) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
end

function update_cutscene_2()
	dtb_update()
end

//scott meets shrike after robert dead
function draw_cutscene_3()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike	
	if loaded == false then
		for message in all(dialogue_3) do
			dtb_disp(message)
		end
		loaded = true
 end	
 dtb_draw()
end

function update_cutscene_3()
	dtb_update()
end

//level 2
//shrike briefs scott
function draw_cutscene_4()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike	
	if loaded == false then
		for message in all(dialogue_4) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
end

function update_cutscene_4()
	dtb_update()
end

//scott kills yorbin
function draw_cutscene_5()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike	
	if loaded == false then
		for message in all(dialogue_5) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
end

function update_cutscene_5()
	dtb_update()
end

//level 3
function draw_cutscene_6()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike			
	if loaded == false then
		for message in all(dialogue_6) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
end

function update_cutscene_6()
	dtb_update()
end

function draw_cutscene_7()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike		
	if loaded == false then
		for message in all(dialogue_7) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
end

function update_cutscene_7()
	dtb_update()
end


//level 4
//here insert cutscene 8
function draw_cutscene_8()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(196, 100, 60, 4, 4) //shrike		
	if loaded == false then
		for message in all(dialogue_8) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
 
end

function update_cutscene_8()
	dtb_update()
end



function draw_cutscene_9()
	cls()
	camera(0,0) //line up camera with dialogue
	spr(192, 0, 60, 4, 4) //scott
	spr(204, 100, 60, 4, 4) //cop
	if loaded == false then
		for message in all(dialogue_9) do
			dtb_disp(message)
		end
		loaded = true
 	end	
 	dtb_draw()
 
end

function update_cutscene_9()
	dtb_update()
end
-->8
--dialogue engine
// based on oli414s dialogue demo

-- this will add a piece of text to the queu. the queu is processed automatically.
function dtb_disp(txt,callback)
    local lines={}
    local currline=""
    local curword=""
    local curchar=""
    local upt=function()
        if #curword+#currline>29 then
            add(lines,currline)
            currline=""
        end
        currline=currline..curword
        curword=""
    end
    for i=1,#txt do
        curchar=sub(txt,i,i)
        curword=curword..curchar
        if curchar==" " then
            upt()
        elseif #curword>28 then
            curword=curword.."-"
            upt()
        end
    end
    upt()
    if currline~="" then
        add(lines,currline)
    end
    add(dtb_queu,lines)
    if callback==nil then
        callback=0
    end
    add(dtb_queuf,callback)
end

-- functions with an underscore prefix are ment for internal use, don't worry about them.
function _dtb_clean()
    dtb_dislines={}
    for i=1,dtb_numlines do
        add(dtb_dislines,"")
    end
    dtb_curline=0
    dtb_ltime=0
end

function _dtb_nextline()
    dtb_curline+=1
    for i=1,#dtb_dislines-1 do
        dtb_dislines[i]=dtb_dislines[i+1]
    end
    dtb_dislines[#dtb_dislines]=""
    //sfx(11)
end

function _dtb_nexttext()
    if dtb_queuf[1]~=0 then
        dtb_queuf[1]()
    end
    del(dtb_queuf,dtb_queuf[1])
    del(dtb_queu,dtb_queu[1])
    _dtb_clean()
    //
end

-- make sure that this function is called each update.
function dtb_update()
    if #dtb_queu>0 then
        if dtb_curline==0 then
            dtb_curline=1
        end
        local dislineslength=#dtb_dislines
        local curlines=dtb_queu[1]
        local curlinelength=#dtb_dislines[dislineslength]
        local complete=curlinelength>=#curlines[dtb_curline]
        if complete and dtb_curline>=#curlines then
            if btnp(4) then
                _dtb_nexttext()
                return
            end
        elseif dtb_curline>0 then
            dtb_ltime-=1
            if not complete then
                if dtb_ltime<=0 then
                    local curchari=curlinelength+1
                    local curchar=sub(curlines[dtb_curline],curchari,curchari)
                    dtb_ltime=1
                    if curchar~=" " then
                        sfx(11)
                    end
                    if curchar=="." then
                        dtb_ltime=6
                    end
                    dtb_dislines[dislineslength]=dtb_dislines[dislineslength]..curchar
                end
                if btnp(4) then
                    dtb_dislines[dislineslength]=curlines[dtb_curline]
                end
            else
                if btnp(4) then
                    _dtb_nextline()
                end
            end
        end
    else
		scene = "game"
	end
end

-- make sure to call this function everytime you draw.
function dtb_draw()
    if #dtb_queu>0 then
        local dislineslength=#dtb_dislines
        local offset=0
        if dtb_curline<dislineslength then
            offset=dislineslength-dtb_curline
        end
        rectfill(2,125-dislineslength*8,125,125,0)
        if dtb_curline>0 and #dtb_dislines[#dtb_dislines]==#dtb_queu[1][dtb_curline] then
            print("\x8e",118,120,10)
        end
        for i=1,dislineslength do
            print(dtb_dislines[i],4,i*8+119-(dislineslength+offset)*8,7)
        end
    end
end

//initialize dtb
dtb_init()

-->8
--interaction

//////

//interact with robert
function interaction_2()
	//interaction		
	
	if map_collision(player, "left",3)
	then
	//if button is pressed at the right spot
	
	 if btn(4)
	 then
		player.interaction = true
		end
		
	else
	//only interact when in spot
	player.interaction = false
		
	end
		
end

function draw_interaction_2()

 if map_collision(player, "left",3)
	then
	 print("🅾️",player.x - 8,player.y - 9, 10)
 end 
 
		if player.interaction == true 
		then
		//scott gets to richard dialogue
		 start_dialogue()
 		scene = "cutscene_2"
 	//switch to dead robert sprite
			mset(player.x/8-1, player.y/8, 3)
		//make sprite non-interactable 
		 fset(2, 0, false)
		 fset(2, 1, false)
		 fset(2, 3, false)
		 
		end
end

//interact with shrike

function interaction_3()
	
	if map_collision(player, "left",4)
	then
	
	//if button is pressed at the right
	//spot
	 if btn(4)
	 then
		player.interaction3 = true
		end
		
		else
		//only interact when in spot
		player.interaction3 = false
		
	end
		
end

function draw_interaction_3()

if map_collision(player, "left",4)
then
	 print("🅾️",player.x - 9,player.y - 9, 10)
end
 
		if player.interaction3 == true 
		then
		//level_1 ending dialogue
		 start_dialogue()
 	 scene = "cutscene_3"
  //make sprite non-interactable 
		 fset(4, 0, false)
		 fset(4, 1, false)
		 fset(4, 4, false)
		 //change level
		 player.x = 1000
		 player.y = 100
		 player.v = 1
		else if not fget (4,4)
		then
   scene = "part_2"
		 
		 end
		end
		
end

//level 2
function interaction_4()
	
	if map_collision(player, "right",5)
	then
	//if button is pressed at the right spot
	
	 if btn(4)
	 then
		player.interaction4 = true
		end
		
	else
	//only interact when in spot
	player.interaction4 = false
		
	end
		
end

//ineract with yorbin
function draw_interaction_4()

if map_collision(player, "right",5)
then
	 print("🅾️",player.x + 8,player.y - 9, 10)
end
 
		if player.interaction4 == true 
		then
		start_dialogue()
 	scene = "cutscene_5"
		//dead yorbin sprite
  mset(player.x/8+1, player.y/8, 8) 
	 //make sprite non-interactable 
		 fset(7, 0, false)
		 fset(7, 1, false)
		 fset(7, 5, false)
		
		end
end

//end level 2
function interaction_5()
	
	if map_collision(player, "left",6)
	then
	//if button is pressed at the right spot
	
	 if btn(4)
	 then
		player.interaction5 = true
		end
		
	else
	//only interact when in spot
	player.interaction5 = false
		
	end
		
end


function draw_interaction_5()

if map_collision(player, "left",6)
then
	 print("🅾️",player.x - 8,player.y - 9, 10)
end
 
		if player.interaction5 == true 
		then
		start_dialogue()
		
 	scene = "part_3"
 	
		//change level
		 player.x = 10
		 player.y = 200
		 player.v = 123
		end
end

//level 3 only one interaction here
function interaction_6()
	
	if map_collision(player, "right",7)
	then
	
	 if btn(4)
	 then
		player.interaction6 = true
		end
		
	else
	
	player.interaction6 = false
		
	end
		
end


function draw_interaction_6()

if map_collision(player, "right",7)
then
	 print("🅾️",player.x,player.y - 9, 10)
end
 
		if player.interaction6 == true 
		then
		start_dialogue()
 	scene = "cutscene_7"
 	fset(64,7, false)
		//change level
		 player.x = 10
		 player.y = 10
		 player.v = 1
		 
		 else if not fget(64,7)
		 then
		 scene = "part_4"
		 end
		end
end


//level 4 interact with cop
function interaction_7()
	
	if map_collision(player, "right",2)
	then
	
	 if btn(4)
	 then
		player.interaction7 = true
		end
		
	else
	
	player.interaction7 = false
		
	end
		
end


function draw_interaction_7()

if map_collision(player, "right",2)
then
	 print("🅾️",player.x + 8,player.y - 9, 10)
end
 
		if player.interaction7 == true 
		then
		start_dialogue()
 	scene = "cutscene_9"
  fset(5, 2, false)
  else if not fget(5,2)
  then
		scene = "credits"
		end
		
		end
		

end

__gfx__
00000000055555001244421111111111112222211ddddd11000aaaa01333331111111111dddddddd000000000000000000000111000000000000000001111111
00000000055555501444441111111111122222221ddddd11000000001f3f3f1111111111dddddddd0d0dddddddddddddddddd011050555555555555550111111
007007000ddddd0014040411111111111150505115555511000000001999991111111111dddddddd0dd000000000000000000001055000000000000000011111
0007700066ffff001444a4111111111114fffff41fffff11000000001fffff1111111111dddddddd0dd0dddddddddddddddddd01055055555555555555011111
000770000666666055505a511111111111444441ddddddd1000000002a222a2111111133dddddddd0dd0deeedededeeddddddd01055055555555555555011111
007007000665660055558c511111484111404041ddddadd10000000022aaa2211111f8f3dddddddd0dd0dededededddddddddd0105505cccc5555cccc5011111
0000000006666600455555411155484111444441fdddddf166066666f22222f1112af8f3dddddddd0dd0dedddddddddccccccd0105505cccc5555cccc5011111
0000000000555000166266111654888811511151155155116066666615515511152f8888dddddddd0dd0ded7777777dcccc7cd0105505cccc5555cccc5011111
055555000055555000555550111111112226611111111111111111111111111811111111111111110dd0dddddddddddcccc7cd0105505cccc5555cccc5011111
05555550055555500555555011111111222a16111118111111166611111111bc11111111911111110dd0d000000ddddccc7ccd01055055555555555555011111
0ddddd0000ddddd000ddddd011166111222216111158511116886666111111b1111111119b1111110dd0d0dddd0ddddccc7ccd01055055555555555555011111
66ffff0000ffff6600ffff66166666612a221611155555111666868611111113111111111b1111110dd0d0dddd0ddddccccccd01055055550000005555011111
066666600666666006666660116565112a22161111878111168888661111111301111111911111110dd0d0dd0d0ddddddddddd01055055550222205555011111
0665660000665660006656601165651122221611118781111cc555111111111c001111119b1111110dd0d0dddd0ddddddddddd01055055550222205555011111
0666660000666660006666601165651122221611178887111111111111111118401111111b1111110dd0d0dddd0ddddddddddd01055055550200205555011111
0500050000500050000555001166661122221611158885111111111111111111440111111111111110d0d0dddd0ddddddddddd01055055550200205555011111
06606aaa888888aaaaaa8886004444444444444444444444660222214400111111111111555445551111111112a2222111111111111111110222205555077777
0660668888888888aaaa88861004444444444444444444446602a2214440111111111111555445551111111112a2222111111111111122110222205555077777
066066666666666a6aa666661050000000000000000000006602a221000011111111111155544555111111111222222111111111111122110222205555077777
066066666666666aaa6666661055055555555555555555556602a221111111111111111044444444111111111222222111111111111122110000000000077777
06606600000000000066666610550555555555555555555566022221111111111111110444444444111111111222222111111111111222217777777777777777
0660660dddddddddd066660610550555555555555ccc5cc500022221111111111111110455544555000000000000000000000000000222217777777777777777
0660660dddddddddd066666010550555555555555ccc5cc5660222211111111111111110555445550606666666666666666666666602a2217777777777777777
0660660dddddddddd066660610550555555555555ccc5cc5660222211111111111111111555445550660000000000000000000000602a2217000000000000000
0660660dddddddddd066666610550555444455555ccc5cc566011111111111116602222155544555066066666666666666666666660111111111111111111111
0660660ddd0dd0ddd066666610550555444455555555555566011111111111116602222155544555066066666666666666666666660111111111111111111111
0660660ddd0dd0ddd066666610550554444445555555555566011111000000016602222155544555066066866666666666666666660111111000000000000000
0660660dddddddddd066066610550554444445555555555566011111444444406602a2215554455506606aa666666666666666a6660111100040444444444444
0660660dddddddddd066606610550554444a45555555555566011111000000046602a2215554455506606a866666666666666aa6660111044444000000000000
0660660dddddddddd066660010550554444a45555555555506011111444444406602a2215555555506606a888aaaaaaaaaa8aa86660111044440044444444444
6060660dddddddddd06660661055055444444555555555556001111144444444660222215555555506606aaaaaaaaaaaa8aaa886660111104404444444444444
6600000000000000000000001105055444444555555555550011111144444444660222215555555506606aaa888888aaaaaa8886660111114044444444444444
11a1111a116666666656566611111111112222221112a2222222111111111111222a222112222221222221111222222222a22222111111112222111122222211
a11111111655555555655556221111111122a2221112a2222a22111111122111222a222112a222212a22221112a2222222a22222111111112222211122222211
1111a11116555cc555555511222111111122a2221122a2222a221111111221112222222112a222212a2a222112a2222222222222111112222a2221112222a211
1111111165555cc55cc51111a2211111112222221122222222222111122222212222222112222221222a222112a2222222222a221111122a2a2221112222a211
1a1111a115555cc55cc51111a221111111222222112222a22222221112222221222222211222a22122222221122222a222222a221111122a222221112222a211
1111111111555cc55cc511112221111111222222112222a22a22a21112222221a22222211222a221222a2a21122222a222a22222111112222222211122222211
165bb561111555555cc511112a2111111122222a122222a22a22a21122a22a22a222a22112a222212a2a2a21122222a222a22222111122a2222a211122222211
6666666611155555555511112a2111111122222a122222222222221122a22a222222a21112a222212a2222211222222222222222111122a2222a211122222211
11111155116666666666666666666111111166666666666666611111111166666666611111111116666661111111111111111111111111111111111111111111
11111166666555555555555555556666666655555555555555566666111655555555566666666665555556611111111111111111111111111111111111111111
1111115555555cc5cc5555cc5cc55555655565555cc55cc555555556116555555555555555555555555555561111111111111111111111111111111111111111
1666666655555cc5cc5555cc5cc55555165555555cc55cc555555561115555555555555555555555555555551111111111111111111111111111111111111111
116111555ccc5cc5cc5555cc5cc5ccc5111555555cc55cc555555111115555555555555555555555555555551111111111111111111111111155b11111118861
11611166ccc55cc5cc5555cc5cc5ccc5111555555cc55cc555555111115555555555555555555555555555556666666666666666666611111155b1111111e661
1116666655555555cc5555cc55555555111555555cc55cc555555111115555555555555555555555555555553333333333333333333311111155b1111111e661
11111166555555555555555555555555111555555555555555555111115555555555555555555555555555553333333333333333333311111155a11111118661
66611111555555556666666611111111112222111222222111222211112a22111111111112222221111111113333333333333338888311111155a1111111e661
556666665555555565555555111111111122a211122a22211122a211112a221111111111222a2221112111113113131331311338888311111155b11111118661
555555555555555511555555111111211122a221122a22211122a2111122222111111211122a2221122111113313311331313338888311111155b11111118661
555555555555555511115cc51111112111222221122222211122221111222221111122111222a221222211113113331331311333388311111155111111111661
555555555555555511115cc52211122211222211122222211122221111222211111222111222a221222211113333333313333333333311111155111111116661
555555555555555511115cc5a211122a1122221112222a211122221111222211112a221111222211222211113333333333333333333311111115511111116111
555555555555555511115cc5a211122a1222221112222a21112a221111222a11112a22111122a21122a211115555555555555555555511111111511111116111
55555555555555551111555522111a221222221112222221112a221111222a11112222111122a21122a211116666666666666666666611111111511111116111
55555555555555556666666666666661116666661115555555551111665656666666666611111111111666661111111166566667111111111111111111111111
5555555555c55555555555555555556666555555111555555555111155655556565555651111666616655556111111116656666711111111111cc11111111111
5c5555c55cc5cc555c5555c55cc55cc555555c5511155cc55cc511115cc5551165cccc55166665556555cc55111111116656666711111111111ccc1111111111
5cc55cc5555ccc555cc55cc55cc55cc55c555cc511155cc55cc511115cc5511155cccc5511655595555ccc551111111155555557111ccc1111ccccc111111111
5cc55cc555cccc555cc55cc55cc55cc55cc55cc511155cc55cc511115cc5511155cccc551115559955cccc55111111115666656611ccccc111cccc1111111111
55c55c5555ccc5555c555c555cc55cc55cc555c511155cc55cc511115cc5511155cccc551115599955cccc55111cc1115666656611ccccc1cccccc1111111111
55555555555555c555555555555555555555555511155cc55cc51111555551115555555511155995555555551ccccccc566665661111ccc11111111111111111
5555555555555555555555555555555555555555111555555555111155555111555555551115595555555555ccccccc155555555111111111111111111111111
55551111555555556606666655555555111555555555111111111111112222225555555555555555555666115555511166666611555555541166111122222221
55551111555555556660666655555555111555555555111111111111112222a255555555555555555552211155555111555556665555555111a161112a222221
5555111155555555dddddddd5cc55cc511155cc55cc5111111111222112222a25cc55cc555c555c5555291115cc5511155cc55565c5555b4111161112a222221
55551111c55cc55c000000005cc55cc511155cc55cc51111111122a2112222225cc55cc55cc55cc5555921115cc5511155ccc5555cc55cc51111611122222221
55551111c55cc55c000000005cc55cc511155cc55cc51111111222a2112222225cc55cc55cc55cc5555665115cc5511155cccc555cc55cc51111611122222221
55551111c55cc55c000000005cc55cc511155cc55cc511111112a222112a22225cc55cc55c555c55555511115cc5511155cccc5555c55c55111161112222a221
55551111c55cc55c000000005555555511155555555511111112a222112a22225cc55cc55555555555551111555551115555555555555555111161112222a221
55551111555555550000000055555555111555555555111111122222112222225555555555555555555511115555511155555555555555551111611122222221
11111155111155555555511111555555666666116661111111116666555511115555555511155555111666665555555511111555666661116666661111115111
11111166111155555555511111155555555556665556666666665555555662115555555111155555111655555555555111155555555566665555566666666666
1111115511115cc55cc5511111115cc5555555555c5555566555655555c5b111cc55c511111555c5111555c55555c511111555c58282828282cc555682828282
1111116611115cc55cc5511111115cc555ccc5555cc55561165555555cc5b111cc5cc51111155cc511155cc5555cc51111155cc55555555555ccc55555555555
1111115511115cc55cc5511111115cc555cccc555ccc51111115555b5cc5d111cc5cc51111155cc511155cc5555cc51111155cc58282828282cccc8282828282
1111116611115cc55cc5511111115cc555cccc555cc55111111555b55cc5b1115c5cc51111155c5511155c55555cc51111155c555555555555cccc5555555555
1111115511115555555551111111555555555551555551111115bb55555666615555551111155555111555555555551111155582828282828282828282828282
1111116611111555555511111111155555555511555551111115b55b555111115555511111155555111555555555511111155555555555555555555555555555
55111111551111116666611166666666111666661111555555511111555555551661111166666666666666665555555166666111666151111211111111111111
66111111661111115555611165555555166555566666655555551111555555551161111155555555658cc5b65555551165555661555666661222111111111111
55111111551111115cc5511155cccc556555cc55a18855c55cc5511155cccc5511611111555cc55566c550565cc5511155cc5556555555561222221111111111
66666666661111115cc5511155cccc5566555cc511885cc55cc5661155cccc5511611111555cc555565850065cc551115cc555665c5555611a22221111111c11
55111161551111115cc5511155cccc5511155cc511995cc55cc5581155cccc5511611111555cc555565555565cc551115cc551115cc551111a222211111cccc1
66111661661111115cc5511155cccc55111155c511885cc55cc5591155cccc5511611111555cc5556650b5565cc551115c5511115ccc51111222a21111cccccc
66666611551111115555511155cccc5511111555666665555cc5661155cccc5511611111555cc555655055565555511155511111555551111222a21111cccccc
66111111661111118282511155555555111111151111555555551111555555551161111155555555666666665555511151111111555551111222221111111111
11111111555555556666666611112111666666666666666555555555111155552222222212222221112222111112211122221111111116665555555555555555
11111121828282828888888811122111655555555555556555555555111155552222222212222a211122221111122111a2222111111666555555555555555555
1111122255555555888889881122221156666666666666c55cc555c5111155552222222222222a221222222111122111a2222111111555c5cc5555cc555cc555
112212228282828288828899122222215cc55cc55cc55cc55cc55cc51111555522a2222222222222122a2221112222112222211111155cc5cc5555cc555cc555
22222222555555558898899812a222215cc55cc55cc55cc55cc55cc51111555522a2222222a22222122a22211122a2112222211111155cc5cc5555cc555cc555
22222a22828282828982889912a222215cc55cc55cc55cc555c55cc5111155552222222222a22222122222211122a21122a2211111155c55cc5555cc555cc555
2a222a21555555559888888812222a215cc55cc55cc55cc5555556551111555522222222222222a2122222211122221122a2211111155555cc5555cc555cc555
2a222221828282828282828212222a215555555555555555555558551111555522222222222222a2122222211122221122222111111555555555555555555555
00000000000777777777777000000000000000000077777777777777000000000000000000000000777777000000000000000000000000000000000000000000
00000000007700000000007700000000000000007770000000000007700000000000000000000777700007770000000000000000000007777700000000000000
00000000077001111111110770000000000000077000222222222200700000000000000000000770044440077700000000000000000777111777700000000000
00000000770011111001111177000000000000070022222222222220770000000000000007777704444444400777000000000000007711111111777700000000
00000000700111111111111117700000000000070222222222222222077000000000000077000044444444744007770000000000071111111111111770000000
000000077011110111111111117700000000007702222022222222220070000000000007706004444444444400000700000000000711111aa111111177700000
00000007001110111111110111070000000000702222022222222222207000000000007700060044444444400060070000000000771111aaaa11111111770000
00000007011110111111111011177000000077702220222002222222207700000000007006000444444444400600070000000000770011aaaa11111111170000
00000077011111111111111101107000000070002222222220222220220700000000007000604444444444440006070000000077000000111111111111170000
00000070111111111111111111117700000770222222222222202222020700000000007000044444444000040060070000000070000000001111111111170000
00000070111111111100111110001770000702200000222222220222220700000000007000044444440444404000070000000070000000000111111010770000
00000070111111111011111111100077000702005550022222222222220700000000007700440444440444404400770000000077000000000000111107700000
00000070111111101111111100111007000700000055502222220555550700000000000704440044440400404440700000000000700000000000000007000000
00000070011111011111111100001107000777700000000000000000000700000000000704444444440444404400700000000007705500000555555507700000
0000007770dd0011111111055550010700000070000fff000000ffffff07000000000007044444444440000440407000000000070ff5555555fffffff0700000
0000000770000001111110550000000700000070000ffff0000fffff0f070000000000070444444000444a4444407000000000070ffffffffffffff0f0700000
000000070fffff550000000000000777000000700fff00fffffffff0ff07000000000007044444000004444444407000000000070fff0ffffffffffff0700000
000000070ff0fffffff000ff00077700000000700fff0fffffffffffff07000000000007044040060700404444077000000000070fff00fff0fffffff0700000
000000070fff0ffffffffff0ff070000000000700ffffffffffffffff00700000000000704440060007004a440070000000000070fffffffff0ffff007700000
000000070fffffffffffff00ff070000000000700fffffffff0fff000077000000000007704440000000444407770000000000070fffff000ffffff577000000
0000000770fffffffffffffff0770000000000770dfffffff0fffffd077000000000000070044400400444a4070000000000000770fffffffffffff070000000
000000007700ffffff0000fff0700000000000070dff000ff0fff0d0070000000000000077004444444444a4070000000000000077000ffffff0ff0770000000
00000000070dfffffffffffff07000000000000700ffffffffff0dd0770000000000000007700400000444440700000000000077777700000005f00777000000
000000000770fff0fffff0ff0770000000000007700ffffffffffdf0700000000000000000770040604444a407000000000007000000055555fff00007777000
000000777770ffff0ffffff00777000000000000770000000ffffff070000000000000777777044404444444077777700000770111100555ffff000000007000
00007770000000ffd0ffff0000077770000000000770ddddfffffff0700000000000077000000444444444a0000000770000700dd11100fffff0011ddd007700
00077000666000fffd00000000000070007777777770ddfffffffff07777777000077707777700444444440777777007000770111d110022ff001111ddd00770
00770000660000ffffdddd0006660077077000000000fffffffffd00000000077707007000007000444440a700000700000700111dd10022000111ddddd10070
07700060000000000000000000660007700404444440ffffffffd04440544400077707000000077000000070000000700077011111d1102200111dd111111070
070006666000000001111100000066077044450444400ffffff00444054444400770000777700007000777000c00007007701111000077777777777711111070
07006666666000000011100000666607744445044440022222004440054444440770700000000007007770a88c00000707001111000770000000000770111070
0700666666600000001110000666660774444450444400222204444054444444077070000000000707000000a000000707011111007701111111110077011070
__label__
70000000777070707770077077707770000077007770777077700770777077707070777000007770777077707770000077707770770000000000000000000000
07000000700070707070707070700700000070707000070070007000070007007070700000007070700007007070000070700700707000000000000000000000
00700000770007007770707077000700000070707700070077007000070007007070770000007700770007007770000077000700707000000000000000000000
07000000700070707000707070700700000070707000070070007000070007007770700000007070700007007070000070700700707000000000000000000000
70000000777070707000770070700700000077707770070077700770070077700700777077707770777007007070070077707770707000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606660660000006600066066600000666060606660066066606660000060606600066066606060666066000000066060606660660006606660066000000000
60006060606000006060606006000000600060606060606060600600000060606060600060606060600060600000600060606060606060006000600000000000
60006660606000006060606006000000660006006660606066000600000060606060666066606060660060600000600066606660606060006600666000000000
60006060606000006060606006000000600060606000606060600600000060606060006060606660600060600000600060606060606060606000006000000000
06606060606000006060660006000000666060606000660060600600000006606060660060600600666066600000066060606060606066606660660000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666066600660666000000660666060606660000066606660666006606660000000000000000000000000000000000000000000000000000000000000
60606000600060606000600000006000606060606000000060000600606060000600000000000000000000000000000000000000000000000000000000000000
66606000660066606660660000006660666060606600000066000600660066600600000000000000000000000000000000000000000000000000000000000000
60006000600060600060600000000060606066606000000060000600606000600600000000000000000000000000000000000000000000000000000000000000
60006660666060606600666000006600606006006660000060006660606066000600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000077007770777077700770777077707070777000007770777077707770000077707770770000000111111111111111
07000000700070707070707070700700000070707000070070007000070007007070700000007070700007007070000070700700707000000111111111111111
00700000770007007770707077000700000070707700070077007000070007007070770000007700770007007770000077000700707000000111111111111111
07000000700070707000707070700700000070707000070070007000070007007770700000007070700007007070000070700700707000000111111111111111
70000000777070707000770070700700000077707770070077700770070077700700777077707770777007007070070077707770707000000111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111
66000660000066600660066066000000666006606060660066000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060000006006000606060600000600060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000
60606060000006006000606060600000660060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000
60606060000006006000606060600000600060606060606060600000000000000000000000000000000000000000000000000000000000000000000000000000
60606600000066600660660060600000600066000660606066600000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666066600660666000000660666066606660606066606660000066600000600066606660666060000000066066600000606006606660000000006660
60606000600060606000600000006000606060600600606060606000000060600000600060606060600060000000606060600000606060006000000000000600
66606000660066606660660000006000666066600600606066006600000066600000600066606600660060000000606066000000606066606600000066600600
60006000600060600060600000006000606060000600606060606000000060600000600060606060600060000000606060600000606000606000000000000600
60006660666060606600666000000660606060000600066060606660000060600000666060606660666066600000660060600000066066006660000000006660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000000222a221111111111111111111111111122222211155b11111ccccc1222211111111111111111111111111111111111111111111111111111111
0700000000000222a221111111111111111111111111122222211155b11111ccccc1222211111111111111111111111111111111111111111111111111111111
00700000000002a2222111111111111111111111111122a22a221155b1111111ccc122a211111111111111111111111111111111111111111111111111111111
07000000000002a2222111111111111111111111111122a22a221155a1111111111122a211111111111111111111111111111111111111111111111111111111
70000000000002a2222211111111222221111111111122a222221155a11115555511222211111111111111111111111111111111111112222221111111111111
00000000000002a22222111111112a2222111111111122a222221155b111155555512222211111111111111111111111111111111111122a2221111111111111
11111111111122222222111112222a2a222111111111222222221155b1111ddddd222a22211111111111111111111111111111111111122a2221111112111111
11111111111122222a22111122a2222a22211111111122222a221155111166ffff2a2a222111111111111111111111111c111111111112222221111122111111
11111111111122222a22111222a2222222211111111122222a22115511111666666a222221111111111111111111111cccc11111111112222221111222111111
11111111111122a222221112a222222a2a211111111122a22222111551111665662222222111111111111111111111cccccc1111111112222a21112a22111111
11111111111122a222221112a2222a2a2a211111111122a2222211115111166666a2222a2111111111111111111111cccccc1111111112222a21112a22111111
11111111111122222222111222222a222221111111112222222211115111115552a2222a21111111111111111111111111111111111112222221112222111111
21111111666666666665666666656666666611666666666666666666611111666666666666111111211111111111111111111111111112222221124442111111
22116666555565555566655555665555555566655555555555555555666666655555555556661112211111111111111111111111111112a22221144444111111
2221655565555cc55cc55cc55cc55cc55cc555555cc55cc55cc55cc5555555555cc555cc55561122221111111111111111111111111112a22221140404111111
2221165555555cc55cc55cc55cc55cc55cc555555cc55cc55cc55cc5555555555cc555ccc55512222221111111111111111111111111122222211444a4111111
22211115555b5cc55cc55cc55cc55cc55cc55ccc5cc55cc55cc55cc5ccc55ccc5cc555cccc5512a222211111111111111111111111111222a22155505a511111
2a21111555b55cc55cc55cc55cc55cc55cc5ccc55cc55cc55cc55cc5ccc5ccc55cc555cccc5512a222211111111111111111111111111222a22155558c511111
2a211115bb55555555555555555555555555555555555555555555555555555555555555555512222a2111111111111111111111111112a22221455555411111
22211115b55b555555555555555555555555555555555555555555555555555555555555555512222a2111111111111111111111111112a22221166266111111
22211115555555555555333333333333333855555555555555555555555555555555555555551222222111111111111111111111111166666666665656661111
222111155555555555553113131331311338555555555555555555555555555555555555555512a2222111111111111111111111666656555565556555561111
222111155cc55c5555c533133113313133385c5555c55c5555c55c5555c55c5555c55c5555c512a2222111111111111111111666655565cccc555cc555111111
222111155cc55cc55cc531133313313113335cc55cc55cc55cc55cc55cc55cc55cc55cc55cc51222222111111111111111111165559555cccc555cc551111111
222111155cc55cc55cc533333333133333335cc55cc55cc55cc55cc55cc55cc55cc55cc55cc51222a22111111111111111111115559955cccc555cc551111111
a22111155cc555c55c55333333333333333355c55c5555c55c5555c55c5555c55c5555c55c551222a22111111111111111111115599955cccc555cc551111111
a22111155555555555555555555555555555555555555555555555555555555555555555555512a2222111111111111111111115599555555555555551111111
222111155555555555556666666666666666555555555555555555555555555555555555555512a2222111111111111111111115595555555555555551111111
22211111155555555555555555555555555555555555555555555555555555555555555555551222222111111111111111111115555555555555555511111111
2221166665555555555555555555555555555555555555555555555555555555555555555555122a222111111111112111111115555555c55555555511111111
22211a1855c55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc5122a2221111111111221111111155cc55cc5cc555cc511111111
222111185cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc512222221111111112222111111155cc5555ccc555cc511111111
222111195cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc512222221111111112222111111155cc555cccc555cc511111111
222111185cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc512222a21111cc1112222111111155cc555ccc5555cc511111111
a22116666555555555555555555555555555555555555555555555555555555555555555555512222a211ccccccc22a2111111155555555555c5555511111111
a21111115555555555555555555555555555555555555555555555555555555555555555555512222221ccccccc122a211111115555555555555555511111111
22221115555555555555555555555555555555555555666666666666666655555555555555551222222111111111222211111115555555555555555511111111
2222111555555555555555555555555555555555555588888888888888885555555555555555122a222111111111222221111115555555555555555511111111
2222111555c55c5555c55c5555c55c5555c55c5555c588888988888889885c5555c55c5555c5122a2221111111112a22211111155cc555cccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc588988899889888995cc55cc55cc55cc512222221111111112a22211111155cc555cccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc588988998889889985cc55cc55cc55cc512222221111111112222211111155cc555cccc555cc511111111
222211155c5555c55c5555c55c5555c55c5555c55c55899888998998889955c55c5555c55c5512222a21111111112222211111155cc555cccc555cc511111111
222211155555555555555555555555555555555555559888888898888888555555555555555512222a2111111111222a21111115555555555555555511111111
22221115555555555555555555555555555555555555555555555555555555555555555555551222222111111111222a21111115555555555555555511111111
22221115555555555555555555555555555555555555555555555555555555555555555555551222222111111111222221111115555555555555555511111111
2222111555555555555555555555555555555555555555555555555555555555555555555555122a2221111111112a2222111115555555c55555555511111111
222211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc5122a2221111111112a2a222111155cc55cc5cc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc51222222111111111222a222111155cc5555ccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc512222221111111112222222111155cc555cccc555cc511111111
222211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc512222a2111111111222a2a2111155cc555ccc5555cc511111111
222211155555555555555555555555555555555555555555555555555555555555555555555512222a21111111112a2a2a2111155555555555c5555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555512222221111111112a2222211115555555555555555511111111
22221115555555555555555555555555555555555555555555555555555555555555555555552222222211111111222222211115555555555555555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a22222111111112a2222211115555555c55555555511111111
2222111555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c522a22222111111112a22222111155cc55cc5cc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a22111111112222222111155cc5555ccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a22111111112222222111155cc555cccc555cc511111111
222211155c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5522222222111111112222a22111155cc555ccc5555cc511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a22222111111112222a22111155555555555c5555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a2222211111111222222211115555555555555555511111111
22221115555555555555555555555555555555555555555555555555555555555555555555552222222211111111222222211115555555555555555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a22222111111112a2222211115555555c55555555511111111
222211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522a22222111112222a22222111155cc55cc5cc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a22111122a22222222111155cc5555ccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a22111222a22222222111155cc555cccc555cc511111111
222211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc5222222221112a2222222a22111155cc555ccc5555cc511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a222221112a2222222a22111155555555555c5555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a2222211122222222222211115555555555555555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522222222111222a2222222211115555555555555555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a22222111222222a2222211115555555c55555555511111111
2222111555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c522a22222112222222a22222111155cc55cc5cc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a221122a2222222222111155cc5555ccc555cc511111111
2a2211155cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc55cc522222a221122a2222222222111155cc555cccc555cc511111111
222211155c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5555c55c5522222222112222222222a22111155cc555ccc5555cc511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a2222212222a222222a22111155555555555c5555511111111
222211155555555555555555555555555555555555555555555555555555555555555555555522a2222212222a22222222211115555555555555555511111111
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55aa55
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
00000b0013070023000001010101010000000043000003000000000000000000000000000000000000000000000000000000000000000001000001010100010181010100000000000000000000000000010101010101010101010100000000000300030000000000000000000000000100000101010000010101010003000000
0000030000000000000001000100000000000000010101010000010000010101010001010101010000010100010100000000010001010000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000030300000000000000000000000000000000
__map__
7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f5b5c5d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c7f7f7f7b7f5f7f7f7f7f7f7f7e7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7b7f7f7f7f7e7f7f7f7f7f7f7f7f6b6c6d7f7f7f7f7f7f7f7f7f7f7f7e7f7f7f7f7f7f7c
7c7f7f7f7f496f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7fbb7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f5b5c5d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7b7f7f7f7f7f7f7f7f7f7f7f7f7f7faf7f7f7f7d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f687fa87fa8077f7f7f7f7f7f7f7f7f7f7f7f7f7f7faf7f7c
7c7f7f7f7a72947f7f687f7f7f7f7f7f7f7f7f7f7f7b7f7e7f7f7fba7f7f7f7f7f7f7f7d7f7f7f7f7f7f7f7f6b6c6d7e7fbb7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7d7fba7fa9a9a9a97f7f7f7f7e7f7f7f7f7f7f7f7f7f7f7f7f7c
7c7f7f7f8888977f7e497f7f7f475e7d6a7f7f7f7fba7f7f7f7f5455567f7b7b7f7f7f7f7f7f7f7f7f7f7f7fa87da87f7fbb7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7faf7f7fbb7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f657f888888b67f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c4543868888766a7f4c864a7f4c6e4d4e7f7faf7f65687f7f7f7588977f7f7f7fb35f7f7f7f7f7f7f7f7f547374729568ba7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f68ba7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f16657f8888b4b57f477f7f7f7f7f7f7aa9a99e7f7f7f7f7f7c
7c748c8788888b4a96737352515253518cb37f7f7f49667f7f7fa588857f7f7f7f656f7f7f7f7f7f7f7f7fb77083838564657f7f7f7f7f7f7f5e7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f5e7f64657f7f7f7f7f7f62555555555555427f7f7f7f7f7f7f7f7f7f7f7fb97fbfbfbfbf7f4c7f7f7f6a7f99bfa7a7bf8b7f7f7f7f7c
7c709b8788b6858f75706b6c7070707070497f7f7978777f7fbb75888bbbba7fa47878ac7f7f7f7f7f7f7f9ca7a7a78b6565167f7f7f057f7f6e7f4a7f687f7c7c7f7f7f7f137f7f7f7f6e7f65657f687f7f7f7fb7bebebfbfbebe807f867f7f7f7f7f7f7f7fae7f8f7f88b688887f4c7f7f7f4e7f84bfa7a7bf8b7f7f7f7f7c
7c707687b4b58548a58181818181818181657b6a7571767f7fba75888b444c7f9c88b6857f7f7f7f7f7f7fa5a7a7a78b4b4b7fbd5255525552ad7f497f667f7c7c7f7f7f7a5255525552ad7f4b4b7f67bb7f7f7fb7be6b6cbfbebe807f877f7f7f7f7f7f7f7fb97f8f7fb4b588887f4c7f7f684e7f84bfa7a7bf8b7f7f7f7f7c
7c7076448888854c9970707070b2b27070657f4e75a7767f7fb9758876444c7f84b4b5857f7f7f7f7f7f7f75a7a7a78b4b4b7f9929bebebebe8b7f4916877f7c7c7f7f90bf6b6cbebebe807f4b4b7f4fba7f7f7fa5bebebfbfbebe807f876a7fa452525252ac4c7f8f7fbfbfbfbf7f4cbb7f874f7f84bfa7a7bf8b7f7f7f7f7c
7c70764488888b4c848181818181818181657f4a7571767f7fb8758876874c7f9383838b7f7f515252537f9ca7a7a78b4b4b7f9939bebebebe8b7f4968447f7c7c7f7f50bfbebebebebe807f4b4b7f4f49687f7fb7bebebfbfbebe8a7f87bc7f7f888888887fb8648f7f888888887f4cba7f874f7fa5bfa7a7bf8b7fbb7f7f7c
7c70a68788888bb8997070707070707070b87f8f75a7767f7f4c758876874c7f918888857f50bfbfbfbf7f75a7a7a78b4b4b7f99bebebebebe8b7f4944447f7c7c7f7f90bfbebebebebe807f4b4b7f4849447f7fb7bebebfbfbebe807f874f7f5088888888864c444c7f888888887f4c4c7f874f7f84bfa7a7bf8b7fba7f7f7c
7c70764488888bb8758181818181818181b8868f7571767f7fb875888b444c7f9188888b7f90bfbfbfbf7f75a7a7a78b4b4b7f99bebebebebe8b7f4944447f7c7c7f7f90bfbebebebebe807f4b4b7f8f4b44437fb7bebebfbfbeaa807f874f7f7fbebebebe45b844b87fbfbfbfbf7f4c4c7f874f7f84bfa7a7bf8b7fb97f7f7c
7c89768788888bb8997070707070707070b8458f75a7768e7f4c75888b44147f9188888b8e7f61bebe618e9ca7a7a78b4b4b7f99bebebebebe8b7f4944877f7c7c7f8e13bfa7bebea7be808e4b4b7f484b87147fb7bebebfbfbebe807f87147f7f888888884b4c4b4c7f888888887f4c4c7f4c4b7fb7bfa7a7bf807fb87f7f7c
7c82828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282
7c06060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606
7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f5b5b5d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c7c7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f6b6c6d7f7f7f7b7f7f7f7faf7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c7f7f7f7f7f7f7f7f7f9aa17f50a27f7faf7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f687f7f7f7c7c7e7f7f7faf7f7f7f7f687f7f7f7f7f04a87fa87f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7d7f7c
7c7f7f7f7f7f7f7f7f7f99a17f908b7f7f7f7f7f7f7f7f7f7f7d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7e7f7f7f7f7f7f7f7d7fba7f7f7f7c7c7f7f7f7f7f7f7f7d7fba7f7f7f545552555255567f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7faf7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c5555427faf7f7f7fa3a7a07f90a7a37f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7e7f7f7f7f7f7f7f7f7f7b7f7f7f7f7f7f7f7f7f7f657f7f687c7c7f7f7f7f7f7f7f7f7f657f7f7f90bfbfbfbfbf7f7f7f7f7f7f7f7f7f7f7f7f7f7b7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c88a7767f7f7f7fa3a799a17f908ba7a37f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f657f7f457c7c7f7f7f7f7f7f7f7f7f657f7b7f5088be88be887f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7b7f7f7f7f7f7f7f7f7f7f7f7f7c
7c88a7767f7f7f9aa7a799a17f908ba7a7a27fb37f7d7f7f7f7f7f7f7f7f7e7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f407f7fb37f7f7f7f7fb97f7f447c7c7f6a7fb37f7f7f7f7fb97f7f7f90bfbfbfbebf7f7f7f7f7e7f7f7f7fb37f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c88a7a6bb7f7f99a7a799a17f508ba7a78b7f497f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7fbb7f7f7fa4a9a9a9a9ac497f7f7fae7f8f7f7f877c7c7f4c7f497f7f7fae7f8f7f7f7f9088beb4b5887f7f7f7f7f7f7f7fbb497f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7c
7c88a776ba7f7f99a7a799a17f908ba7a78b7f657b6a7f7f7f7f7f7f7f7f7f7f7f5455567f7f7f7f7f7f7fba7f7f7f7fbfa7a7bf7f657b6a7fb97f8f7f7f877c7c684c7f657b6a7fb97f8f7f7f7f90bfbfbfbfbf7f7f7f7f7f7f7f7fba657b6a7f7f7f5e7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7fb37f7f7f7f7c
7c88a776b97f7f99a7a799a07f908ba7a78b7f657f4e7f7f7f7f7f7f7f7f7f7f9aa788a7a27f7f7f7f7f7fb97f167f7fbfa7a7bf7f657f4e7f4c7f8f7f7f877c7c874c7f657f4e7f4c7f8f7f7f7f9088be88be887f7f7f7f7f7f7f7fb9657f4e7f7f026e7f7f7f7f7fba7f7f7f6a7f7f7f7f7f7f7f7f7f7f7f7f8f7f7f7f7f7c
7c88a776b87f7fa7a7a7a7a17f90a7a7a7a77f657f4a7f7f7f7f7f7f7f7f7f7f75bfbfbfab7f7f7f7f7f16b87f7f7f17bfa7a7bf19657f4a4db8458f7f7f877c7c874c2a2b2c4a7fb8478f7f7f7f50bfbfbfbfbf7f7f7f7f7f7f7f7fb8657f4a7f7a55559e7f7f7f2a2b2c2d45467f7f7f7f7f7f7f7f7f7f7f7f8f7f7f7f7f7c
7c88a7764c7f7f88888888a17f90888888887fb87f8f7f7f7f7f7f7f7f7f7f7f75bfbfbf927f7f7f7f7f7f4c7f7f7f7fbfa7a7bf7fb87f8f454c444c7f7f877c7c874c3a3b3c38684c4c4c7f7f7f9088be88be887f7f7f7f7f7f7f7f4cb87f8f17a78888a77f7f7f3a3b3c384b4f5b5b5d7f7f7f7f283e3f37188f7f7f7f6a7c
7c88a776b87f7f88888888a17f50888888887fb8868f7f7f7f0a0b0c7f7f7f7f75bfbfbf8b7f7f7f0d0e0fb87f7f7f7fbfa7a7bf7fb8868f45b844b87f7f447c7c874c2021222645b84cb87f7f7f7fbfbfbfbfbf7f7f7f7f0a0b0c7fb8b8868f7fa78888a77f7f7f202122264b4f6b6c6d7f7f7f7f7f232425278f7f7f7fbc7c
7c88a7764c8e7fa7a7a7a77f7f7fa7a7a7a77fb8458f7f8e7f1a1b1c7f8e7f7f75bfbfbf8b8e7f7f1d1e1f4c7f8e7f15bfa7a7bf7fb8458f4b4c444c7f8e4b7c7c4c4c303132264b4c4c4c7f7f7f7f88bea7be887f7f7f7f1a1b1c7f4cb8458f7fa78888a77f7f7f303132264b4fa87fa87f157f7f7f3334357f487f7f7f147c
8282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282828282
0606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606
__sfx__
04060d0f04750057500775008750080500a7500d75010750177501a7501a7501a7501a7501975019750197001970019700190001a0001a0001a00000700007000060000600000001100000000000000000000000
910400000c7301075000700007001773020730007002b720317400070000700007000070022730147400f72008740057300175000720007000000000000000000000000000000000000000000000000000000000
9204000c034200c026034200c026064200d026044200c026044200c026044200c026054200c026044200d026054200d026054200d006044060c006054060e006054060d006044060c006054060c000054000d000
0119000013710107101571020712187102871005700377102571001710057100b71013710177101c710257100b7102871019710237103d7150b71003710097100c71012710197102a71228710047002071013010
9119000006010090100c0101001015010220101f0001a010130100f0100a000090100a0000d000150101d0101f01018010120100c0000900008010070000701006000080000b0001701018010100101401024010
011900001b71025700147101c7101d7002070023710267002671029710187101b7101d7101c7101c710237101d70017710127000e7100b71010710167101471013710137001a7101a70018710137101571018710
011900202071000000187101c7101f71000000207101f710000001b710000001871012710167102071000000227101f7101c7101e7100000000000187101b7101d7100070023710217100670015710000001b710
a406002112153123510d10117301141510435108051073510310116301111510b053121510a3512c051063511315303303101031635305153155510a1510e5510b01109503151030e55111153085510b05319151
000213131c720237302f730397403a74038740337402b750237501c75016750107500e7400f7401174014740187301c7301d730207301f7301e7301f7001b7001c7001e700227001e70015700117000e7000d700
9009000013550155201a5501d5000a5500b52000000000000d5200000011550000000000000000000001454019540155201c5500000000000000001355000000115400c550000000000010520145200000000000
980700200e650124500f6200d0300b450000200d6500b4400004008630074300003000000044300c030000000c6500b45000040000000b6500b6500a450000400763007650144200b62008440000001265011450
000100001105012050110501c05015050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 03064544
02 04034344
02 05064344

