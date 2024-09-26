function create_anim (frames, frame_duration)
    return {
        frames = frames,
        -- frame duration in game frames
        frame_duration = frame_duration,
    }
end

function get_frame (animation, time)
    local frame_index = flr(time / animation.frame_duration) % #animation.frames + 1
    return animation.frames[frame_index]
end