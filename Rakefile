require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "oauth-wrap"
    gem.summary = %Q{Implementaton of OAuth WRAP (draft)}
    gem.description = %Q{Web Resource Authorization Protocol (WRAP) is a profile of OAuth, also called OAuth WRAP.
      While similar in pattern to OAuth 1.0A, the WRAP profile(s) have a number of important
      capabilities that were not available previously in OAuth. For more info see http://wiki.oauth.net/OAuth-WRAP}
    gem.email = "marcel@northdocks.com"
    gem.homepage = "http://github.com/sirlantis/oauth-wrap-ruby"
    gem.authors = ["Marcel Jackwerth"]
    gem.add_dependency "httparty", ">= 0"
    gem.add_development_dependency "mocha", ">= 0"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "webmock", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tt #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
