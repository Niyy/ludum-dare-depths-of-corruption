require 'app/Grid_Object.rb'
require 'app/Sprite_Grid_Object.rb'


class Actor < Sprite_Grid_Object
    attr_accessor :selected, :attack_target, :move_target, :current_path, :open_list,
    :info, :closed, :parents, :working_out_path, :current_search, :health, :speed,
    :strength, :speed_build_up, :type, :base_health, :base_speed, :base_strength,
    :start_animation, :animation_increment


    def initialize(init_args)
        super(init_args)
        @working_out_path = false 
        @attack_target = nil
        @move_target = nil
        @current_search = nil
        @start_animation = nil
        @current_path = [] 
        @open_list = []
        @info = {}
        @closed = {} 
        @parents = {}
        @max_path_interval = 1
        @type = init_args[:type]
        @health = @base_health = init_args[:health] != nil ? init_args[:health] : 100
        @speed = @base_speed = init_args[:speed] != nil ? init_args[:speed] : 20
        @strength = @base_strength = init_args[:strength] != nil ? init_args[:strength] : 
            (5..20).to_a
        @speed_build_up = 0 
    end


    def clear()
        @working_out_path = false 
        @attack_target = nil
        @move_target = nil
        @current_search = nil
        @start_animation = nil
        @current_path = [] 
        @open_list = []
        @info = {}
        @closed = {} 
        @parents = {}
        @max_path_interval = 1
        @speed_build_up = 0
        @attack_target = nil
    end


    def move(args, grid, units)
        if(@current_path.empty?)
            return
        end

        if(@attack_target != nil)
            if(find_manhattan(@attack_target) <= 1)
                @current_path = []
            end
            if(@current_path[0] != @move_target)
                find_move_target(grid, units)
                find_path_to_target(grid, units, @move_target)
            end 
        end
        if(args.state.tick_count % 20 == 0)
            move_to_next_tile(grid, units)
        end
    end


    def move_to_next_tile(grid, units)
        next_position = @current_path.pop()
        if(units[next_position[:row]][next_position[:col]] == nil)
            knight = units[@row][@col]
            units[@row][@col] = nil 
            set_everything_from_tile(next_position)
            units[next_position[:row]][next_position[:col]] = knight
        elsif(!@current_path.empty?)
            path_end = @current_path[0]
            find_path_to_target(grid, units, path_end)
        end
    end

    
    def move_toward_target()

    end


    def damage(damage)
        puts "ARgh. That hurt. #{@type}"
        @health -= damage

        if(@health <= 0)
            return true
        end
    end


    def attack_target_on(tile)
    end


    def find_path_to_target(grid, units, target)
        @current_path = [] 
        @open_list = []
        @info = {}
        @closed = {} 
        @parents = {}

        unfiltered_path = a_sharp(grid, units, target)

        if(unfiltered_path != nil)
            scout = @move_target
            @current_path = []

            while scout != nil do
                @current_path << scout
                if(unfiltered_path[scout] == get_tile_position)
                    break
                end
                scout = unfiltered_path[scout]
            end

            @open_list = []
            @info = {}
            @closed = {} 
            @parents = {}
        end
    end


    def a_sharp(grid, units, target)

        interval = 0 
        start = grid[@row][@col]
        @move_target = target
        open_list.push(start)
        info[start.get_tile_position] = { 
            cost: 0,
            heur: (start.col - target.col).abs + (start.row - target.row).abs,
            final: 1000 
        }
        parents[start.get_tile_position] = nil

        until (open_list.empty?) do
            min = 100000
            min_index = -1 

            # Find next item to investigate
            (0...open_list.size).each do |index|
                if(info[open_list[index].get_tile_position][:final] < min)
                    min = info[open_list[index].get_tile_position][:final]
                    min_index = index
                end
            end

            @current_search = min_object = open_list.delete_at(min_index)
            #puts "-------current parent: #{min_object.get_tile_position}---------"
            #puts "info"
            #info.each do |key, value|
            #    puts "#{key} = #{value}"
            #end
            #puts "parents"
            #parents.each do |key, value|
            #    puts "#{key} = #{value}"
            #end
            # Discover neighbors
            left = grid[min_object.row][min_object.col - 1] if(min_object.col - 1 >= 0)
            right = grid[min_object.row][min_object.col + 1] if(min_object.col + 1 <= grid[:max_x])
            down = grid[min_object.row - 1][min_object.col] if(min_object.row - 1 >= 0)
            up = grid[min_object.row + 1][min_object.col] if(min_object.row + 1 <= grid[:max_y])

            # Assign parental duties
            if(left != nil && !closed.has_key?(left.get_tile_position))
                parents[left.get_tile_position] = min_object.get_tile_position 
            end
            if(right != nil && !closed.has_key?(right.get_tile_position))
                parents[right.get_tile_position] = min_object.get_tile_position
            end
            if(down != nil && !closed.has_key?(down.get_tile_position))
                parents[down.get_tile_position] = min_object.get_tile_position
            end
            if(up != nil && !closed.has_key?(up.get_tile_position))
                parents[up.get_tile_position] = min_object.get_tile_position
            end

            # Assess those values baby!
            left_result = assess_tile(units, min_object, left, target, 
                open_list, closed, info) if(left != nil)
            right_result = assess_tile(units, min_object, right, target, 
                open_list, closed, info) if(right != nil)
            down_result = assess_tile(units, min_object, down, target, 
                open_list, closed, info) if(down != nil)
            up_result = assess_tile(units, min_object, up, target, 
                open_list, closed, info) if(up != nil)

            #puts "closed:\n #{closed}"
            #puts "open:\n "
            #open_list.each do |i|
            #    puts "#{i.get_tile_position}"
            #end

            if(left_result == target || right_result == target || down_result == target ||
            up_result == target)
                return parents
            end

            closed[min_object.get_tile_position] = true
        end

        return nil
    end


    def assess_tile(units, min_object, investigate, target, open_list, closed, info)
        #puts "investigate: #{investigate.get_tile_position}"
        investigate_info = investigate.get_tile_position
        if(investigate.get_tile_position == target)
            return target
        end
        if(closed.has_key?(investigate.get_tile_position) ||
        investigate.marked == -1 || 
        units[investigate_info[:row]][investigate_info[:col]] != nil)
            return nil
        end

        cost = investigate.cost + info[min_object.get_tile_position][:cost]
        heur = (investigate.col - target.col).abs + (investigate.row - target.row).abs
        final = cost + heur

        if(!info.has_key?(investigate.get_tile_position)) 
            info[investigate.get_tile_position] = {
                cost: cost,
                heur: heur,
                final: final
            }
        end

        current_info = info[investigate.get_tile_position]
        current_info[:cost] = cost if(current_info[:cost] > cost)
        current_info[:heur] = heur if(current_info[:heur] > heur)
        current_info[:final] = final if(current_info[:final] > final)

        if(!open_list.include?(investigate))
            open_list.push(investigate)
        end

        return nil
    end


    def pick_up_from(pick_up_symbol, tile)
    end


    def interact_with(interactable_symbol, tile)

    end


    def use_item(item_from_pack)

    end


    def find_manhattan(target)
        manhattan = (@col - target.col).abs +
            (@row - target.row).abs
    end


    def find_move_target(grid, units)
        manhattan = []
        left = right = up = down = -1 
        if(@attack_target.col - 1 >= 0)
            left = grid[@attack_target.row][@attack_target.col - 1]
            manhattan << left if(left.marked != -1)
        end
        if(@attack_target.col + 1 <= grid[:max_x])
            right = grid[@attack_target.row][@attack_target.col + 1]
            manhattan << right if(right.marked != -1)
        end
        if(@attack_target.row + 1 <= grid[:max_y])
            up = grid[@attack_target.row + 1][@attack_target.col]
            manhattan << up if(up.marked != -1)
        end
        if(@attack_target.row - 1 >= 0)
            down = grid[@attack_target.row - 1][@attack_target.col] 
            manhattan << down if(down.marked != -1)
        end

        manhattan.sort do |a, b|
            a_man = find_manhattan(a)
            b_man = find_manhattan(b)

            if((a_man <=> b_man) == 1)
                return a
            end

            return b
        end

        manhattan.each do |tile|
            if(units[tile.get_tile_position] == nil)
                @move_target = tile
            end
        end
    end


    def attack_your_target(args, grid, units)
        if(@attack_target != nil)
            if(@current_path.empty? && find_manhattan(@attack_target) > 1)
                find_move_target(grid, units)
                find_path_to_target(grid, units, @attack_target.get_tile_position)
            elsif(find_manhattan(@attack_target) <= 1)
                @current_path = []

                if(@attack_target.health <= 0)
                    @attack_target = nil 
                end
                if(@speed_build_up >= @speed)
                    if(@attack_target == nil || @attack_target.damage(@strength.sample()))
                        @attack_target = nil
                    end

                    @speed_build_up = 0
                end
            end
        end

        if(@speed_build_up <= @speed && args.state.tick_count % 10 == 0)
            @speed_build_up += 1
        end
    end


    # 1. Create a serialize method that returns a hash with all of
    #    the values you care about.
    def serialize()
        { x: @x, y: @y, w: @w, h: @h, path: @path, x_offset: @x_offset,
        y_offset: @y_offset, w_offset: @w_offset, h_offset: @h_offset,
        source_x: @source_x, source_y: @source_y, source_w: @source_w,
        source_h: @source_h, col: @col, row: @row, current_path: @current_path,
        attack_target: @attack_target, health: @health, speed: @speed,
        strength: @strength }
    end
end