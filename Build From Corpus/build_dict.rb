#! /usr/bin/env ruby
require 'json'

# step 0: find defs
# step 1: tokenize into word bags
#   (document -> paragraphs(provisions, subprovisions) -> sentences -> words)
#   drop trash words
#   drop punctuation
#   lowercase
#   spell correct
#   stemming
# step 2: add meta-data to word bags

if ARGV[0] == '--step-one'
  collc = ARGV[1]
  files = Dir.glob("#{collc}/*")
  stops = File.readlines(File.join(File.dirname(__FILE__), 'stop_words.txt')).each{ |e| e.chomp! }
  word_counts = Hash.new(0)

  files.each do |file|
    print "Parsing =>\t#{file}.\t"
    words = File.read(file) #.unpack("C*").pack("U*")
    words = words.split(' ').reject{ |e| e.length < 4 }.reject{ |e| ! e[/^[a-zA-Z]+/] }.map{ |e| e.gsub(/(\W|\d)/, "") }
    words = words.each{ |e| e.downcase! }.reject{ |e| stops.include?(e) }
    words.each {|w| word_counts[w] += 1 }
    words = []
    print "Done.\n"
  end

  words     = word_counts.to_a.sort_by{ |e| e[1] }.reverse
  words_txt = words.map{ |e| e.join(', ') }
  words_jsn = words.reduce([]){ |r,e| r << { text: e[0], weight: e[1] }; r }
  write_txt = File.join(File.dirname(__FILE__), "#{collc}-counts.txt")
  write_jsn = File.join(File.dirname(__FILE__), "#{collc}-counts.js")
  File.open(write_txt, 'w'){ |f| f.write(words_txt.join("\n")) }
  File.open(write_jsn, 'w'){ |f| f.write('var word_array = ' + words_jsn.to_json.to_s) }
end

