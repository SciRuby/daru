module Daru
  module ArrayHelper
    module_function

    # Recode repeated values on an array, adding the number of repetition
    # at the end
    # Example:
    #   a=%w{a b c c d d d e}
    #   a.recode_repeated
    #   => ["a","b","c_1","c_2","d_1","d_2","d_3","e"]
    def recode_repeated(array)
      return array if array.size == array.uniq.size

      # create hash of { <name> => 0}
      # for all names which are more than one time in array
      counter = array
                .group_by(&:itself)
                .select { |_, g| g.size > 1 }
                .map(&:first)
                .collect { |n| [n, 0] }.to_h

      # ...and use this hash for actual recode
      array.collect do |n|
        if counter.key?(n)
          counter[n] += 1
          new_n = '%s_%d' % [n, counter[n]]
          n.is_a?(Symbol) ? new_n.to_sym : new_n
        else
          n
        end
      end
    end

    def array_of?(array, match)
      array.is_a?(Array) &&
        !array.empty? &&
        array.all? { |el| match === el } # rubocop:disable Style/CaseEquality
    end
  end
end
