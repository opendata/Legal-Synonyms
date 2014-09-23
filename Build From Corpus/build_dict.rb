#! /usr/bin/env ruby
require 'json'

def build_file_list(directory)
  files = Dir.glob("#{directory}/*")
  if files.include?("#{directory}/results")
    files.delete("#{directory}/results")
    results_dir = Dir.glob("#{directory}/results/*")
    if results_dir.include?("#{directory}/results/counts") and results_dir.include?("#{directory}/results/arcs")
      # assumes arcs are saved last so if arcs exist that file has been parsed completely
      finished_files = Dir.glob("#{directory}/results/arcs/*").map{|f| "#{directory}/" + File.basename(f) }
      print "It looks like you have parsed at least a portion of this directory.\n\n"
      print "Do you want me to overwrite the parsed data? (Y|n) "
      response = $stdin.gets.chomp
      unless response == "Y" || response == 'y' || response == "YES" || response == "Yes" || response == 'yes'
        files          = files.reject{|f| finished_files.include?(f) }
      end
    else
      Dir.mkdir("#{directory}/results/counts")
      Dir.mkdir("#{directory}/results/arcs")
    end
  else
    Dir.mkdir("#{directory}/results")
    Dir.mkdir("#{directory}/results/counts")
    Dir.mkdir("#{directory}/results/arcs")
  end
  return files
end

def build_stop_words
  return File.readlines(File.join(File.dirname(__FILE__), 'stop_words.txt')).each{ |e| e.chomp! }
end

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
  # words = reject_non_utf8(words)
  words = build_word_array(words)
  words = reject_non_words(words)
  words = reject_short_words(words)
  words = downcase_words(words)
  words = reject_stop_words(words, stops)
  return words
end

def build_word_arcs(words)
  base_word = words[1]
  arc       = fragment(words.join(' ')).do(:tokenize, :parse)
  arc_out   = base_word + "\t"
  arc.words.each_with_index do |word, i|
    arc_out << (word.value + "/" + word.tag + "/" + word.category + "/" + i.to_s + ' ')
  end
  return arc_out
end

def write_word_count(word_counts, file)
  words       = word_counts.to_a.sort_by{ |e| e[1] }.reverse
  word_counts = []
  words_txt   = words.map{ |e| e.join(', ') }
  write_txt   = File.join(File.dirname(file), 'results', 'counts', "#{File.basename(file)}")
  File.open(write_txt, 'w'){ |f| f.write(words_txt.join("\n")) }

  # The following lines are only helpful for making a nice js file for word clouds
  # TODO - move into optional function
  # words_jsn   = words.reduce([]){ |r,e| r << { text: e[0], weight: e[1] }; r }
  # write_jsn   = File.join(File.dirname(__FILE__), "#{collc}-counts.js")
  # File.open(write_jsn, 'w'){ |f| f.write('var word_array = ' + words_jsn.to_json.to_s) }
end

def write_word_arcs(storage, file)
  word_arcs  = storage.hgetall(file)
  word_arcs  = word_arcs.to_a.sort_by{ |e| e[1] }.reverse
  word_arcs  = word_arcs.map{ |e| e.join("\t") }
  write_arcs = File.join(File.dirname(file), 'results', 'arcs', "#{File.basename(file)}")
  File.open(write_arcs, 'w'){ |f| f.write(word_arcs.join("\n"))}
  storage.del(file)
end

