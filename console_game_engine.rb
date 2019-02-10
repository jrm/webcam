require "bundler"
require "curses"

Bundler.require(:default)

module ConsoleGameEngine
  module COLOUR
  	FG_BLACK		    = 0x0000
  	FG_DARK_BLUE    = 0x0001
  	FG_DARK_GREEN   = 0x0002
  	FG_DARK_CYAN    = 0x0003
  	FG_DARK_RED     = 0x0004
  	FG_DARK_MAGENTA = 0x0005
  	FG_DARK_YELLOW  = 0x0006
  	FG_GREY			    = 0x0007
  	FG_DARK_GREY    = 0x0008
  	FG_BLUE			    = 0x0009
  	FG_GREEN		    = 0x000A
  	FG_CYAN			    = 0x000B
  	FG_RED			    = 0x000C
  	FG_MAGENTA		  = 0x000D
  	FG_YELLOW		    = 0x000E
  	FG_WHITE		    = 0x000F
  	BG_BLACK		    = 0x0000
  	BG_DARK_BLUE	  = 0x0010
  	BG_DARK_GREEN	  = 0x0020
  	BG_DARK_CYAN	  = 0x0030
  	BG_DARK_RED	 	  = 0x0040
  	BG_DARK_MAGENTA = 0x0050
  	BG_DARK_YELLOW	= 0x0060
  	BG_GREY			    = 0x0070
  	BG_DARK_GREY	  = 0x0080
  	BG_BLUE		    	= 0x0090
  	BG_GREEN		    = 0x00A0
  	BG_CYAN			    = 0x00B0
  	BG_RED			    = 0x00C0
  	BG_MAGENTA		  = 0x00D0
  	BG_YELLOW		    = 0x00E0
  	BG_WHITE		    = 0x00F0
  end

  module PIXEL_TYPE
    PIXEL_SOLID         = 0x00DB
    PIXEL_THREEQUARTERS = 0x00B2
    PIXEL_HALF          = 0x00B1
    PIXEL_QUARTER       = 0x00B0
  end

  class Sprite

    include COLOUR

    attr_accessor :width
    attr_accessor :height

    def self.load(file_name)
      Marshal.load(File.read(file_name))
    end

    def initialize(width, height)
      @width = width
      @height = height
      @glyphs = Array.new(width*height) {" "}
      @colours = Array.new(width*height) { FG_BLACK }
    end

    def set_glyph(x,y,c)
      @glyphs[y * width + x] = c
    end

    def get_glyph(x,y)
      @glyphs[y * width + x] || " "
    end

    def set_colour(x,y,c)
      @colours[y * width + x] = c
    end

    def get_colour(x,y)
      @colours[y * width + x] || FG_BLACK
    end

    def sample_glyph(x,y)
      sx = x * width.to_f
      sx = y * (height - 1).to_f
      return " " if sx <0 || sx >= width || sy < 0 || sy >= height
      @glyphs[sy * width + sx]
    end

    def sample_colour(x,y)
      sx = x * width.to_f
      sx = y * (height - 1).to_f
      return FG_BLACK if sx <0 || sx >= width || sy < 0 || sy >= height
      @colours[sy * width + sx]
    end

    def save(file_name)
      File.open(file_name, "wb") do  |f|
        f << Marshal.dump(self)
      end
    end

  end

  class Engine

    include COLOUR
    include PIXEL_TYPE

    attr_accessor :screen_width
    attr_accessor :screen_height
    attr_accessor :app_name

    def initialize(opts = {})
      @screen_width = opts[:screen_width] || 80
      @screen_height = opts[:screen_height] || 30
      @step = opts[:step] || 0.05
      @app_name = opts[:app_name] || "My Game"
      @active = Concurrent::Atom.new(false)
      @time_point_1 = 0
      @time_point_2 = 0
      @elapsed_time = 0
    end

    def on_user_create()
      return false
    end

    def on_user_update()
      return false
    end

    def create_audio()
      return false
    end

    def draw(x,y,character,colour)
      if (x >= 0 && x < @screen_width && y >= 0 && y < @screen_height)
        @screen_buffer[y * @screen_width + x][:character] = character
        @screen_buffer[y * @screen_width + x][:colour] = colour
      end
    end

    def fill(x1, y1, x2, y2, character = PIXEL_SOLID, colour = FG_BLACK)

    end

    def draw_string(x,y,string = "",colour = FG_WHITE)
      string.chars.each_with_index do |c,i|
        @screen_buffer[y * @screen_width + x + i][:character] = c
        @screen_buffer[y * @screen_width + x + i][:colour] = colour
      end
    end

    def draw_string_alpha(x,y,string = "",colour = FG_WHITE)

    end

    def clip

    end

    def draw_line(x1, y1, x2, y2, c = 0x2588, col = 0x000F)
      dx = x2 - x1
      dy = y2 - y1
      dx1 = dx.abs
      dy1 = dy.abs
      px = 2 * dy1 - dx1
      py = 2 * dx1 - dy1
      if (dy1 <= dx1)
        if (dx >= 0)
          x = x1
          y = y1
          xe = x2
        else
          x = x2
          y = y2
          xe = x1
        end
        draw(x, y, c, col)
        x.upto(xe) do |i|
          x = x + 1
          if px < 0
            px = px + 2 * dy1
          else
            if ((dx<0 && dy<0) || (dx>0 && dy>0))
              y = y + 1
            else
              y = y - 1
            end
            px = px + 2 * (dy1 - dx1)
          end
          draw(x, y, c, col)
        end
      else
        if dy >= 0
          x = x1
          y = y1
          ye = y2
        else
          x = x2
          y = y2
          ye = y1
        end
        draw(x, y, c, col)
        y.upto(ye) do |i|
          y = y + 1
          if (py <= 0)
            py = py + 2 * dx1
          else
            if ((dx<0 && dy<0) || (dx>0 && dy>0))
              x = x + 1
            else
              x = x - 1
            end
            py = py + 2 * (dx1 - dy1)
          end
          draw(x, y, c, col)
        end
      end
    end

    def draw_triangle(x1, y1, x2, y2, x3, y3, c = 0x2588, col = 0x000F)
      draw_line(x1, y1, x2, y2, c, col)
      draw_line(x2, y2, x3, y3, c, col)
      draw_line(x3, y3, x1, y1, c, col)
    end

    def fill_triangle

    end

    def draw_circle(xc, yc, r, c = 0x2588, col = 0x000F)
      x = 0;
      y = r;
      p = 3 - 2 * r;
      while(y >= x) do
        draw(xc - x, yc - y, c, col)
        draw(xc - y, yc - x, c, col)
        draw(xc + y, yc - x, c, col)
        draw(xc + x, yc - y, c, col)
        draw(xc - x, yc + y, c, col)
        draw(xc - y, yc + x, c, col)
        draw(xc + y, yc + x, c, col)
        draw(xc + x, yc + y, c, col)
        if p < 0
          x += 1
          p += 4 * x + 6
        else
          y =- 1
          x += 1
          p += 4 * (x - y) + 10
        end
      end
    end

    def fill_circle(xc, yc, r, c = 0x2588, col = 0x000F)
  		x = 0
  		y = r
  		p = 3 - 2 * r
      line = Proc.new do |sx,ex,ny|
        sx.upto(ex) {|i| draw(i,ny,c,col) }
      end
      while (y >= x) do
  			line.call(xc - x, xc + x, yc - y)
  			line.call(xc - y, xc + y, yc - x)
  			line.call(xc - x, xc + x, yc + y)
  			line.call(xc - y, xc + y, yc + x)
        if p < 0
          x += 1
          p += 4 * x + 6
        else
          y =- 1
          x += 1
          p += 4 * (x - y) + 10
        end
      end
    end

    def draw_sprite

    end

    def draw_partial_sprite

    end

    def draw_wire_frame_model

    end

    def start
      @active = true
      game_thread = Thread.new do
        main_game_hander
      end
      game_thread.join
    end

    def create_console(width, height, font_width = nil, font_height = nil)
      @screen_width = width
      @screen_height = height
      @window = Curses::Window.new(@screen_height, @screen_width, 0, 0)
      @window.keypad = true
      @window.timeout = 5
      @window.nodelay = true
      @screen_buffer = Array.new(@screen_width * @screen_height - 1) { {character: PIXEL_SOLID, colour: FG_BLACK} }
    end

    private

    def main_game_hander
      if !on_user_create
        @active = false
      end
      while @active
        update_clock
        get_keys
        on_user_update(@elapsed_time)
        @window.clear
        @screen_buffer.each do |c|
          @window.addch(c[:character])
          #@window.addch(c[:character].chr)
        end
        @window.refresh
        sleep(@step)
      end
    end

    def update_clock
      if @time_point_1 == 0 && @time_point_2 == 0
        @time_point_1 = Time.now.to_f
        @time_point_2 = Time.now.to_f
      end
      @time_point_2 = Time.now.to_f
      @elapsed_time = @time_point_2 - @time_point_1
      @time_point_1 = @time_point_2
    end

    def get_keys
      @key = @window.getch
    end

  end

end
