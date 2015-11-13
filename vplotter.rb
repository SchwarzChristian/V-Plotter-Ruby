require "ffi"

# main class
# == Example
#
#   plotter = VPlotter.new :default
#   plotter.draw do |d|
#     d.goto 50, 50
#     d.penDown
#     d.move 100, 0
#     d.penUp
#     d.home
#   end
class VPlotter
  # Helper class to encapsulate drawing functionality
  # You should not use this class directly, use VPlotter#draw instead!
  class Commander
    # You should not use this class directly, use VPlotter#draw instead!
    def initialize position, config
      @position = position
      @config   = config
      M_intern.vp_init(config[:pos_left][0],  config[:pos_left][1],
                       config[:pos_right][0], config[:pos_right][1],
                       position[0],           position[1],
                       config[:width],        config[:height])
    end

    # Resets the current position to the calibration points position.
    def calibrate
      M_intern.vp_calibrate
      @position = @config[:pos_cali]
    end

    # Wait for the given time (in seconds, fractions are allowed)
    # [Parameter]
    #   +seconds+:: time to wait
    def wait seconds
      M_intern vp_wait seconds.to_f
    end

    # Set the printing speed.
    # [Parameter]
    #   +speed+:: new printing speed
    def printSpeed speed # [mm/s]
      # TODO
    end

    # Take the pen up to stop drawing.
    def penUp
      M_intern.vp_pen_up
    end

    # Push the pen down to start drawing.
    def penDown
      M_intern.vp_pen_down
    end
    
    # Set the pens servo motor to the given position.
    # [Parameter]
    #   +pos+:: position to set servo motor to
    def setPen pos # [0..100]
      M_intern.vp_set_pen pos.to_i
    end

    # Rotate the left motor.
    # Warning: This command may cause loosing calibration information!
    # [Parameter]
    #   +distance+:: cord length to wind/unwind in mm
    def rotateLeftMotor distance
      M_intern.vp_move_left_motor distance.to_i
    end

    # Rotate the right motor.
    # Warning: This command may cause loosing calibration information!
    # [Parameter]
    #   +distance+:: cord length to wind/unwind in mm
    def rotateRightMotor distance
      M_intern.vp_move_right_motor distance.to_i
    end

    # Moves the print head to the given position.
    # [Parameter]
    #   +x+:: x coordinate
    #   +y+:: y coordinate
    def goto x, y
      M_intern.vp_goto x.to_i, y.to_i
      @position = [x, y]
    end

    # Moves the print head relative to the current position.
    # [Parameter]
    #   +x+:: x coordinate
    #   +y+:: y coordinate
    def move x, y
      M_intern.vp_move x.to_i, y.to_i
      @position = [@position[0] + x, @position[1] + y]
    end

    # Moves the print head back to the calibration point.
    def home
      M_intern.vp_home
      @position = @config[:pos_cali]
    end

    # You should not use this class directly, use VPlotter#draw instead!
    def close
      M_intern.vp_close
      @position
    end
  end

  # Creates a new VPlotter-instance.
  # [Parameter]
  #   +config+:: configuration to use (default: +:default+)
  def initialize config = nil
    use_config config
  end

  # Use a predefined config.
  # [Parameter]
  #   +config+:: config to use
  def use_config config
    unless config.is_a?(Symbol) and use_predefined(config)
      if config.is_a? Hash then
        @config = config
      else
        use_predefined :default
      end
    end
    @position = @config[:pos_cali]
  end

  # Sets a custom configuration to use.
  # [Parameter]
  #   +hash+:: configuration to use as +Hash+
  #
  # == Example
  #
  #   config = {
  #     pos_left:  [  0, 100], # position of the left motor
  #     pos_right: [100, 100], # position of the right motor
  #     pos_cali:  [ 50, 100], # position of the calibration point
  #     width:     100,        # width of the canvas
  #     height:    100,        # height of the canvas
  #   }
  #
  #   # you can pass your configuration directly to the constructor
  #   plotter = VPlotter.new config
  #
  #   # or you use VPlotter#customConfig
  #   plotter = VPlotter.new
  #   plotter.customConfig config
  #
  def customConfig hash
    @config = hash
  end

  # Start drawing.
  #
  # The given block will pe called with a +Commander+-instance as
  # parameter that can be used to draw stuff.
  def draw &block
    cmd = Commander.new @position, @config
    
    block.call cmd
    
    @position = cmd.close
  end

  def position
    @position
  end

  def width
    @config[:width]
  end

  def height
    @config[:height]
  end
  
  private

  module M_intern
    extend FFI::Library
    ffi_lib '/usr/lib/libvplotter.so'
    
    attach_function :vp_init,
    [:int, :int, :int, :int,
     :int, :int, :int, :int], :void
    attach_function :vp_calibrate, [], :void
    attach_function :vp_wait, [:float], :void
    attach_function :vp_pen_up, [], :void
    attach_function :vp_pen_down, [], :void
    attach_function :vp_set_pen, [:int], :void
    attach_function :vp_move_left_motor, [:int], :void
    attach_function :vp_move_right_motor, [:int], :void
    attach_function :vp_goto, [:int, :int], :void
    attach_function :vp_move, [:int, :int], :void
    attach_function :vp_home, [], :void
    attach_function :vp_close, [], :void
  end

  Predefined = {
    default: {
      pos_left:  [  0, 200],
      pos_right: [100, 200],
      pos_cali:  [ 50, 150],
      width:     100,
      height:    200,
    },
    plotbert: {
      pos_left:  [-27, 440],
      pos_right: [543, 440],
      pos_cali:  [230, 350],
      width:     580,
      height:    400,
    },
    
  }

  def finalize
    draw do |d|
      d.home
    end
  end

  def use_predefined config
    @config = Predefined[config]
  end
end