# Step One parses the data into new text files with arcs and total word counts
if ARGV[0] == '--step-one'

  # Set the Dependencies and Environment
  require 'treat'
  require 'redis'
  include Treat::Core::DSL

  # Treat requires java in order to process the word arcs
  unless ENV['JAVA_HOME']
    print "Please make sure your JAVA_HOME is set.\n"
    print "On Ubuntu this is usually:\n\n"
    print "export JAVA_HOME=/usr/lib/jvm/java-7-oracle\n\n"
    exit 1
  end

  # We use Redis as it manages the Hashes better than Ruby's in-memory hash management
  begin
    storage = Redis.new
  rescue
    print "Redis does not appear to be running.\n\nOn Ubuntu start redis with sudo service redis-server start.\n"
    exit 1
  end

  # Initial setup
  collc = ARGV[1]
  files = build_file_list(collc)
  stops = build_stop_words

  # fc and fi are file count and file index. they are used as progress update pointers.
  fc = files.count
  fi = 0
  files.each do |file|
    fi += 1

    # Create a Hash to dump the word counts into
    word_counts = Hash.new(0)

    # simple word counter
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tCounting\t"
    these_words = read_and_clean_file(file, stops)
    these_words.each{|w| word_counts[w] += 1 }
    print "Done!\n"

    # fire the writers, round 1
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tFinished Counting. Now Writing Results.\t"
    write_word_count(word_counts, file)
    word_counts = []

    # loop thru the corpus, chunk into thirds, and build word arcs
    i = 0
    twl = these_words.length
    until i == (twl - 2)
      wa = these_words[i..i+2]
      print "Parsing => #{file}\t[#{fi} of #{fc}]\t[#{i} of #{twl}]\n"
      storage.hincrby file, build_word_arcs(wa), 1
      i += 1
    end

    # fire the writers, round 2
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tFinished Parsing. Now Writing Results.\t"
    write_word_arcs(storage, file)

    # explicitly clear these to control memory allocation a bit more
    these_words = []
    print "Done!\n"
  end
end

# Once the arc files are built, then it is time to send them to the database
#   in a collated fashion.
if ARGV[0] == '--step-two'
  require 'data_mapper'
  require 'dm-migrations'

  collc = ARGV[1]
  files = Dir.glob("#{collc}/results/arcs/*")

  DataMapper.setup(:default, "postgres://#{ARGV[2]}@localhost/legalsyn")

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
  DataMapper.finalize

  begin
    if DataMapper.repository(:default).adapter.storage_exists?('arcs')
      print "You already have data in the table.\n\n"
      print "Do you want me to overwrite the parsed data? (Y|n) "
      response = $stdin.gets.chomp
      unless response == "Y" || response == 'y' || response == "YES" || response == "Yes" || response == 'yes'
        DataMapper.auto_upgrade!
      else
        print "Migrating DB!\n"
        DataMapper.auto_migrate!
      end
    else
      DataMapper.auto_migrate!
    end
  rescue
    print "Please pass the proper username:password to the script.\n\n"
    print "This step should be called via ruby build_dict.rb --step-two directory user:pass\n"
    exit 1
  end

  # fc and fi are file count and file index. they are used as progress update pointers.
  fc = files.count
  fi = 0

  #temp
  files = [files[0]]
  files.each do |file|
    fi += 1

    arcs = File.readlines(file)
    ai   = 0
    ac   = arcs.count
    arcs.each do |arc|
      ai += 1

      arc_partial = arc.split(/\W/)
      print "Logging => #{file}\t[#{fi} of #{fc}]\t[#{ai} of #{ac}]\t#{arc_partial[0]}\n"

      arc_exists = Arc.all( primary_word: arc_partial[0], primary_pos: arc_partial[6], secondary_word_1: arc_partial[1], secondary_1_pos: arc_partial[2], secondary_word_2: arc_partial[9], secondary_2_pos: arc_partial[10] )

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
          arc_exists.arc_occurrance += arc_partial[14].to_i
        else
          arc_exists.arc_occurrance = arc_partial[14]
        end
        arc_exists.save
      else
        arc_new = Arc.create( primary_word: arc_partial[0], primary_pos: arc_partial[6], secondary_word_1: arc_partial[1], secondary_1_pos: arc_partial[2], secondary_word_2: arc_partial[9], secondary_2_pos: arc_partial[10], arc_occurrance: arc_partial[14] )
        arc_new.save
      end
    end
  end
end

