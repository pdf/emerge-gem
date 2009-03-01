class Ebuild
  attr_accessor :spec, :source, :dependencies

  def initialize(spec_pair)
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

  def pv
    spec.version.version
  end

  def atom_of(dependency)
    "dev-ruby/#{dependency.name}"
  end

  def uri
    "#{source}/gems/#{p}.gem"
  end

  def write
    output = eruby.result( binding )
    FileUtils.mkdir_p('ebuilds')
    File.open("ebuilds/#{filename}", 'w') {|f| f.write(output) }
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

  def self.create_from_spec_lookup(package)
    @@inst ||= Gem::DependencyInstaller.new
    spec_pair = @@inst.find_spec_by_name_and_version(package).first
    self.new(spec_pair)
  end
end
