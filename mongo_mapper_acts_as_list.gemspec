# encoding: UTF-8
require File.expand_path('../lib/mongo_mapper/plugins/version', __FILE__)



Gem::Specification.new do |s|
  
  s.name = 'mongo_mapper_acts_as_list'
  s.version = MongoMapper::Plugins::ActsAsList::Version  
  s.author = 'Tomas Celizna'
  s.email = 'tomas.celizna@gmail.com'    
  s.homepage = 'http://github.com/tomasc/mongo_mapper_acts_as_list'
  s.summary = "Port of classic Rails ActsAsList for MongoMapper."
  s.description = "This is a port of classic Rails' acts_as_list to Mongo Mapper. This Mongo Mapper plugin provides the capabilities for sorting and reordering a number of objects in a list. If you do not specify custom position column in the options, a key named position will be added and used by default."

  s.files = Dir["{lib,spec}/**/*", "[A-Z]*", "init.rb"] - ["Gemfile.lock"]  
  s.require_path = 'lib'

  s.add_dependency 'mongo_mapper'
  s.add_development_dependency 'rake'
  
end