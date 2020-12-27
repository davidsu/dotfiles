#!/usr/bin/env ruby
#
# usage: ./preview.rb [-v] FILENAME[:LINE][:IGNORED]

require 'shellwords'

COMMAND = %[(rougify highlight --theme base16.monokai {} || cat {}) 2> /dev/null]
ANSI    = /\x1b\[[0-9;]*m/
REVERSE = "\x1b[7m"
RESET   = "\x1b[m"

split = ARGV.delete('-v')

def usage
  puts "usage: #$0 [-v] FILENAME[:LINENO][:IGNORED]"
  exit 1
end

usage if ARGV.empty?

file, center = ARGV.first.split(':')
usage unless file

path = File.expand_path(file)
unless File.readable? path
  puts "File not found: #{file}"
  puts "File not found: #{path}"
  exit 1
end

if `file --mime "#{file}"` =~ /binary/
  puts "#{file} is a binary file"
  exit 0
end
# puts "#{center}"
center = (center || 0).to_i

IO.popen(['sh', '-c', COMMAND.gsub('{}', Shellwords.shellescape(path))]) do |io|
  io.each_line.each_with_index do |line, lno|
	if lno == center -1
	  puts REVERSE + line.chomp.gsub(ANSI) { |m| m + REVERSE } + RESET
	else
	  puts line
	end
  end
end