def prepare_files_for_three(collc, files)
  counts = Hash.new(0)
  files.each do |file|
    f = File.readlines(file).map{|e| e.split(', ')}
    f.each{|e| counts[e[0]] += e[1].to_i }
  end
  counts = counts.to_a.sort_by{|e| e[1]}.reverse
  counts_save = counts.map{|e| e.join(', ')}
  File.open("#{collc}/results/counts/collated-counts.txt", 'w'){|f| f.write(counts_save.join("\n"))}
  counts_save = ''
  return counts
end

def sum_it(to_sum)
  sum = to_sum.reduce(0) do |s,e|
    begin
      s += e.arc_occurrance
    rescue
    end
    s
  end
  return sum
end

def compare_cat_and_dog(dog_base, qat_base)
  dog        = Arc.all(primary_word: dog_base)
  qat        = Arc.all(primary_word: qat_base)
  inter1     = dog.reduce([]){|arr,d| arr<<[d.secondary_word_1, d.secondary_1_pos]; arr}
  inter2     = qat.reduce([]){|arr,d| arr<<[d.secondary_word_1, d.secondary_1_pos]; arr}
  inter3     = dog.reduce([]){|arr,d| arr<<[d.secondary_word_2, d.secondary_2_pos]; arr}
  inter4     = qat.reduce([]){|arr,d| arr<<[d.secondary_word_2, d.secondary_2_pos]; arr}
  preceding  = inter1 & inter2
  postceding = inter3 & inter4
  pre_union  = preceding.reduce(0) do |sum, w|
    a = Arc.all(primary_word: dog_base, secondary_word_1: w[0], secondary_1_pos: w[1]) +
      Arc.all(primary_word: qat_base, secondary_word_1: w[0], secondary_1_pos: w[1])
    sum += sum_it(a)
  end
  post_union = postceding.reduce(0) do |sum, w|
    a = Arc.all(primary_word: dog_base, secondary_word_2: w[0], secondary_2_pos: w[1]) +
      Arc.all(primary_word: qat_base, secondary_word_2: w[0], secondary_2_pos: w[1])
      sum += sum_it(a)
  end
  union      = pre_union + post_union
  dog_occur  = sum_it(dog)
  qat_occur  = sum_it(qat)
  occurances = dog_occur + qat_occur
  similarity = ( 2 * union.to_f ) / occurances.to_f
  return similarity
end

# Once the arcs are sent to the database, its time to calculate the dice coefficients
if ARGV[0] == '--step-three'
  require 'data_mapper'
  require 'dm-migrations'

  collc = ARGV[1]
  files = Dir.glob("#{collc}/results/counts/*")

  if files.include?("#{collc}/results/counts/collated-counts.txt")
    print "You already have counts collated.\n\n"
    print "Do you want me to overwrite the parsed data? (Y|n) "
    response = $stdin.gets.chomp
    unless response == "Y" || response == 'y' || response == "YES" || response == "Yes" || response == 'yes'
      counts = File.readlines("#{collc}/results/counts/collated-counts.txt").map{|e| e = e.split(", "); e[1] = e[1].chomp.to_i; e}
    else
      counts = prepare_files_for_three(collc, files)
    end
  else
    counts = prepare_files_for_three(collc, files)
  end

  counts = counts.reject{|e| e[1] <= 100 }

  DataMapper.setup(:default, "postgres://#{ARGV[2]}@localhost/legalsyn")

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
  DataMapper.finalize
  DataMapper.auto_upgrade!

  counts = counts.map{|e| e[0]}
  counts.each_with_index do |word, i|
    t = 0
    print "Similarities => #{word}\t[#{(i+1)} of #{counts.length}]\tCalculating."
    until t == counts.length
      print "Similarities => #{word}\t[#{(i+1)} of #{counts.length}]\t[#{t} of #{counts.length}]\n"
      if t == i
        t += 1
        next
      end
      if (Sim.all( word1: word, word2: counts[t] ) + Sim.all( word1: counts[t], word2: word )).empty?
        sim = Sim.create( word1: word, word2: counts[t], dice: compare_cat_and_dog(word, counts[t]))
        sim.save
      end
      t += 1
    end
  end
end