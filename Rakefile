# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "google-safe-browsing-plugin"
  gem.homepage = "http://github.com/lonex/google-safe-browsing-plugin"
  gem.license = "MIT"
  gem.summary = %Q{Rails plugin for Google Safe Browsing}
  gem.description = %Q{A Ruby implementation of the Google Safe Browsing v2. Rails is the dependency mainly because of the data layer.}
  gem.email = "stonelonely@gmail.com"
  gem.authors = ["Lonex"]
  
  gem.add_dependency 'faraday', '~> 0.8.7'
  gem.add_dependency 'activesupport', '>= 2.3.0'
  
  gem.files = Dir.glob('lib/**/*.{rb,rake,yml,data}')
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "google-safe-browsing-plugin #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
