require 'app/tile.rb'


def generate(dim, pillar_density = 0, pillar_count = 0)
    door_in = [0, 1, 2, 3].sample()
    door_out = [0, 1, 2, 3].sample()
    center_offset = {x_offset: ((1280 - (dim[:w] * 32)) / 2),
        y_offset: ((720 - (dim[:h] * 32)) / 2) 
    }
    puts center_offset
    grid = {}

    (0..dim[:h]).each do |h|
        grid[h] = {}
        (0..dim[:w]).each do |w|
            tile = Tile.new({
                col: w,
                row: h,
                w: 32,
                h: 32,
                x_offset: center_offset[:x_offset],
                y_offset: center_offset[:y_offset],
                path: "sprites/floor.png"
            })

            if(h == 0 || h == dim[:h] || w == 0 || w == dim[:w])
                tile.path = "sprites/wall.png"
                tile.marked = -1
            end
           
            tile.set_to_coord(tile.get_tile_position)
            grid[h][w] = tile
        end
    end

    case door_in
    when 0
        door_in = grid[0].
            values.
            slice(2...dim[:w] - 1).
            sample()
        door_in.path = "sprites/floor.png"
        door_in.marked = -1
    when 1
        door_in = grid[0].
            values.
            slice(2...dim[:w] - 1)
            .sample()
        door_in.path = "sprites/floor.png"
        door_in.marked = -1
    when 2
        door_in = grid.values.
            slice(2...dim[:h] - 1).
            sample()[0]
        door_in.path = "sprites/floor.png"
        door_in.marked = -1
    when 3
        door_in = grid.values.
            slice(2...dim[:h] - 1).
            sample()[dim[:w]]
        door_in.path = "sprites/floor.png"
        door_in.marked = -1
    end


    (0..pillar_count).each do |index|
        if(pillar_density > 0)
            h_location = grid.values.sample()
            tile = h_location.values.sample()

            if(check_for_door_block(door_in.get_tile_position, tile.get_tile_position))
                tile.marked = -1
                tile.path = "sprites/wall.png"
                pillar_list = []
                pillar_list << tile

                (1...pillar_density).each do |index|
                    current_tile = pillar_list.shift


                    if([0, 1].sample() == 0)
                        mark_children(grid, door_in, dim, current_tile, pillar_list, 0, -1)
                        mark_children(grid, door_in, dim, current_tile, pillar_list, 0, 1)
                    else
                        mark_children(grid, door_in, dim, current_tile, pillar_list, -1, 0)
                        mark_children(grid, door_in, dim, current_tile, pillar_list, 1, 0)
                    end

                    if(pillar_list.empty?)
                        break
                    end
                end
            end
        end
    end

    grid[:max_x] = dim[:h]
    grid[:max_y] = dim[:w]
    grid[:door_in] = door_in
    
    return grid
end


def check_for_door_block(door, tile_being_place)
    manhattan = (tile_being_place[:col] - door[:col]).abs +
        (tile_being_place[:row] - door[:row]).abs

    return manhattan > 3
end


def mark_children(grid, door_in, dim, current_tile, pillar_list, horizontal, vertical)
    tile = current_tile.get_tile_position
    tile = {col: tile[:col] + horizontal, row: tile[:row] + vertical}

    if(tile[:row] >= 0 && tile[:row] <= dim[:h] &&
    tile[:col] >= 0 && tile[:col] <= dim[:w])
        full_tile = grid[tile[:row]][tile[:col]]

        if(check_for_door_block(door_in.get_tile_position, tile))
            full_tile.marked = -1
            full_tile.path = "sprites/wall.png"

            pillar_list << full_tile
        end
    end

    return
end