module Daru
  # Module encapsulating advanced data cleaning methods on DataFrame.
  module Clean
    # replace elements with those from given set of elements
    # based on similarity
    # @param vector [Daru::Vector] vector to be cleansed
    # @param dict [Array] the array serving as key set
    # @example
    #   df = Daru::DataFrame.new({ a: ['mal','femal','M','F','Fem']})
    #   df.fuzzy_match :a, ['MALE','FEMALE']
    #   # => #<Daru::DataFrame(5x1)>
    #   #           a
    #   #   0    MALE
    #   #   1  FEMALE
    #   #   2    MALE
    #   #   3  FEMALE
    #   #   4  FEMALE
    require 'fuzzy_match'
    def fuzzy_replace vector, dict
      key = FuzzyMatch.new(dict)
      self[vector].map! {|ele| key.find(ele)}
    end

    # fill missing places using linear regression
    # @param vector [Daru::Vector] vector to be cleansed
    # @example
    #   df = Daru::DataFrame.new({ a: [1,3,nil,7,9,nil]})
    #   df.impute :a
    #   # => #<Daru::DataFrame(6x1)>
    #   #       a
    #   #   0   1
    #   #   1   3
    #   #   2   5
    #   #   3   7
    #   #   4   9
    #   #   5   11
    def impute vector
      # TODO
    end

    # Split multi valued cells in more than one column into rows
    # @example
    #   df = Daru::DataFrame.new({
    #      REF: ['2002, 2003', '3001, 3002, 3003'],
    #      Handle: ['t-shirt1', 't-shirt2'],
    #      Size: ['M, L', 'S, M, L'],
    #      Price: [23,24]
    #   })
    #   df.split_cell
    #   # => #<Daru::DataFrame(5x4)>
    #   #       REF    Handle  Size  Price
    #   #   0  2002  t-shirt1     M     23
    #   #   1  2003  t-shirt1     L     23
    #   #   2  3001  t-shirt2     S     24
    #   #   3  3002  t-shirt2     M     24
    #   #   4  3003  t-shirt2     L     24
    def split_cell cols, delimiter: ","
      self[cols[0]].each_with_index do |row, idx|
        next unless row.to_s.include? delimiter
        (0...row.split(delimiter).size).each do |i|
          arr = []
          self.row[idx].each_with_index do |ele, idx1|
            arr << ((cols.include? idx1) ? ele.split(delimiter)[i].chomp : ele)
          end
          self.add_row arr
        end
      end
      self[cols[0]].each_with_index do |row, idx|
        next unless row.to_s.include? delimiter
        self.delete_row idx
      end
    end

    # check dependency of one column to another
    # @param vec1 [Daru::Vector] vector to be checked
    # @param vec2 [Daru::Vector] vector to be checked
    #   df = Daru::DataFrame.new({
    #      a: [1,1,1,2,1]
    #      b: [11,12,11,12,7,12]
    #      c: ['a','a','a','b','a']
    #   })
    #   df.depend? :a, :c
    #   # => true
    #
    #   df.depend? :b, :c
    #   # => false
    def depend? vec1, vec2
      # TODO
    end
  end
end
