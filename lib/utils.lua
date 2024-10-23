-- vector utils
-- taken fron by https://www.lexaloffle.com/bbs/?tid=50410 by ThaCuber

function vector(x, y) return { x = x or 0, y = y or 0 } end
function v_copy(v) return vector(v.x, v.y) end
function v_tostr(v) return "[" .. v.x .. ", " .. v.y .. "]" end

function v_add(a, b) return vector(a.x + b.x, a.y + b.y) end
function v_sub(a, b) return v_add(a, v_neg(b)) end
function v_scale(v, n) return vector(v.x * n, v.y * n) end
v_mul = v_scale
function v_div(v, n) return v_scale(v, 1 / n) end
function v_neg(v) return v_scale(v, -1) end

function v_dot(a, b) return a.x * b.x + a.y * b.y end
function v_magsq(v) return v_dot(v, v) end
function v_mag(v) return sqrt(v_magsq(v)) end
function v_distsq(a, b) return v_magsq(v_sub(b, a)) end
function v_dist(a, b) return sqrt(v_distsq(a, b)) end
function v_norm(v) return v_div(v, v_mag(v)) end

-- text utils

-- taken from @dredds https://www.lexaloffle.com/bbs/?tid=34512
function print_width(s)
    if #s == 0 then return 0 end

    w = 0
    for i = 1, #s do
        if sub(s, i, i) >= "\x80" then
            w += 7
        else
            w += 3
        end
    end

    return w + #s - 1
end

function print_height(s)
    return 6 * #split(s, "\n") - 1
end

function wrap_text(s, width, separator)
    local line = ""
    local words = split(s, separator)
    local final = ""

    for i = 1, #words do
        local word = words[i]
        local c_line = line .. word

        if print_width(c_line) > width then
            final = final .. line .. "\n"
            line = word .. separator
        else
            line = c_line .. separator
        end
    end

    final = final .. sub(line, 1, #line - 1)

    return final
end

function print_centered(s, x, y, c) print(s, x - print_width(s) / 2, y, c) end

function btn_prompt(btn, text, x, y, c1, c2)
    print(btn, x, y, c1)
    print(text, x + 10, y, c2)
end

function btn_prompt_centered(btn, text, x, y, c1, c2)
    local w = print_width(btn .. text)
    btn_prompt(btn, text, x - w / 2, y, c1, c2)
end

-- camera
function create_camera(x, y) return { pos = vector(x, y) } end

function draw_sprite(cam, n, p, w, h, flip_x, flip_y)
    local tp = v_sub(p, cam.pos)
    spr(n, tp.x, tp.y, w, h, flip_x, flip_y)
end

function draw_map(cam, cel_x, cel_y, p, cel_w, cel_h, layer)
    map(celx, cely, p.x - cam.pos.x, p.y - cam.pos.y, cel_w, cel_h, layer)
end

function draw_rect(cam, p0, p1, col)
    rect(p0.x - cam.pos.x, p0.y - cam.pos.y, p1.x - cam.pos.x, p1.y - cam.pos.y, col)
end

function screen_to_world(cam, pos) return v_add(cam.pos, pos) end

-- animation
function create_anim(frames, frame_duration)
    return {
        frames = frames,
        -- frame duration in game frames
        frame_duration = frame_duration
    }
end

function get_frame(animation, time)
    local frame_index = flr(time / animation.frame_duration) % #animation.frames + 1
    return animation.frames[frame_index]
end

-- debug utils

function debug_draw_mouse(cam)
    local mx = stat(32)
    local my = stat(33)
    local world = screen_to_world(cam, vector(mx, my))
    print("mouse: " .. mx .. ", " .. my, 0, 0, 7)
    print("world: " .. v_tostr(world), 0, 7, 7)
    local tile = v_div(world, 8)
    tile.x = flr(tile.x)
    tile.y = flr(tile.y)
    print("tile: " .. v_tostr(tile), 0, 14, 7)
    rectfill(mx, my, mx, my, 8)
end

function debug_log(message) printh(message, "log.txt", false) end