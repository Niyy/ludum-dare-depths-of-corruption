require 'app/Grid_Object.rb'
require 'app/Sprite_Grid_Object.rb'


class Actor < Sprite_Grid_Object
    attr_accessor :selected, :attack_target, :move_target, :current_path, :open_list,
    :info, :closed, :parents, :working_out_path, :current_search


    def initialize(init_args)
        super(init_args)
        @working_out_path = false 
        @attack_target = nil
        @move_target = nil
        @current_search = nil
        @current_path = [] 
        @open_list = []
        @info = {}
        @closed = {} 
        @parents = {}
        @max_path_interval = 1
    end


    def move(args)
        if(@current_path.empty?)
            return
        end

        if(args.state.tick_count % 30 == 0)
            move_to_next_tile()
        end
    end


    def move_to_next_tile()
        set_to_coord(@current_path.pop())
    end

    
    def move_toward_target()

    end


    def attack_target_on(tile)
    end


    def find_path_to_target(grid, target)
        #puts "Working on finding path"
        unfiltered_path = a_sharp(grid, target)

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
            @move_target = nil
        end
    end


    def a_sharp(grid, target)
        interval = 0 
        start = grid[@row][@col]
        @move_target = target
        open_list.push(start)
        puts start 
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
            left_result = assess_tile(min_object, left, target, open_list, closed, info) if(left != nil)
            right_result = assess_tile(min_object, right, target, open_list, closed, info) if(right != nil)
            down_result = assess_tile(min_object, down, target, open_list, closed, info) if(down != nil)
            up_result = assess_tile(min_object, up, target, open_list, closed, info) if(up != nil)

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


    def assess_tile(min_object, investigate, target, open_list, closed, info)
        #puts "investigate: #{investigate.get_tile_position}"
        if(investigate.get_tile_position == target)
            return target
        end
        if(closed.has_key?(investigate.get_tile_position))
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
end