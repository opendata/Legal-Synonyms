#!/usr/bin/env ruby

# to extract the noise from the ocr'd text. loops through the characters of a string
#   and selects only those which are word characters (letters, numbers, underscores)
#   or whitespace or '-' or '/'. It is not the closest regex purge possible, but it
#   works for this purpose.
def purge_the_ocr_noise text_blob
  text_blob = text_blob.split("").select{|e| e[/(\w|\s|-|\/)/] }.join("")

  # deal with white space
  text_blob = text_blob.squeeze(" ") || text_blob
  text_blob.strip!

  # deal with stray -, _, /
  text_blob = text_blob.squeeze("\-") || text_blob
  text_blob.gsub!("_", "")
  text_blob.gsub!(" -", "")
  text_blob.gsub!(" /", "")

  # finally, purge some stray patterns
  text_blob.gsub!(/ [\w]-\z/, '')
  text_blob.gsub!(/ [\w]\z/, '')
  text_blob.gsub!(/-\z/, '')
  text_blob.gsub!(/\/\z/, '')
  text_blob.gsub!(/\A-/, '')

  # fin
  return text_blob
end

# the csv file has been built so that groupings are delimited by a blank line
#   function loops through the lines and builts a result string by adding lines
#   with comma delimitation (as required by solr) and where there are blank
#   lines it adds a new line character. the gsubs are there to provide some cleanup.
#   finally the function downcases all the characters.
def assemble_line_delimited_into_comma_delimited cleaned_synonyms
  mapped_synonyms = cleaned_synonyms.reduce("") do |result, line|
    if line.empty?
      result << "\n"
    else
      result << ( line + ", ")
    end
    result
  end
  mapped_synonyms.gsub!(", \n", "\n")
  mapped_synonyms.gsub!(/, \z/, '')
  mapped_synonyms.gsub!("\n\n", '')
  return mapped_synonyms.downcase!
end

file_to_process   = ARGV[0]
output_file       = ARGV[1]
synonyms_in_lines = File.readlines file_to_process
cleaned_synonyms  = synonyms_in_lines.map{ |line| purge_the_ocr_noise(line) }
mapped_synonyms   = assemble_line_delimited_into_comma_delimited(cleaned_synonyms)

File.open(output_file, 'w'){|f| f.write(mapped_synonyms)}
