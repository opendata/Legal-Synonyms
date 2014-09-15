#! /usr/bin/env ruby

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
    words = File.read(files[0]).split(' ').reject{ |e| ! e[/^[a-zA-Z]+/] }.map{ |e| e.gsub(/(\W|\d)/, "") }
    words = words.each{ |e| e.downcase! }.reject{ |e| stops.include?(e) }
    words.each {|w| word_counts[w.downcase] += 1 }
    words = []
  end

  words = word_counts.to_a.sort_by{ |e| e[1] }.reverse.map{ |e| e.join(', ') }
  writer = File.join(File.dirname(__FILE__), "#{collc}.txt")
  File.open(writer, 'w'){|f| f.write(words.join("\n"))}
end