$:.unshift File.dirname(__FILE__)

require 'maths/arithmetic/vector.rb'
require 'maths/statistics/vector.rb'
require 'plotting/vector.rb'
require 'accessors/array_wrapper.rb'
require 'accessors/nmatrix_wrapper.rb'
require 'accessors/gsl_wrapper.rb'

module Daru
  class Vector
    include Enumerable
    include Daru::Maths::Arithmetic::Vector
    include Daru::Maths::Statistics::Vector
    include Daru::Plotting::Vector

    def each(&block)
      return to_enum(:each) unless block_given?
      
      @data.each(&block)
      self
    end

    def each_index(&block)
      return to_enum(:each_index) unless block_given?

      @index.each(&block)
      self
    end

    def map!(&block)
      return to_enum(:map!) unless block_given?
      @data.map!(&block)
      update
      self
    end

    # The name of the Daru::Vector. String.
    attr_reader :name
    # The row index. Can be either Daru::Index or Daru::MultiIndex.
    attr_reader :index
    # The total number of elements of the vector.
    attr_reader :size
    # The underlying dtype of the Vector. Can be either :array, :nmatrix or :gsl.
    attr_reader :dtype
    # If the dtype is :nmatrix, this attribute represents the data type of the
    # underlying NMatrix object. See NMatrix docs for more details on NMatrix
    # data types.
    attr_reader :nm_dtype
    # An Array or the positions in the vector that are being treated as 'missing'.
    attr_reader :missing_positions

    # Create a Vector object.
    # 
    # == Arguments
    # 
    # @param source[Array,Hash] - Supply elements in the form of an Array or a 
    # Hash. If Array, a numeric index will be created if not supplied in the 
    # options. Specifying more index elements than actual values in *source* 
    # will insert *nil* into the surplus index elements. When a Hash is specified, 
    # the keys of the Hash are taken as the index elements and the corresponding 
    # values as the values that populate the vector.
    # 
    # == Options
    # 
    # * +:name+  - Name of the vector
    # 
    # * +:index+ - Index of the vector
    # 
    # * +:dtype+ - The underlying data type. Can be :array, :nmatrix or :gsl. 
    # Default :array.
    # 
    # * +:nm_dtype+ - For NMatrix, the data type of the numbers. See the NMatrix docs for
    # further information on supported data type.
    # 
    # * +:missing_values+ - An Array of the values that are to be treated as 'missing'.
    # nil is the default missing value.
    # 
    # == Usage
    # 
    #   vecarr = Daru::Vector.new [1,2,3,4], index: [:a, :e, :i, :o]
    #   vechsh = Daru::Vector.new({a: 1, e: 2, i: 3, o: 4})
    def initialize source, opts={}
      index = nil
      if source.is_a?(Hash)
        index  = source.keys
        source = source.values
      else
        index  = opts[:index]
        source = source || []
      end
      name   = opts[:name]
      set_name name

      @data  = cast_vector_to(opts[:dtype] || :array, source, opts[:nm_dtype])
      @index = create_index(index || @data.size)
      
      if @index.size > @data.size
        cast(dtype: :array) # NM with nils seg faults
        (@index.size - @data.size).times { @data << nil }
      elsif @index.size < @data.size
        raise IndexError, "Expected index size >= vector size. Index size : #{@index.size}, vector size : #{@data.size}"
      end

      @possibly_changed_type = true
      set_missing_values opts[:missing_values]
      set_missing_positions
      set_size
    end

    # Create a new vector by specifying the size and an optional value
    # and block to generate values.
    # 
    # == Options
    # :value
    # All the rest like .new
    def self.new_with_size n, opts={}, &block
      value = opts[:value]
      opts.delete :value
      if block
        vector = Daru::Vector.new n.times.map { |i| block.call(i) }, opts
      else
        vector = Daru::Vector.new n.times.map { value }, opts
      end
      vector
    end

    # Get one or more elements with specified index or a range.
    # 
    # == Usage
    #   # For vectors employing single layer Index
    # 
    #   v[:one, :two] # => Daru::Vector with indexes :one and :two
    #   v[:one]       # => Single element
    #   v[:one..:three] # => Daru::Vector with indexes :one, :two and :three
    # 
    #   # For vectors employing hierarchial multi index
    #   
    def [](*indexes)
      location = indexes[0]
      if @index.is_a?(MultiIndex)
        result = 
        if location.is_a?(Integer)
          element_from_numeric_index(location)
        elsif location.is_a?(Range)
          arry = location.inject([]) do |memo, num|
            memo << element_from_numeric_index(num)
            memo
          end

          new_index = Daru::MultiIndex.new(@index.to_a[location])
          Daru::Vector.new(arry, index: new_index, name: @name, dtype: dtype)
        else
          sub_index = @index[indexes]

          if sub_index.is_a?(Integer)
            element_from_numeric_index(sub_index)
          else
            elements = sub_index.map do |tuple|
              @data[@index[(indexes + tuple)]]
            end
            Daru::Vector.new(elements, index: Daru::MultiIndex.new(sub_index.to_a),
              name: @name, dtype: @dtype)
          end
        end

        return result
      else
        unless indexes[1]
          case location
          when Range
            range = 
            if location.first.is_a?(Numeric)
              location
            else
              first = location.first
              last  = location.last

              (first..last)
            end
            indexes = @index[range]
          else
            return element_from_numeric_index(location)
          end
        end

        Daru::Vector.new indexes.map { |loc| @data[index_for(loc)] }, name: @name, 
          index: indexes.map { |e| named_index_for(e) }, dtype: @dtype
      end
    end

    def []=(*location, value)
      cast(dtype: :array) if value.nil? and dtype != :array

      @possibly_changed_type = true if @type == :object  and (value.nil? or 
        value.is_a?(Numeric))
      @possibly_changed_type = true if @type == :numeric and (!value.is_a?(Numeric) and
        !value.nil?)

      pos =
      if @index.is_a?(MultiIndex) and !location[0].is_a?(Integer)
        index_for location
      else
        index_for location[0]
      end

      if pos.is_a?(MultiIndex)
        pos.each do |sub_tuple|
          self[*(location + sub_tuple)] = value
        end
      else
        @data[pos] = value
      end

      set_size
      set_missing_positions unless Daru.lazy_update
    end

    # The values to be treated as 'missing'. *nil* is the default missing
    # type. To set missing values see the missing_values= method.
    def missing_values
      @missing_values.keys  
    end

    # Assign an Array to treat certain values as 'missing'.
    # 
    # == Usage
    # 
    #   v = Daru::Vector.new [1,2,3,4,5]
    #   v.missing_values = [3]
    #   v.update
    #   v.missing_positions 
    #   #=> [2]
    def missing_values= values
      set_missing_values values
      set_missing_positions unless Daru.lazy_update
    end

    # Method for updating the metadata (i.e. missing value positions) of the
    # after assingment/deletion etc. are complete. This is provided so that
    # time is not wasted in creating the metadata for the vector each time
    # assignment/deletion of elements is done. Updating data this way is called
    # lazy loading. To set or unset lazy loading, see the .lazy_update= method.
    def update
      if Daru.lazy_update
        set_missing_positions
      end
    end

    # Two vectors are equal if the have the exact same index values corresponding
    # with the exact same elements. Name is ignored.
    def == other
      case other
      when Daru::Vector
        @index == other.index and @size == other.size and
        @index.all? do |index|
          self[index] == other[index]
        end
      else
        # TODO: Compare against some other obj (string, number, etc.)
      end
    end

    def head q=10
      self[0..q]
    end

    def tail q=10
      self[-q..-1]
    end

    # Reports whether missing data is present in the Vector.
    def has_missing_data?
      !missing_positions.empty?
    end
    alias :flawed? :has_missing_data?


    # Append an element to the vector by specifying the element and index
    def concat element, index=nil
      raise IndexError, "Expected new unique index" if @index.include? index

      if index.nil? and @index.index_class == Integer
        @index = create_index(@size + 1)
        index  = @size
      else
        begin
          @index = create_index(@index + index)
        rescue StandardError => e
          raise e, "Expected valid index."
        end
      end
      @data[@index[index]] = element
      set_size
      set_missing_positions unless Daru.lazy_update
    end
    alias :push :concat 
    alias :<< :concat

    # Cast a vector to a new data type.
    # 
    # == Options
    # 
    # * +:dtype+ - :array for Ruby Array. :nmatrix for NMatrix.
    def cast opts={}
      dt = opts[:dtype]
      raise ArgumentError, "Unsupported dtype #{opts[:dtype]}" unless 
        dt == :array or dt == :nmatrix or dt == :gsl

      @data = cast_vector_to dt unless @dtype == dt
    end

    # Delete an element by value
    def delete element
      self.delete_at index_of(element)      
    end

    # Delete element by index
    def delete_at index
      idx = named_index_for index
      @data.delete_at @index[idx]

      if @index.index_class == Integer
        @index = Daru::Index.new @size-1
      else
        @index = Daru::Index.new (@index.to_a - [idx])
      end

      set_size
      set_missing_positions unless Daru.lazy_update
    end

    # The type of data contained in the vector. Can be :object or :numeric. If
    # the underlying dtype is an NMatrix, this method will return the data type
    # of the NMatrix object.
    #   
    # Running through the data to figure out the kind of data is delayed to the
    # last possible moment.    
    def type
      return @data.nm_dtype if dtype == :nmatrix

      if @type.nil? or @possibly_changed_type
        @type = :numeric
        self.each do |e|
          unless e.nil?
            unless e.is_a?(Numeric)
              @type = :object
              break
            end
          end
        end
        @possibly_changed_type = false
      end

      @type
    end

    # Get index of element
    def index_of element
      @index.key @data.index(element)
    end

    # Keep only unique elements of the vector alongwith their indexes.
    def uniq
      uniq_vector = @data.uniq
      new_index   = uniq_vector.inject([]) do |acc, element|  
        acc << index_of(element) 
        acc
      end

      Daru::Vector.new uniq_vector, name: @name, index: new_index, dtype: @dtype
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
    def sort opts={}, &block
      opts = {
        ascending: true,
        type: :quick_sort
      }.merge(opts)

      block = lambda { |a,b| a <=> b } unless block
    
      order = opts[:ascending] ? :ascending : :descending
      vector, index = send(opts[:type], @data.to_a.dup, @index.to_a, order, &block)
      index = @index.is_a?(MultiIndex) ? Daru::MultiIndex.new(index) : index

      Daru::Vector.new(vector, index: create_index(index), name: @name, dtype: @dtype)
    end

    # Just sort the data and get an Array in return using Enumerable#sort. 
    # Non-destructive.
    def sorted_data &block
      @data.to_a.sort(&block)
    end

    # Returns *true* if the value passed actually exists in the vector.
    def exists? value
      !self[index_of(value)].nil?
    end

    # Like map, but returns a Daru::Vector with the returned values.
    def recode dt=nil, &block
      return to_enum(:recode) unless block_given?

      dup.recode! dt, &block
    end

    # Destructive version of recode!
    def recode! dt=nil, &block
      return to_enum(:recode!) unless block_given?

      @data.map!(&block).data
      @data = cast_vector_to(dt || @dtype)
      self
    end

    def delete_if &block
      return to_enum(:delete_if) unless block_given?

      keep_e = []
      keep_i = []
      each_with_index do |n, i|
        if yield(n)
          keep_e << n
          keep_i << i
        end
      end

      @data = cast_vector_to @dtype, keep_e
      @index = @index.is_a?(MultiIndex) ? MultiIndex.new(keep_i) : Index.new(keep_i)
      set_missing_positions unless Daru.lazy_update
      set_size

      self
    end

    # Reports all values that doesn't comply with a condition.
    # Returns a hash with the index of data and the invalid data.
    def verify &block
      h = {}
      (0...size).each do |i|
        if !(yield @data[i])
          h[i] = @data[i]
        end
      end

      h
    end

    # Return an Array with the data splitted by a separator.
    #   a=Daru::Vector.new(["a,b","c,d","a,b","d"])
    #   a.splitted
    #     =>
    #   [["a","b"],["c","d"],["a","b"],["d"]]
    def splitted sep=","
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
    # Example:
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
    def split_by_separator sep=","
      split_data = splitted sep
      factors = split_data.flatten.uniq.compact

      out = factors.inject({}) do |h,x|
        h[x] = []
        h
      end

      split_data.each do |r|
        if r.nil?
          factors.each do |f|
            out[f].push(nil)
          end
        else
          factors.each do |f|
            out[f].push(r.include?(f) ? 1:0)
          end
        end
      end

      out.inject({}) do |s,v|
        s[v[0]] = Daru::Vector.new v[1]
        s
      end
    end

    def split_by_separator_freq(sep=",")
      split_by_separator(sep).inject({}) do |a,v|
        a[v[0]] = v[1].inject { |s,x| s+x.to_i }
        a
      end
    end

    def reset_index!
      @index = Daru::Index.new(Array.new(size) { |i| i })
      self
    end

    # Returns a vector which has *true* in the position where the element in self
    # is nil, and false otherwise.
    # 
    # == Usage
    # 
    #   v = Daru::Vector.new([1,2,4,nil])
    #   v.is_nil?
    #   # => 
    #   #<Daru::Vector:89421000 @name = nil @size = 4 >
    #   #      nil
    #   #  0  false
    #   #  1  false
    #   #  2  false
    #   #  3  true
    def is_nil?
      nil_truth_vector = clone_structure
      @index.each do |idx|
        nil_truth_vector[idx] = self[idx].nil? ? true : false
      end

      nil_truth_vector
    end

    # Opposite of #is_nil?
    def not_nil?
      nil_truth_vector = clone_structure
      @index.each do |idx|
        nil_truth_vector[idx] = self[idx].nil? ? false : true
      end

      nil_truth_vector
    end

    # Replace all nils in the vector with the value passed as an argument. Destructive.
    # See #replace_nils for non-destructive version
    # 
    # == Arguments
    # 
    # * +replacement+ - The value which should replace all nils
    def replace_nils! replacement
      missing_positions.each do |idx|
        self[idx] = replacement
      end

      self
    end

    # Non-destructive version of #replace_nils!
    def replace_nils replacement
      self.dup.replace_nils!(replacement)
    end

    # number of non-missing elements
    def n_valid
      @size - missing_positions.size
    end

    # Returns *true* if an index exists
    def has_index? index
      @index.include? index
    end

    # Convert Vector to a horizontal or vertical Ruby Matrix.
    # 
    # == Arguments
    # 
    # * +axis+ - Specify whether you want a *:horizontal* or a *:vertical* matrix.
    def to_matrix axis=:horizontal
      if axis == :horizontal
        Matrix[to_a]
      elsif axis == :vertical
        Matrix.columns([to_a])
      else
        raise ArgumentError, "axis should be either :horizontal or :vertical, not #{axis}"
      end
    end

    # If dtype != gsl, will convert data to GSL::Vector with to_a. Otherwise returns
    # the stored GSL::Vector object.
    def to_gsl
      if Daru.has_gsl?
        if dtype == :gsl
          return @data.data
        else
          GSL::Vector.alloc only_valid(:array).to_a
        end
      else
        raise NoMethodError, "Install gsl-nmatrix for access to this functionality."
      end
    end

    # Convert to hash. Hash keys are indexes and values are the correspoding elements
    def to_hash
      @index.inject({}) do |hsh, index|
        hsh[index] = self[index]
        hsh
      end
    end

    # Return an array
    def to_a
      @data.to_a
    end

    # Convert the hash from to_hash to json
    def to_json *args 
      self.to_hash.to_json
    end

    # Convert to html for iruby
    def to_html threshold=30
      name = @name || 'nil'
      html = '<table>' + '<tr><th> </th><th>' + name.to_s + '</th></tr>'
      @index.each_with_index do |index, num|
        html += '<tr><td>' + index.to_s + '</td>' + '<td>' + self[index].to_s + '</td></tr>'
    
        if num > threshold
          html += '<tr><td>...</td><td>...</td></tr>'
          break
        end
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Create a summary of the Vector using Report Builder.
    def summary(method = :to_text)
      ReportBuilder.new(no_title: true).add(self).send(method)
    end

    def report_building b
      b.section(:name => name) do |s|
        s.text "n :#{size}"
        s.text "n valid:#{n_valid}"
        if @type == :object
          s.text  "factors: #{factors.join(',')}"
          s.text  "mode: #{mode}"

          s.table(:name => "Distribution") do |t|
            frequencies.sort.each do |k,v|
              key = @index.include?(k) ? @index[k] : k
              t.row [key, v , ("%0.2f%%" % (v.quo(n_valid)*100))]
            end
          end
        end

        s.text "median: #{median.to_s}" if (@type==:numeric or @type==:numeric)
        if @type==:numeric
          s.text "mean: %0.4f" % mean
          if sd
            s.text "std.dev.: %0.4f" % sd
            s.text "std.err.: %0.4f" % se
            s.text "skew: %0.4f" % skew
            s.text "kurtosis: %0.4f" % kurtosis
          end
        end
      end
    end

    # Over rides original inspect for pretty printing in irb
    def inspect spacing=20, threshold=15
      longest = [@name.to_s.size,
                 @index.to_a.map(&:to_s).map(&:size).max, 
                 @data    .map(&:to_s).map(&:size).max,
                 'nil'.size].max

      content   = ""
      longest   = spacing if longest > spacing
      name      = @name || 'nil'
      formatter = "\n%#{longest}.#{longest}s %#{longest}.#{longest}s"
      content  += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + name.to_s + " @size = " + size.to_s + " >"

      content += sprintf formatter, "", name
      @index.each_with_index do |index, num|
        content += sprintf formatter, index.to_s, (self[*index] || 'nil').to_s
        if num > threshold
          content += sprintf formatter, '...', '...'
          break
        end
      end
      content += "\n"

      content
    end

    # Create a new vector with a different index.
    # 
    # @param new_index [Symbol, Array, Daru::Index] The new index. Passing *:seq*
    #   will reindex with sequential numbers from 0 to (n-1).
    def reindex new_index
      index = create_index(new_index == :seq ? @size : new_index)
      Daru::Vector.new @data.to_a, index: index, name: name, dtype: @dtype
    end

    # Give the vector a new name
    # 
    # @param new_name [Symbol] The new name.
    def rename new_name
      if new_name.is_a?(Numeric)
        @name = new_name 
        return
      end

      if new_name.is_a? String
        @name = new_name.strip.downcase.squeeze(" ").gsub(" ", "_").to_sym
      else
        @name = new_name.to_sym
      end
    end

    # Duplicate elements and indexes
    def dup 
      Daru::Vector.new @data.dup, name: @name, index: @index.dup
    end

    # == Bootstrap
    # Generate +nr+ resamples (with replacement) of size  +s+
    # from vector, computing each estimate from +estimators+
    # over each resample.
    # +estimators+ could be
    # a) Hash with variable names as keys and lambdas as  values
    #   a.bootstrap(:log_s2=>lambda {|v| Math.log(v.variance)},1000)
    # b) Array with names of method to bootstrap
    #   a.bootstrap([:mean, :sd],1000)
    # c) A single method to bootstrap
    #   a.jacknife(:mean, 1000)
    # If s is nil, is set to vector size by default.
    #
    # Returns a DataFrame where each vector is a vector
    # of length +nr+ containing the computed resample estimates.
    def bootstrap(estimators, nr, s=nil)
      s ||= size
      h_est, es, bss = prepare_bootstrap(estimators)

      nr.times do |i|
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
    #   a.jacknife(:log_s2=>lambda {|v| Math.log(v.variance)})
    # b) Array with method names to jacknife
    #   a.jacknife([:mean, :sd])
    # c) A single method to jacknife
    #   a.jacknife(:mean)
    # +k+ represent the block size for block jacknife. By default
    # is set to 1, for classic delete-one jacknife.
    #
    # Returns a dataset where each vector is an vector
    # of length +cases+/+k+ containing the computed jacknife estimates.
    #
    # == Reference:
    # * Sawyer, S. (2005). Resampling Data: Using a Statistical Jacknife.
    def jackknife(estimators, k=1)
      raise "n should be divisible by k:#{k}" unless size % k==0

      nb = (size / k).to_i
      h_est, es, ps = prepare_bootstrap(estimators)

      est_n = es.inject({}) do |h,v|
        h[v] = h_est[v].call(self)
        h
      end

      nb.times do |i|
        other = @data.dup
        other.slice!(i*k, k)
        other = Daru::Vector.new other

        es.each do |estimator|
          # Add pseudovalue
          ps[estimator].push(
            nb * est_n[estimator] - (nb-1) * h_est[estimator].call(other))
        end
      end

      es.each do |est|
        ps[est] = Daru::Vector.new ps[est]
      end
      Daru::DataFrame.new ps
    end

    # Creates a new vector consisting only of non-nil data
    # 
    # == Arguments
    # 
    # @as_a [Symbol] Passing :array will return only the elements
    # as an Array. Otherwise will return a Daru::Vector.
    def only_valid as_a=:vector
      return self if !has_missing_data? and as_a == :vector
      return self.to_a if !has_missing_data? and as_a != :vector

      new_index = @index.to_a - missing_positions
      new_vector = new_index.map do |idx|
        self[idx]
      end

      return new_vector if as_a != :vector
      
      Daru::Vector.new new_vector, index: new_index, name: @name, dtype: dtype
    end

    # Copies the structure of the vector (i.e the index, size, etc.) and fills all
    # all values with nils.
    def clone_structure
      Daru::Vector.new(([nil]*@size), name: @name, index: @index.dup)
    end

    # Save the vector to a file
    # 
    # == Arguments
    # 
    # * filename - Path of file where the vector is to be saved
    def save filename
      Daru::IO.save self, filename
    end

    def _dump(depth) # :nodoc:
      Marshal.dump({
        data:  @data.to_a, 
        dtype: @dtype, 
        name:  @name, 
        index: @index,
        missing_values: @missing_values})
    end

    def self._load(data) # :nodoc:
      h = Marshal.load(data)
      Daru::Vector.new(h[:data], index: h[:index], 
        name: h[:name], dtype: h[:dtype], missing_values: h[:missing_values])
    end

    def daru_vector *name
      self
    end

    alias :dv :daru_vector

    def method_missing(name, *args, &block)
      if name.match(/(.+)\=/)
        self[name] = args[0]
      elsif has_index?(name)
        self[name]
      else
        super(name, *args, &block)
      end
    end

   private

    # For an array or hash of estimators methods, returns
    # an array with three elements
    # 1.- A hash with estimators names as keys and lambdas as values
    # 2.- An array with estimators names
    # 3.- A Hash with estimators names as keys and empty arrays as values
    def prepare_bootstrap(estimators)
      h_est = estimators
      h_est = [h_est] unless h_est.is_a?(Array) or h_est.is_a?(Hash)

      if h_est.is_a? Array
        h_est = h_est.inject({}) do |h, est|
          h[est] = lambda { |v| Daru::Vector.new(v).send(est) }
          h
        end
      end
      bss = h_est.keys.inject({}) { |h,v| h[v] = []; h }

      [h_est, h_est.keys, bss]
    end

    def quick_sort vector, index, order, &block
      recursive_quick_sort vector, index, order, 0, @size-1, &block
      [vector, index]
    end

    def recursive_quick_sort vector, index, order, left_lower, right_upper, &block
      if left_lower < right_upper
        left_upper, right_lower = partition(vector, index, order, left_lower, right_upper, &block)
        if left_upper - left_lower < right_upper - right_lower
          recursive_quick_sort(vector, index, order, left_lower, left_upper, &block)
          recursive_quick_sort(vector, index, order, right_lower, right_upper, &block)
        else
          recursive_quick_sort(vector, index, order, right_lower, right_upper, &block)
          recursive_quick_sort(vector, index, order, left_lower, left_upper, &block)
        end
      end
    end

    def partition vector, index, order, left_lower, right_upper, &block
      mindex = (left_lower + right_upper) / 2
      mvalue = vector[mindex]
      i = left_lower
      j = right_upper
      opposite_order = order == :ascending ? :descending : :ascending

      i += 1 while(keep?(vector[i], mvalue, order, &block))
      j -= 1 while(keep?(vector[j], mvalue, opposite_order, &block))

      while i < j - 1
        vector[i], vector[j] = vector[j], vector[i]
        index[i], index[j]   = index[j], index[i]
        i += 1
        j -= 1

        i += 1 while(keep?(vector[i], mvalue, order, &block))
        j -= 1 while(keep?(vector[j], mvalue, opposite_order, &block))
      end

      if i <= j
        if i < j
          vector[i], vector[j] = vector[j], vector[i]
          index[i], index[j]   = index[j], index[i]
        end
        i += 1
        j -= 1
      end

      [j,i]
    end

    def keep? a, b, order, &block
      return false if a.nil? or b.nil?
      eval = block.call(a,b)
      if order == :ascending 
        return true  if eval == -1
        return false if eval == 1
      elsif order == :descending
        return false if eval == -1
        return true  if eval == 1
      end
      return false
    end

    # Note: To maintain sanity, this _MUST_ be the _ONLY_ place in daru where the
    # @dtype variable is set and the underlying data type of vector changed.
    def cast_vector_to dtype, source=nil, nm_dtype=nil
      source = @data.to_a if source.nil?

      new_vector = 
      case dtype
      when :array   then Daru::Accessors::ArrayWrapper.new(source, self)
      when :nmatrix then Daru::Accessors::NMatrixWrapper.new(source, self, nm_dtype)
      when :gsl then Daru::Accessors::GSLWrapper.new(source, self)
      when :mdarray then raise NotImplementedError, "MDArray not yet supported."
      else raise "Unknown dtype #{dtype}"
      end

      @dtype = dtype || :array
      new_vector
    end

    def named_index_for index
      if @index.include? index
        index
      elsif @index.key index
        @index.key index
      else
        raise IndexError, "Specified index #{index} does not exist."
      end
    end

    def index_for index
      if @index.include?(index)
        @index[index]
      elsif index.is_a?(Numeric)
        index
      end
    end

    def set_size
      @size = @data.size
    end

    def set_name name
      @name = 
      if name.is_a?(Numeric)  then name 
      elsif name.is_a?(Array) then name.join.to_sym # in case of MultiIndex tuple
      elsif name              then name.to_sym # anything but Numeric or nil
      else
        nil
      end
    end

    def set_missing_positions
      @missing_positions = []
      @index.each do |e|
        @missing_positions << e if (@missing_values.has_key?(self[e]))
      end
    end

    def create_index potential_index
      if potential_index.is_a?(Daru::MultiIndex) or potential_index.is_a?(Daru::Index)
        potential_index
      else
        Daru::Index.new(potential_index)
      end
    end

    def element_from_numeric_index location
      pos = index_for location
      pos ? @data[pos] : nil
    end

    # Setup missing_values. The missing_values instance variable is set
    # as a Hash for faster lookup times.
    def set_missing_values values_arry
      @missing_values = {}
      @missing_values[nil] = 0
      if values_arry
        values_arry.each do |e|
          @missing_values[e] = 0
        end
      end
    end
  end
end