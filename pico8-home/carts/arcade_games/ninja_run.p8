pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--ninjarun! by alexa,aria,arthur
--jimmy,jordan,tyler,and diana

cartdata("ninjarunfinal")

att, default, roll, dead="att", "default", "roll", "dead"
cutscene, gameplay="cutscene", "gameplay"
melee, ranged, boss="melee", "ranged", "boss"
enm_lyr=4

act={}

function upd_act()
	for lyr in all(act) do
		for actor in all(lyr)do
			actor:upd()
		end
	end 
end

function draw_act()
	for lyr in all(act) do
		for actor in all(lyr)do
			actor:draw()
		end
	end 
end

function remove_act(actor)
	del(act[actor.lyr],actor)
	if(actor.die !=nil) actor:die()
	if(actor.pb !=nil) remove_pb(actor.pb)
end

function base_mk_actor(pos, upd, draw, lyr)
	local new_actor={
		state=default,
		lyr=lyr,
		sprite_size=v_1,
		flip_x=1,
		pos=v(pos),
		upd=upd,
		draw=draw
	}
	add(act[lyr], new_actor)
	return new_actor
end

function base_draw_actor(actor)
	spr(actor.sprite,actor.pos.x, actor.pos.y, actor.sprite_size.x, actor.sprite_size.y, actor.flip_x==-1)
end

function mk_plr(pos)
	local plr=base_mk_actor(pos, plr_upd,base_draw_actor,5)
	plr.damaged=function(self, atter, impact, dir)
		if(self.state==roll) then 
			sfx(15) 
			return 
		end
		impact()
		self.state=dead
		M_VFX.blood(self.pos + v_4, dir, 8)
		remove_act(self) 
		start_coroutine({
			0.4,
			function() 
				sfx(8)
				start_transition(false, current_lvl) 
			end
		})
	end

	plr.animations={
		idle=mk_animation("sprite=64,sx=1,sy=1,frame_count=2,frame_itvl=0.4"),
		air_up=mk_animation("sprite=66,sx=1,sy=1,frame_count=1,frame_itvl=100"),
		air_down=mk_animation("sprite=67,sx=1,sy=1,frame_count=1,frame_itvl=100"),
		walk=mk_animation("sprite=68,sx=1,sy=1,frame_count=2,frame_itvl=0.15"),
		wall_slide=mk_animation("sprite=70,sx=1,sy=1,frame_count=1,frame_itvl=100"),
		roll=mk_animation("sprite=71,sx=1,sy=1,frame_count=4,frame_itvl=0.05"),
		att_v=mk_animation("sprite=75,sx=1,sy=1,frame_count=1,frame_itvl=100"),
		att_h=mk_animation("sprite=76,sx=1,sy=1,frame_count=1,frame_itvl=100"),
	}
	plr.current_animation=plr.animations.idle

	plr.stats={
		mvm=s2t("move_speed=90,accel=15,accel_air=10,jump_vel=0~-140,jump_count=1,jump_control_ratio=0.4,jump_margin=6,walljump_vel=235~-130,wallslide_vel=40,roll_forgive=5,roll_dir=0,roll_ready_frames=0,wallhang_frames=6,is_wall_hanging=false,wall_side=0"),
		roll=s2t("off_cd=true,cd=0.55,duration=0.16,vel=255,dir=0,sfx=11,afimg_c=1"),
		att=s2t("off_cd=true,cd=0.65,hit_cd=0.25,duration=0.09,h_vel=200,v_vel=240,d_vel=200,h_hitbox=23~11,v_hitbox=12~23,d_hitbox=12~12,swing_sfx=10,hit_sfx=9,p_color=10,s_color=7,streak_c=7") 
	}

	local pb=add_pb(plr, humanoid_pb_upd, 1)
	pb.friction, pb.air_friction=0.8, 0.93
	return plr
end

