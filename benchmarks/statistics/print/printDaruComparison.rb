module DaruBenchmark
  module Print
    module DaruComparison
      def print_array_compare(array, task, pandasTime, numpyTime)
        puts 
        puts "Method on Vector (Vector access from DataFrame and apply method): **#{task}**"
        puts
        puts " | Number of rows | Real Time | Pandas avg time | daru/pandas | NumPy avg time | daru/numpy | "
        puts " |------------|------------|------------|------------|------------|------------| "
        array.each_with_index do |val, index|
          puts " | 10 ** #{index + 2} | #{val} | #{pandasTime[index]} | #{Float(val)/Float(pandasTime[index])} | #{numpyTime[index]} | #{Float(val)/Float(numpyTime[index])} |" 
        end
      end
    end # module DaruComparison end
  end # module Print end
end
