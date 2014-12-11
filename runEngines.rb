puts "Running Hive engine..."
system 'cd hive && hive -f engine.hql'

puts "Running Pig engine..."
system 'cd pig && pig -x local -param_file params.conf -stop_on_failure engine.pig'

puts "Done!"