require 'rubygems/dependency_installer'
require 'erb'

require 'emerge-gem/ebuild'

class EmergeGem
  VERSION = "0.5.0"

  def print_usage_and_exit
    puts "#{$0} [options] <gem name> [gem name...] [-- <emerge/paludis options>]"
    puts "    -h --help                       show usage"
    puts "    --no-emerge                     don't actually execute any emerge/paludis commands"
    puts "    --no-paludis                    don't actually execute any paludis/emerge commands"
    puts "    --emerge-bin <emerge|paludis>   use a specific Portage tool instead of emerge"
    puts "    --portage-base-dir <path>       (default /usr/local/portage)"
    puts "    --portage-path <path>           relative to portage base dir (default dev-ruby)"
    puts "    --verbose                       print more details about work being done"
    exit 1
  end

  def initialize( argv )
    @gems = []
    @emerge_options = []
    portage_base_dir = '/shared/portage/overlay'
    @portage_path = 'dev-ruby'
    @emerge_command = 'emerge'

    collecting_emerge_options = false
    while argv.any?
      arg = argv.shift
      case arg
      when '--'
        collecting_emerge_options = true
      when '-h', '--help'
        print_usage_and_exit
      when '--no-emerge', '--no-paludis'
        @no_emerge = true
      when '--portage-base-dir'
        portage_base_dir = argv.shift
      when '--portage-path'
        @portage_path = argv.shift
      when '--emerge-bin'
        @emerge_command = argv.shift
      when '-v', '--verbose'
        @verbose = true
        puts "(verbose mode)"
      when '--version'
        puts "emerge-gem #{VERSION}"
        exit 0
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

    @ebuild_dest ||= "#{portage_base_dir}/#{@portage_path}"

    @eix_installed = system( 'which eix > /dev/null' )
    if @eix_installed
      inform "eix detected"
    end
  end

  def run
    gather_ebuilds
    check_local_gems
    write_ebuilds
    digest_ebuilds
    emerge
  end

  def self.non_portage_gems
    `gem list -l`.scan( /^(\S+) / ).reject { |gem|
      package_installed?( gem )
    }
  end

  def check_local_gems
    return  if ! @eix_installed
    @gems.each do |gem|
      inform "Checking installation of #{gem}"
      gem_versions = EmergeGem.gem_versions_installed( gem )
      next  if gem_versions.empty?
      inform "#{gem} gem installed"

      package_version = EmergeGem.portage_version_installed( gem )
      if package_version
        next  if gem_versions.include?( package_version )

        puts "Portage version of #{gem} is #{package_version} but Rubygems reports version(s):"
        puts gem_versions.join( ', ' )
        puts "Sync Rubygem installation with Portage's version? [y/n]"
        answer = $stdin.gets.strip
        if answer =~ /^y/i
          shell "gem uninstall -a -x -I #{gem}"
          shell "gem install -v #{package_version} #{gem}"
        else
          puts "(retaining differing gem installation of #{gem})"
        end
      else
        puts "#{gem} seems to be installed via gem and not Portage."
        puts "Uninstall the #{gem} gem before emerging?  [y/n]"
        answer = $stdin.gets.strip
        if answer =~ /^y/i
          shell "gem uninstall #{gem}"
        else
          puts "(not uninstalling #{gem} gem)"
        end
      end
    end
  end

  def self.gem_versions_installed( gem_name )
    Gem.source_index.find_name( gem_name ).map { |gem| gem.version.to_s }
  end

  def self.gem_installed?( gem_name )
    gem_versions_installed( gem_name ).any?
  end

  def self.portage_version_installed( gem_name )
	@portage_path ||= 'dev-ruby'
    `eix -Ien* --format '<installedversionsshort>' #{@portage_path}/#{gem_name}`[ /([0-9.]+)/, 1 ]
  end

  def self.package_installed?( package_name )
    !!portage_version_installed( package_name )
  end

  def gather_ebuilds
    @ebuilds = {}
    gems = @gems.dup
    while gems.any?
      next_package = gems.shift

      if ! @ebuilds[ next_package ]
        inform "Gathering info about #{next_package} gem..."
        @ebuilds[ next_package ] = Ebuild.create_from_spec_lookup( next_package )
      end

      @ebuilds[ next_package ].spec.dependencies.each do |dependency|
        next  if @ebuilds[ dependency.name ]
        inform "  Looking up dependency #{dependency.name}"
        gems.push dependency.name
        @gems.push dependency.name
      end
    end
  end

  def write_ebuilds
    @ebuilds.each do |name, ebuild|
      inform "Writing out #{ebuild.filename}"
      ebuild.write @ebuild_dest
    end
  end

  def digest_ebuilds
    @ebuilds.each do |name, ebuild|
      shell "ebuild #{ebuild.local_path} digest"
    end
  end

  def emerge
    ebuild_names = @ebuilds.values.map { |e| "#{@portage_path}/#{e.name}" }.join( ' ' )
    command = "#{@emerge_command} #{@emerge_options.join( ' ' )} #{ebuild_names}"
    if @no_emerge
      puts "(would execute: #{command})"
    else
      shell command
    end
  end

  def shell( command )
    puts "\033[1m#{command}\033[0m"
    system( command ) or
      exit $?
  end

  def inform( message )
    return  if ! @verbose
    puts message
  end
end

