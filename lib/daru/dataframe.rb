require_relative 'dataframe_by_row.rb'
require_relative 'dataframe_by_vector.rb'
require_relative 'io.rb'

module Daru
  class DataFrame

    class << self
      def from_csv path, opts={}, &block
        Daru::IO.from_csv path, opts, &block      
      end
    end

    attr_reader :vectors
    attr_reader :index
    attr_reader :name
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    # Arguments - source, vectors, index, name in that order. Last 3 are optional.
    def initialize source, *args
      vectors = args.shift
      index   = args.shift
      @name   = args.shift || SecureRandom.uuid

      @data = []

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

            @data << v.dv(name, @index)
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
              @data << Daru::Vector.new(vector, [], @index)

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
              @data << source[name].dup.dv(name, @index)
            end
          end

        end
      end

      set_size
      validate
    end

    def [](*names, axis)
      if axis == :vector
        access_vector *names
      elsif axis == :row
        access_row *names
      else
        raise IndexError, "Expected axis to be row or vector not #{axis}"
      end
    end

    def []=(name, axis ,vector)
      if axis == :vector
        @vectors = @vectors.re_index(@vectors + name)

        insert_vector name, vector
      elsif axis == :row        
        insert_or_modify_row name, vector
      else
        raise IndexError, "Expected axis to be row or vector, not #{axis}."
      end
    end

    def vector
      Daru::DataFrameByVector.new(self)
    end

    def row
      Daru::DataFrameByRow.new(self)
    end

    def dup
      src = {}
      @vectors.each do |vector|
        src[vector] = @data[@vectors[vector]]
      end

      Daru::DataFrame.new src, @vectors.dup, @index.dup, @name
    end

    def each_vector(&block)
      @data.each(&block)

      self
    end

    def each_vector_with_index(&block)
      @vectors.each do |vector|
        yield @data[@vectors[vector]], vector
      end 

      self
    end

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
      @index.each do |index|
        keep_row = yield access_row(index)

        delete_row index unless keep_row
      end
    end

    def keep_vector_if &block
      @vectors.each do |vector|
        keep_vector = yield @data[@vectors[vector]], vector
        
        delete_vector vector unless keep_vector
      end
    end

    def has_vector? name
      !!@vectors[name]
    end

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

    def to_html threshold=15
      html = '<table><tr><th></th>'

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

    def inspect spacing=10, threshold=15
      longest = [@vectors.map(&:to_s).map(&:size).max, 
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

      row_num = 1

      self.each_row_with_index do |row, index|
        content += sprintf formatter, index.to_s, *row.to_hash.values.map { |e| (e || 'nil').to_s }

        row_num += 1
        if row_num > threshold
          dots = []

          (@vectors.size + 1).times { dots << "..." }
          content += sprint formatter, *dots
          break
        end
      end

      content += "\n"

      content
    end

    def == other
      @index == other.index and @size == other.size and @vectors.all? { |vector|
                            self[vector, :vector] == other[vector, :vector] }
    end

    def method_missing(name, *args, &block)
      if md = name.match(/(.+)\=/)
        insert_vector name[/(.+)\=/].delete("="), args[0]
      elsif self.has_vector? name
        self[name, :vector]
      else
        super(name, *args)
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

      Daru::DataFrame.new new_vcs, new_vcs.keys, @index, @name
    end

    def insert_vector name, vector
      if @vectors.include? name
        validate_vector_indexes vector if vector.is_a?(Daru::Vector)

        v = vector.dv(name, @index)

        @data[@vectors[name]] = vector.dv(name, @index)
      else
        raise Exception, "Vector named #{name} not found in Index."
      end
    end

    def access_row *names
      unless names[1]
        row = []

        @vectors.each do |vector|
          row << @data[@vectors[vector]][names[0]]
        end

        if @index.include? names[0]
          name = names[0]
        elsif @index.key names[0]
          name = @index.key names[0]
        else
          raise IndexError, "Specified row #{names[0]} does not exist."
        end

        Daru::Vector.new name, row, @vectors
      else
        # TODO: Access multiple rows
      end
    end

    def insert_or_modify_row name, vector      
      if @index.include? name
        validate_vector_indexes vector, @vectors if vector.is_a?(Daru::Vector)

        v = vector.dv(name, @vectors)

        @vectors.each do |vector|
          @data[@vectors[vector]][name] = v[vector]
        end
      else
        @index = @index.re_index(@index + name)

        validate_vector_indexes vector, @vectors if vector.is_a?(Daru::Vector)

        v = vector.dv(name, @vectors)

        @vectors.each do |vector|
          @data[@vectors[vector]].concat v[vector], name
        end
      end

      set_size
    end

    def create_empty_vectors
      @vectors.each do |name|
        @data << Daru::Vector.new(name, [], @index)
      end
    end

    def validate_labels
      raise IndexError, "Expected equal number of vectors for number of Hash pairs" if 
        @vectors.size != @data.size

      raise IndexError, "Expected number of indexes same as number of rows" if
        @index.size != @data[0].size
    end

    def validate_vector_sizes
      @data.each do |vector|
        raise IndexError, "Expected vectors with equal length" if vector.size != @size
      end
    end

    def validate_vector_indexes single_vector=nil, index=nil
      index = @index if index.nil?

      if single_vector.nil?
        @data.each do |vector|
          raise NotImplementedError, "Expected matching indexes in all vectors. DataFrame with mismatched indexes not implemented yet." unless 
            vector.index == index 
        end
      else
        raise IndexError, "Expected same index as DataFrame" unless 
          single_vector.index == index
      end
    end

    def validate
      # TODO: [IMP] when vectors of different dimensions are specified, they should
      # be inserted into the dataframe by inserting nils wherever necessary.
      validate_labels
      validate_vector_indexes 
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