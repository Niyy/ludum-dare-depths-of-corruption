require 'app/actor.rb'


class Enemy < Actor
    attr_accessor :sight

    def initialize(init_args)
        super(init_args)
        @sight = init_args[:sight] != nil ? init_args[:sight] : 10 
    end


    def check_to_move(args, grid, units,  knights)
        if(@current_path.empty? && @attack_target == nil)
            knights.each do |knight|
                manhattan = find_manhattan(knight)
                if(@sight > manhattan)
                    @attack_target = knight
                    return
                end
            end
        else(@attack_target != nil && args.state.tick_count % 240 == 0)
            if(!@current_path.empty? && 
                @attack_target.get_tile_position != @current_path[0])
                @current_path = []
                find_move_target(grid, units)
                if(@move_target != nil)
                    find_path_to_target(grid, units, @attack_target.get_tile_position)
                end
            end
        end
    end


    def attack_your_target(args, grid, units)
        if(@attack_target != nil)
            if(@current_path.empty? && find_manhattan(@attack_target) > 1)
                find_move_target(grid, units)
                find_path_to_target(grid, units, @attack_target.get_tile_position)
            elsif(find_manhattan(@attack_target) <= 1)
                if(args.state.tick_count % 180)
                    @speed_build_up += 1
                end
                if(@speed_build_up >= @speed)
                    @attack_target.damage(@strength.sample())
                    @speed_build_up = 0
                end
            end
        end
    end
end