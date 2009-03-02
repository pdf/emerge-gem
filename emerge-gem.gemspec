Gem::Specification.new do |s|
    s.name = 'emerge-gem'
    s.version = '0.3.1'
    s.summary = 'Gentoo tool to emerge gems as if there were already downstream ebuilds for them.'
    s.description = 'Gentoo tool to emerge gems as if there were already downstream ebuilds for them.'
    s.homepage = 'http://github.com/Pistos/emerge-gem'
    #s.rubyforge_project = 'ruby-which'

    s.authors = [ 'Pistos' ]
    s.email = 'pistos at purepistos dot net'

    s.files = [
        #'CHANGELOG',
        'README',
        'LICENCE',
        'bin/emerge-gem',
        'lib/emerge-gem.rb',
        'lib/emerge-gem/ebuild.rb',
    ]
    s.executables = [ 'emerge-gem' ]
    s.extra_rdoc_files = [ 'README', 'LICENCE', ]
    #s.test_files = Dir.glob( 'test/*-test.rb' )
    s.has_rdoc = false
end
