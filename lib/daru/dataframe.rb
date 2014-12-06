require_relative 'accessors/dataframe_by_row.rb'
require_relative 'accessors/dataframe_by_vector.rb'
require_relative 'maths/arithmetic/dataframe.rb'
require_relative 'maths/statistics/dataframe.rb'
require_relative 'plotting/dataframe.rb'
require_relative 'io/io.rb'

module Daru
  class DataFrame

    include Daru::Maths::Arithmetic::DataFrame
    include Daru::Maths::Statistics::DataFrame
    include Daru::Plotting::DataFrame

    class << self
      # Load data from a CSV file. 
      # Arguments - path, options, block(optional)
      # 
      # Accepts a block for pre-conditioning of CSV data if any.
      def from_csv path, opts={}, &block
        Daru::IO.from_csv path, opts, &block      
      end

      # Create DataFrame by specifying rows as an Array of Arrays or Array of
      # Daru::Vector objects.
      def rows source, opts={}
        if source.all? { |v| v.size == source[0].size }
          first = source[0]
          index = []
          order =
          unless opts[:order]
            if first.is_a?(Daru::Vector) # assume that all are Vectors only
              source.each { |vec| index << vec.name }
              first.index.to_a
            elsif first.is_a?(Array)
              Array.new(first.size) { |i| i.to_s }
            end
          else
            opts[:order]
          end

          opts[:order] = order
          df           = Daru::DataFrame.new({}, opts)
          source.each_with_index do |row,idx|
            df[(index[idx] || idx), :row] = row
          end
        else
          raise SizeError, "All vectors must have same length"
        end

        df
      end
    end

    # The vectors (columns) index of the DataFrame
    attr_reader :vectors

    # The index of the rows of the DataFrame
    attr_reader :index

    # The name of the DataFrame
    attr_reader :name

    # The number of rows present in the DataFrame
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    # Arguments - source, vectors, index, name.
    # 
    # == Usage
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [6,7,8,9]}, order: [:b, :a], 
    #     index: [:a, :b, :c, :d], name: :spider_man)
    # 
    #   # => 
    #   # <Daru::DataFrame:80766980 @name = spider_man @size = 4>
    #   #             b          a 
    #   #  a          6          1 
    #   #  b          7          2 
    #   #  c          8          3 
    #   #  d          9          4 
    def initialize source, opts={}
      vectors = opts[:order]
      index   = opts[:index]
      @dtype  = opts[:dtype] || Array
      @name   = (opts[:name] || SecureRandom.uuid).to_sym
      @data   = []

      if source.empty?
        @vectors = Daru::Index.new vectors
        @index   = Daru::Index.new index
        create_empty_vectors
      else
        case source
        when Array
          if vectors.nil?
            @vectors = Daru::Index.new source[0].keys.map(&:to_sym)
          else
            @vectors = Daru::Index.new (vectors + (source[0].keys - vectors)).uniq.map(&:to_sym)
          end

          if index.nil?
            @index = Daru::Index.new source.size
          else
            @index = Daru::Index.new index
          end

          @vectors.each do |name|
            v = []
            source.each do |hsh|
              v << (hsh[name] || hsh[name.to_s])
            end

            @data << v.dv(name, @index, @dtype)
          end
        when Hash
          create_vectors_index_with vectors, source
          if all_daru_vectors_in_source? source
            if !index.nil?
              @index = index.to_index
            elsif all_vectors_have_equal_indexes? source
              @index = source.values[0].index.dup
            else
              all_indexes = []
              source.each_value do |vector|
                all_indexes << vector.index.to_a
              end
              # sort only if missing indexes detected
              all_indexes.flatten!.uniq!.sort!

              @index = Daru::Index.new all_indexes
            end
            @vectors.each do |vector|
              @data << Daru::Vector.new([], name: vector, index: @index, dtype: @dtype)

              @index.each do |idx|
                begin
                  @data[@vectors[vector]][idx] = source[vector][idx]                   
                rescue IndexError
                  # If the index is not present in the vector under consideration
                  # (in source) then an error is raised. Put a nil in that place if
                  # that is the case.
                  @data[@vectors[vector]][idx] = nil                  
                end
              end
            end
          else   
            index = source.values[0].size if index.nil?
            if index.is_a?(Daru::Index)
              @index   = index.to_index
            else
              @index   = Daru::Index.new index     
            end

            @vectors.each do |name|
              @data << source[name].dup.dv(name, @index, @dtype)
            end
          end
        end
      end

      set_size
      validate
    end

    # Access row or vector. Specify name of row/vector followed by axis(:row, :vector).
    # Use of this method is not recommended for accessing rows or vectors.
    # Use df.row[:a] for accessing row with index ':a' or df.vector[:vec] for
    # accessing vector with index ':vec'
    def [](*names, axis)
      if axis == :vector
        access_vector *names
      elsif axis == :row
        access_row *names
      else
        raise IndexError, "Expected axis to be row or vector not #{axis}"
      end
    end

    # Insert a new row/vector of the specified name or modify a previous row.
    # Instead of using this method directly, use df.row[:a] = [1,2,3] to set/create
    # a row ':a' to [1,2,3], or df.vector[:vec] = [1,2,3] for vectors.
    # 
    # In case a Daru::Vector is specified after the equality the sign, the indexes
    # of the vector will be matched against the row/vector indexes of the DataFrame
    # before an insertion is performed. Unmatched indexes will be set to nil.
    def []=(name, axis ,vector)
      if axis == :vector
        insert_or_modify_vector name, vector
      elsif axis == :row        
        insert_or_modify_row name, vector
      else
        raise IndexError, "Expected axis to be row or vector, not #{axis}."
      end
    end

    # Access a vector or set/create a vector. Refer #[] and #[]= docs for details.
    # 
    # == Usage
    #   df.vector[:a] # access vector named ':a'
    #   df.vector[:b] = [1,2,3] # set vector ':b' to [1,2,3]
    def vector
      Daru::Accessors::DataFrameByVector.new(self)
    end

    # Access a vector by name.
    def column name
      vector[name]
    end

    # Access a row or set/create a row. Refer #[] and #[]= docs for details.
    # 
    # == Usage
    #   df.row[:a] # access row named ':a'
    #   df.row[:b] = [1,2,3] # set row ':b' to [1,2,3]
    def row
      Daru::Accessors::DataFrameByRow.new(self)
    end

    # Duplicate the DataFrame entirely.
    def dup
      src = {}
      @vectors.each do |vector|
        src[vector] = @data[@vectors[vector]].dup
      end

      Daru::DataFrame.new src, order: @vectors.dup, index: @index.dup, name: @name, dtype: @dtype
    end

    # Iterate over each vector
    def each_vector(&block)
      @data.each(&block)

      self
    end

    alias_method :each_column, :each_vector

    # Iterate over each vector alongwith the name of the vector
    def each_vector_with_index(&block)
      @vectors.each do |vector|
        yield @data[@vectors[vector]], vector
      end 

      self
    end

    alias_method :each_column_with_index, :each_vector_with_index

    # Iterate over each row
    def each_row(&block)
      @index.each do |index|
        yield access_row(index)
      end

      self
    end

    def each_row_with_index(&block)
      @index.each do |index|
        yield access_row(index), index
      end

      self
    end

    # Map each vector. Returns a DataFrame whose vectors are modified according
    # to the value returned by the block.
    def map_vectors(&block)
      df = self.dup
      df.each_vector_with_index do |vector, name|
        df[name, :vector] = yield(vector)
      end

      df
    end

    def map_vectors_with_index(&block)
      df = self.dup
      df.each_vector_with_index do |vector, name|
        df[name, :vector] = yield(vector, name)
      end

      df
    end

    # Map each row
    def map_rows(&block)
      df = self.dup
      df.each_row_with_index do |row, index|
        df[index, :row] = yield(row)
      end

      df
    end

    def map_rows_with_index(&block)
      df = self.dup
      df.each_row_with_index do |row, index|
        df[index, :row] = yield(row, index)
      end

      df
    end

    # Delete a vector
    def delete_vector vector
      if @vectors.include? vector
        @data.delete_at @vectors[vector]
        @vectors = Daru::Index.new @vectors.to_a - [vector]
      else
        raise IndexError, "Vector #{vector} does not exist."
      end
    end

    def delete_row index
      idx = named_index_for index

      if @index.include? idx
        @index = (@index.to_a - [idx]).to_index
        self.each_vector do |vector|
          vector.delete_at idx
        end
      else
        raise IndexError, "Index #{index} does not exist."
      end

      set_size
    end

    def keep_row_if &block
      deletion = []

      @index.each do |index|
        keep_row = yield access_row(index)

        deletion << index unless keep_row
      end
      deletion.each { |idx| 
        delete_row idx 
      }
    end

    def keep_vector_if &block
      @vectors.each do |vector|
        keep_vector = yield @data[@vectors[vector]], vector
        
        delete_vector vector unless keep_vector
      end
    end

    # Iterates over each row and retains it in a new DataFrame if the block returns
    # true for that row.
    def filter_rows &block
      df = Daru::DataFrame.new({}, order: @vectors.to_a)
      marked = []

      @index.each do |index|
        keep_row = yield access_row(index)
        marked << index if keep_row
      end

      marked.each do |idx|
        df.row[idx] = self[idx, :row]
      end

      df
    end

    # Iterates over each vector and retains it in a new DataFrame if the block returns
    # true for that vector.
    def filter_vectors &block
      df = self.dup
      df.keep_vector_if &block

      df
    end

    # Check if a vector is present
    def has_vector? name
      !!@vectors[name]
    end

    def head quantity=10
      self[0..quantity, :row]
    end

    def tail quantity=10
      self[(@size - quantity)..@size, :row]
    end

    # def sort_by_row name
      
    # end

    # def sort_by_vector name
      
    # end
    
    # Converts the DataFrame into an array of hashes where key is vector name
    # and value is the corresponding element.
    # The 0th index of the array contains the array of hashes while the 1th
    # index contains the indexes of each row of the dataframe. Each element in
    # the index array corresponds to its row in the array of hashes, which has
    # the same index.
    def to_a
      arry = [[],[]]
      self.each_row do |row|
        arry[0] << row.to_hash
      end
      arry[1] = @index.to_a

      arry
    end

    def to_json no_index=true
      if no_index
        self.to_a[0].to_json
      else
        self.to_a.to_json
      end
    end

    # Convert to html for IRuby.
    def to_html threshold=30
      html  = '<table><tr><th></th>'
      @vectors.each { |vector| html += '<th>' + vector.to_s + '</th>' }
      html += '</tr>'

      @index.each_with_index do |index, num|
        html += '<tr>'
        html += '<td>' + index.to_s + '</td>'

        self.row[index].each do |element|
          html += '<td>' + element.to_s + '</td>'
        end

        html += '</tr>'
        if num > threshold
          html += '<tr>'
          (@vectors + 1).size.times { html += '<td>...</td>' }
          html += '</tr>'
          break
        end
      end
      html += '</table>'

      html
    end

    def to_s
      to_html
    end

    # Pretty print in a nice table format for the command line (irb)
    def inspect spacing=10, threshold=15
      longest = [@name.to_s.size,
                 @vectors.map(&:to_s).map(&:size).max, 
                 @index  .map(&:to_s).map(&:size).max,
                 @data   .map{ |v|  v.map(&:to_s).map(&:size).max }.max].max

      name      = @name || 'nil'
      content   = ""
      longest   = spacing if longest > spacing
      formatter = "\n"

      (@vectors.size + 1).times { formatter += "%#{longest}.#{longest}s " }
      content += "\n#<" + self.class.to_s + ":" + self.object_id.to_s + " @name = " + 
                    name.to_s + " @size = " + @size.to_s + ">"
      content += sprintf formatter, "" , *@vectors.map(&:to_s)
      row_num  = 1

      self.each_row_with_index do |row, index|
        content += sprintf formatter, index.to_s, *row.to_hash.values.map { |e| (e || 'nil').to_s }
        row_num += 1
        if row_num > threshold
          dots = []

          (@vectors.size + 1).times { dots << "..." }
          content += sprintf formatter, *dots
          break
        end
      end
      content += "\n"

      content
    end

    def dtype= dtype
      @dtype = dtype

      @vectors.each do |vec|
        pos = @vectors[vec]
        @data[pos] = @data[pos].coerce(@dtype)
      end
    end

    def == other
      @index == other.index and @size == other.size and @vectors.all? { |vector|
                            self[vector, :vector] == other[vector, :vector] }
    end

    def method_missing(name, *args, &block)
      if md = name.match(/(.+)\=/)
        insert_or_modify_vector name[/(.+)\=/].delete("="), args[0]
      elsif self.has_vector? name
        self[name, :vector]
      else
        super(name, *args, &block)
      end
    end

   private

    def access_vector *names
      unless names[1]
        if @vectors.include? names[0]
          return @data[@vectors[names[0]]]
        elsif @vectors.key names[0]
          return @data[names[0]]
        else
          raise IndexError, "Specified index #{names[0]} does not exist."
        end
      end
      new_vcs = {}

      names.each do |name|
        name = name.to_sym unless name.is_a?(Integer)

        new_vcs[name] = @data[@vectors[name]]
      end
      Daru::DataFrame.new new_vcs, order: new_vcs.keys, index: @index, name: @name
    end

    def access_row *names
      if names[1].nil?
        access_token = names[0]
        if access_token.is_a?(Range)
          index_arry = @index.to_a

          range = 
          if access_token.first.is_a?(Numeric)
            access_token
          else
            first_index = index_arry.index access_token.first
            last_index  = index_arry.index access_token.last

            first_index..last_index
          end

          names = index_arry[range]
        else
          row  = []
          name = named_index_for names[0]
          @vectors.each do |vector|
            row << @data[@vectors[vector]][name]
          end

          return Daru::Vector.new(row, index: @vectors, name: name, dtype: @dtype)
        end
      end
      # Access multiple rows
      rows = []
      names.each do |name|
        rows << self.row[name]
      end
      
      Daru::DataFrame.rows rows, name: @name, dtype: @dtype
    end

    def insert_or_modify_vector name, vector
      @vectors = @vectors.re_index(@vectors + name)
      v        = nil

      if vector.is_a?(Daru::Vector)
        v = Daru::Vector.new [], name: name, index: @index, dtype: @dtype
        nil_data = false
        @index.each do |idx|
          begin
            v[idx] = vector[idx]
          rescue IndexError
            v[idx] = nil
          end
        end
      else
        raise Exception, "Specified vector of length #{vector.size} cannot be inserted in DataFrame of size #{@size}" if
          @size != vector.size

        v = vector.dv(name, @index, @dtype)
      end

      @data[@vectors[name]] = v
    end

    def insert_or_modify_row name, vector      
      if @index.include? name
        v = vector.dv(name, @vectors, @dtype)

        @vectors.each do |vector|
          begin
            @data[@vectors[vector]][name] = v[vector] 
          rescue IndexError
            @data[@vectors[vector]][name] = nil
          end
        end
      else
        @index = @index.re_index(@index + name)
        v      = vector.dv(name, @vectors, @dtype)

        @vectors.each do |vector|
          begin
            @data[@vectors[vector]].concat v[vector], name     
          rescue IndexError
            @data[@vectors[vector]].concat nil, name
          end
        end
      end

      set_size
    end

    def create_empty_vectors
      @vectors.each do |name|
        @data << Daru::Vector.new([],name: name, index: @index, dtype: @dtype)
      end
    end

    def validate_labels
      raise IndexError, "Expected equal number of vectors for number of Hash pairs" if 
        @vectors and @vectors.size != @data.size

      raise IndexError, "Expected number of indexes same as number of rows" if
        @index and @data[0] and @index.size != @data[0].size
    end

    def validate_vector_sizes
      @data.each do |vector|
        raise IndexError, "Expected vectors with equal length" if vector.size != @size
      end
    end

    def validate
      # TODO: [IMP] when vectors of different dimensions are specified, they should
      # be inserted into the dataframe by inserting nils wherever necessary.
      validate_labels
      validate_vector_sizes
    end

    def all_daru_vectors_in_source? source
      source.values.all? do |vector|
        vector.is_a?(Daru::Vector)
      end
    end

    def set_size
      @size = @index.size
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

    def create_vectors_index_with vectors, source
      vectors = source.keys.sort if vectors.nil?

      if vectors.is_a?(Daru::Index)
        @vectors = vectors.to_index
      else
        @vectors = Daru::Index.new (vectors + (source.keys - vectors)).uniq.map(&:to_sym)
      end
    end

    def all_vectors_have_equal_indexes? source
      index = source.values[0].index

      source.all? do |name, vector|
        index == vector.index
      end
    end
  end
end