function plr_upd(plr)
	local sts=plr.stats
	local pb, p_mvm, p_roll, p_att=plr.pb, sts.mvm, sts.roll, sts.att
	local cache_dx, grounded=pb.velocity.x, pb.grounded

	if(plr.state==default) p_mvm.wallhang_frames +=1

	input_x, input_y=
	(get_inp_held("R") and 1 or 0) + (get_inp_held("L") and -1 or 0),
	(get_inp_held("D") and 1 or 0) + (get_inp_held("U") and -1 or 0)

	p_mvm.jump_count=grounded and 0 or p_mvm.jump_count 

	if(get_inp_held("att") and can_perform_att(plr, p_att))then
		perform_melee_att(plr, pb, p_att, input_x, input_y, {2,3})
	end

	if input_x != 0 then
		p_mvm.roll_ready_frames = p_mvm.roll_forgive
		p_mvm.roll_dir = input_x
	else
		p_mvm.roll_ready_frames -= 1
	end

	if get_inp_held("D") and p_mvm.roll_ready_frames > 0 and can_roll(plr,p_roll,grounded) then
		slow_time(0.05,0.4)
		perform_roll(plr, pb, p_roll, p_mvm.roll_dir)
	end

	pb.drop_down=input_y > 0 and plr.state !=roll
	if(plr.state==default) then
		pb.friction_on=pb_move(
			pb, 
			input_x, 
			p_mvm)==false

		local is_over_max_speed=abs(pb.velocity.x) > p_mvm.move_speed
		pb.friction_on=pb.friction_on or is_over_max_speed
		pb.friction_scale=is_over_max_speed and 0.4 or 1

		wall_slide_upd(plr,pb,p_mvm, input_x, input_y,grounded)

		if(p_mvm.is_wall_hanging) then
			plr.flip_x=-p_mvm.wall_side
		elseif(input_x !=0) then
			plr.flip_x=input_x
		end

		if(get_inp_down("jump") and (#box_cast_all(plr.pos,v_8,{5}) > 0 or can_jump(pb, p_mvm))) then
			sfx(6)
			if(p_mvm.is_wall_hanging) then
				local j_vel=v(p_mvm.walljump_vel)
				j_vel.x *=-p_mvm.wall_side
				pb_jump(pb, p_mvm, j_vel)
				M_VFX.jump(plr.pos + v_4, -p_mvm.wall_side)
			else
				pb_jump(pb, p_mvm, p_mvm.jump_vel)
				M_VFX.jump(plr.pos + v(4,8), 0)
			end
		elseif(get_inp_up("jump") and pb.velocity.y < 0) then
			pb.velocity.y *=p_mvm.jump_control_ratio
		end
	end

	

	humanoid_anims(plr, p_mvm, cache_dx)
	upd_animation(plr)
end

function wall_slide_upd(actor, pb, a_mvm, input_x, input_y,grounded)

	local wall_jumpable=function()
		a_mvm.is_wall_hanging, a_mvm.jump_count, jump_vel=
		true,
		0,
		v(a_mvm.walljump_vel)
		jump_vel.x *=-a_mvm.wall_side

		M_VFX.sliding(actor.pos + v(8 * (a_mvm.wall_side + 1)/2,4))
	end

	-- see if any walls next to actor
	local wallOnLeft=fget(mget_pos(actor.pos + v(-1,0)),0) or fget(mget_pos(actor.pos + v(-1,8)),0)
	local wallOnRight=fget(mget_pos(actor.pos + v(8,6)),0) or fget(mget_pos(actor.pos + v(8,6)),0)
	a_mvm.wall_side=wallOnLeft and -1 or 1

	if(grounded==false and input_y == 0) then
		if(wallOnLeft or wallOnRight) then 
			pb.velocity.y=min(pb.velocity.y,a_mvm.wallslide_vel)
			a_mvm.wallhang_frames=0 
			wall_jumpable()
		else
			a_mvm.is_wall_hanging=false
		end
	else
		a_mvm.is_wall_hanging=false
	end
end

function can_roll(actor,a_roll,grounded)
	return a_roll.off_cd and actor.state==default
end

function perform_roll(actor, pb, a_roll, dir, variation)
	a_roll.off_cd, a_roll.dir, actor.state, pb.friction_on, pb.gravity_scale, variation=false, dir, roll, true, 0, variation or 0
	pb.velocity=v(a_roll.dir * (a_roll.vel + rand(-variation,variation)), 0)
	sfx(a_roll.sfx)
	set_animation_clip(actor,"roll")
	M_VFX.afterimage(actor, a_roll.duration, 20, a_roll.afimg_c)
	M_VFX.wind_streak(actor.pos + v_4 + v(dir * 8,0), -dir, 15,3,a_roll.afimg_c)
	start_coroutine({
		a_roll.duration,
		function()
			actor.state, pb.gravity_scale=default, 1
			pb.velocity.x *=0.2
		end
	})
	start_coroutine({
		a_roll.cd,
		function() a_roll.off_cd=true end
	})
end

function can_perform_att(actor, a_att)
	return a_att.off_cd and actor.state==default
end

function perform_melee_att(actor,pb,a_att, input_x, input_y, lyrs, on_contact)
	a_att.off_cd, a_att.cd_timer, actor.state=false, a_att.cd, att 
	local cd=a_att.cd

	sfx(a_att.swing_sfx)

	local vel, pb_size, hb_size, hb_pos=a_att.h_vel, pb.size
	if(input_y==0)then
		set_animation_clip(actor,"att_h")
		hb_size=a_att.h_hitbox
		input_x=(input_x !=0 and input_x) or actor.flip_x
		hb_pos=actor.pos +
			v((input_x - 1) * (hb_size.x/2 - pb_size.x/2),
				(8 - hb_size.y)/2)
	else
		set_animation_clip(actor,"att_v")
		if(input_x==0)then
			hb_size=a_att.v_hitbox
			vel, hb_pos=
			a_att.v_vel,
			actor.pos + 
				v((8 - hb_size.x)/2,
					(input_y - 1) * (hb_size.y/2 - pb_size.y/2))
		else
			hb_size=a_att.d_hitbox
			vel, hb_pos=
			a_att.d_vel,
			actor.pos +
				v((input_x - 1) * (hb_size.x)/2 + (input_x + 1) * (pb_size.x)/2,
					(input_y - 1) * (hb_size.y)/2 + (input_y + 1) * (pb_size.y)/2)
		end
	end
	local dir=v(input_x,input_y):normalized()
	local angle=atan2(input_x,input_y)

	mk_sweep_effect(actor, pb_size / 2, 0.09,
		5,7,
		0,5.5,
		angle-0.2, angle+0.4, angle,
		0.15, a_att.p_color, false)
	mk_sweep_effect(actor, pb_size / 2, 0.14,
		6,12,
		0,0.5,
		angle-0.2, angle+0.3, angle,
		0.15, a_att.s_color, true)

	local hits=box_cast_all(hb_pos,hb_size, lyrs)
	local x_lunge=1
	if(#hits > 0)then   
		m_cam.effect_adjust=dir * 10 + rand_v(-2,2)
		for hit in all(hits)do
			local h_a=hit.actor
			if(hit.lyr==3) x_lunge=0
			local impact=function()   
				sfx(a_att.hit_sfx)
				local pos=h_a.pos + (hit.size * 0.6)
				pos.y -=2
				local vari, length, width=22, 200, 2
				mk_streak_effect(pos + (dir * length),pos + (dir * -length),0.15,width + ((dir.x !=0 and dir.y !=0) and 1 or 0), a_att.streak_c,vari)
			end

			if(h_a.damaged) h_a.damaged(h_a,actor, impact, dir)

			if(a_att.hit_cd) cd=a_att.hit_cd 
			::cont::
		end

		m_cam.effect_adjust=dir * 11 + rand_v(-2.5,2.5)
		slow_time(0.12,0.0001)
	end


	pb.friction_on, pb.velocity, pb.grounded=
	true, v(input_x * x_lunge,input_y) * vel, false
	pb.velocity.y -=0.1
	pb.gravity_scale=pb.velocity.y <=-0.2 and 6 or (pb.velocity.y >=0.2 and -4 or 0)

	start_coroutine({
		a_att.duration,
		function() 
			actor.state, pb.gravity_scale=actor.state==dead and dead or default, 1
			pb.velocity *=0.5
		end
	})
	start_coroutine({
		cd,
		function() a_att.off_cd=true end
	})
	return #hits > 0
end

function humanoid_anims(actor, a_mvm, vel_x)
	if(actor.state !=default) return
	if(default_ground_anim(actor,vel_x, a_mvm)==false)then
		if(a_mvm.wallhang_frames and a_mvm.wallhang_frames==0)then
			set_animation_clip(actor,"wall_slide")
		elseif(actor.pb.velocity.y > 0) then
			set_animation_clip(actor,"air_down")
		else
			set_animation_clip(actor,"air_up")
		end
	end
end

function default_ground_anim(actor, x_vel, a_mvm)
	if(actor.pb.grounded)then
		if(abs(x_vel) > 0)then
			actor.animations.walk.frame_itvl=0.12 + 0.1*max(0,(1 - abs(x_vel)/a_mvm.move_speed))
			set_animation_clip(actor,"walk")
			return true
		else
			set_animation_clip(actor,"idle")
			return true
		end
	end
	return false
end

function enm_damaged(self, atter, impact, dir)
	if(self.state==dead) return
	if(self.state==roll) then 
		sfx(15) 
		return
	end
	impact()
	self.state=dead
	M_VFX.blood(self.pos + self.pb.size/2, dir)
	start_coroutine({
		0.05,
		function() remove_act(self) end
	})
end

function mk_enm(pos, type, facing, left_patrol, right_patrol)
	local enm=base_mk_actor(pos, base_enm_upd,base_draw_actor,enm_lyr)
	enm.damaged=enm_damaged
	enm.flip_x=facing
	local close_bhvr, mid_bhvr, mvm, roll, att, ai=nil
	if(type==ranged) then
		enm.animations={       
			idle=mk_animation("sprite=96,sx=1,sy=1,frame_count=2,frame_itvl=0.4"),
			shoot=mk_animation("sprite=103,sx=1,sy=1,frame_count=1,frame_itvl=1"),
			att=mk_animation("sprite=102,sx=1,sy=1,frame_count=1,frame_itvl=1"),
			air_up=mk_animation("sprite=100,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			air_down=mk_animation("sprite=101,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			walk=mk_animation("sprite=98,sx=1,sy=1,frame_count=2,frame_itvl=0.15"),
			roll=mk_animation("sprite=104,sx=1,sy=1,frame_count=4,frame_itvl=0.05")
		}
		close_bhvr, mid_bhvr, ai, mvm, roll, att=
		ranged_enm_close_bhvr,
		ranged_enm_mid_bhvr,
		"dx=0,dy=0,target=nil,los=64~18,close_dist=13,mid_dist=56,react_time=0",
		"move_speed=25,walk_speed=20,accel=3,accel_air=2,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
		"off_cd=true,cd=1.15,duration=0.16,vel=225,dir=0,sfx=11,afimg_c=2",
		"off_cd=true,cd=0.85"
	elseif(type==melee) then
		enm.animations={
			idle=mk_animation("sprite=80,sx=1,sy=1,frame_count=2,frame_itvl=0.4"),
			air_up=mk_animation("sprite=83,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			air_down=mk_animation("sprite=84,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			walk=mk_animation("sprite=81,sx=1,sy=1,frame_count=2,frame_itvl=0.15"),
			att=mk_animation("sprite=86,sx=1,sy=1,frame_count=1,frame_itvl=0.15"),
			roll=mk_animation("sprite=87,sx=1,sy=1,frame_count=4,frame_itvl=0.05")
		}
		close_bhvr, mid_bhvr, ai, mvm, roll, att=
		melee_enm_close_bhvr,
		melee_enm_mid_bhvr,
		"dx=0,dy=0,target=nil,los=64~18,close_dist=20,mid_dist=23,react_time=0.15",
		"move_speed=90,walk_speed=20,accel=3,accel_air=2,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
		"off_cd=true,cd=1.35,duration=0.2,vel=200,dir=0,sfx=11,afimg_c=8",
		"off_cd=true,cd=0.7,hit_cd=0.6,duration=0.1,h_vel=310,v_vel=290,d_vel=245,h_hitbox=22~7,v_hitbox=7~22,d_hitbox=10~10,swing_sfx=10,hit_sfx=9,p_color=8,s_color=7,streak_c=8"
	elseif(type==boss) then
		enm.animations={
			idle=mk_animation("sprite=112,sx=1,sy=1,frame_count=2,frame_itvl=0.4"),
			air_up=mk_animation("sprite=114,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			air_down=mk_animation("sprite=115,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			walk=mk_animation("sprite=116,sx=1,sy=1,frame_count=2,frame_itvl=0.15"),
			roll=mk_animation("sprite=119,sx=1,sy=1,frame_count=4,frame_itvl=0.05"),
			att_v=mk_animation("sprite=123,sx=1,sy=1,frame_count=1,frame_itvl=100"),
			att_h=mk_animation("sprite=124,sx=1,sy=1,frame_count=1,frame_itvl=100"),
		}
		close_bhvr, mid_bhvr, ai, mvm, roll, att=
		melee_enm_close_bhvr,
		melee_enm_mid_bhvr,
		"dx=0,dy=0,target=nil,los=64~100,close_dist=21,mid_dist=23,react_time=0",
		"move_speed=200,walk_speed=20,accel=4,accel_air=2.5,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
		"off_cd=true,cd=0.5,duration=0.2,vel=215,dir=0,sfx=11,afimg_c=2",
		"off_cd=true,cd=0.4,hit_cd=0.4,duration=0.1,h_vel=310,v_vel=290,d_vel=245,h_hitbox=23~7,v_hitbox=7~23,d_hitbox=10~10,swing_sfx=10,hit_sfx=9,p_color=7,s_color=12,streak_c=12"
	end
	enm.stats={
		ai=concat_tbl(
			{
				close_bhvr=close_bhvr,
				mid_bhvr=mid_bhvr,
				left_patrol=pos + v(left_patrol,0),
				right_patrol=pos + v(right_patrol,0),
				should_patrol=left_patrol !=0 or right_patrol !=0
			},
			s2t(ai)
		),
		mvm=s2t(mvm),
		roll=s2t(roll),
		att=s2t(att)
	}
	enm.current_animation=enm.animations.idle
	add_pb(enm, humanoid_pb_upd, 2)
	return enm
end

function melee_enm_close_bhvr(enm, pb, e_att, e_roll, input)
	if(can_perform_att(enm,e_att)==false) return
	e_att.off_cd=false
	enm.state=att
	pb.velocity=v()
	start_coroutine({
		0.08,
		function() if(enm.state !=dead) perform_melee_att(enm, pb, e_att, input.x, input.y, {1}) end
	})
end

function melee_enm_mid_bhvr(enm, pb, e_att, e_roll, input)
	if(can_roll(enm, e_roll, pb.grounded)==false) return
	perform_roll(enm, pb, e_roll, sgn(rand(-1,1)) * enm.flip_x, 30)
end

function ranged_enm_close_bhvr(enm, pb, e_att, e_roll, input)
	if(can_roll(enm, e_roll, pb.grounded)==false) return
	perform_roll(enm, pb, e_roll, sgn(rand(-1,1)) * enm.flip_x, 30)
end

function ranged_enm_mid_bhvr(enm, pb, e_att, e_roll, input, diff)
	if(can_perform_att(enm,e_att)==false) return
	e_att.off_cd,enm.state,pb.velocity=false,att,v()
	local diff=nil
	set_animation_clip(enm,"att")
	start_coroutine({
		0.15,
		function() 
			set_animation_clip(enm,"shoot") 
			diff=enm.stats.ai.target.pos - enm.pos
		end,
		0.06,
		function() 
			if(enm.state==dead) return
			M_VFX.enm_muzzle_flash(enm.pos,sgn(diff.x))
			sfx(17) 
			for i=0,3 do
				local dir=diff:normalized() + rand_v(-0.15,0.15)
				mk_projectile(enm.pos + v_4, dir:normalized(), 230, 5, 1) 
			end
			enm.state=default
		end,
		e_att.cd,
		function() e_att.off_cd=true end,
	})
end

function base_enm_upd(enm)
	local sts=enm.stats
	local pb, e_mvm, e_roll, e_att, e_ai=enm.pb, sts.mvm, sts.roll, sts.att, sts.ai
	local grounded, input, target=pb.grounded, v(), e_ai.target
	e_mvm.jump_count=grounded and 0 or e_mvm.jump_count

	if(target) then
		e_mvm.walking=false
		local diff=target.pos - enm.pos
		local dx, dy, dist=diff.x, diff.y, diff:length()
		input=round_to_8(diff)
		if(target.state !=dead) then
			if(dist <=e_ai.close_dist)then
				e_ai.close_bhvr(enm, pb, e_att, e_roll, input, diff)
			end
			if(dist <=e_ai.mid_dist) then
				e_ai.mid_bhvr(enm,pb, e_att, e_roll,input, diff)
			end
		else 
			input, dx,dy=v(), 0,0
		end
		if(enm.state==default) then
			pb.drop_down=input.y > 0
			pb.friction_on=pb_move(
				pb, 
				sign(dx), 
				e_mvm)==false
			if(dy < -7 and e_mvm.jump_cd_up and can_jump(pb, e_mvm)) then
				enm_jump(enm, pb, e_mvm)
			end
		end
	else
		input.x=base_enm_patrol(enm, pb, e_mvm, e_ai)
	end
	if(input.x !=0) then
		enm.flip_x=input.x
	end
	humanoid_anims(enm, e_mvm, input.x)
	upd_animation(enm)
end

function enm_jump(enm, pb, e_mvm)
	e_mvm.jump_cd_up=false
	start_coroutine({
		e_mvm.jump_cd,
		function() e_mvm.jump_cd_up=true end
	})
	pb_jump(pb, e_mvm, e_mvm.jump_vel)
	M_VFX.jump(enm.pos + v(4,8), 0, 1)
end

function base_enm_patrol(enm, pb, e_mvm, e_ai)
	if(enm.state==dead) return
	local i_x=0
	if(e_ai.should_patrol) then
		i_x=enm.pos.x < e_ai.left_patrol.x and 1 or (enm.pos.x > e_ai.right_patrol.x and -1 or enm.flip_x)
		e_mvm.walking=true
		pb.friction_on=pb_move(
				pb, 
				i_x, 
				e_mvm)==false
	end
	local pos=v(enm.pos)
	pos.x -=enm.flip_x==-1 and e_ai.los.x + 4 or -12
	pos.y -=(e_ai.los.y - 8)
	local hits, self_hit=box_cast_all(pos, e_ai.los, {1}), box_cast_all(enm.pos, v_8, {1})
	add(hits,self_hit[1])
	if(hits[1] and map_cast(hits[1].actor.pos + v_4, enm.pos + v_4)==false and not e_ai.found) then
		e_ai.found=true
		sfx(0)
		M_VFX.alerted(enm.pos)
		start_coroutine({
			e_ai.react_time,
			function() e_ai.target=hits[1].actor end
		})
	end
	return i_x
end


function mk_projectile(pos, dir, speed, lifetime, t_lyr)
	local streak=dir * (-4.5 + rand(-1.5,1.5))
	local p_hits, lx, ly={}, streak.x, streak.y
	local projectile=base_mk_actor( 
		pos,  
		function(self)
			lifetime -=delta_time
			if(lifetime <=0) then
				remove_act(self)
				return
			end
			local lyr=self.t_lyr
			local hits=box_cast_all(self.pos,v(1,1),{lyr})
			local hit=hits[1]
			if(hit and p_hits[hit]==nil and not hit.actor.prj_in) then
				p_hits[hit]=true
				local h_a=hit.actor
				h_a.prj_in=true
				start_coroutine({
					0.02,
					function() 
						h_a.prj_in=false
						if(self.t_lyr !=lyr) return
						m_cam.effect_adjust=dir * 11 + rand_v(-2.5,2.5)
						slow_time(0.15,0.0001)
						h_a.damaged(h_a,self,function()
							sfx(14)
						end, dir)  
					end
				})      
			end
		end,
		function(self)
			local pos=self.pos
			line(pos.x - lx,pos.y -  ly,pos.x + lx, pos.y + ly, 7)     
		end,
		7
	)
	projectile.damaged=function(self, src) 
		if(not src) return
		sfx(13)
		dir *=-1
		M_VFX.deflect(projectile.pos)
		projectile.pb.velocity *=-1
		projectile.t_lyr=2
	end
	projectile.t_lyr=t_lyr
	local pb=add_pb(projectile,proj_pb_upd, 3)
	pb.velocity, pb.friction_on, pb.gravity_scale, pb.drop_down, pb.size=
	dir * speed, false, 0, true, v(1,1)
end

function mk_dj(pos)
	local dj=base_mk_actor(pos, upd_animation, base_draw_actor, 2)
	dj.current_animation=mk_animation("sprite=30,sx=1,sy=1,frame_count=2,frame_itvl=0.4")
	add_pb(dj, nf, 5)
end

function mk_lvl_exit(pos, end_timer)
	local can_end, snd=true, true
	local exit=base_mk_actor( 
		pos or v(0,0),  
		function(self)
			if(#act[enm_lyr]==0 and can_end) then
				if(pos==nil) then
					can_end=false
					if(end_timer) save_time()
					start_coroutine({
						2,
						function() start_transition(false, current_lvl.stats.next_state) end
					})
					return
				end
				if(snd) sfx(19)
				self.sprite, snd=44, false
				if(#box_cast_all(pos+v_8,v_1, {1}) > 0) then
					if(end_timer) save_time()
					sfx(18)
					can_end=false
					remove_act(plr)
					start_transition(false, current_lvl.stats.next_state)
				end
			end
		end,
		pos and base_draw_actor or nf,
		2
	)
	exit.sprite_size, exit.sprite=v(2,2), 46    
end

function save_time()
	pause_time=true
	if(type(low_time) !="number" or game_time < low_time) then
		new_hs, low_time=true, flr(game_time * 100)/100
		dset(0,low_time)
	end
end

GRAVITY_ACCELERATION=325

p_bodies={}

function add_pb(actor, upd, lyr)
	local pb={
		actor=actor,
		lyr=lyr,
		upd=upd
	}
	concat_tbl(pb,s2t("velocity=0~0,h_dir=0,size=8~8,friction_scale=1,friction_on=true,friction=0.75,air_friction=0.9,gravity_scale=1,air_frames=0,grounded=false,wall_dir=0,drop_down=false"))
	actor.pb=pb
	add(p_bodies[lyr],pb)
	return pb
end

function humanoid_pb_upd(pb)
	if(pb.actor.state==roll)then
		pb.friction_scale=0.25
	elseif(pb.actor.state==att)then
		pb.friction_scale=1.5
	else
		pb.friction_scale=1
	end

	base_pb_upd(pb)

	if(pb.grounded)then
		pb.air_frames=0
	else
		pb.air_frames +=1
	end

	pb.h_dir=sign(pb.velocity.x)
end

function proj_pb_upd(pb)
	local hit=base_pb_upd(pb)
	if(hit) then
		M_VFX.projectile_debris(pb.actor.pos)
		remove_act(pb.actor)
	end
end

function base_pb_upd(pb)
	pb.velocity.y +=GRAVITY_ACCELERATION * pb.gravity_scale * delta_time

	local drag_factor=1 - (FRAMERATE * delta_time * pb.friction_scale * (1 - (pb.grounded and pb.friction or pb.air_friction))) 
	if(pb.friction_on) pb.velocity.x *=drag_factor

	local h_speed=abs(pb.velocity.x), abs(pb.velocity.y)
	if(h_speed < 1) pb.velocity.x=0

	local move_vtor=pb.velocity * delta_time
	local new_pos=pb.actor.pos + move_vtor
 
	local itvl=max(h_speed,v_speed) > 400 and 0.5 or 1
	return map_collision(pb, new_pos, itvl)
end

function pb_move(pb, input_x, a_mvm)
	local accel=pb.grounded and a_mvm.accel or a_mvm.accel_air
	local max_speed=a_mvm.walking and a_mvm.walk_speed or a_mvm.move_speed
	if(input_x==0) return false
	local vel=pb.velocity
	local vel_after=vel.x + input_x * accel
	if(abs(vel.x) < max_speed or pb.h_dir !=input_x) then
		if(abs(vel_after) <=max_speed or pb.h_dir !=input_x)then
			vel.x +=input_x * accel
		else
			vel.x=max_speed * input_x
		end       
	end
	return true
end

function can_jump(pb, a_mvm)
	return a_mvm.jump_count < 1 and (pb.air_frames < a_mvm.jump_margin or a_mvm.is_wall_hanging)
end

function pb_jump(pb, a_mvm, jump_vel)
	a_mvm.wallhang_frames=6
	a_mvm.jump_count +=1
	pb.velocity.y=0
	pb.velocity +=jump_vel
end

function upd_p_bodies()
	for lyr in all(p_bodies) do
		for pb in all(lyr) do
			pb:upd()
		end
	end
end

function remove_pb(pb)
	del(p_bodies[pb.lyr],pb)
	pb.actor.pb=nil
end

function map_collision(pb, pos, itvl)
	local p_a,vel, prev_pos, size, pre_x, pre_dy, resolved_pos=
	pb.actor,
	v(pb.velocity),
	v(pb.actor.pos),
	pb.size,
	pos.x,
	pb.velocity.y,
	v(pos)

	local xhit=check_horizontal_map_collision(prev_pos,pos,size,vel, itvl, p_a)
	if(xhit !=nil) then
		pb.velocity.x, vel.x, resolved_pos.x=
		0, 0, xhit.p_x
	end
	local yhit=check_vertical_map_collision(prev_pos,resolved_pos,size,vel, itvl, p_a)
	local solid_y_hit=yhit !=nil and (yhit.type !=1 or pb.drop_down==false)
	if(solid_y_hit) then
		pb.velocity.y, resolved_pos.y=0, yhit.p_y
	end

	pb.grounded, p_a.pos=
	solid_y_hit and pre_dy >=0, resolved_pos
	return solid_y_hit or xhit
end

function check_vertical_map_collision(prev_pos, pos, size, vel, itvl, actor)
	local offset, flags, ret_tbl=0, 0

	if(vel.y > 0)then
		offset=size.y
	elseif(vel.y==0)then
		return nil
	end

	for c=itvl, 1, itvl do
		local sweep_pos=v_lerp(prev_pos,pos,c)
		for i=0,1 do
			local pos=sweep_pos + v(i * (size.x - 1), offset)
			local celType=mget_pos(pos)  
			if(fget(celType,0)) then
				ret_tbl={
					type=0,
					p_y=flr(pos.y/8 - sgn(vel.y)) * 8
				}
			elseif(fget(celType,1)) then
				local hit_data=calc_coll_dists(prev_pos,size,pos_round_to_tile(pos),v_8)
				if(hit_data.y >=0 and vel.y >=0 and ret_tbl==nil) then
					ret_tbl={
						type=1,
						p_y=flr(pos.y/8 - sgn(vel.y)) * 8
					}
				end
			elseif(fget(celType,2)) then
				actor.damaged(actor,nil,function() sfx(16) end,v())
			end
		end
	end
	return ret_tbl
end

function check_horizontal_map_collision(prev_pos, pos, size, vel, itvl, actor)
	local offset=0
	if(vel.x > 0)then
		offset=size.x
	elseif (vel.x==0) then
		return nil
	end

	for c=itvl, 1, itvl do
		local sweep_pos=v_lerp(prev_pos,pos,c)
		for i=0,1 do
			local pos=sweep_pos + v(offset,i * (size.y - 1))
			local celType=mget_pos(pos)
			if(fget(celType,0)) then
				local hit_data=calc_coll_dists(prev_pos,size,pos_round_to_tile(pos),v_8)
				if(hit_data.x >=0 and hit_data.y <=0) then
					return {
						type=0,
						p_x=flr(pos.x/8 - sgn(vel.x)) * 8
					}
				end
			elseif(fget(celType,2)) then
				actor.damaged(actor,nil,function() sfx(16) end,v())
			end
		end
	end

	return nil
end

function mk_camera(a_target)
	local cam={
		camera_target=a_target,
		upd=upd_camera,
	}
	concat_tbl(cam, s2t("pos=0~0,aim_adjust=0~0,aim_mag=16,aim_speed=0.08,effect_adjust=0~0,cam_x=0,cam_y=0"))
	return cam
end

function world_to_cam(pos)
	return pos - v(m_cam.cam_x,m_cam.cam_y)
end

function upd_camera(cam) 
	local pos=cam.pos
	--follow
	if(cam.camera_target !=nil) then
		pos=cam.camera_target.pos + v(-64, -64)
	end
	--effect resolve
	cam.effect_adjust *=0.9
	if(cam.effect_adjust:length() < 2)cam.effect_adjust=v()
	--apply values to the final camera pos
	if(cam.bounded) then
		pos.x=clamp(pos.x,cam.l_bound, cam.r_bound)
		pos.y=clamp(pos.y,cam.u_bound, cam.d_bound)
	end
	pos +=cam.aim_adjust
	cam.cam_x=pos.x + cam.effect_adjust.x
	cam.cam_y=pos.y + cam.effect_adjust.y
end

function init_scene_data()
	scene_data={
		ct_intro={
			stats=s2t("type=cutscene,next_state=ct_controls_basic,music=15,restart=true,cx=-12,cy=-24"),
			map=s2t("x=18,y=41,w=13,h=7"),
			dlg={
				"\n\f9kid\f7:mom & dad are at work, and i \nhave the whole house to myself!",
				"\n\f9kid\f7:what was that?",
				"\n\f9kid\f7:oh no! if my parents find \nthat the house was invaded while \nthey were out, i'll be grounded!",
				"\n\f9kid\f7:i, the legendary \n\faninja-master\f7\nwill save the house!",
				"\nyour house has been taken\nover by \f8enemy\f7 ninjas!",
				"\nit's up to you to defend\nyour home against these\n\f8invaders!",
			},
			custom_bhvr={
				[1]=function() 
					plr=mk_plr(v(12,32)) 
					plr.state="static"
				end,
				[2]=function() 
					sfx(11)
				end,
				[3]=function() 
					local enm = load_enm("pos=32~-16,type=melee,facing=1,l_patrol=0,r_patrol=1000")	
					start_coroutine({
						3.7,
						function() remove_act(enm) end
					})		
					sfx(14)			
				end
			}
		},
		ct_victory={
			stats=s2t("type=cutscene,next_state=ct_intro,music=15,cx=-12,cy=-24"),
			map=s2t("x=86,y=41,w=13,h=7"),
			dlg={
				"\n\fcmom\f7: we're home! \nwhat did you get up to today?",
				"\n\f9kid\f7: oh, nothing much. \ni'm glad you're home!",
				"\n\fbcongratulations\f7! youve defeated \nall the \f8enemy ninjas\f7 and \nprotected your home!",
				"\ncontinue to restart\ntry to beat your \fbfastest time!"
			},
			custom_bhvr={
				[1]=function() 
					plr=mk_plr(v(12,32)) 
					plr.state="static"
				end
			}
		},
		ct_controls_basic={
			stats=s2t("type=cutscene,next_state=lvl_tut_1,music=15,cx=-12,cy=-24"),
			map=s2t("x=18,y=41,w=13,h=7"),
			dlg={
				"the controls are as follows:\n\fc⬅️\f7 - move left \n\fc➡️\f7 - move right\n\fc⬇️\f7 - roll/drop down\n\fc\148\f7 - aim up",
				"\n\fb❎\f7 - att\n\f8🅾️\f7 - jump",
				"holding \f8jump\f7 lets you jump \nhigher \n\nwhile tapping results in a short \nhop!"
			},
			custom_bhvr={
				[1]=function() 
					plr=mk_plr(v(12,32)) 
					plr.state="static"
				end
			}
		},
		lvl_tut_1={
			stats=s2t("type=gameplay,next_state=ct_controls_walljmp,plr_spawn=20~112,music=15,exit_door=128~104"),
			cam=s2t("bounded=true,l_bound=0,r_bound=24,u_bound=0,d_bound=0"),
			map=s2t("x=17,y=32,w=19,h=16"),
		},
		ct_controls_walljmp={
			stats=s2t("type=cutscene,next_state=lvl_tut_2,music=15,cx=-34,cy=40"),
			map=s2t("x=35,y=32,w=6,h=16"),
			dlg={
				"\n\f9kid\f7:lets start by clearing \nout the basement!",
				"\n\f9kid\f7:uh oh! i need a way to get \nup these walls!",
				"slide on walls by positioning \nnext to one while falling\n\npress \f8jump\f7 while sliding \nto wall jump!",
			},
			custom_bhvr={
				[1]=function() 
					plr=mk_plr(v(20,96)) 
					plr.state="static"
				end
			}
		},
		lvl_tut_2={
			stats=s2t("type=gameplay,next_state=ct_controls_dj,plr_spawn=20~108,music=15,exit_door=232~24"),
			cam=s2t("bounded=true,l_bound=0,r_bound=136,u_bound=0,d_bound=0"),
			map=s2t("x=35,y=32,w=33,h=16"),
		},
		ct_controls_dj={
			stats=s2t("type=cutscene,next_state=lvl_tut_2b,music=15"),
			dlg={
				"\nhit \f8jump\f7 while in the \n\faboost zones\f7 to jump again!",
			},
			custom_bhvr={
				[1]=function() 
					mk_dj(v(60,48))
				end
			}
		},
		lvl_tut_2b={
			stats=s2t("type=gameplay,next_state=ct_controls_ranged,plr_spawn=20~108,music=15,exit_door=40~16"),
			cam=s2t("bounded=true,l_bound=-28,r_bound=-28,u_bound=0,d_bound=0"),
			map=s2t("x=88,y=0,w=9,h=16"),
			dj_zones={
				v(50,95),
				v(34,73),
				v(19,51)
			}
		},
		ct_controls_ranged={
			stats=s2t("type=cutscene,next_state=lvl_tut_3,music=15,cx=8,cy=-16"),
			map=s2t("x=67,y=32,w=18,h=8"),
			dlg={
				"\n\f9kid\f7:theres a ninja up ahead!",
				"\nninjas in \f3green\f7 throw \n\faninja stars\f7 at you from a\ndistance.",
				"don't worry! you're able to \ndeflect \faninja stars \f7with your \n\f8attacks\f7\nor dodge them with your \fcroll",
				"\nremember, hit \n\fc⬇️\f7 while moving to \fcroll!\n\f7tip:you can roll mid-air!",
				"\nclear the room of enemies to \nprogress to the next one!",
				"\nthink fast-- once your enemies\nsee you, they will attack!"
			},
			custom_bhvr={
				[1]=function() 
					load_enm("pos=117~49,type=ranged,facing=-1,l_patrol=0,r_patrol=0")
				end
			}
		},
		lvl_tut_3={
			stats=s2t("type=gameplay,next_state=ct_controls_melee,plr_spawn=20~49,music=15,exit_door=112~24"),
			cam=s2t("bounded=true,l_bound=0,r_bound=16,u_bound=-28,d_bound=-28"),
			map=s2t("x=67,y=32,w=18,h=8"),
			enemies={
				"pos=117~49,type=ranged,facing=-1,l_patrol=0,r_patrol=0"
			}
		},
		ct_controls_melee={
			stats=s2t("type=cutscene,next_state=lvl_tut_4,music=15,cx=8,cy=-16"),
			map=s2t("x=67,y=40,w=18,h=8"),
			dlg={
				"\n\f9kid\f7:another ninja!",
				"\nkeep a close eye out-- \nninjas in \f8red\f7 attack fast\nand close with heavy attacks",
				"\ndodge them with your \fcroll\f7 \nor strike first!",
				"\nbe careful! \nthey can \fcroll\f7 too!"
			},
			custom_bhvr={
				[1]=function() 
					load_enm("pos=117~49,type=melee,facing=-1,l_patrol=0,r_patrol=0")
				end
			}
		},
		lvl_tut_4={
			stats=s2t("type=gameplay,next_state=ct_controls_sneak,plr_spawn=20~49,music=15,exit_door=112~24"),
			cam=s2t("bounded=true,l_bound=0,r_bound=16,u_bound=-28,d_bound=-28"),
			map=s2t("x=67,y=40,w=18,h=8"),
			enemies={
				"pos=117~49,type=melee,facing=-1,l_patrol=0,r_patrol=0"
			}
		},
		ct_controls_sneak={
			stats=s2t("type=cutscene,next_state=lvl_bmt_e1,music=15"),
			map=s2t("x=32,y=0,w=28,h=17"),
			dlg={
				"\nremember, \f8enemies\f7 can't see \nbelow or behind themselves\nnor can they see far up!",
				"\nuse that to your advantage \nto take them out stealthily!",
				"\ntip:use your movement keys \nto aim your \f8attack\f7!\ne.g: holding \fc\148\f7 and \f8attacking\f7 \nwill \f8attack\f7 upwards!",
				"\ngood luck, and defend your \nhome from the house ninjas!"
			},
			custom_bhvr={
				[1]=function() 
					load_enm("pos=94~22,type=melee,facing=-1,l_patrol=-53,r_patrol=0")
					load_enm("pos=120~46,type=ranged,facing=-1,l_patrol=0,r_patrol=0")
				end
			}
		},
		lvl_bmt_e1={
			stats=s2t("type=gameplay,next_state=lvl_bmt_e2,plr_spawn=20~110,music=0,exit_door=200~72"),
			cam=s2t("bounded=true,l_bound=0,r_bound=108,u_bound=0,d_bound=0"),
			map=s2t("x=32,y=0,w=28,h=17"),
			enemies={
				"pos=193~78,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=165~23,type=melee,facing=-1,l_patrol=-28,r_patrol=28",
				"pos=94~22,type=melee,facing=-1,l_patrol=-53,r_patrol=0",
				"pos=120~46,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
			}
		},
		lvl_bmt_e2={
			stats=s2t("type=gameplay,next_state=lvl_bmt_e3,plr_spawn=20~49,music=0,exit_door=96~40"),
			cam=s2t("bounded=true,l_bound=0,r_bound=0,u_bound=-28,d_bound=-28"),
			map=s2t("x=0,y=15,w=16,h=9"),
			enemies={
				"pos=80~49,type=melee,facing=1,l_patrol=-64,r_patrol=24"
			}
		},
		lvl_bmt_e3={
			stats=s2t("type=gameplay,next_state=lvl_bmt_e4,plr_spawn=20~108,music=0,exit_door=152~32"),
			cam=s2t("bounded=true,l_bound=0,r_bound=80,u_bound=0,d_bound=0"),
			map=s2t("x=16,y=16,w=25,h=16"),
			enemies={
				"pos=121~64,type=melee,facing=1,l_patrol=0,r_patrol=0",
				"pos=121~32,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=71~47,type=melee,facing=-1,l_patrol=0,r_patrol=0",
				"pos=71~24,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
			},
			dj_zones={
				v(36,76),
				v(36,42),
				v(156,92),
				v(156,60)
			}
		},
		lvl_bmt_e4={
			stats=s2t("type=gameplay,next_state=lvl_bmt_m1,plr_spawn=12~49,music=0,exit_door=104~48"),
			cam=s2t("bounded=true,l_bound=0,r_bound=0,u_bound=-28,d_bound=-28"),
			map=s2t("x=0,y=23,w=16,h=9"),
			enemies={
				"pos=72~23,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=48~55,type=ranged,facing=1,l_patrol=0,r_patrol=0"
			}
		},
		lvl_bmt_m1={
			stats=s2t("type=gameplay,next_state=lvl_bmt_m2,plr_spawn=36~26,music=0,exit_door=64~16"),
			cam=s2t("bounded=true,l_bound=0,r_bound=0,u_bound=0,d_bound=0"),
			map=s2t("x=0,y=0,w=16,h=23"),
			enemies={
				"pos=82~18,type=ranged,facing=-1,l_patrol=0,r_patrol=0"
			},
			dj_zones={
				v(89,44)
			}
		},
		lvl_bmt_m2={
			stats=s2t("type=gameplay,next_state=lvl_bmt_m3,plr_spawn=28~108,music=0,exit_door=24~64"),
			cam=s2t("bounded=true,l_bound=0,r_bound=0,u_bound=0,d_bound=0"),
			map=s2t("x=16,y=0,w=16,h=16"),
			enemies={
				"pos=72~71,type=melee,facing=1,l_patrol=0,r_patrol=0",
				"pos=72~40,type=melee,facing=1,l_patrol=0,r_patrol=0",
				"pos=112~56,type=melee,facing=-1,l_patrol=0,r_patrol=0",
				"pos=8~16,type=ranged,facing=1,l_patrol=0,r_patrol=0",
			}
		},
		lvl_bmt_m3={
			stats=s2t("type=gameplay,next_state=lvl_bmt_h1,plr_spawn=18~89,music=0,exit_door=56~16"),
			cam=s2t("bounded=true,l_bound=0,r_bound=136,u_bound=0,d_bound=0"),
			map=s2t("x=40,y=16,w=33,h=16"),
			enemies={
				"pos=183~88,type=ranged,facing=1,l_patrol=-120,r_patrol=32",
				"pos=176~88,type=ranged,facing=1,l_patrol=-112,r_patrol=32",
				"pos=168~88,type=melee,facing=1,l_patrol=-104,r_patrol=32",
				"pos=216~56,type=melee,facing=-1,l_patrol=-16,r_patrol=31",
				"pos=80~16,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=16~40,type=melee,facing=1,l_patrol=0,r_patrol=0"
			},
			dj_zones={
				v(188,78), 
				v(240,78)
			}
		},
		lvl_bmt_h1={
			stats=s2t("type=gameplay,next_state=lvl_bmt_h2,plr_spawn=173~114,music=0,exit_door=88~72"),
			cam=s2t("bounded=true,l_bound=0,r_bound=72,u_bound=0,d_bound=0"),
			map=s2t("x=72,y=16,w=25,h=16"),
			enemies={
				"pos=164~48,type=melee,facing=1,l_patrol=-20,r_patrol=12",
				"pos=28~40,type=melee,facing=1,l_patrol=0,r_patrol=0",
				"pos=20~40,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=55~112,type=melee,facing=-1,l_patrol=0,r_patrol=0",
				"pos=33~112,type=melee,facing=1,l_patrol=0,r_patrol=0",
			},
			dj_zones={
				v(176,92), 
				v(128,102),
				v(64,102)
			}
		},
		lvl_bmt_h2={ 
			stats=s2t("type=gameplay,next_state=lvl_inh_e1,plr_spawn=20~112,music=0,exit_door=8~16"),
			cam=s2t("bounded=true,l_bound=0,r_bound=104,u_bound=0,d_bound=0"),
			map=s2t("x=60,y=0,w=29,h=17"),
			enemies={
				"pos=130~111,type=melee,facing=-1,l_patrol=-14,r_patrol=8",
				"pos=214~20,type=melee,facing=-1,l_patrol=-21,r_patrol=1",
				"pos=188~92,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=88~40,type=ranged,facing=-1,l_patrol=-4,r_patrol=4",
			}
		},
		lvl_inh_e1={
			stats=s2t("type=gameplay,next_state=lvl_inh_e2,plr_spawn=12~100,music=15,exit_door=96~8"),
			cam=s2t("bounded=true,l_bound=0,r_bound=12,u_bound=0,d_bound=0"),
			map=s2t("x=1,y=32,w=16,h=16"),
			dj_zones={
					v(110,87), 
					v(80,60),
					v(35,35),
					v(55,10)
			},
		},
		lvl_inh_e2={
			stats=s2t("type=gameplay,next_state=lvl_inh_e3,plr_spawn=28~100,music=15,exit_door=216~104"),
			cam=s2t("bounded=true,l_bound=0,r_bound=128,u_bound=0,d_bound=0"),
			map=s2t("x=96,y=0,w=48,h=16"),
			dj_zones={
					v(92,52),
					v(156,52)
			},
			enemies={
				"pos=124~31,type=melee,facing=1,l_patrol=-24,r_patrol=24",
				"pos=124~31,type=melee,facing=-1,l_patrol=-24,r_patrol=24",
				"pos=8~14,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=240~14,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=225~54,type=ranged,facing=-1,l_patrol=-10,r_patrol=0",
				"pos=24~54,type=ranged,facing=1,l_patrol=0,r_patrol=10",
			}
		},
		lvl_inh_e3={
			stats=s2t("type=gameplay,next_state=lvl_inh_e4,plr_spawn=20~96,music=15,exit_door=175~8"),
			cam=s2t("bounded=true,l_bound=0,r_bound=72,u_bound=0,d_bound=0"),
			map=s2t("x=103,y=32,w=25,h=16"),
			enemies={
				"pos=101~112,type=melee,facing=-1,l_patrol=0,r_patrol=0",
				"pos=91~48,type=melee,facing=1,l_patrol=0,r_patrol=20",
				"pos=168~16,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=23~24,type=melee,facing=1,l_patrol=0,r_patrol=0",
				"pos=15~24,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=168~88,type=melee,facing=-1,l_patrol=0,r_patrol=0",
				"pos=176~88,type=ranged,facing=-1,l_patrol=0,r_patrol=0"
			},
			dj_zones={
					v(60,80), 
					v(132,80)
			},
		},
		lvl_inh_e4={
			stats=s2t("type=gameplay,next_state=ct_boss,plr_spawn=28~30,music=15,exit_door=216~72"),
			cam=s2t("bounded=true,l_bound=0,r_bound=128,u_bound=0,d_bound=0"),
			map=s2t("x=96,y=16,w=48,h=16"),
			dj_zones={
				v(152,52),
				v(152,90),
			},
			enemies={
				"pos=98~28,type=melee,facing=1,l_patrol=-2,r_patrol=22",
				"pos=208~28,type=melee,facing=-1,l_patrol=-22,r_patrol=2",
				"pos=24~87,type=ranged,facing=1,l_patrol=0,r_patrol=0",
				"pos=80~87,type=ranged,facing=-1,l_patrol=0,r_patrol=0",
				"pos=152~60,type=ranged,facing=-1,l_patrol=-8,r_patrol=8",
				"pos=152~80,type=melee,facing=1,l_patrol=-8,r_patrol=8"
			}
		},
		ct_boss={
			stats=s2t("type=cutscene,next_state=lvl_boss,music=15"),
			dlg={
				"\nall the \f8intruders\f7 have \nbeen taken care of!",
				"\nexcept for one . . .",
				"\nthe \f2big boss!",
				"\n\f2the boss\f7 is in my bedroom\nso lets take him down!"
			}
		},
		lvl_boss={
			stats=s2t("type=gameplay,next_state=ct_victory,plr_spawn=20~20,music=15,last=true"),
			cam=s2t("bounded=true,l_bound=0,r_bound=24,u_bound=0,d_bound=0"),
			map=s2t("x=85,y=32,w=24,h=16"),
			dj_zones={
					v(69,64), 
					v(100,78),
					v(39,81),
			},
			enemies={
				"pos=111~85,type=boss,facing=-1,l_patrol=0,r_patrol=0",
			}
		}
	}
end

function load_scene(scene)
	if(type(scene)=="string") scene=scene_data[scene]
	local stats=scene.stats
	local type=stats.type
	if(stats.restart) then
		game_time, new_hs, pause_time=0, false, false
	end
	start_transition(true)
	reset_act_pbodies()
	load_music(stats.music)
	if(type==gameplay) load_lvl(scene)
	if(type==cutscene) load_cutscene(scene)
end

function load_lvl(lvl_data)
	local stats,map=lvl_data.stats,lvl_data.map
	gme_st=gameplay
	plr=mk_plr(stats.plr_spawn)
	m_cam=mk_camera(plr)
	if(lvl_data.cam) concat_tbl(m_cam,lvl_data.cam)
	map_x,map_y,map_w,map_h=map.x,map.y,map.w,map.h
	for enm in all(lvl_data.enemies) do
		load_enm(enm)
	end
	for dj in all(lvl_data.dj_zones) do
		mk_dj(dj)
	end
	mk_lvl_exit(stats.exit_door,stats.last)
	current_lvl=lvl_data
end

function load_enm(enm_str)
	local enm=s2t(enm_str)
	return mk_enm(enm.pos, enm.type, enm.facing, enm.l_patrol, enm.r_patrol)
end

function load_cutscene(cutscene_data)
	local stats=cutscene_data.stats
	gme_st=cutscene
	m_cam=mk_camera()
	m_cam.pos=v(stats.cx,stats.cy)
	current_cutscene=cutscene_data
	if(cutscene_data.custom_load) cutscene_data.custom_load()
	if(cutscene_data.map) map_x,map_y=cutscene_data.map.x,cutscene_data.map.y
	load_dlg_block(cutscene_data.dlg, stats.next_state, cutscene_data.custom_bhvr)
end

function load_music(m_num)
	if(m_num==c_music) return
	c_music=m_num
	music(m_num)
end

gme_st=nil

time_scale, game_speed, FRAMERATE, current_frame, low_time=
1,
0.95,
60,
0,
dget(0) !=0 and dget(0) or 'n/a'



function _init()
	palt(14, true)
	palt(0, true)
	prev_time, current_time, delta_time, game_time=time(), time(), 1/FRAMERATE, 0
	v_1, v_4, v_8=v(1,1), v(4,4), v(8,8)
	reset_act_pbodies()
	setup_input() 
	init_scene_data()
	load_scene(scene_data.ct_intro)
end

function reset_act_pbodies()
	for i=1,10 do
		act[i]={}
		p_bodies[i]={}
	end
end

function _update60()
	upd_time()
	upd_input()
	upd_coroutines()
	if(gme_st==gameplay) gameplay_upd()
	if(gme_st==cutscene) cutscene_upd()
	transition:upd()
end

function upd_time()
	current_time=time()
	raw_delta_time=(current_time - prev_time)
	delta_time=raw_delta_time * time_scale * game_speed
	prev_time=current_time
	current_frame +=1
end

function _draw()
	cls(0)
	m_cam:upd()
	camera(m_cam.cam_x, m_cam.cam_y)
	if(gme_st==gameplay) gameplay_draw()
	if(gme_st==cutscene) cutscene_draw()
	local trunc_time = flr(game_time * 100) / 100
	print("game time:\f9" .. trunc_time, m_cam.cam_x, m_cam.cam_y + 9,7)
	print("best time:\f9" .. low_time, m_cam.cam_x, m_cam.cam_y + 1,new_hs and 11 or 7)
	transition:draw()
end

function cutscene_draw()
	local cmap=current_cutscene.map
	if(cmap) map(cmap.x,cmap.y,0,0,cmap.w,cmap.h)
	draw_act()
	camera(0,0)
	rectfill(0,88,128,128, 0)
	if(dlg) then
		local data=dlg.text[dlg.index]
		print(data, 0, 92, 7)
		print("\fb❎\f7 >", 106, 120, 7)
	end
	camera(m_cam.cam_x, m_cam.cam_y)
end

function cutscene_upd()
	upd_p_bodies()
	upd_act()
	if(get_inp_down("att")) progress_dlg()
end

function gameplay_draw()
	map(map_x,map_y,0,0,map_w,map_h)
	draw_act()    
end

function gameplay_upd()
	upd_p_bodies()
	upd_act()
	if(not pause_time) game_time +=raw_delta_time
end

function load_dlg_block(block, next_state, bhvr)
	dlg={
		text=block,
		bhvr=bhvr,
		index=1,
		next=function()
			start_transition(false, next_state)
		end
	}
	if(bhvr and bhvr[1]) bhvr[1]()
end

function progress_dlg()
	if(dlg==nil) return
	dlg.index +=1
	local bhvr=dlg.bhvr
	if(bhvr and bhvr[dlg.index]) bhvr[dlg.index]()
	if(dlg.index > #dlg.text) then
		dlg:next()
		dlg=nil
	end
end

M_VFX=
{
	sliding=function(pos)
		local size=v(1,2)
		if(current_frame % 3==0) mk_ptcle(pos,size,size,rand_v(-1,1),1,0.2,7,0)
	end,
	deflect=function(pos)
		local size=v(1.5,1.5)
		for i=0,7 do
			mk_ptcle(pos + v(-4,1), size, size, rand_v(-50,50):normalized() * 80, 0.5, 0.6 + rand(-0.3,0.1), 10, 0.7 , 8)
		end
	end,
	enm_muzzle_flash=function(pos, dir, color)
		local tby_size, mw_size, c, pos=v(dir*2,3), v(dir*4,5), color or 6, pos + v(4,2) + v(6,0) * dir 
		mk_ptcle(pos + v(dir,1), tby_size, tby_size, v(), 0,0.17, 7, 0.5, 6)
		mk_ptcle(pos, mw_size, mw_size, v(), 0, 0.15, c, 0.5, 5)
	end,
	blood=function(pos, dir, color)
		for i=0,15 do
			local size=rand_v(2,3)
			mk_ptcle(pos + rand_v(-6,6), size,size,dir * 150 + rand_v(-100,100), 0.9, 2, color or 8, 1)
		end
	end,
	jump=function(pos, h_dir, color)
		local c, size=color or 7, h_dir==0 and v(2,1) or v(1,2)
		for i=0,15 do
			local vel=v(cos(i/15),sin(i/15))
			if(h_dir==0) then vel.y /=3
			else vel.x /=3 end
			mk_ptcle(pos + vel * 2.5, size,size,vel * 100, 0.15, 0.4 + rand(-0.1,0.1), c, 0,3)
		end
		M_VFX.wind_streak(pos,h_dir,10, 5,c)
	end,
	wind_streak=function(pos, h_dir, len, width, c)
		if(h_dir !=0) then
			local size, size_end, vel=v(h_dir*-len,1), v(0,1), v(h_dir*75,0)
			mk_ptcle(pos + v(rand(0,h_dir*16),width), size , size_end, vel, 0.8, 0.25, c, 0,3)
			mk_ptcle(pos + v(rand(0,h_dir*16),-width), size , size_end, vel, 0.8, 0.25, c, 0,3)
		else
			local size, size_end, vel=v(1,len), v(1,0), v()
			mk_ptcle(pos + v(width,rand(-15,-5)), size, size_end,vel, 0.8, 0.25, c, -0.6,3)
			mk_ptcle(pos + v(-width,rand(-15,-5)), size, size_end,vel, 0.8, 0.25, c, -0.6,3)
		end
	end,
	afterimage=function(actor, duration, count, color)
		local shadow=function() 
			local size,pos=rand_v(2,4), actor.pos + rand_v(-2,2)
			local size2=size + v(1,1)
			mk_ptcle(pos + v(4,4), size,size,v(), 0, 0.15, color, 0, 2) 
			mk_ptcle(pos + v(3,3), size2,size2,v(), 0, 0.15, 7, 0, 1) 
		end
		for i=0,count do
			start_coroutine({
				duration/count * i,
				shadow
			})      
		end
	end,
	projectile_debris=function(pos)
		for i=0,2 do
			mk_ptcle(pos, v_1,v_1, rand_v(-50,50), 0.6, 0.5,7, 1)
		end
	end,
	alerted=function(pos)
		local s1,s2=v(2,4),v(2,2)
		mk_ptcle(pos + v(0,-12), s1,s1, v(), 0, 0.5,7, 0)
		mk_ptcle(pos + v(0,-4), s2,s2, v(), 0, 0.5,7, 0)
		mk_ptcle(pos + v(1,-13), s1,s1, v(), 0, 0.5,8, 0)
		mk_ptcle(pos + v(1,-5), s2,s2, v(), 0, 0.5,8, 0)
	end
}

function mk_ptcle(pos, size, size_end, velocity, drag, lifetime, color, grav_scale, lyr)
	local lifetimer, b_size, sx,sy=lifetime, v(size), sgn(size.x), sgn(size.y)
	local ptcle=base_mk_actor( 
		pos,  
		function(self)
			lifetimer -=delta_time
			if(lifetimer <=0) then
				remove_act(self)
				return
			end
			local vel, t=velocity, 1 - lifetimer / lifetime
			vel.y +=GRAVITY_ACCELERATION * grav_scale * delta_time
			vel=vel * drag
			size=v_lerp(b_size,size_end,t)
			pos +=vel * delta_time
		end,
		function(self)
			rectfill(pos.x,pos.y,pos.x+size.x - sx,pos.y+size.y - sy,color)     
		end,
		lyr or 6
	)
end

function start_transition(fadein, next_state)
	if(fadein) then mk_transition(0,128,128,128,1.1)
	else mk_transition(0,0,0,128,1.1) end
	if(next_state==nil) return
	start_coroutine({
		1.05,
		function() 
			load_scene(next_state)
		end
	},true)
end

function mk_transition(l1, l2, r1, r2, duration, color)
	input_enabled=false
	local timer, l, r=duration, l1, r1
	transition={
		upd=function(self)
			timer -=raw_delta_time
			if(timer <=0) then
				l,r=-1,-1
				input_enabled=true
				return
			end
			local t=smooth(1 - timer / duration)
			l, r=lerp(l1,l2,t), lerp(r1,r2,t)
		end,
		draw=function(self)
			rectfill(l + m_cam.cam_x,m_cam.cam_y, m_cam.cam_x + r,m_cam.cam_y + 128 , 0)
		end,
	}
end

function mk_streak_effect(p1,p2, duration, width, color,rand)
	local variation=rand_v(-rand,rand)
	p1 +=variation
	p2 -=variation
	local dist=(p2 - p1):length()
	local slash=base_mk_actor(
		v(),
		function(self) 
			self.timer -=delta_time
			if(self.timer <=0) then 
				remove_act(self) 
				return 
			end
			local t=self.timer / duration
			self.c_width=flr(width * t + 0.5)
			p2=p1 + (self.dir * (t * dist))
		end,
		function(self) 
			base_draw_line(p1,p2,self.c_width,color)
		end,
		8
	)
	slash.timer, slash.c_width, slash.c=duration, width, v(p2)
	slash.dir=(slash.c - p1):normalized()
end

function mk_sweep_effect(tracked_actor, offset, duration,
	min_rad, max_rad,
	min_width, max_width,
	start_angle, end_angle,mid_angle,
	start_t, color, sharp)
	local sweep=base_mk_actor(
		v(),
		function(self) 
			self.timer -=delta_time
			if(self.timer <=0) then 
				remove_act(self) 
				return 
			end
			local t=start_t + (1 - self.timer / duration) * (1-start_t)
			self.c_angle=lerp(start_angle,end_angle,t)
		end,
		function(self) 
			draw_sweep_vfx(tracked_actor.pos + offset,
			min_rad,max_rad,
			min_width,max_width,
			start_angle,end_angle,mid_angle, self.c_angle,
			color, sharp)
		end,
		7
	)
	sweep.timer, sweep.c_angle=duration, start_angle
end

function base_draw_line(p1,p2,width,color)
	if(width==1)then
		line(p1.x,p1.y,p2.x,p2.y,color)
		return
	end
	width -=1
	local perp=v(p2.y - p1.y,p1.x-p2.x)
	local x_o, y_o=sgn(perp.x), sgn(perp.y)
	perp=perp:normalized()
	for i=-width/2, width/2-1, 1 do
		local p1=p1 + (perp * i)
		local p2=p2 + (perp * i)
		line(p1.x,p1.y,p2.x,p2.y,color)
		line(p1.x,p1.y+y_o,p2.x,p2.y+y_o,color)
		line(p1.x+x_o,p1.y,p2.x+x_o,p2.y,color)
	end
end

function draw_sweep_vfx(pos,
	min_rad, max_rad,
	min_width, max_width,
	a_start,a_end, a_mid, a_current,
	color, sharp)
	local itvl,px,py=1/90 * sgn(a_end - a_start), pos.x, pos.y
	local draw_segment=function(_start,_end,_current, invert)
		for i=_start, min(_current,_end), itvl do
			local t=(i - _start)/(_end-_start)
			t=invert and 1 - t or t
			radius=lerp(min_rad,max_rad,sharp and t or smooth(t))
			radius2=radius + max(0,lerp(min_width,max_width,t))
			local x,y=cos(i), sin(i)
			if(radius2 !=radius) line(x*radius + px,y*radius + py, flr(x*radius2 + px), flr(y*radius2 + py), color)
		end
	end
	draw_segment(a_start,a_mid,a_current, false)
	draw_segment(a_mid,a_end,a_current, true)
	
end

function mk_animation(data_string)
	local anim_clip=s2t(data_string)
	anim_clip.timer, anim_clip.current_frame, anim_clip.size=0, 0, v(anim_clip.sx,anim_clip.sy)
	return anim_clip
end

function upd_animation(actor)
	local ca=actor.current_animation
	ca.timer +=delta_time
	if(ca.timer >=ca.frame_itvl) ca.timer, ca.current_frame=0, (ca.current_frame + 1) % ca.frame_count
	actor.sprite=ca.sprite + ca.current_frame * ca.size.x
end

function set_animation_clip(actor, clip_name)
	local c_anim=actor.current_animation
	if(c_anim==actor.animations[clip_name] or actor.animations[clip_name]==nil) return
	c_anim=actor.animations[clip_name]
	c_anim.current_frame, c_anim.timer=0,0
	actor.current_animation=c_anim
end


function clamp(value,lower,upper)
	if(value < lower) then
		return lower
	elseif(value > upper) then
		return upper
	end
	return value
end

function nf() end

function sign(a) 
	return a==0 and 0 or sgn(a)
end

function lerp(a,b,t)
	t=clamp(t,0,1)
	return a + (b-a)*t
end

function rand(l,r)
	if(l > r) l,r=r,l
	local val=rnd(r-l) + l
	return val
end

function rand_v(l,r)
	return v(rand(l,r),rand(l,r))
end

function smooth(t)
	return t*t*t *(t * (6*t - 15) + 10)
end

function s2t(data)
	local res={}
	local props=split(data,",")
	for prop in all(props)do
		local components=split(prop,"=")
		local rhs=components[2]
		if(type(rhs)=="number") then rhs=tonum(rhs)
		elseif(rhs=="false") then rhs=false
		elseif(rhs=="true") then rhs=true
		elseif(rhs=="nil") then rhs=nil
		else 
			local p_v=split(rhs,"~")
			if(#p_v==2) rhs=v(tonum(p_v[1]),tonum(p_v[2]))
		end
		res[components[1]]=rhs
	end
	return res
end

function concat_tbl(t1,t2)
	for k,v in pairs(t2) do t1[k]=v end
	return t1
end


v_mt={}

function v_lerp(a,b,t)
	return v(lerp(a.x,b.x,t),lerp(a.y,b.y,t))
end

function v(x,y)
	if(x==nil) return v(0,0)
	local v={
		x=x,
		y=y,		
		length=function(self) return 100*sqrt((self.x/100)^2 + (self.y/100)^2) end,		
		normalized=function(self)        
			local len=self:length()
			if(len==0) return v()
			return self / len
		end
	}
	if(type(x) !="number") v.x, v.y=x.x, x.y
	setmetatable(v,v_mt)
	return v
end

function v_mt.__add(a, b)
	return v(a.x + b.x, a.y + b.y)
end

function v_mt.__sub(a,b)
	return v(a.x - b.x, a.y - b.y)
end

function v_mt.__mul(a, b)
	return v(a.x * b, a.y * b)
end

function v_mt.__div(a, b)
	return v(a.x / b, a.y / b)
end

function pos_round_to_tile(pos)
	local rounded=v(pos)
	rounded.x, rounded.y=flr(rounded.x / 8) * 8, flr(rounded.y / 8) * 8
	return rounded
end

r_tbl={v(1,0),v(1,-1),v(0,-1),v(-1,-1),v(-1,0),v(-1,1),v(0,1),v(1,1),v(1,0)}
function round_to_8(v)
	local round=flr(atan2(v.x,v.y) * 8 + 0.5) + 1
	return r_tbl[round]
end

function mget_pos(pos)
	return mget(pos.x/8 + map_x,pos.y/8 + map_y)
end

function map_cast(p1,p2)
	local itvls=(p1 - p2):length() / 8 + 1
	for i=0, itvls do 
		if(fget(mget_pos(v_lerp(p1,p2,i/itvls)),0)) return true
	end
	return false
end

function AABintersection_check(p1, s1, p2, s2)
	if(p1.x + s1.x < p2.x)then
		return false
	elseif(p2.x + s2.x < p1.x)then
		return false
	end

	if(p1.y + s1.y < p2.y)then
		return false
	elseif(p2.y + s2.y < p1.y)then
		return false
	end
	return true
end

function box_cast_all(pos,size,lyrs)
	local hits={}
	for lyr in all(lyrs)do
		for body in all(p_bodies[lyr])do
			if(AABintersection_check(pos,size,body.actor.pos,body.size)) add(hits,body)
		end
	end
	return hits
end

function calc_coll_dists(p1, s1, p2, s2)
	local dx,dy, x1, x2, y1, y2=0,0, p1.x, p2.x, p1.y, p2.y
	if(x1 < x2)then
		dx=x2 - (x1 + s1.x)
	elseif(x1 > x2) then
		dx=x1 - (x2 + s2.x)
	end
	if(y1 < y2)then
		dy=y2 - (y1 + s1.y)
	elseif(y1 > y2) then
		dy=y1 - (y2 + s2.y)
	end
	return{
		x=dx,
		y=dy
	}
end

function calc_coll_time(p1, s1, vel, p2, s2)
	local dists=calc_coll_dists(p1,s1,p2,s2)

	local dx,dy=dists.x,dists.y

	local t_x,t_y, s_time, s_axis=
	vel.x==0 and 0 or abs(dx / vel.x),
	vel.y==0 and 0 or abs(dy / vel.y),
	0, 0

	if(vel.x !=0 and vel.y==0)then
		s_axis, s_time=0, t_x
	elseif(vel.x==0 and vel.y !=0)then
		s_axis, s_time=1, t_y
	else
		if(t_x > t_y) s_axis=1
		s_time=min(t_x,t_y)
	end
	return {time=s_time, axis=s_axis,dx=dx, dy=dy}
end

raw_keyboard_map=s2t("44=jump,43=tab,30=mspawn,31=rspawn,4=L,7=R,26=U,22=D,17=att,16=jump")


default_i_m={
	L=s2t("b=0,p=0"),
	R=s2t("b=1,p=0"),
	U=s2t("b=2,p=0"),
	D=s2t("b=3,p=0"),
	att=s2t("b=5,p=0"),
	jump=s2t("b=4,p=0"),
}

i_s=s2t("L=0,R=0,U=0,D=0,jump=0,att=0,tab=0,rspawn=0,mspawn=0")

function setup_input()
	poke(0x5f2d, 1|2|4)
end

function upd_input()
	mouse_x=stat(32)
	mouse_y=stat(33)
	for i_m, state in pairs(i_s) do
		i_s[i_m]=(state << 1) & 8
	end
	if(input_enabled)then
		for  keycode, i_m in pairs(raw_keyboard_map) do
			i_s[i_m] |=stat(28,keycode) and 4 or 0
		end
		for i_m, d_i  in pairs(default_i_m) do
			i_s[i_m] |=btn(d_i.b,d_i.p) and 4 or 0
		end
	end
	for i_m, state in pairs(i_s) do
		if(state & 8==8) then
			if(state & 4 !=4) i_s[i_m] |=1
		else
			if(state & 4==4) i_s[i_m] |=2
		end
	end
end

function get_mouse_pos()
	return v(mouse_x,mouse_y)
end

function get_inp_state(i,f)
	local st=i_s[i]
	return (st & f==f)
end

function get_inp_held(i)
	return get_inp_state(i,4)
end

function get_inp_down(i)
	return get_inp_state(i,2)
end

function get_inp_up(i)
	return get_inp_state(i,1)
end

coroutines={}

function upd_coroutines()
	for i=#(coroutines), 1, -1 do
		local c=coroutines[i]
		c.timer +=c.raw and raw_delta_time or delta_time
		if(c.timer >=c.cList[c.index]) then
			c.timer=0
			c.index +=1
			if(progress_coroutine(c)==false) del(coroutines,c)     
		end        
	end
end

function progress_coroutine(c)
	for i=c.index, #(c.cList) do
		local command=c.cList[i]
		c.index=i
		if(type(command)=="number")then
			break
		else
			command()
		end
	end
	if(c.index >=#(c.cList))then
		return false
	end
	return true
end

function start_coroutine(c_l, raw)
	local c={
		raw=raw,
		cList=c_l,
		index=1,
		timer=0
	}
	if(progress_coroutine(c))then
		add(coroutines,c)
	end   
	return c
end

function clear_all_coroutines()
	coroutines={}
end

function stop_coroutine(c)
	del(coroutines,c)
end

function slow_time(duration, scale)
	stop_coroutine(time_slow)
	time_scale *=scale
	time_slow=start_coroutine({
		duration,
		function() time_scale=1 end
	}, true)
end

__gfx__
000000004444444444444444dddddddddddddddd6611111111111111111111662222222266666666666666666555555655666555555666556666666644444444
000000004cccccccccccccc4dddddddddddddddd6111111111111111111111162222222266666666666666665777777556665cccccc566656446644677777777
000000004cccc111111cccc4ddccccccccccccdd111111111111111111111111dddddddd66666666666666665777777566665cccccc566666444444676555567
000000004ccc11111111ccc4ddccccccccccccdd111111111111111111111111dddddddd66666666666666665777777566666555555666666404404675666657
000000004ccc111fff11ccc4ddc0000cc00000dd111111111111111111111111dddddddd66666666666336665777777566666666666666664640046456666665
000000004ccc1fffff11ccc4ddcffffc00fff0dd111111111111111111111111dddddddd666666666633336657777775666dddddddddd666644ff44666666666
000000004ccccffffffcccc4ddcffffc0ffff0dd111111111111111111111111dddddddd666666666333333657777775666d11115555d66664ffff4666666666
000000004cccc777777cccc4ddcffffc0ffff0dd111111111111111111111111dddddddd666666663333333365555556666d11111555d6664666666466666666
644475474ccc777777777cc4dd777777ceeeefdd44444444444444444444444466ccccc77ccccc666665566666666666666d11115555d6660000000090077009
467475744c77777777777ac4ddf7777000eeefdd4442222233333111116666446cccccc77cccccc66665566666666666666d11155555d6660a0770a00a0000a0
446777744c777777777775c4ddf7777fffeecfdd444222223333311111666644ccc7ccc77ccc7ccc6665566666666666666d11115555d6660090090000009000
6662875547777577775c5554ddc1cc1fffeeeedd444227223373311711667644cccc7cc77cccc7cc6665566666666666666d11111555d6660707a0a0709a7007
446227774777c555555cc6c4ddc1cf33333feedd444227223373311711667644ccccccc77ccccccc6665566664666446666d11115555d6660a0a70707007a907
466666444cccc555555cc6c4ddc1fc1333ccfcdd444227223373311711667644ccccccc77ccccccc6665566644544444666d11111555d6660090090000090000
465646644ccccffccffcc6c4dddddddddddddddd444227223373311711667644ccccccc77ccccccc6665566655555555666d11115555d6660a0770a00a0000a0
655655564444444444444444dddddddddddddddd444227223373311711667644ccccccc77ccccccc6665566644444544666d11111555d6660000000090077009
55555555444445444444454444444544dddddddd444222223333311111666644ccccccc77ccccccc666666666666666655666555555666555566655555566655
55000055444445444444454444444544dddddddd444222223333311111666644ccccccc77ccccccc666666666666666656665bbbbbb566655666588888856665
5050050544466666666645444444454411111111444444444444444444444444ccccccc77ccccccc666666666666666666665bbbbbb566666666588888856666
50055005552222222222255555555555111111114444444444444444444444447777777777777777666655566555666666666555555666666666655555566666
50055005442222222222244444544444111111114444444444444444444444447777777777777777666544455444566666666666666666666666666666666666
5050050544222222222224444454444411111111444444444444444444444444ccccccc77ccccccc6665444554445666666dddddddddd666666dddddddddd666
5500005544222222222224444454444411111111444333111122220000555544ccccccc77ccccccc6665444554445666666d11115555d666666d6666d666d666
5555555555666666666665555555555511111111444333111122220000555544ccc7ccc77ccc7ccc6666555665556666666d11111555d666666d6666d666d666
dddddddd44222222222225444444ffffffff4544444333111122220000555544cccc7cc77cccc7cc6665444554445666666d11115555d666666d6666d666d666
5555555544222222222225444ffff000000ffff4444373117127220700575544ccccccc77ccccccc6665444554445666666d11155555d666666d666d6666d666
5466664544222222222225444ffffffffffffff4444373117127220700575544ccccccc77ccccccc6665444554445666666d11115555d666666d666d6666d666
5644456555222222222225555ffffffffffffff5444373117127220700575544ccccccc77ccccccc6665444554445666666d11111555d666666d666d6666d666
6555555644666666666664444ffffffffffffff4444333117127220700575544ccccccc77ccccccc6665444554445666666d11115555d666666d666d6666d666
4454444444222222222224444ffffffffffffff4444333111122220000555544ccccccc77ccccccc6665444554445666666d11111555d666666d6666d666d666
4454444444222222222224444ffffffffffffff444433311112222000055554477777777777777776665444554445666666d11115555d666666d6666d666d666
5555555555522222222255555ffffffffffffff544444444444444444444444477777777777777776665444554445666666d11111555d666666d6666d666d666
00101100000000000000000001100000100000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101110001101100000110000001110001101100100111001101100001101100000000000000010000000000000110a00010faa0000000000000000000000000
0101f100100111000011110000001110000111000001f1001011100011111100000110110004001000000fa00011110a0101110a000000000000000000000000
000771000001f1000101f1fa40011f100001f100000771f0001f10a011111f00000111110004f0110100004f0101f1fa0101f1fa000000000000000000000000
000777fa000771fa0107714004477100444771f00007774af7710400000777f00001111f00f557f111f775500f07104a4407710a000000000000000000000000
0005574000077740444755000005774a0005574a4445570007774f004447774a4455774a000577f11117755f0005570a0045574a000000000000000000000000
4445550044455500000555f000f5550000f555000005550055550000000555000f5577000005771101111450004555a0000555a0000000000000000000000000
000f0f00000f0f0000f00000000000f0000000f00000ff00f550000000ff00f0000f00f00000af000011040004f000f000faaaf0000000000000000000000000
00808880000000000080888000000000000088800080000000077770000007700008000000770000000077000000000000000000000000000000000000000000
00088ff00080888000088ff000808880008888f00008888000808887080888070000880007000800000000700000000000000000000000000000000000000000
0080888000088ff00080888000088ff000088f8000888f8000088ff70088ff0700000888700d008000000f270000000000000000000000000000000000000000
00088500008088800008850000808880008885020f0088f00080888708088500000008f8700df088000000df0000000000000000000000000000000000000000
000858f20f08850000f858f20f088500000858fd000885000f088507000858f00000088f70f858f808f855870000000000000000000000000000000000000000
0f0555d0000555f2ddd555d0000555f20f0555d0ddd555f0000555f7ddd588d2dd8558d2700855f808f5858f0000000000000000000000000000000000000000
ddd888f0ddd888d000088800ddd888df00d8888f00f888d2ddd888d7000555000f8585070708588808880d870000000000000000000000000000000000000000
00f000f000f000f0000ff00000f000f0ddf00000000000f00777777000ff00f0077f77f700772f0000888d700000000000000000000000000000000000000000
00303330000000000030333000000000000033300030000000303330003777300000000000000300007777000007700000000000000000000000000000000000
00033ff00030333000033ff000303330003333f00003333007033ff007733f700303330000000330070003700000070000000000000000000000000000000000
0030333000033ff00030333000033ff000033f3007333f307f7033307f7033370033ff00000000307000703700007f7000000000000000000000000000000000
00033200073033300073320007303330003332007f7033f00703320f0703320703033207000003337007f7330000070f00000000000000000000000000000000
070323f07f73320f07f723f07f73320f070323f0070332000003230000032307007323f7000003f300f323f303f3223700000000000000000000000000000000
7f7222000702220000722200070222007f722200000222f0000222000002220707f23307003223f3000323f303f2323f00000000000000000000000000000000
070333f0000333f0000333000003333f0703333f00f33300000333f000033370007222700f323277000322330333003700000000000000000000000000000000
00f000f000f000f0000ff00000f000f000f00000000000f000f000f000f777f000ff77f0077f07f700000f000033377000000000000000000000000000000000
00202200000000000000000002200000200000000220220000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202220002202200000220000002220002202200200222001101100002202200000000000000020000000000000220c00020fcc0000000000000000000000000
0202f200200222000022220000002220000222000002f2001011100022222200000220220004002000000fc00022220c0202220c000000000000000000000000
000772000002f2000202f2fc40022f200002f200000772f0001f10a022222f00000222220004f0220200004f0202f2fc0202f2fc000000000000000000000000
000777fc000772fc0207724004477200444772f00007774cf7710400000777f00002222f00fdd7f222f77dd00f07204c4407720c000000000000000000000000
000dd740000777404447dd00000d774c000dd74c444dd70007774f004447774c44dd774c000d77f222277ddf000dd70c004dd74c000000000000000000000000
444ddd00444ddd00000dddf000fddd0000fddd00000ddd00dddd0000000ddd000fdd7700000d7722022224d0004dddc0000dddc0000000000000000000000000
000f0f00000f0f0000f00000000000f0000000f00000ff00fdd0000000ff00f0000f00f00000cf000022040004f000f000fcccf0000000000000000000000000
029090909090909090909090b0b0b0b0900202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
029090909090909090909090b0e2f2b09002909090909090909090900c0c0c0c0c0c0c0201010101010101023232323232323232323232023232323232323232
32323202023232323232323232323232323232020202b0b0b0b0909090909090909090902c2c2c0290909090909090909090bdcdcddd90909090909090e2f202
029090909090909090909090b0e3f3b0900290909090909090819190909090909090900232323232323232023232323232323232323232023232323232323232
32323202323232323232323232323232323232320202b0c0d0b090909090909090909090902c2c0290909090909090909090bfcfcfdf9090909090e090e3f302
0290f0f09090909090909090f0f0f0f0900290909090909090829290909090909090900232323232323232020202030303030202023232023232323232323232
e2f2320232323232323232323232323232e2f2320202b0c1d1b09090909090909090909090902c02909090909090909090909090909090909090901c1c1c1c02
0290909090909090909090909090909090029090909081919083939090909090b1b1b10232323232323232020132323232320202023232020232323232323232
e3f3320232323232323232323232323232e3f33202021c1c1c1c90909090909090909090909090021c1c1c1c9090909090909090909090909090909090909002
020c304090909090b0b09090909030400c02909090908292901c1ced90909090ed03030203030303023232020202323232323201020132020232323232320203
0303030232c0d032323232323232323232030332020290909090903c4c90903c4c90903c4c909002909090909090909090909090909090909090909090909002
020c314190909090b0b09090909031410c02909090908393909090ee0c0c0c0cee32320232323232020132020202323232323201023232020203030303020232
3232320232c1d132323232323232334332323232020290909090903d4d90903d4d90903d4d9090020c0c90909090909090909090909090909090909090bddd02
029090909090909090909090909090909002908191901c1c909090bfffffcfcfde32320232323232023232020132323232320202023232023232323232020232
32323202424242424242424242424242424242420202903c4c90903e4e90903e4e90903e4e9090025c0c90909090909090901c1c1c1c909090909090bdcede02
0290909090909090909090909090909090029082929090909090909090909090ee32320232323232023232020132323232320202023232023232323232323232
32323202020202020202020202020202020202020202903d4d90901c1c90901c1c90901c1c9090020c0c9090909090909090a09090a0909090909090bfcede02
0290909081919090304090908191909090029083939090909090903040909090ee32320232323232023232020202323232323201023232023232323232323232
32323202323232323232323232323232323232320202903e4e90909090909030409090909090900290909090909081919090a11020a190819190909090bfdf02
029090908292909031419090829290909002901c1c9090909090903141909090ee32320232323232023232020202323232323201023232023232323232323202
03030302323232323232323232323232323232320202901c1c909090909090314190909090909002b0b0b0b0909082929090a11121a190829290909090909002
0290909083939090a090a0908393909090029010209090909090909090909090ee03030232323232023201020232323232320202023201023232020303030302
3232320232323232323232323232323232e2f2320202901020909090909090909090909090909002b0c0d0b0909083939090a19090a190839390909090909002
02b1b1b1b190a09051617190909090a09002901121905161711c5161711c5161ee32320232323232023232020232323232320202023232020303023232323232
3232320232323232323232323232323232e3f3320202901121905161711c5161711c516171a09002b0c1d1b0909090909090a19090a190909090901c1c1c1c02
0232c0d03290a1a2526272b2909090a19002909090a05262721c5262721c5262eee2f20232c0d032023232323232323232320202023232323232323232323232
3232320232c0d0323212223232323232320303320202909090a05262721c5262721c526272a190021c1c1c1c909090909090a1a2b2a190909090909090a09002
0232c1d13290a1a3536373b3506070a1e002e00e1ea15363731c5363731c5363fde3f30232c1d132023232323232323232320202023232323232323232323232
3232020232c1d1323213233232323232323232320202e00e1ea15363731c5363731c536373a190029090909090904242e090a1a3b3a190424242424242a19002
80808080808080808080808080808080808080808080808080808080808080808080800242424242424242424242424242424242424242424242424242424242
42424242424242424242424242424242424242420202808080808080808080808080808080808002424242424242606042424242424242606060606060424202
61117117dddddddddddddddd6699999779999966ffffffff99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1671717144444444dddddddd6999999779999996f444444f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1167777146444464dddddddd9997999779997999f454454f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
6662871144666644dddddddd9999799779999799f444444f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1162277746666664dddddddd9999999779999999f444444f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1666661166666666dddddddd9999999779999999f454454f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
1616166166666666dddddddd9999999779999999f444444f99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
6116111666666666dddddddd9999999779999999ffffffff99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc565656569999999779999999555555555555555555555555550000555500005555555555fffffffffffffffffffffffffffffffff444444f
cccccccccccccccc656565659999999779999999550000555500005555000055550000555500005555000055f4444444444444444444444ff444444ff444444f
cccccccccccccccc565656569999999779999999505005000050050000500505505005055050050550500505f4544444444444444444454ff454454ff444444f
cccccccccccccccc656565657777777777777777500550000005500000055005500550055005500550055005f4444444444444444444444ff444444ff444444f
cccccccccccccccc565656567777777777777777500550000005500000055005500550055005500550055005f4444444444444444444444ff444444ff444444f
cccccccccccccccc656565659999999779999999505005000050050000500505505005055050050550500505f4444444444444444444444ff444444ff454454f
cccccccccccccccc565656569999999779999999550000500500005005000055550000555500005555000055f4544444444444444444454ff444444ff444444f
cccccccccccccccc656565659997999779997999550000055000000550000055550000555555555555000055f4444444444444444444444ff444444fffffffff
4666666666666664cccccccc9999799779999799550000055000000550000055555555555555555555555555f4444444444444444444444ff444444fffffffff
4666666666666664cccccccc9999999779999999550000500500005005000055550000555500005555000055f4544444444444444444454ff444444ff4444444
4666666666667774cccccccc9999999779999999505005000050050000500505005005000050050550500500f4444444444444444444444ff444444ff4544444
46cccccc66c77774cccccccc9999999779999999500550000005500000055005000550000005500550055000f4444444444444444444444ff444444ff4444444
4cccccccccccccc4cccccccc9999999779999999500550000005500000055005000550000005500550055000f4444444444444444444444ff444444ff4444444
4cccccccccccccc4cccccccc9999999779999999505005000050050000500505005005000050050550500500f4444444444444444444444ff444444ff4544444
4cccccccccccccc4cccccccc7777777777777777550000500500005005000055550000555500005555000055f4544444444444444444454ff444444ff4444444
4cccccccccccccc4cccccccc7777777777777777550000055000000550000055555555555555555555555555f4444444444444444444444ff444444fffffffff
cccccccccccccccccccccccccccccccccccccccc550000055000000550000055ccccccccccccccccccccccccf4444444444444444444444fffffffffffffffff
cccccccccccccccccccccccccccccccccccccccc550000500500005005000055ccccccccccccccccccccccccf4544444444444444444454f4444444f44444444
cccccccccccccccccccccccccccccccccccccccc505005000050050000500505ccccccccccccccccccccccccf4444444444444444444444f4444454f44444444
cccccccccccccccccccccccccccccccccccccccc500550000005500000055005ccccccccccccccccccccccccf4444444444444444444444f4444444f44444444
cccccccccccccccccccccccccccccccccccccccc500550000005500000055005ccccccccccccccccccccccccf4444444444444444444444f4444444f44444444
cccccccccccccccccccccccccccccccccccccccc505005000050050000500505ccccccccccccccccccccccccf4544444444444444444454f4444454f44444444
cccccccccccccccccccccccccccccccccccccccc550000555500005555000055ccccccccccccccccccccccccf4444444444444444444444f4444444f44444444
cccccccccccccccccccccccccccccccccccccccc555555555555555555555555ccccccccccccccccccccccccffffffffffffffffffffffffffffffffffffffff
__gff__
0000000000000100010000000000020204000000000202020000000000000000010000000100000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004020100000100000000000000000000000000000001010101010101010101010000000000010101010101010101010100000000000101010000000101010101
__map__
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
2023232323232320232323232323232020232323232323232323232323232320202323232323232323232323232323232323232323232323232323232030303030303030303030202020202323232020232323202020202020232323232323232009090909090909090909090309090304090909090909090909090909090920
20232323232323202e2f2323232122202023232323232323232323232323232020232323232323232323232323232323232323232323232323232323202e2f2323232323232323202323232323232020232323232323232320232323232e2f232009090909090909090909181909091314090918190909090909090e09090920
202323230c0d23203e3f2323233132202020202323232323232323232323232020232323232323232323232323232323232323232323232323232323203e3f2323232020232323202323232323232320232323232323232320232323233e3f232020c1c1c1c1c1c1c1de092829090909090909282909dec1c1c1c1c1c1c12020
202323231c1d232020203030302020202020202030303020203030303030202020232323232030303030303020232323232030303030303020232323202020232323202023232323232323232323232023232323232323232030303020202020202009090909090909ee0e3839090909090909383909ee090909090909092020
203020202020202020202323232020202020232323232320202323232323202020232323232023232323232323232323232323232323232320232323202023232323202023232323232323232323232023302020303030302023232323232323200909030409181909dfc1c1c1c1dbdcdcddc1c1c1c1df091819090304090920
2023201010101020202023232323102020232323232320202020303023232320202323232320232323232323232323232323232323232323202323232020232323232020232323232323232323232323232320202323232320232323232323232009091314092829090909090909eb1819ed0909090909092829091314090920
2023232323232320102323232320202020232323232320202020232323232320202323232320232323303020202030302323232323232323202323232020303030202020303020202030232323232323232320202323232320232323232323232009090909093839090909090909eb2829ed0909090909093839090909090920
202323232323232010232323232020202023232e2f232320202323233030202020232323232023232323232020202323232323232323232320232323202020202020202020202020202020202020202030302020232323232023232323232323200909dbddc1c1c1c1de09090909eb3839ed09090909dec1c1c1c1dbdd090e20
202323232323232020202323232310202020233e3f2320202023232323232020202323232320232323202020202023232323232323232323232e2f2320202020202020202020202020202020202020203030202023232323202323232323232320c1c1ebfd09090909eec1c1c1c1eb1819edc1c1c1c1ee09090909fbedc1c120
2010101010102320202023232323102020202020202020202020303023232320202323232320232323202020202023232323232323232323233e3f23202323232323232323232323232323232323232323232020232323232023232323232323200909df0909090909ee09090909eb2829ed09090909ee0909090909df090920
202020202010232020202323232020202020202020202020202023232323232020232323232023232320202020203030303030303030202024242420202323232323232323232323232323232323232323232323232323232023232323232323200909090909090909ee09090909eb3839ed09090909ee090909090909090920
20202320201023232323232323202020202323232323232323232323303020202023232323232323232323232323232323232323232320200606062020232323232323232323232323232323232323232323232323232323202323232323232320090b0b0b0b090909df1516170afbfcfcfd0a151617df0909090b0b0b0b0920
202323232010232323232323232020202023230c0d232323232323232323202020230c0d23212223232323232323232323232323232323230606062020230c0d23232323232323232323232323232323303030303030303020230c0d2323232320090b0c0d0b090909092526271a090909091a252627090909090b2e2f0b0920
202023202020202020202020202020202023231c1d232323232323232323202020231c1d23313223233334232323232030303030202323230606062020231c1d23232323302020202020202020202020202020202020202020231c1d2323232320090b1c1d0b09090e093536371a090909091a35363709090e090b3e3f0b0920
2020202020202020202020202020202024242424242424242424242424242420202424242424242424242424242424242424242424242424060606202024242424242424242424242424242424242424242424242424242420242424242424242008080808080808080808080808080808080808080808080808080808080820
2020232323232323232323232323202020202020202020202020101010101020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020
2023232323212223232321222323232020202023232323202020232323232320202023232323202020232323232323232320232323202023232323232323232323202023232323232023232323232323232323232323232323232020232323232009090909090909090909090909090909090909090909090909090909090920
20233334233132233334313233342320201023232323232323232323232323232323232323232020202323232323232e2f202323232323232323232323232323232020232323232320232323232323232323232323232323232320202301022320c10b0b0b0bc1c1c1c1c1c1c1c3c4c1c1c1c1c1c1c1c1c1c3c4c1c1c1c1c120
20233030303030303030303030302320201023232323232323232323232323232323232323232020202323232323233e3f203023232323232323232323232323232323232323232320232323232323232330302020232323232320202311122320090b0c0d0b0909090909090ad3d40a090909090909090ad3d40a0909090920
20230c0d23212221222323232e2f2320202020303030302020202323232323232323232e2f232310202323233030202020202323232323232323232323232323232323232323232320232323232323212223232020232323232320232323232320090b1c1d0b0909090909091ae3e41a090909090909091ae3e41a0909090920
20231c1d23313231323334233e3f2320202020232323232020203023232323232323233e3f23231020232323232323232323232323232323232323212223232323232323232323232023232323232331322320202020232323232323232323232009c1c1c1c10909090909dbdcdcdcdcdd0909090909dbdcdcdcdcdd09090920
2024242424242424242424242424242020102323232323232323232323232320202030303030202020303023232323232323232323232020202323313223232323232323232323232020202020202030303020202020232323232323232323232009090909090909090909fbfcfcfcfcfd0909090909fbfcfcfcfcfdc1c1c120
202020202020202020202020202020202010232323232323232323232323232020202323232320202023232323233334232323202020202020202020202020232323232323232323202020202020202323232020202023232320203030302020200909090909c3c4090909090909090909090909090909090909090909090920
202023232323232323202020232323202020203030303020202023232323232323232323232323102020202020202020202020202020202020202020202020303020202020303030202023232323232323232323232323232320202323232020200909090909d3d40909090909090909090909090909090909090b0b0b0b0920
20232323232323232323202023232320202020232323232020202323232323232323232323232310202020202023232323232323232323232323232323232323232020202023232320232323232323232323232e2f2323232323232323232323200909090909e3e4090909090909151617c1c1c1c1c1151617090b2e2f0b0920
2023232323232323232320202323232020232323232323232323232323232320202030303030202020230c0d2323232323232323232323232323232323232323232323232023232320232323232020232323233e3f232323232323232323232320090a090909c1c10909090a09092526270909090909252627090b3e3f0b0920
2023232323232323232320202323232020232323232323232323232323232320202023232323232320231c1d2323232323232323232333342323232323232323232323232023232320232320202020303030202020203030303030202023232320091a09090909090909091a09093536370909090909353637c1c1c1c1c1c120
2023232320203030303020202323232020230c0d232323232323232323232323232323232323232320242424303030202020202020202020202020202020202020202020203030302023232020202023232320202020232323232320202323232009151617c1c1c1c11516170909effffe0909090909effffe09090304090920
200c0d232020232323232323232e2f2020231c1d232323302030232323232320303023232323232320060606232323202020202020202020202020202020202020202020202323232023232323232323232323232323232323232323230c0d2320092526270909090925262709091a091a09090909091a091a090a13140a0920
201c1d232020232323232323233e3f2020202020202020202010101010101020202020202020202020060606232323232323232323232323232323232323232323232323232323232023232323333423232323232323232323232323231c1d2320093536370909090935363709091a091a09090909091a091a091a09091a0920
2424242424242424242424242424242424242424242424242424242424242424242424242424242424060606242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242424242008080808080808080808080808080808080808080808080808080808080820
__sfx__
27050000250412b041330413d04100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c043000000000000000
291000000000000000021400202502110020400212002015021400202502110020400212002015021400201002140020200211502040021200201002140020250211002040021250201002140020100214502013
9110000021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d04021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d040
011000000000000000280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015
0701000028620276201b620275000b5001f5001e50021500254202542028420302203230032200321003d7003f7003f5003f7003f70034700327002e6002b2002820025200212001d2001a2001f7000000000000
9e0200000c2700e2701057011550130501505017740187401a7401c74000000000000000000000000000000000000000000000000000000003220032200322003220032200322003220032200312003120031200
0003000027050300501d7001d7001e7001e7001c7001c70021700207001e7001c7001b7001970018700167001470013700117000f7000d7000c70000000000000000000000000000000000000000000000000000
490f0000363502c35032350283502d34022340283301f330243201e32018320183101831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4903000022670000001e640066000000000000000000000000000000000000000000000001e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09030000116141f6222f7312f7412f5312f5212f5112f5112f5150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c6140c6210c631186311863118621186111861118611186110c6110c6150060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000116141f6222f7312f7412f5312f5212f5112f5112f5150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
27030000390523f042390323902239012390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000116241f652116421754217542116421753217521175150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001811418121182312433124531246212431124311243112461118311183150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c1140c1210c231183311853118621183111831118311186110c3110c3150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010100001065300000000000000010653000000000000000106530000000000000001065300000000000000010653000000000000000106530000000000000001065300000000000000010653000000000000000
000400000000021530155402f54027530205302353029530315303653032530285301b5301c530205302553029530305302e53021530185301c5302053024530325303555038550395503b550000000000000000
180300001f5001c240200502a5002e44031450317300c7000c7000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000
011000000f7501175013750167500c75016750117500f7500f75011750167500f7500f7500c750137500f75011750137500c7500c7500c75016750117500f750137500c7500f7500f7500c750137500f7500f750
011000000503505045050350504505035050450503505045050350704507035070450703507045070350704503035030450303503045030350304503035030450503507045070350704507035070450703507045
11100000187551b7401b7401b7421b7421b7401b7421b7421d7401f7411f7401d7402274022742227401d7421d74018740187401d7411d7401b7401874218740187401b7421f7421f7401d7401d7411d74118745
001000002e1103011033110331103311033112331122e1122e1103311035111351102911029112291122b1122b1102e1112e11030112331112e1102e1113011133110331123511235110331122e1122e1122e110
__music__
01 01464344
00 01024344
00 01024344
00 01024304
00 01024304
00 01424304
00 01424304
00 01420304
00 01420304
00 01020304
00 01020304
00 01020344
00 01020344
00 01420344
02 01420344
01 15554344
00 15144144
00 15145644
00 15164144
00 15164344
00 15161744
00 15171644
00 15171444
00 14151744
00 41151744
02 41141544

