require 'app/Grid_Object.rb'
require 'app/Sprite_Grid_Object.rb'
require 'app/Tile.rb'
require 'app/Actor.rb'


def init args
  args.state.grid = {}
  args.state.pause = false
  args.state.grid[:max_y] = 20
  args.state.grid[:max_x] = 40 

  (0..20).each do |row|
    tile_col = {}
    (0..39).each do |col|
      tile = Tile.new({
        col: col,
        row: row,
        path: "sprites/wall-0000.png",
        w: 32,
        h: 32
      })
      tile.set_to_coord(tile.get_tile_position)

      tile_col[col] = tile
    end
    args.state.grid[row] = tile_col
  end

  args.state.player = Actor.new({
    col: 1,
    row: 1,
    path: "sprites/circle/blue.png",
    w: 32,
    h: 32
  })
  args.state.player.set_to_coord(args.state.player.get_tile_position)    
  args.state.player.find_path_to_target(args.state.grid, {col: 38, row: 20})
end


def tick args
  mouse_output = ""
  init args if(args.state.tick_count == 0)
  point = args.inputs.mouse.point
  point_grid = Grid_Object.with_dimensions_to_tile({w: 32, h: 32}, 
    {x: point[0], y: point[1]}
  )

  # logic/calc
  if(!args.state.pause)
    args.state.player.move(args)
  end

  if(args.inputs.keyboard.key_down.w)
    puts "Pauseing"
    args.state.pause = !args.state.pause 
  end


  args.state.grid.values.map do |columns|
    if(columns.kind_of?(Hash))
      args.outputs.sprites << columns.values.map do |tile|
        tile
      end
    end
  end

  mouse_output += "#{point_grid}"
  args.outputs.labels << [point.x, point.y, mouse_output] 
  args.outputs.sprites << args.state.player
end