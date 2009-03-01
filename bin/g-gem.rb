#!/usr/bin/env ruby

require 'rubygems'
require 'rubygems/dependency_installer'

require 'ruby-debug'
require 'erb'

require 'emerge-gem/ebuild'

package = ARGV.first || 'activerecord'

gems_to_lookup = [package]
ebuilds = {}
until gems_to_lookup.empty?
  next_package = gems_to_lookup.shift

  unless ebuilds.has_key?(next_package)
    puts "Gathering info about #{next_package}..."

    ebuilds[next_package] = Ebuild.create_from_spec_lookup(next_package)
  else
    puts "Already know about #{next_package}"
  end

  ebuilds[next_package].spec.dependencies.each do |dependency|
    unless ebuilds.has_key? dependency.name
      puts "Need to lookup dependency #{dependency.name}"
      gems_to_lookup.push(dependency.name)
    end
  end
end

ebuilds.each_pair do |name, ebuild|
  puts "Writing out #{ebuild.filename}"
  ebuild.write
end
