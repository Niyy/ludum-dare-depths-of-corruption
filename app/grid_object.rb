class Grid_Object
    attr_accessor :col, :row, :w_tile, :h_tile, :z

    def initialize(init_args)
        @w_tile = init_args[:w] != nil ? init_args[:w] : 32
        @h_tile = init_args[:h] != nil ? init_args[:h] : 32
        @z = init_args[:z] != nil ? init_args[:z] : 0 
    end


    def set_to_coord(tile)
        position = tile_to_coord(tile)

        @x = position[:x]
        @y = position[:y] 
    end


    def set_to_grid(coord)
        position = to_grid(coord)

        @col = position[:col]
        @row = position[:row]
    end


    def coord_to_grid(coord)
        col_tile = coord[:x] / @w_tile 
        row_tile = coord[:y] / @h_tile 

        return {
            col: col_tile.floor,
            row: row_tile.floor
        }
    end


    def tile_to_coord(tile)
        x_tile = (tile[:col] * @w_tile)
        y_tile = (tile[:row] * @h_tile)

        return {
            x: x_tile,
            y: y_tile,
        }
    end


    def set_coord_to_grid(coord)
        tile = coord_to_grid(coord)
        return tile_to_coord(tile)
    end


    def self.with_dimensions_to_tile(dim, coord)
        col_tile = coord[:x] / dim[:w] 
        row_tile = coord[:y] / dim[:h] 

        return {
            col: col_tile.floor,
            row: row_tile.floor
        }
    end


    def get_tile_position()
        return {col: @col, row: @row}
    end


    def get_coord_position()
        return {x: @x, y: @y}
    end


    def self.with_dimensions_to_coord(dim, tile)
        x_tile = (tile[:col] * dim[:w])
        y_tile = (tile[:row] * dim[:h])

        return {
            x: x_tile,
            y: y_tile,
        }
    end
end