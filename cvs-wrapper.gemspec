Gem::Specification.new do |s|
  s.name        = 'cvs-wrapper'
  s.version     = '0.7.3'
  s.date        = '2013-06-05'
  s.summary     = 'CVS-Wrapper'
  s.description = 'A simple wrapper around CVS command line tool'
  s.authors     = ['Fabio Neves']
  s.email       = 'fabio.neves@datalex.com'
  s.files       = %w(lib/cvs.rb)
  s.homepage    = 'http://rubygems.org/gems/cvs-wrapper'
  s.add_dependency 'childprocess', '0.5.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
