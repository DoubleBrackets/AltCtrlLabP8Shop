btn_ids = {
    left = 1,
    right = 2,
    up = 3,
    down = 4,
    primary = 5,
    secondary = 6
}

btn_count = 6

function create_button_states()
    states = {}
    for i = 1, btn_count do
        states[i] = {
            held = false,
            -- pressed or released this frame
            pressed = false,
            released = false
        }
    end
    return states
end

function update_button_states(button_states)
    for i = 1, btn_count do
        button_states[i].pressed = false
        button_states[i].released = false

        if btn(i - 1) then
            if not button_states[i].held then
                button_states[i].pressed = true
            end
            button_states[i].held = true
        else
            if button_states[i].held then
                button_states[i].released = true
            end
            button_states[i].held = false
        end
    end
end