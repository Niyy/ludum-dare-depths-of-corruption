class Player
    attr_accessor :left_mouse_state


    def initialize(init_args)
        @left_mouse_state = "UP"
    end


    def inputs(args)
        mouse_inputs(args)
    end


    def mouse_inputs(args)
        left_mouse(args)      
    end


    def left_mouse(args)
        if(args.inputs.mouse.button_left)
            left_mouse_select(args)
        elsif(@left_mouse_state == "DOWN")
            left_mouse_accept(args)
        end
    end


    def left_mouse_select(args)
        if(@left_mouse_state == "UP")
            @left_mouse_state = "DOWN"
        end
    end
end