module DaruBenchmark
  module Print
    module DaruComparisonPandas
      def print_array_compare(array, task, pandasTime)
        puts 
        puts "Method on Vector (Vector access from DataFrame and apply method): **#{task}**"
        puts
        puts " | Number of rows | Real Time | Pandas avg time | daru/pandas | "
        puts " |------------|------------|------------|------------|"
        array.each_with_index do |val, index|
          puts " | 10 ** #{index + 2} | #{val} | #{pandasTime[index]} | #{Float(val)/Float(pandasTime[index])} | " 
        end
      end
    end # module DaruComparison end
  end # module Print end
end
