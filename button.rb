#encoding: UTF-8
require 'rubygems'
require 'serialport'
require 'pi_piper'
require 'httparty'
require 'chunky_png'

# restart me like
# sudo supervisorctl restart all

def port
  @port ||= SerialPort.new '/dev/ttyUSB0', 9600, 8, 1, SerialPort::NONE
end

# PiPiper.watch :pin => 10, :invert => false do |pin|
# #p 'push'
#   port.write("\x1b\x40") # RESET
#   port.write("\x1b\x21\x10\x1b\x21\x20\x1b\x45\x01\x1b\x61\01") # DOUZBLE WIDTH - DOUBLE HEIGHT - BOLD - CENTER
#   port.write(HTTParty.get('http://so-statements.herokuapp.com/').body) # TEXT
#   port.write("\n\n\n\n\n\n\n\n") # LINEFEED
#   port.write("\x1d\x56\x00") # FULLCUT
# end
#
# PiPiper.wait
#
at_exit do
  port.close
end

port.write("\x1b\x40") # RESET
port.write(File.binread('star.raw'))
port.write("YAY")
port.write("\n\n\n\n\n\n\n\n") # LINEFEED
port.write("\x1d\x56\x00") # FULLCUT

# # Image format
# S_RASTER_N      = "\x1d\x76\x30\x00" # Set raster image normal size
# S_RASTER_2W     = "\x1d\x76\x30\x01" # Set raster image double width
# S_RASTER_2H     = "\x1d\x76\x30\x02" # Set raster image double height
# S_RASTER_Q      = "\x1d\x76\x30\x03" # Set raster image quadruple
#
# def decode_hex(buffer)
#   buffer.scan(/../).map(&:hex).map(&:chr).join
# end
#
# def print_image(line, size)
#   # Print formatted image
#   i = 0
#   cont = 0
#   buffer = ""
#
#   port.write(S_RASTER_N)
#   buffer = "%02X%02X%02X%02X" % [((size[0] / size[1]) / 8), 0, size[1], 0]
#   port.write(decode_hex(buffer))
#   buffer = ""
#
#   while i < line.length do
#     hex_string = line[i..i+8].to_i(2)
#     #hex_string = line[i..i+8].to_s(2)
#
#     buffer += "%02X" % hex_string
#     i += 8
#     cont += 1
#     if cont % 4 == 0
#       port.write(decode_hex(buffer))
#       buffer = ""
#       cont = 0
#     end
#   end
# end
#
#
# def check_image_size(size)
#   # Check and fix the size of the image to 32 bits
#   if size % 32 == 0
#     return (0..0)
#   else
#     image_border = 32 - (size % 32)
#     if image_border % 2 == 0
#       return [image_border / 2, image_border / 2]
#     else
#       return [image_border / 2, (image_border / 2) + 1]
#     end
#   end
# end
#
# def convert_image(im)
#   # Parse image and prepare it to a printable format
#   pixels   = []
#   pix_line = ""
#   im_left  = ""
#   im_right = ""
#   switch   = 0
#   img_size = [0, 0]
#
#   if im.width > 512
#     puts "WARNING: Image is wider than 512 and could be truncated at print time"
#   end
#
#   if im.height > 255
#     raise "Image height too big"
#   end
#
#   im_border = check_image_size(im.width)
#
#   (0..im_border[0]).each do
#     im_left += "0"
#   end
#
#   (0..im_border[1]).each do
#     im_right += "0"
#   end
#
#   (0...im.height).each do |y|
#     img_size[1] += 1
#     pix_line += im_left
#     img_size[0] += im_border[0]
#
#     (0...im.width).each do |x|
#       img_size[0] += 1
#       color = im.get_pixel(x, y)
#
#       rgb = [ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color)]
#       im_color = rgb[0] + rgb[1] + rgb[2]
#       im_pattern = "1X0"
#       pattern_len = im_pattern.length
#       switch = (switch - 1 ) * (-1)
#       (0..pattern_len).each do |xx|
#         if im_color <= (255 * 3 / pattern_len * (xx+1))
#           if im_pattern[xx] == "X"
#             pix_line += "%d" % switch
#           else
#             pix_line += im_pattern[xx]
#             break
#           end
#         elsif im_color > (255 * 3 / pattern_len * pattern_len) && im_color <= (255 * 3)
#           pix_line += im_pattern[-1]
#           break
#         end
#       end
#     end
#     pix_line += im_right
#     img_size[0] += im_border[1]
#   end
#
#   print_image(pix_line, img_size)
# end
#
# def image(path)
#   image = ChunkyPNG::Image.from_file(path)
#   convert_image(image)
# end
#
# image(File.expand_path('../logo.png', __FILE__))
