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

-- simple move with x axis tile collision
function simple_move(pos, size, move_vector, coll_flag)
    local new_pos = v_add(pos, move_vector)
    local new_tile = nil
    if move_vector.x < 0 then
        new_tile = mget(new_pos.x / 8, new_pos.y / 8)
    elseif move_vector.x > 0 then
        new_tile = mget((new_pos.x + size.x) / 8, new_pos.y / 8)
    end
    
    if fget(new_tile, coll_flag) then
        if move_vector.x > 0 then
            new_pos.x = flr((new_pos.x + size.x) / 8) * 8 - size.x
        elseif move_vector.x < 0 then
            new_pos.x = flr(new_pos.x / 8) * 8 + 8
        end
    end
    return new_pos
end