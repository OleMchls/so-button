#encoding: UTF-8
require 'rubygems'
require 'serialport'
require 'pi_piper'

PiPiper.watch :pin => 17, :invert => true do |pin|
	port = SerialPort.new '/dev/ttyUSB0', 9600, 8, 1, SerialPort::NONE
	port.write("\x1b\x40") # RESET
	port.write("\x1b\x21\x10\x1b\x21\x20\x1b\x45\x01\x1b\x61\01") # DOUZBLE WIDTH - DOUBLE HEIGHT - BOLD - CENTER
	port.write(HTTParty.get('http://so-statements.herokuapp.com/').body) # TEXT
	port.write("\n\n\n\n\n\n\n\n") # LINEFEED
	port.write("\x1d\x561\x0c") # FULLCUT
	port.close
end

PiPiper.wait