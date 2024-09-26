main_cam = {
    pos = vector(0, 0)
}

function draw_sprite(n, x, y, w, h, flip_x, flip_y)
    local sx = x - main_cam.pos.x
    local sy = y - main_cam.pos.y
    spr(n, sx, sy, w, h, flip_x, flip_y)
end

function draw_map(cel_x, cel_y, sx, sy, cel_w, cel_h, layer)
    map(celx, cely, sx - main_cam.pos.x, sy - main_cam.pos.y, cel_w, cel_h, layer)
end

function draw_rect(x0, y0, x1, y1, col)
    rect(x0 - main_cam.pos.x, y0 - main_cam.pos.y, x1 - main_cam.pos.x, y1 - main_cam.pos.y, col)
end