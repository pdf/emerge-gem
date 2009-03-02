require 'rubygems/dependency_installer'
require 'erb'

require 'emerge-gem/ebuild'

class EmergeGem
  def print_usage_and_exit
    puts "#{$0} [options] <gem name> [gem name...] [-- <emerge options>]"
    puts "    -h --help              show usage"
    puts "    --portage-base-dir     (default /usr/local/portage)"
    puts "    --portage-path         relative to portage base dir (default dev-ruby)"
    exit 1
  end

  def initialize( argv )
    @gems = []
    @emerge_options = []
    portage_base_dir = '/usr/local/portage'
    portage_path = 'dev-ruby'

    collecting_emerge_options = false
    while argv.any?
      arg = argv.shift
      case arg
      when '--'
        collecting_emerge_options = true
      when '-h', '--help'
        print_usage_and_exit
      when '--portage-base-dir'
        portage_base_dir = arg
      when '--portage-path'
        portage_path = arg
      else
        if collecting_emerge_options
          @emerge_options << arg
        else
          @gems << arg
        end
      end
    end

    if @gems.empty?
      print_usage_and_exit
    end

    @ebuild_dest ||= "#{portage_base_dir}/#{portage_path}"
  end

  def run
    gather_ebuilds
    write_ebuilds
    digest_ebuilds
    emerge
  end

  def gather_ebuilds
    @ebuilds = {}
    while @gems.any?
      next_package = @gems.shift

      if ! @ebuilds[ next_package ]
        puts "Gathering info about #{next_package}..."
        @ebuilds[ next_package ] = Ebuild.create_from_spec_lookup( next_package )
      else
        puts "(already know about #{next_package})"
      end

      @ebuilds[ next_package ].spec.dependencies.each do |dependency|
        next  if @ebuilds[ dependency.name ]
        puts "Need to lookup dependency #{dependency.name}"
        @gems.push dependency.name
      end
    end
  end

  def write_ebuilds
    @ebuilds.each do |name, ebuild|
      puts "Writing out #{ebuild.filename}"
      ebuild.write
    end
  end

  def digest_ebuilds
    @ebuilds.each do |name, ebuild|
      shell "ebuild #{ebuild.local_path} digest"
    end
  end

  def emerge
    ebuild_names = @ebuilds.map { |e| e.name }.join( ' ' )
    shell "emerge #{@emerge_options} #{ebuild_names}"
  end

  def shell( command )
    puts command
    system( command ) or
      exit $?
  end
end

