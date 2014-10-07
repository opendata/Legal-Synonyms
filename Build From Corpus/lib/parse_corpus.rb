#! /usr/bin/env ruby

def build_word_array(words)
  return words.split(' ')
end

def reject_non_utf8(words)
  return words.unpack("C*").pack("U*")
end

def reject_non_words(words)
  return words.reject{ |e| ! e[/^[a-zA-Z]+/] }.map{ |e| e.gsub(/(\W|\d)/, "") }
end

def reject_short_words(words)
  return words.reject{ |e| e.length < 4 }
end

def reject_stop_words(words, stops)
  return words.reject{ |e| stops.include?(e) }
end

def downcase_words(words)
  return words.each{ |e| e.downcase! }
end

def read_and_clean_file(file, stops)
  words = File.read(file)
  # uncomment the next line if you have invalid character's arguments
  # this is a slow-ish process so it is optional by default
  # words = reject_non_utf8(words)
  words = build_word_array(words)
  words = reject_non_words(words)
  words = reject_short_words(words)
  words = downcase_words(words)
  words = reject_stop_words(words, stops)
  return words
end

def build_word_arcs(words)
  arc       = fragment(words.join(' ')).do(:tokenize, :parse)
  arc_exists = Arc.all( primary_word: arc.words[1].value, primary_pos: arc.words[1].tag, secondary_word_1: arc.words[0].value, secondary_1_pos: arc.words[0].tag, secondary_word_2: arc.words[2].value, secondary_2_pos: arc.words[2].tag )
  if arc_exists && arc_exists.count > 1
    # this if statement should rarely, if ever, be triggered... but just in case.
    total_occurences = arc_exists.reduce(0){|total, arc| total += arc.arc_occurrance }
    to_delete = arc_exists[1..-1].map{|e| e.id }
    to.delete.each{|record| deletor = Arc.get(record); deletor.destroy }
    arc_exists = arc_exists[0]
    arc_exists.arc_occurrance = total_occurences
    arc_exists.save
  elsif ! arc_exists.empty?
    arc_exists = arc_exists[0]
    if arc_exists.arc_occurrance
      arc_exists.arc_occurrance += 1
    else
      arc_exists.arc_occurrance = 1
    end
    arc_exists.save
  else
    arc_new = Arc.create( primary_word: arc.words[1].value, primary_pos: arc.words[1].tag, secondary_word_1: arc.words[0].value, secondary_1_pos: arc.words[0].tag, secondary_word_2: arc.words[2].value, secondary_2_pos: arc.words[2].tag, arc_occurrance: 1 )
    arc_new.save
  end
end

def write_word_count(word_counts, file)
  words       = word_counts.to_a.sort_by{ |e| e[1] }.reverse
  word_counts = []
  words_txt   = words.map{ |e| e.join(', ') }
  write_txt   = File.join(File.dirname(file), 'results', 'counts', "#{File.basename(file)}")
  File.open(write_txt, 'w'){ |f| f.write(words_txt.join("\n")) }
end
