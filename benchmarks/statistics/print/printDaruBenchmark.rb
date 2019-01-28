module DaruBenchmark
  module Print
    module DaruBenchmark
      def print_array(array, task, numberOfRows=[2,3,4,5,6,7,8,9])
        puts 
        puts "Method on Vector (Vector access from DataFrame and apply method): **#{task}**"
        puts
        puts " | Number of rows | Real Time | "
        puts " |------------|------------| "
        array.each_with_index do |val, index|
          puts " | 10 ** #{numberOfRows[index]} | #{val} | " 
        end
      end
    end # module DaruBenchmark end
  end # module Print end
end