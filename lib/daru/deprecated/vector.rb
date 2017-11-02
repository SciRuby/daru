module Daru
  module Deprecated
    module Vector
      DATE_REGEXP = /^(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})$/

      # Returns the database type for the vector, according to its content
      def db_type
        # first, detect any character not number
        case
        when @data.any? { |v| v.to_s =~ DATE_REGEXP }
          'DATE'
        when @data.any? { |v| v.to_s =~ /[^0-9e.-]/ }
          'VARCHAR (255)'
        when @data.any? { |v| v.to_s =~ /\./ }
          'DOUBLE'
        else
          'INTEGER'
        end
      end

      def detach_index
        Daru::DataFrame.new(
          index: @index.to_a,
          values: @data.to_a
        )
      end

      # :nocov:
      def daru_vector(*)
        self
      end
      # :nocov:

      alias :dv :daru_vector

      def plotting_library=(lib)
        case lib
        when :gruff, :nyaplot
          @plotting_library = lib
          if Daru.send("has_#{lib}?".to_sym)
            extend Module.const_get(
              "Daru::Plotting::Vector::#{lib.to_s.capitalize}Library"
            )
          end
        else
          raise ArguementError, "Plotting library #{lib} not supported. "\
            'Supported libraries are :nyaplot and :gruff'
        end
      end

      def head(q=10)
        self[0..(q-1)]
      end

      def tail(q=10)
        start = [size - q, 0].max
        self[start..(size-1)]
      end

      # Just sort the data and get an Array in return using Enumerable#sort.
      # Non-destructive.
      # Was never used nowhere :)
      # :nocov:
      def sorted_data(&block)
        @data.to_a.sort(&block)
      end
      # :nocov:

      # Delete an element if block returns true. Destructive.
      def delete_if
        return to_enum(:delete_if) unless block_given?

        keep_e, keep_i = each_with_index.reject { |n, _i| yield(n) }.transpose

        @data = cast_vector_to @dtype, keep_e
        @index = Daru::Index.new(keep_i)

        update_position_cache

        self
      end

      # Keep an element if block returns true. Destructive.
      def keep_if
        return to_enum(:keep_if) unless block_given?

        delete_if { |val| !yield(val) }
      end

      # Return an Array with the data splitted by a separator.
      #   a=Daru::Vector.new(["a,b","c,d","a,b","d"])
      #   a.splitted
      #     =>
      #   [["a","b"],["c","d"],["a","b"],["d"]]
      def splitted(sep=',')
        @data.map do |s|
          if s.nil?
            nil
          elsif s.respond_to? :split
            s.split sep
          else
            [s]
          end
        end
      end

      # Returns a hash of Vectors, defined by the different values
      # defined on the fields
      #
      # @example
      #
      #  a=Daru::Vector.new(["a,b","c,d","a,b"])
      #  a.split_by_separator
      #  =>  {"a"=>#<Daru::Vector:0x7f2dbcc09d88
      #        @data=[1, 0, 1]>,
      #       "b"=>#<Daru::Vector:0x7f2dbcc09c48
      #        @data=[1, 1, 0]>,
      #      "c"=>#<Daru::Vector:0x7f2dbcc09b08
      #        @data=[0, 1, 1]>}
      #
      def split_by_separator(sep=',')
        split_data = splitted sep
        split_data
          .flatten.uniq.compact.map do |key|
          [
            key,
            Daru::Vector.new(split_data.map { |v| split_value(key, v) })
          ]
        end.to_h
      end

      def split_by_separator_freq(sep=',')
        split_by_separator(sep).map { |k, v|
          [k, v.map(&:to_i).inject(:+)]
        }.to_h
      end

      # Convert the hash from to_h to json
      def to_json(*)
        to_h.to_json
      end

      # == Bootstrap
      # Generate +nr+ resamples (with replacement) of size  +s+
      # from vector, computing each estimate from +estimators+
      # over each resample.
      # +estimators+ could be
      # a) Hash with variable names as keys and lambdas as  values
      #   `a.bootstrap(:log_s2=>lambda {|v| Math.log(v.variance)},1000)`
      # b) Array with names of method to bootstrap
      #   `a.bootstrap([:mean, :sd],1000)`
      # c) A single method to bootstrap
      #   `a.jacknife(:mean, 1000)`
      # If s is nil, is set to vector size by default.
      #
      # Returns a DataFrame where each vector is a vector
      # of length +nr+ containing the computed resample estimates.
      def bootstrap(estimators, nr, s=nil)
        s ||= size
        h_est, es, bss = prepare_bootstrap(estimators)

        nr.times do
          bs = sample_with_replacement(s)
          es.each do |estimator|
            bss[estimator].push(h_est[estimator].call(bs))
          end
        end

        es.each do |est|
          bss[est] = Daru::Vector.new bss[est]
        end

        Daru::DataFrame.new bss
      end

      # == Jacknife
      # Returns a dataset with jacknife delete-+k+ +estimators+
      # +estimators+ could be:
      # a) Hash with variable names as keys and lambdas as values
      #   `a.jacknife(:log_s2=>lambda {|v| Math.log(v.variance)})`
      # b) Array with method names to jacknife
      #   `a.jacknife([:mean, :sd])`
      # c) A single method to jacknife
      #   `a.jacknife(:mean)`
      # +k+ represent the block size for block jacknife. By default
      # is set to 1, for classic delete-one jacknife.
      #
      # Returns a dataset where each vector is an vector
      # of length +cases+/+k+ containing the computed jacknife estimates.
      #
      # == Reference:
      # * Sawyer, S. (2005). Resampling Data: Using a Statistical Jacknife.
      def jackknife(estimators, k=1) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        raise "n should be divisible by k:#{k}" unless (size % k).zero?

        nb = (size / k).to_i
        h_est, es, ps = prepare_bootstrap(estimators)

        est_n = es.map { |v| [v, h_est[v].call(self)] }.to_h

        nb.times do |i|
          other = @data.dup
          other.slice!(i*k, k)
          other = Daru::Vector.new other

          es.each do |estimator|
            # Add pseudovalue
            ps[estimator].push(
              nb * est_n[estimator] - (nb-1) * h_est[estimator].call(other)
            )
          end
        end

        es.each do |est|
          ps[est] = Daru::Vector.new ps[est]
        end
        Daru::DataFrame.new ps
      end

      def method_missing(name, *args, &block)
        # FIXME: it is shamefully fragile. Should be either made stronger
        # (string/symbol dychotomy, informative errors) or removed totally. - zverok
        if name =~ /(.+)\=/
          self[$1.to_sym] = args[0]
        elsif has_index?(name)
          self[name]
        else
          super
        end
      end

      def respond_to_missing?(name, include_private=false)
        name.to_s.end_with?('=') || has_index?(name) || super
      end

      # Copies the structure of the vector (i.e the index, size, etc.) and fills all
      # all values with nils.
      # Deprecated, because it is just `vector.recode { nil }`
      def clone_structure
        Daru::Vector.new(([nil]*size), name: @name, index: @index.dup)
      end

      # Reports all values that doesn't comply with a condition.
      # Returns a hash with the index of data and the invalid data.
      def verify
        (0...size)
          .map { |i| [i, @data[i]] }
          .reject { |_i, val| yield(val) }
          .to_h
      end

      # Replace all nils in the vector with the value passed as an argument. Destructive.
      # See #replace_nils for non-destructive version
      #
      # == Arguments
      #
      # * +replacement+ - The value which should replace all nils
      def replace_nils!(replacement)
        indexes(*Daru::MISSING_VALUES).each do |idx|
          self[idx] = replacement
        end

        self
      end

      # Non-destructive version of #replace_nils!
      def replace_nils(replacement)
        dup.replace_nils!(replacement)
      end

      # Sorts a vector according to its values. If a block is specified, the contents
      # will be evaluated and data will be swapped whenever the block evaluates
      # to *true*. Defaults to ascending order sorting. Any missing values will be
      # put at the end of the vector. Preserves indexing. Default sort algorithm is
      # quick sort.
      #
      # == Options
      #
      # * +:ascending+ - if false, will sort in descending order. Defaults to true.
      #
      # * +:type+ - Specify the sorting algorithm. Only supports quick_sort for now.
      # == Usage
      #
      #   v = Daru::Vector.new ["My first guitar", "jazz", "guitar"]
      #   # Say you want to sort these strings by length.
      #   v.sort(ascending: false) { |a,b| a.length <=> b.length }
      def sort(ascending: true, &block)
        vector_index = resort_index(@data.each_with_index, ascending, &block)
        vector, index = vector_index.transpose

        index = @index.reorder index

        Daru::Vector.new(vector, index: index, name: @name, dtype: @dtype)
      end

      # Convert Vector to a horizontal or vertical Ruby Matrix.
      #
      # == Arguments
      #
      # * +axis+ - Specify whether you want a *:horizontal* or a *:vertical* matrix.
      def to_matrix(axis=:horizontal)
        if axis == :horizontal
          Matrix[to_a]
        elsif axis == :vertical
          Matrix.columns([to_a])
        else
          raise ArgumentError, "axis should be either :horizontal or :vertical, not #{axis}"
        end
      end

      # Convert vector to nmatrix object
      # @param [Symbol] axis :horizontal or :vertical
      # @return [NMatrix] NMatrix object containing all values of the vector
      # @example
      #   dv = Daru::Vector.new [1, 2, 3]
      #   dv.to_nmatrix
      #   # =>
      #   # [
      #   #   [1, 2, 3] ]
      def to_nmatrix(axis=:horizontal)
        unless numeric? && !include?(nil)
          raise ArgumentError, 'Can not convert to nmatrix'\
            'because the vector is numeric'
        end

        case axis
        when :horizontal
          NMatrix.new [1, size], to_a
        when :vertical
          NMatrix.new [size, 1], to_a
        else
          raise ArgumentError, 'Invalid axis specified. '\
            'Valid axis are :horizontal and :vertical'
        end
      end

      # If dtype != gsl, will convert data to GSL::Vector with to_a. Otherwise returns
      # the stored GSL::Vector object.
      def to_gsl
        raise NoMethodError, 'Install gsl-nmatrix for access to this functionality.' unless Daru.has_gsl?
        if dtype == :gsl
          @data.data
        else
          GSL::Vector.alloc(reject_values(*Daru::MISSING_VALUES).to_a)
        end
      end

      private

      # @private
      DEFAULT_SORTER = lambda { |(lv, li), (rv, ri)|
        case
        when lv.nil? && rv.nil?
          li <=> ri
        when lv.nil?
          -1
        when rv.nil?
          1
        else
          lv <=> rv
        end
      }

      def resort_index(vector_index, ascending)
        if block_given?
          vector_index.sort { |(lv, _li), (rv, _ri)| yield(lv, rv) }
        else
          vector_index.sort(&DEFAULT_SORTER)
        end
          .tap { |res| res.reverse! unless ascending }
      end

      def nil_positions
        @nil_positions ||= size.times.select { |i| @data[i].nil? }
      end

      def nan_positions
        @nan_positions ||= size.times.select { |i| @data[i].respond_to?(:nan?) && @data[i].nan? }
      end

      def guard_type_check(value)
        @possibly_changed_type = true \
          if object? && (value.nil? || value.is_a?(Numeric)) ||
             numeric? && !value.is_a?(Numeric) && !value.nil?
      end
    end
  end
end
