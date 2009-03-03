#!/usr/bin/env ruby

$LOAD_PATH.unshift './lib'
require 'emerge-gem'

def shell( command )
  puts command
  system( command ) or
    puts "Command error: #{$?}" and exit 1
end

prefix = '/usr'
lib_dir = $LOAD_PATH.grep( /site_ruby/ ).first
bin_dir = nil
doc_dir = nil
verbose = false

argv = ARGV.dup
while argv.any?
  arg = argv.shift
  case arg
    when '--prefix'
      prefix = argv.shift
    when '--bindir'
      bin_dir = argv.shift
    when '--docdir'
      doc_dir = argv.shift
    when '--libdir'
      lib_dir = argv.shift
    when '--verbose'
      verbose = true
  end
end

bin_dir ||= "#{prefix}/bin"
doc_dir ||= "#{prefix}/share/doc"

# ------------

versioned_package = "emerge-gem-#{EmergeGem::VERSION}"
dir = "#{doc_dir}/#{versioned_package}"
shell "mkdir -p #{dir}"
shell "cp README LICENCE #{dir}"

dir = "#{lib_dir}/emerge-gem"
shell "mkdir -p #{dir}"
shell "cp -r lib/* #{dir}/"

shell "install bin/emerge-gem #{bin_dir}"
