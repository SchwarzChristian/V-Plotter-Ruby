require "ffi"

class VPlotter
  class Plotter
    def initialize config
      M_intern.vp_init(config[:pos_left][0],  config[:pos_left][1],
                       config[:pos_right][0], config[:pos_right][1],
                       config[:pos_cali][0],  config[:pos_cali][1],
                       config[:width],        config[:height])
    end

    def calibrate
      M_intern.vp_calibrate
    end

    def wait seconds
      M_intern vp_wait seconds.to_f
    end
    
    def printSpeed speed # [mm/s]
      # TODO
    end

    def penUp
      M_intern.vp_pen_up
    end

    def penDown
      M_intern.vp_pen_down
    end

    def setPen pos # [0..100]
      M_intern.vp_set_pen pos.to_i
    end

    def rotateLeftMotor distance
      M_intern.vp_move_left_motor distance.to_i
    end

    def rotateRightMotor distance
      M_intern.vp_move_right_motor distance.to_i
    end

    def goto x, y
      M_intern.vp_goto x.to_i, y.to_i
    end

    def move x, y
      M_intern.vp_move x.to_i, y.to_i
    end

    def home
      M_intern.vp_home
    end

    def close
      M_intern.vp_close
    end
  end
  
  def initialize config = nil
    return if config.is_a?(Symbol) and use_predefined(config)
    if config.is_a? Hash then
      @config    = config
    end
  end

  def finalize
    draw do |d|
      d.home
    end
  end

  def customConfig hash
    @config = hash
  end

  def draw &block
    plotter = Plotter.new @config
    
    block.call plotter
    
    plotter.close
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
      pos_left:  [-27, 440],
      pos_right: [543, 440],
      pos_cali:  [230, 350],
      width:     580,
      height:    400,
    },
    
  }

  def use_predefined config
    @config = Predefined[config]
  end
end
