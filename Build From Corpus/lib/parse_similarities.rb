#! /usr/bin/env ruby

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