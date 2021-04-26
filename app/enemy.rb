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
        else(@attack_target != nil && args.state.tick_count % 120 == 0)
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
end