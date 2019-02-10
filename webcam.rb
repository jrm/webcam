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
  end

  def on_user_update(elapsed_time)
    image = Magick::ImageList.new
    image.from_blob @capture.capture
    image = image.flop
    image = image.scale(@screen_width / image.columns.to_f)
    image = image.scale(image.columns, image.rows / 1.7)
    image = image.quantize(8)
    image.each_pixel do |pixel, col, row|
      #c = classify_pixel(pixel.to_HSL[0])
      pixel_a = (pixel.to_HSL[0] * 10).to_int
      pixel_b = (pixel.to_HSL[1] * 10).to_int
      pixel_c = (pixel.to_HSL[2] * 10).to_int
      c = ["0", "k", "x", "o", "u", "=", ":", "'", ".", " "][pixel_a & pixel_c] || "#{pixel_a}"
      draw(col,row,c,'')
    end
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

  def classify_pixel(luminance)
    pixel_bw = (luminance * 13).to_int
    case pixel_bw
    when 0
      bg_col = BG_BLACK
      fg_col = FG_BLACK
      sym = PIXEL_SOLID
    when 1
      bg_col = BG_BLACK
      fg_col = FG_DARK_GREY
      sym = PIXEL_QUARTER
    when 2
      bg_col = BG_BLACK
      fg_col = FG_DARK_GREY
      sym = PIXEL_HALF
    when 3
      bg_col = BG_BLACK
      fg_col = FG_DARK_GREY
      sym = PIXEL_THREEQUARTERS
    when 4
      bg_col = BG_DARK_GREY
      fg_col = FG_DARK_GREY
      sym = PIXEL_SOLID
    when 5
      bg_col = BG_DARK_GREY
      fg_col = FG_GREY
      sym = PIXEL_QUARTER
    when 6
      bg_col = BG_DARK_GREY
      fg_col = FG_GREY
      sym = PIXEL_HALF
    when 7
      bg_col = BG_DARK_GREY
      fg_col = FG_GREY
      sym = PIXEL_THREEQUARTERS
    when 8
      bg_col = BG_DARK_GREY
      fg_col = FG_GREY
      sym = PIXEL_SOLID
    when 9
      bg_col = BG_GREY
      fg_col = FG_WHITE
      sym = PIXEL_QUARTER
    when 10
      bg_col = BG_GREY
      fg_col = FG_WHITE
      sym = PIXEL_HALF
    when 11
      bg_col = BG_GREY
      fg_col = FG_WHITE
      sym = PIXEL_THREEQUARTERS
    when 12
      bg_col = BG_GREY
      fg_col = FG_WHITE
      sym = PIXEL_SOLID
    end
    #return  [bg_col, fg_col, sym]
    return sym
  end

end

webcam = WebCam.new(app_name: "James", screen_width: 160)
webcam.start
