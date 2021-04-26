require 'app/Grid_Object.rb'
require 'app/sprite_grid_object.rb'
require 'app/tile.rb'
require 'app/actor.rb'
require 'app/map_generator.rb'
require 'app/player.rb'
require 'app/enemy.rb'


def init args
  args.state.grid = {}
  args.state.units = {}
  args.state.enemies = [] 
  args.state.knights = [] 
  args.state.pause = false
  args.state.grid[:max_y] = 20
  args.state.grid[:max_x] = 20

  args.state.grid = generate(
    {h: args.state.grid[:max_x], w: args.state.grid[:max_y]}, 
    3,
    4
  )
  (0..args.state.grid[:max_y]).each do |row|
    args.state.units[row] = {}
    (0..args.state.grid[:max_x]).each do |col|
      args.state.units[row][col] = nil
    end
  end

  args.state.player = Player.new({args: args})

  spawn_point = identify_knight_spawn_points(args.state.grid)
  (0...3).each do |index|
    knight = Actor.new({
      col: spawn_point[index][:col],
      row: spawn_point[index][:row],
      path: "sprites/knight.png",
      w: 32,
      h: 32,
      type: "KNIGHT"
    })
    knight.set_to_coord(knight.get_tile_position)    
    args.state.knights << knight
    args.state.units[knight.row][knight.col] = knight
  end


  enemy_spawn = identify_legal_spawn_location(args.state.grid, args.state.units)
  enemy = Enemy.new({
    col: enemy_spawn.col,
    row: enemy_spawn.row,
    path: "sprites/dawl.png",
    w: 32,
    h: 32,
    type: "ENEMY",
    strength: [0, 1, 2]
  })
  enemy.set_to_coord(enemy.get_tile_position)
  args.state.enemies << enemy  
  args.state.units[enemy.row][enemy.col] = enemy
end


def identify_legal_spawn_location(grid, units)
  range_y = nil
  spawn_location = {col: -1, row: -1}
  case grid[:door_in].row
  when 0
    range_y = ((grid[:max_y]/2).floor...grid[:max_y]).to_a
  when grid[:max_y] 
    range_y = (1..(grid[:max_y/2].floor)).to_a
  else
    range_x = nil

    case grid[:door_in].col
    when 0
      range_x = ((grid[:max_x]/2).floor...grid[:max_x]).to_a
    when grid[:max_x]
      range_x = (1..(grid[:max_x]/2).floor).to_a
    end

    return find_unmarked_tile(grid, units, (1...grid[:max_y]).to_a, range_x)
  end

  return find_unmarked_tile(grid, units, range_y, (1...grid[:max_x]).to_a)
end


def identify_knight_spawn_points(grid)

  case grid[:door_in].row
  when 0
    one = {col: grid[:door_in].col, row: grid[:door_in].row + 1}
    two = {col: grid[:door_in].col - 1, row: grid[:door_in].row + 1}
    three = {col: grid[:door_in].col + 1, row: grid[:door_in].row + 1}

    return [one, two, three]
  when grid[:max_y] 
    one = {col: grid[:door_in].col, row: grid[:door_in].row - 1}
    two = {col: grid[:door_in].col - 1, row: grid[:door_in].row - 1}
    three = {col: grid[:door_in].col + 1, row: grid[:door_in].row - 1}

    return [one, two, three]
  else
    case grid[:door_in].col
    when 0
      one = {col: grid[:door_in].col + 1, row: grid[:door_in].row}
      two = {col: grid[:door_in].col + 1, row: grid[:door_in].row - 1}
      three = {col: grid[:door_in].col + 1, row: grid[:door_in].row + 1}

      return [one, two, three]
    when grid[:max_x]
      one = {col: grid[:door_in].col - 1, row: grid[:door_in].row}
      two = {col: grid[:door_in].col - 1, row: grid[:door_in].row - 1}
      three = {col: grid[:door_in].col - 1, row: grid[:door_in].row + 1}

      return [one, two, three]
    end
  end
end


def find_unmarked_tile(grid, units, range_h, range_w)
    spawn_location = {}
    spawn_location[:col] = range_w.sample
    spawn_location[:row] = range_h.sample

    while grid[spawn_location[:row]][spawn_location[:col]].marked && 
    units[spawn_location[:row]] != nil && units[spawn_location[:row]][spawn_location[:col]] != nil
      spawn_location[:col] = range_w.sample
      spawn_location[:row] = range_h.sample
    end

    return spawn_location
end

def logic(args)
  if(!args.state.pause)
    args.state.knights.each do |knight|
      knight.move(args, args.state.grid, args.state.units)
    end
    args.state.enemies.each do |enemy|
      enemy.check_to_move(args, args.state.grid, args.state.units, args.state.knights)
      enemy.attack_your_target(args, args.state.grid, args.state.units)
      enemy.move(args, args.state.grid, args.state.units)
    end
  end
end


def inputs(args)
  if(args.inputs.keyboard.key_down.w)
    puts "Pauseing"
    args.state.pause = !args.state.pause 
  end
  
  args.state.player.inputs()
end


def renders(args)
  args.state.grid.values.map do |columns|
    if(columns.kind_of?(Hash))
      args.outputs.sprites << columns.values.map do |tile|
        [tile, args.state.units[tile.row][tile.col]]
      end
    end
  end
end


def debug(args)
  point = args.inputs.mouse.point
  point_grid = Grid_Object.with_dimensions_to_tile({w: 32, h: 32}, 
    {x: point[0], y: point[1]}
  )
  args.outputs.labels << {x: point.x, y: point.y, text: "#{point_grid}"} 
  args.outputs.labels << {x: args.grid.left, y: args.grid.top - 16, text: "#{$gtk.current_framerate}"} 
end


def tick args
  init args if(args.state.tick_count == 0)

  logic(args)
  inputs(args) 
  renders(args)
  debug(args)
end