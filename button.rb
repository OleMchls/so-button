#encoding: UTF-8
require 'rubygems'
require 'serialport'
require 'pi_piper'
require 'chunky_png'
require "net/http"
require "uri"
require "json"
require "asciify"

# restart me like
# sudo supervisorctl restart all

class Printer
  QUOTE_URI = URI.parse('http://printer.socoded.com/')
  SCHEDULE_URI = URI.parse('http://socoded.com/schedule.json')

  LINE_WIDTH = 42
  SCHEDULE_UPDATE_INTERVAL = 60

  PRINT_COUNT_FILE = File.expand_path('../printcount', __FILE__)

  def initialize
    @port = SerialPort.new '/dev/ttyUSB0', 115200, 8, 1, SerialPort::NONE
    @quotes = []

    @schedule_offset = 0
    @schedule = []
    @last_schedule_update = nil

    Thread.abort_on_exception = true
    getter = Thread.new do
      while true
        update_schedule! if schedule_update_due?

        if @quotes.length < 1
          puts "Fetching in new quote..."
          new_quote = Net::HTTP.get_response(QUOTE_URI).body.asciify

          puts "New quote is: #{new_quote}"
          @quotes << new_quote
        end
        sleep 0.5
      end
    end

    PiPiper.watch :pin => 10, :invert => false do |pin|
      on_button_press()
    end

    at_exit do
      puts "Button printer exiting"
      @port.close
      Thread.kill(getter)
    end

    puts "Button printer ready"

    PiPiper.wait
  end

  def schedule_update_due?
    !@last_schedule_update || @last_schedule_update + SCHEDULE_UPDATE_INTERVAL < Time.now.to_i
  end

  def update_schedule!
    puts "Updating schedule..."
    data = JSON.parse(Net::HTTP.get_response(SCHEDULE_URI).body)
    @schedule_offset = data['offset']
    @schedule = data['slots']
    @last_schedule_update = Time.now.to_i
    puts "Schedule updated"
  end

  def on_button_press
    reset
    high_speed
    so_coded_logo

    bold
    center
    text "\n\nComing up next:\n"

    double_width
    double_height
    text next_slot

    normal_text
    text "\n\nAfter that:\n"
    double_width
    double_height
    text next_slot(1)

    unbold
    left
    normal_text
    text ""
    line
    text "Look at this:\n"
    quote
    line

    short_line_feed
    center
    text "Feedback? @socodedconf on Twitter!"
    text ""
    text "<3 Stay So Coded! <3"
    text ""
    text "no. #{print_count}"

    line_feed
    full_cut
  end

  protected
  def quote
    if @quotes.empty?
      text "STOP PUSHING!!!!!!111 Seriously."
      return
    end

    quote_parts = @quotes.shift.split(" ")
    quote_lines = [[]]
    while !quote_parts.empty?
      new_part = quote_parts.shift

      if (quote_lines.last + [new_part]).join(" ").length > LINE_WIDTH
        quote_lines << []
      end

      quote_lines.last << new_part
    end

    message = (quote_lines.map {|a| a.join(' ')}).join("\n")
    puts message
    text message
  end

  def text(string)
    _raw "#{string}\n"
  end

  def reset
    _raw "\x1b\x40"
  end

  def normal_text
    _raw "\x1b\x21\x00"
  end

  def double_width
    _raw "\x1b\x21\x10"
  end

  def double_height
    _raw "\x1b\x21\x20"
  end

  def unbold
    _raw "\x1b\x45\x00"
  end

  def bold
    _raw "\x1b\x45\x01"
  end

  def left
    _raw "\x1b\x61\x00"
  end

  def center
    _raw "\x1b\x61\01"
  end

  def full_cut
    _raw "\x1d\x56\x00"
  end

  def short_line_feed
    _raw "\n\n"
  end

  def line_feed
    _raw "\n\n\n\n\n\n\n\n"
  end

  def high_speed
    _raw "\x1Cs\x02"
  end

  def underline
    _raw "\x1b\x2d\x02"
  end

  def ununderline
    _raw "\x1b\x2d\x00"
  end

  def so_coded_logo
    _raw File.binread(File.expand_path('../star.raw', __FILE__))
  end

  def next_slot(offset = 0)
    time = Time.now.to_i - (@schedule_offset * 60)
    i = 0
    while @schedule[i]['time'] < time
      i += 1
    end

    i += offset

    return "FIN" if i > @schedule.length - 1

    @schedule[i]['speaker']
  end

  def line
    underline
    text " " * LINE_WIDTH
    ununderline
  end

  def print_count
    write_count(0) unless File.exist?(PRINT_COUNT_FILE)
    count = File.read(PRINT_COUNT_FILE).to_i
    write_count(count + 1)
  end

  def write_count(count)
    File.open(PRINT_COUNT_FILE, 'w') {|f| f.print count.to_s}
    count
  end

  def _raw(message)
    @port.write(message)
  end
end

printer = Printer.new
