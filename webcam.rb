require './console_game_engine.rb'
require 'av_capture'
require 'rmagick'
require 'rainbow'

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
  end

  def on_user_update(elapsed_time)
    image = Magick::ImageList.new
    image.from_blob @capture.capture
    image = image.flop
    image = image.scale(@screen_width / image.columns.to_f)
    image = image.scale(image.columns, image.rows / 1.7)
    image = image.quantize(8)
    image.each_pixel do |pixel, col, row|
      pixel_h, pixel_s, pixel_l = pixel.to_HSL.map{|v| (v * 10).to_i }
      r,g,b = hsl_to_rgb(*pixel.to_HSL)
      index = (pixel_l)
      chars = [" ", ".", "'", ":", "=", "u", "o", "x", "k", "0"]
      c = chars[index] || "*"
      colour = get_colour(r,g,b)
      draw(col,row,c,colour)
    end
    status_string = "FPS=%3.2f C=%i" % [1.0/elapsed_time, @colours.size]
    draw_string(0,0,status_string,0)
  end

  def hsl_to_rgb(h, s, v)
    h, s, v = h.to_f/360, s.to_f/100, v.to_f/100
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

  def get_colour(r,g,b)
    number = (r * 255) + (g * 1000) + b
    if @colours[number]
      return number
    else
      colour_values = [r,g,b].map{|h| h / 0.255}.map(&:to_i)
      Curses.init_color(number, *colour_values)
      @colours[number] = colour_values
    end
    return number
  end

end

webcam = WebCam.new(app_name: "WebCam", screen_width: 160, step: 0.05)
webcam.start
