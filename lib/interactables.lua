function create_interactable (x, y, w, h, on_interact, on_while_in_range)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        on_interact = on_interact,
        on_while_in_range = on_while_in_range
    }
end

interactables = {}

function register_interactable (interactable)
    add(interactables, interactable)
end

function update_interactables (player_pos, player_size, interact_btn_pressed)
    for interactable in all(interactables) do
        local in_range = player_pos.x + player_size.x >= interactable.x and
                         player_pos.x <= interactable.x + interactable.w and
                         player_pos.y + player_size.y >= interactable.y and
                         player_pos.y <= interactable.y + interactable.h
        if in_range then
            if interactable.on_while_in_range then
                interactable.on_while_in_range()
            end
            
            if interact_btn_pressed then
                interactable.on_interact()
            end
            
        end
    end
end

function clear_interactables ()
    interactables = {}
end
