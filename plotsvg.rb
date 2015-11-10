#!/usr/bin/env ruby

require "nokogiri"
require "./vplotter"

DEBUG = true

class SvgPath
  class InvalidCommandError < Exception
  end
    
  def initialize string
    @points = []
    @scale = 1.0
    @offset = [0, 0]
    
    mode = nil
    first_point = nil
    last_point = [0, 0]
    
    string.split(" ").each do |part|
      case part
      when "M"  then
        mode = :absolute
        @points.push :up
      when "m"  then
        mode = :relative
        @points.push :up
      when "L"  then
        mode = :absolute
        @points.push :down
      when "l"  then
        mode = :relative
        @points.push :down
      when /z/i then @points.push first_point
      when /^([+-]?\d+(?:\.\d+)?),([+-]?\d+(?:\.\d+)?)$/ then
        x = $1.to_i
        y = $2.to_i

        if mode == :rel then
          x += last_point[0]
          y += last_point[1]
        end

        if @min then
          @min[0] = x if x < @min[0]
          @min[1] = y if y < @min[1]
        else
          @min = [x, y]
        end

        if @max then
          @max[0] = x if x > @max[0]
          @max[1] = y if y > @max[1]
        else
          @max = [x, y]
        end

        last_point = [x, y]
        first_point = last_point unless first_point
        @points.push last_point
      else raise InvalidCommandError, part
      end
    end
    @points.push :up
  end

  def auto_scale plotter, percentage
    size_x = @max[0] - @min[0]
    size_y = @max[1] - @min[1]
    
    @scale = [plotter.width  * percentage / size_x,
              plotter.height * percentage / size_y].min
    puts "scale: #{@scale}" if DEBUG
  end

  def center plotter
    size_x = @max[0] - @min[0]
    size_y = @max[1] - @min[1]
    
    @offset = [(plotter.width  - size_x * @scale) / 2,
               (plotter.height - size_y * @scale) / 2]
    puts "offset: #{@offset.inspect}" if DEBUG
  end

  def draw drawing
    @points.each do |point|
      case point
      when :up then drawing.penUp
      when :down then drawing.penDown
      else
        x = point[0] * @scale + @offset[0]
        y = point[1] * @scale + @offset[1]
        puts "goto: (%d, %d)" % [x, y]
        drawing.goto x, y
      end
    end
  end
end

def usage
  puts "usage: #{$0} <input>"
  puts "  input:  svg-file to parse"
  exit 0
end

usage if ARGV.length < 1

input = ARGV[0]

if input == "-" then
  input = STDIN
else
  input = File.open input, "r"
end


#------------------------------ main ------------------------------


svg = Nokogiri::XML input

plotter = VPlotter.new :default

plotter.draw do |d|
  svg.css("path").each do |path|
    path = SvgPath.new path.attr(:d)
    path.auto_scale plotter, 0.5
    path.center plotter
    path.draw d
  end
end
