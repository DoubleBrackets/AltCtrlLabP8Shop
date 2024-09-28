-- movement

tile_size = 8

function topdown_body(pos_t, size_t)
    return {
        -- pos and size in tiles
        pos = v_mul(pos_t, tile_size),
        size = v_copy(size_t),
        facing = vector(1, 0),
        visual_pos = v_mul(pos_t, tile_size)
    }
end

function simple_move(body, move_vector, coll_flag)
    local new_pos = v_add(body.pos, move_vector)

    if move_vector.x != 0 or move_vector.y != 0 then
        body.facing = move_vector
    else
        return false
    end

    for i = 0, body.size.x - 1 do
        for j = 0, body.size.y - 1 do
            local tile = mget(new_pos.x + i, new_pos.y + j)
            if fget(tile, coll_flag) then
                return false
            end
        end
    end

    body.pos = new_pos
    body.visual_pos = v_mul(new_pos, tile_size)

    return true
end

function set_body_pos(body, new_pos)
    body.pos = new_pos
    body.visual_pos = v_mul(new_pos, tile_size)
end

-- interaction

interactables = {}

function create_interactable(pos_t, size_t, on_interact, on_while_facing)
    return {
        pos = pos_t,
        size = size_t,
        on_interact = on_interact,
        on_while_facing = on_while_facing
    }
end

function register_interactable(interactable)
    add(interactables, interactable)
end

function draw_interact_box()
    rectfill(0, 95, 127, 127, 0)
    rect(0, 95, 127, 127, 7)
end

function update_interactables(body, interact_btn_pressed)
    target_tile = v_add(body.pos, body.facing)

    for interactable in all(interactables) do
        local pos = interactable.pos
        local size = interactable.size
        local in_range = target_tile.x >= pos.x
                and target_tile.x < pos.x + size.x
                and target_tile.y >= pos.y
                and target_tile.y < pos.y + size.y

        if in_range then
            if interactable.on_while_facing then
                draw_interact_box()
                interactable.on_while_facing()
            end

            if interact_btn_pressed then
                interactable.on_interact()
            end
        end
    end
end

function clear_interactables()
    interactables = {}
end

function debug_draw_interactables(cam)
    for i in all(interactables) do
        local visual_pos = v_mul(i.pos, tile_size)
        local visual_size = v_mul(i.size, tile_size)
        draw_rect(cam, visual_pos, v_add(visual_pos, visual_size), 8)
    end
end