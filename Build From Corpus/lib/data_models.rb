#! /usr/bin/env ruby

class Arc
  include DataMapper::Resource

  property :id,                 Serial
  property :primary_word,       String
  property :primary_pos,        String
  property :secondary_word_1,   String
  property :secondary_1_pos,    String
  property :secondary_word_2,   String
  property :secondary_2_pos,    String
  property :arc_occurrance,     Integer
end

class Sim
  include DataMapper::Resource

  property :id,                 Serial
  property :word1,              String
  property :word2,              String
  property :dice,               Float
end

class ParsedFiles
  include DataMapper::Resource

  property :id,                 Serial
  property :files_parsed,       String
end
