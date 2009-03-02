require 'bacon'
require 'emerge-gem'

Given /I want to install (\w+)/ do |gem_name|
  @gem = gem_name
end

When /I run emerge-gem (\w+)/ do |gem_name|
  @emerge_gem = EmergeGem.new( ARGV.dup )
  @emerge_gem.run
end

Then /(\w+) should be installed into Portage/ do |package_name|
  EmergeGem.package_installed?( package_name ).should.be.true
end

Then /the (\w+) gem should be installed/ do |gem_name|
  EmergeGem.gem_installed?( gem_name ).should.be.true
end