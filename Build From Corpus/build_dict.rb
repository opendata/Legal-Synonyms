#! /usr/bin/env ruby

# StdLib Requires
require 'json'

# Gem Requires
require 'treat'
require 'data_mapper'
require 'dm-migrations'

# File Requires
require File.join(File.dirname(__FILE__), 'lib', 'build_dict.rb')
require File.join(File.dirname(__FILE__), 'lib', 'assemble_files.rb')
require File.join(File.dirname(__FILE__), 'lib', 'data_models.rb')
require File.join(File.dirname(__FILE__), 'lib', 'parse_corpus.rb')
require File.join(File.dirname(__FILE__), 'lib', 'parse_similarities.rb')

# Environment Setup
include Treat::Core::DSL
unless ENV['JAVA_HOME']
  # Treat requires java in order to process the word arcs
  print "Please make sure your JAVA_HOME is set.\n"
  print "On Ubuntu this is usually:\n\n"
  print "export JAVA_HOME=/usr/lib/jvm/java-7-oracle\n\n"
  exit 1
end

if ARGV[0] == '--step-one'
  collc = ARGV[1]
  DataMapper.setup(:default, "postgres://#{ARGV[2]}@localhost/legalsyn")
  DataMapper.finalize
  DataMapper.auto_upgrade!
  perform_step_one(collc)
end

if ARGV[0] == '--step-two'
  collc = ARGV[1]
  DataMapper.setup(:default, "postgres://#{ARGV[2]}@localhost/legalsyn")
  DataMapper.finalize
  DataMapper.auto_upgrade!
  perform_step_two(collc)
end

if ARGV[0] == '--step-three'
  dice        = ARGV[1].to_f
  output_file = ARGV[2]
  DataMapper.setup(:default, "postgres://#{ARGV[3]}@localhost/legalsyn")
  DataMapper.finalize
  DataMapper.auto_upgrade!
  perform_step_three(dice, output_file)
end

if ARGV[0] == '--all-steps'
  collc       = ARGV[1]
  dice        = ARGV[2].to_f
  output_file = ARGV[3]
  DataMapper.setup(:default, "postgres://#{ARGV[4]}@localhost/legalsyn")
  DataMapper.finalize
  DataMapper.auto_upgrade!
  perform_step_one(collc)
  perform_step_two(collc)
  perform_step_three(dice, output_file)
end