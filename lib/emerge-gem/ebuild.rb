class Ebuild
  attr_accessor :spec, :source, :dependencies, :local_path

  def initialize( spec_pair )
    @spec, @source = spec_pair
    @dependencies = []
  end

  def filename
    "#{p}.ebuild"
  end

  def p
    "#{pn}-#{pv}"
  end

  def pn
    spec.name.downcase
  end
  alias :name :pn

  def pv
    spec.version.version
  end

  def atom_of( dependency )
    "dev-ruby/#{dependency.name}"
  end

  def uri
    "#{source}/gems/#{p}.gem"
  end

  def write( target_dir = 'ebuilds' )
    FileUtils.mkdir_p target_dir
    output = eruby.result( binding )
    @local_path = "#{target_dir}/#{filename}"
    File.open( @local_path, 'w' ) do |f|
      f.write output
    end
  end

  protected

  def eruby
    unless @eruby
      @eruby = ERB.new( %{
# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit gems

DESCRIPTION="<%= spec.summary %>"
HOMEPAGE="<%= spec.homepage %>"
SRC_URI="<%= uri %>"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""
RESTRICT="test"

<% unless spec.dependencies.empty? %>
DEPEND="
  <% spec.dependencies.each do |dependency| %>
    <%= atom_of(dependency) %>
  <% end %>
"
<% end %>
      }.strip )
    end
    @eruby
  end

  def self.create_from_spec_lookup( package )
    @@inst ||= Gem::DependencyInstaller.new
    spec_pair = @@inst.find_spec_by_name_and_version( package ).first
    self.new( spec_pair )
  end
end
