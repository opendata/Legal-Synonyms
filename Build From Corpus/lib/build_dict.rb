#! /usr/bin/env ruby

# Step One parses the data into new text files with arcs and total word counts
def perform_step_one(collc)

  # Initial setup
  files = prepare_files_for_one(collc)
  stops = prepare_stop_words

  # fc and fi are file count and file index. they are used as progress update pointers.
  fc = files.count
  fi = 0

  # Loop through the files.
  files.each do |file|
    fi += 1

    # Create a Hash to dump the word counts into
    word_counts = Hash.new(0)

    # simple word counter
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tCounting\t"
    these_words = read_and_clean_file(file, stops)
    these_words.each{|w| word_counts[w] += 1 }
    print "Done!\n"
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tFinished Counting. Now Writing Results.\t"
    write_word_count(word_counts, file)
    word_counts = []

    # loop thru the corpus, chunk into thirds, and build word arcs
    twl = these_words.length
    i = 0
    until i == (twl - 2)
      wa = these_words[i..i+2]
      print "Parsing => #{file}\t[#{fi} of #{fc}]\t[#{i} of #{twl}]\n"
      build_word_arcs(wa)
      i += 1
    end

    # Log that this file is finished.
    print "Parsing => #{file}\t[#{fi} of #{fc}]\tFinished Parsing. \t"
    parsed_file = ParsedFiles.create( files_parsed: file )
    parsed_file.save

    # explicitly clear these to control memory allocation a bit more
    these_words = []
    print "Done!\n"
  end
end

# Once the arcs are sent to the database, its time to calculate the dice coefficients
def perform_step_two(collc)

  counts = find_or_build_collated_counts(collc)

  # counts = counts.reject{|e| e[1] <= 100 }
  counts = counts[0..3999]

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
        begin
          sim = Sim.create( word1: word, word2: counts[t], dice: compare_cat_and_dog(word, counts[t]))
          sim.save
        rescue
          sim = Sim.create( word1: word, word2: counts[t], dice: 0.0)
          sim.save
        end
      end
      t += 1
    end
  end
end

# Finally.... Pull out whatcha need.
def perform_step_three(dice, output_file)

  syns     = Sim.all(:dice.gte => dice)
  syns_out = syns.reduce({}) do |syn, e|
    if syn[e.word1]
      syn[e.word1] << e.word2
    else
      syn[e.word1] = [e.word2]
    end
    if syn[e.word2]
      syn[e.word2] << e.word1
    else
      syn[e.word2] = [e.word1]
    end
    syn[e.word1] = syn[e.word1].uniq
    syn[e.word2] = syn[e.word2].uniq
    syn
  end

  syns_out = syns_out.map{|e| e.to_a.join(', ')}.join("\n")

  File.open(output_file, 'w'){|f| f.write(syns_out.to_s)}
end