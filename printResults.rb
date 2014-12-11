require 'json'
require 'open-uri'
require 'active_support/core_ext/hash'
require 'csv'
require 'pp'

def loadHive(path = "hive/results/000000_0")
  raw = CSV.read(path)
  pretty = []
  raw.each_with_index do |line, indx|
    i = indx + 1
    if(i > 100)
      next
    end
    score = line[2].to_f.round(2)
    pretty.push("#{i}. #{line[1]} (#{score})")
  end
  return pretty
end

def loadPig(path = "pig/result/part-r-00000")
  pretty = []
  i = 1;
  File.open(path, 'rb').each do |line|
    if(i > 100)
      next
    end
    row = JSON.parse(line)
    row['score'] = row['score'].round(2)
    pretty.push("#{i}. #{row['name']} (#{row['score']})")
    i += 1
  end
  return pretty
end

puts "Loading results from Hive recommendation engine...."
puts loadHive()

puts "Loading results from Pig recommendation engine...."
puts loadPig()