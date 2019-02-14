require './console_game_engine.rb'
require 'av_capture'
require 'rmagick'
require 'rgb'

class WebCam < ConsoleGameEngine::Engine

  def initialize(opts = {})
    super(opts)
  end

  def on_user_create
    create_console(@screen_width, @screen_width * 0.375)
    input = AVCapture.devices.find(&:video?).as_input
    output  = AVCapture::StillImageOutput.new
    @session = AVCapture::Session.new
    @session.add_input(input)
    @session.add_output(output)
    @capture = AVCapture::Session::Capture.new output, output.video_connection
    @session.start_running!
    @colours = {}
    Curses.init_pair(Curses::COLOR_GREEN,Curses::COLOR_GREEN,Curses::COLOR_BLACK)
  end

  def on_user_update(elapsed_time)
    image = Magick::ImageList.new
    image.from_blob @capture.capture
    image = image.flop
    image = image.scale(@screen_width / image.columns.to_f)
    image = image.scale(image.columns, image.rows / 1.7)
    image = image.quantize(8)
    image.each_pixel do |pixel, col, row|
      pixel_h, pixel_s, pixel_l, pixel_a = pixel.to_hsla
      #color_hex = pixel.to_color(Magick::AllCompliance, false, 8, 8)
      #color = RGB::Color.from_rgb_hex(color_hex)
      #colour = get_colour(color)
      colour = Curses::COLOR_GREEN
      index = (pixel_l / 255.0 * 10).to_i
      chars = [" ", ".", "'", ":", "=", "u", "o", "x", "k", "0"]
      c = chars[index] || "*"
      draw(col,row,c,colour)
    end
    status_string = "FPS=%3.2f C=%s" % [1.0/elapsed_time, @colours.size]
    draw_string(0,0,status_string,0)
  end

  def hsl_to_rgb(h, s, v, a)
    h, s, v = h.to_f/360, s.to_f/255, v.to_f/255
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    [(r*255).to_i, (g*255).to_i, (b*255).to_i]
  end

  def get_colour(color)
    r,g,b = color.to_rgb
    number = 65536 * r + 256 * g + b
    number = (number / 16777215.0 * 100).to_i
    unless @colours[number]
      @colours[number] = true
      colour_values = [r,g,b].map{|h| h / 0.255}.map(&:to_i)
      Curses.init_color(number,*colour_values)
      Curses.init_pair(number,number,0)
    end
    return number
  end

end

webcam = WebCam.new(app_name: "WebCam", screen_width: 160, step: 0.05)
webcam.start
