#! /usr/bin/env ruby

def prepare_files_for_one(directory)
  files = Dir.glob("#{directory}/*")
  if files.include?("#{directory}/results")
    files.delete("#{directory}/results")
    results_dir = Dir.glob("#{directory}/results/*")
    unless results_dir.include?("#{directory}/results/counts")
      Dir.mkdir("#{directory}/results/counts")
    end
  else
    Dir.mkdir("#{directory}/results")
    Dir.mkdir("#{directory}/results/counts")
  end
  parsed_files = ParsedFiles.all.map{|f| f.files_parsed}
  files        = files.reject{|e| parsed_files.include?(e)}
  return files
end

def prepare_stop_words
  return File.readlines(File.join(File.dirname(__FILE__), 'stop_words.txt')).each{ |e| e.chomp! }
end

def find_or_build_collated_counts(collc)
  files = Dir.glob("#{collc}/results/counts/*")
  if files.include?("#{collc}/results/counts/collated-counts.txt")
    print "You already have counts collated.\n\n"
    print "Do you want me to overwrite the parsed data? (Y|n) "
    response = $stdin.gets.chomp
    unless response == "Y" || response == 'y' || response == "YES" || response == "Yes" || response == 'yes'
      counts = File.readlines("#{collc}/results/counts/collated-counts.txt").map{|e| e = e.split(", "); e[1] = e[1].chomp.to_i; e}
    else
      counts = prepare_files_for_two(collc, files)
    end
  else
    counts = prepare_files_for_two(collc, files)
  end
end

def prepare_files_for_two(collc, files)
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