require 'app/Grid_Object.rb'
require 'app/sprite_grid_object.rb'
require 'app/tile.rb'
require 'app/actor.rb'
require 'app/map_generator.rb'
require 'app/player.rb'
require 'app/enemy.rb'


class Game
  attr_gtk
  attr_accessor :scene

  def init args
    @args.state.grid = {}
    @args.state.units = {}
    @args.state.enemies = [] 
    @args.state.knights = [] 
    @args.state.pause = false
    @args.state.enemy_count = 1
    @args.state.grid[:max_y] = 20
    @args.state.grid[:max_x] = 20
    @args.state.offset = {x_offset: ((1280 - (@args.state.grid[:max_x] * 32)) / 2),
        y_offset: ((720 - (@args.state.grid[:max_y] * 32)) / 2)
      }

    @args.state.grid = generate(
      {h: @args.state.grid[:max_x], w: @args.state.grid[:max_y]}, 
      3,
      4
    )
    (0..@args.state.grid[:max_y]).each do |row|
      @args.state.units[row] = {}
      (0..@args.state.grid[:max_x]).each do |col|
        @args.state.units[row][col] = nil
      end
    end

    @args.state.player = Player.new({args: @args})

    spawn_point = identify_knight_spawn_points(@args.state.grid)
    (0...3).each do |index|
      knight = Actor.new({
        col: spawn_point[index][:col],
        row: spawn_point[index][:row],
        path: "sprites/knight.png",
        w: 32,
        h: 32,
        x_offset: @args.state.offset[:x_offset],
        y_offset: @args.state.offset[:y_offset],
        type: "KNIGHT"
      })
      knight.set_to_coord(knight.get_tile_position)    
      @args.state.knights << knight
      @args.state.units[knight.row][knight.col] = knight
    end

    initialize_enemies()
  end


  def identify_legal_spawn_location(grid, units)
    range_y = nil
    spawn_location = nil 

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

      spawn_location = find_unmarked_tile(grid, units, (1...grid[:max_y]).to_a, range_x)
    end
    
    if(spawn_location == nil)
      spawn_location = find_unmarked_tile(grid, units, range_y, (1...grid[:max_x]).to_a)
    end

    return spawn_location
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

      while grid[spawn_location[:row]][spawn_location[:col]].marked == -1
        spawn_location[:col] = range_w.sample
        spawn_location[:row] = range_h.sample
      end

      return spawn_location
  end


  def create_unit_stats(unit, base, actual, sprite, offset)
    return {
      x: unit.x,
      y: unit.y + offset,
      w: 32 * (actual / base),
      h: 4,
      path: sprite 
    }
  end


  def logic(args)
    if(!@args.state.pause)
      marked_for_removal = []
      @args.state.knights.each do |knight|
        if(knight.health <= 0)
          @args.state.enemies.delete(enemy)
        else
          knight.attack_your_target(@args, @args.state.grid, @args.state.units)
          knight.move(@args, @args.state.grid, @args.state.units)
        end
      end
      @args.state.enemies.each do |enemy|
        if(enemy.health <= 0)
          marked_for_removal << enemy
        else
          enemy.check_to_move(@args, @args.state.grid, @args.state.units, @args.state.knights)
          enemy.attack_your_target(@args, @args.state.grid, @args.state.units)
          enemy.move(@args, @args.state.grid, @args.state.units)
        end
      end

      until marked_for_removal.empty? do
        removing = marked_for_removal.pop
        @args.state.units[removing.row][removing.col] = nil
        @args.state.enemies.delete(removing)
      end
    end
  end


  def inputs(args)
    if(@args.inputs.keyboard.key_down.w)
      puts "Pauseing"
      @args.state.pause = !@args.state.pause 
    end
    
    @args.state.player.inputs()
  end


  def renders(args)
    @args.state.grid.values.map do |columns|
      if(columns.kind_of?(Hash))
        @args.outputs.sprites << columns.values.map do |tile|
          unit = @args.state.units[tile.row][tile.col]
          return_array = [tile]
          if(unit != nil)
            units_stats_health = create_unit_stats(unit, unit.base_health, unit.health,
              "sprites/square/green.png", 0)
            units_stats_speed = create_unit_stats(unit, unit.base_speed, unit.speed_build_up,
              "sprites/square/yellow.png", 7)
            return_array << unit << units_stats_health << units_stats_speed
          end

          return_array
        end
      end
    end

    @args.state.player.render_mouse_utils()
  end


  def debug(args)
    point = @args.inputs.mouse.point
    point_grid = Grid_Object.with_dimensions_to_tile({w: 32, h: 32}, 
      {x: point[0], y: point[1]}
    )
    @args.outputs.labels << {x: point.x, y: point.y, text: "#{point_grid}", r: 255, g: 255, b: 255} 
    @args.outputs.labels << {x: @args.grid.left, y: @args.grid.top - 16, text: "#{$gtk.current_framerate}",
      r: 255, g: 255, b: 255
    } 
  end


  def check_level_end(args)
    if(@args.state.enemies.empty?)
      @args.state.enemy_count += 1
      @args.state.grid = {}
      @args.state.enemies = [] 
      @args.state.pause = false
      @args.state.grid[:max_y] = 20
      @args.state.grid[:max_x] = 20

      @args.state.grid = generate(
        {h: @args.state.grid[:max_x], w: @args.state.grid[:max_y]}, 
        3,
        4
      )
      (0..@args.state.grid[:max_y]).each do |row|
        @args.state.units[row] = {}
        (0..@args.state.grid[:max_x]).each do |col|
          @args.state.units[row][col] = nil
        end
      end

      spawn_point = identify_knight_spawn_points(@args.state.grid)
      (0...@args.state.knights.size).each do |index|
        knight = @args.state.knights[index]
        knight.clear()
        knight.col = spawn_point[index][:col]
        knight.row = spawn_point[index][:row]

        knight.set_to_coord(knight.get_tile_position)    
        @args.state.units[knight.row][knight.col] = knight
      end

      initialize_enemies()
    elsif(@args.state.knights.empty?)
      @scene = "LOSE"
    end
  end


  def initialize_enemies()
    (0..@args.state.enemy_count).each do |index|
      enemy_spawn = identify_legal_spawn_location(@args.state.grid, @args.state.units)
      enemy = Enemy.new({
        col: enemy_spawn.col,
        row: enemy_spawn.row,
        path: "sprites/dawl.png",
        w: 32,
        h: 32,
        x_offset: @args.state.offset[:x_offset],
        y_offset: @args.state.offset[:y_offset],
        type: "ENEMY",
        strength: [0, 1, 2]
      })
      enemy.set_to_coord(enemy.get_tile_position)
      @args.state.enemies << enemy  
      @args.state.units[enemy.row][enemy.col] = enemy
    end
  end


  def labels(args)
    args.outputs.labels << {x: args.grid.left, y: args.grid.top - 16, 
      text: "Level: #{args.state.enemy_count}", r: 255, b: 255, g: 255 
    }
  end


  def tick(args)
    @args.outputs.background_color = [0, 0, 0]
    init @args if(@args.state.tick_count == 0)

    if(@scene == "START")
      @args.outputs.labels << {
        x: @args.grid.left, 
        y: @args.grid.top,
        text: "Depths of Corruption",
        size_enum: 32,
        r: 255,
        b: 255,
        g: 255
      }
      @args.outputs.labels << {
        x: @args.grid.left + 4, 
        y: @args.grid.top - 32 * 3,
        text: "Start",
        size_enum: 24,
        r: 255,
        b: 255,
        g: 255
      }
      @args.state.start_button ||= {
        x: @args.grid.left, 
        y: @args.grid.top - (32*5) - 4,
        w: 24 * 7,
        h: 24 * 3,
        r: 255,
        b: 255,
        g: 255
      }

      @args.outputs.borders << @args.state.start_button

      if(@args.inputs.mouse.point.inside_rect? @args.state.start_button)
        @args.state.start_button[:b] = 0
        @args.state.start_button[:g] = 0

        if(@args.inputs.mouse.button_left)
          @scene = "GAME" 
          @args.state.start_button = nil 
        end
      else
        @args.state.start_button[:b] = 255 
        @args.state.start_button[:g] = 255 
      end
    elsif(@scene == "LOSE")
      @args.outputs.labels << {
        x: @args.grid.left, 
        y: @args.grid.top,
        text: "You Have Failed Your Quest",
        size_enum: 32,
        r: 255,
        b: 255,
        g: 255
      }
      @args.outputs.labels << {
        x: @args.grid.left + 4, 
        y: @args.grid.top - 32 * 3,
        text: "Return to the Darkness?",
        size_enum: 24,
        r: 255,
        b: 255,
        g: 255
      }
      @args.state.start_button ||= {
        x: @args.grid.left, 
        y: @args.grid.top - (32*5) - 4,
        w: 24 * 31 - 10,
        h: 24 * 3,
        r: 255,
        b: 255,
        g: 255
      }

      @args.outputs.borders << @args.state.start_button

      if(@args.inputs.mouse.point.inside_rect? @args.state.start_button)
        @args.state.start_button[:b] = 0
        @args.state.start_button[:g] = 0

        if(@args.inputs.mouse.button_left)
          init(@args)
          @scene = "GAME" 
          @args.state.start_button = nil 
        end
      else
        @args.state.start_button[:b] = 255 
        @args.state.start_button[:g] = 255 
      end
    else
      logic(@args)
      inputs(@args) 
      renders(@args)
      labels(@args)
      #debug(@args)

      check_level_end(@args)
    end
  end
end

$game = Game.new()
$game.args = $gtk.args
$game.scene = "START" 

def tick args
  $game.tick(@args)
end