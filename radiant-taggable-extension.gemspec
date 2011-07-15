# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "radiant-taggable-extension"

Gem::Specification.new do |s|
  s.name        = "radiant-taggable-extension"
  s.version     = RadiantTaggableExtension::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = RadiantTaggableExtension::AUTHORS
  s.email       = RadiantTaggableExtension::EMAIL
  s.homepage    = RadiantTaggableExtension::URL
  s.summary     = RadiantTaggableExtension::SUMMARY
  s.description = RadiantTaggableExtension::DESCRIPTION
  s.add_dependency 'sanitize', "~> 2.0.1"

  ignores = if File.exist?('.gitignore')
    File.read('.gitignore').split("\n").inject([]) {|a,p| a + Dir[p] }
  else
    []
  end
  s.files         = Dir['**/*'] - ignores
  s.test_files    = Dir['test/**/*','spec/**/*','features/**/*'] - ignores
  # s.executables   = Dir['bin/*'] - ignores
  s.require_paths = ["lib"]

  s.post_install_message = %{
  Add this to your radiant project with:

    config.gem 'radiant-taggable-extension', :version => '~> #{RadiantTaggableExtension::VERSION}'

  }
end
