Gem::Specification.new do |s|
  s.name        = 'cvs-wrapper'
  s.version     = '0.7.3'
  s.date        = '2014-09-17'
  s.summary     = 'a cvs command line wrapper'
  s.description = 'A simple wrapper around CVS command line tool'
  s.authors     = ['Fabio Neves']
  s.email       = 'infrastructure@datalex.com'
  s.files       = %w(lib/cvs.rb)
  s.homepage    = 'https://github.com/datalex-opensource/cvs-wrapper'
  s.add_dependency 'childprocess', '0.5.1'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
