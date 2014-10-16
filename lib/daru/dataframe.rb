module Daru
  class DataFrame

    attr_reader :vectors

    attr_reader :fields

    attr_reader :size

    attr_reader :name

    def initialize source, fields=[], name=SecureRandom.uuid, opts={}
      @opts = opts
      set_default_opts

      if source.empty?
        create_empty_vectors_with fields
      elsif source.is_a? Array
        create_empty_vectors_with source[0].keys
        
        source.each do |hash|
          self.insert_row hash.values
        end
      else # source is a Hash
        @vectors = source.inject({}) do |acc, (k,v)|
          acc[k] = v.dv.dup
          acc
        end

        @fields = fields.empty? ? source.keys.sort : fields
      end

      @name = name

      check_length
      set_missing_vectors if @vectors.keys.size < @fields.size
      set_fields_order    if @vectors.keys.sort != @fields.sort
      set_vector_names
    end

    def self.from_csv file, opts={}
      opts[:col_sep]           ||= ','
      opts[:headers]           ||= true
      opts[:converters]        ||= :numeric
      opts[:header_converters] ||= :symbol

      csv = CSV.open file, 'r', opts

      yield csv if block_given?

      first = true
      df    = nil

      csv.each do |row|
        if first
          df = Daru::DataFrame.new({}, csv.headers)
          first = false
        end

        df.insert_row row
      end

      df
    end

    def column name
      @vectors[name]
    end

    def delete_vector name
      @vectors.delete name
      @fields.delete name
    end

    alias_method :delete, :delete_vector

    def delete_row index
      # TODO: Make this work with NMatrix and MDArray
      raise "Expected index less than size." if index > @size

      @fields.each do |field|
        @vectors[field].delete index
      end
    end

    def filter_rows name=self.name, &block
      df = DataFrame.new({}, @fields, name)

      self.each_row do |row|
        keep_row = yield row

        df.insert_row(row.values) if keep_row
      end

      df
    end

    def [] *name
      unless name[1]
        return column(name[0])
      end

      h = {}
      req_fields = @fields & name

      req_fields.each do |f|
        h[f] = @vectors[f]
      end

      DataFrame.new h, req_fields, @name
    end

    def == other
      @name == other.name and @vectors == other.vectors and 
      @size == other.size and @fields  == other.fields 
    end

    def []= name, vector
      insert_vector name, vector
    end

    def row index
      raise Exception, "Expected index to be within bounds" if index > @size

      row = {}
      self.each_vector do |column|
        row[column.name] = column[index]
      end

      row
    end

    def has_vector? vector
      !!@vectors[vector]
    end

    def each_row(&block)
      0.upto(@size-1) do |index|
        r = row(index)
        yield r

        @fields.each { |f| @vectors[f][index] = r[f] }
        # TODO: Make this faaassst.
      end
    end

    def each_row_with_index(&block)
      0.upto(@size-1) do |index|
        r = row(index)
        yield r, index

        @fields.each { |f| @vectors[f][index] = r[f] }
      end
    end

    def each_vector(&block)
      @fields.each do |field|
        yield @vectors[field]
      end

      self
    end

    def each_vector_with_name(&block)
      @fields.each do |field|
        yield @vectors[field], field
      end

      self
    end

    def insert_vector name, vector
      raise Exeception, "Expected vector size to be same as DataFrame\ 
        size." if vector.size != self.size

      @vectors.merge!({name.to_sym => vector.dv(name.to_sym)})

      @fields << name unless @fields.include? name
    end

    def insert_row row
      raise Exception, "Expected new row.size equal to width of DataFrame" if 
        row.size != @fields.size

      @fields.each_with_index do |field, index|
        @vectors[field] << row[index]
      end

      @size = 0 if @size.nil?

      @size += 1
    end

    def to_html(threshold=15)
      html = '<table>'

      html += '<tr>'
      @fields.each { |f| html.concat('<th>' + f.to_s + '</th>') }
      html += '</tr>'

      self.each_row_with_index do |row, index|
        break if index > threshold and index <= @size
        html += '<tr>'
        row.each_value { |val| html.concat('<td>' + val.to_s + '</td>') }
        html += '</tr>'
        if index == threshold
          html += '<tr>'
          row.size.times { html.concat('<td>...</td>') }
          html += '</tr>'
        end
      end

      html += '</table>'
    end

    def to_s
      to_html
    end

    def to_a
      data = []

      0.upto(@size - 1) do |index|
        data << self.row(index)
      end

      data
    end

    def to_json *args
      self.to_a.to_json
    end

    def method_missing(name, *args)
      if md = name.match(/(.+)\=/)
        insert_vector name[/(.+)\=/].delete("="), args[0]
      elsif self.has_vector? name
        column name
      else
        super(name, *args)
      end
    end

   private
    def check_length
      size = nil

      @vectors.each_value do |vector|
        if size.nil?
          size = vector.size
        elsif size != vector.size
          raise Exception, "Expected all vectors to be of the same size. Vector \ 
            #{vector.name} is of size #{vector.size} and another one of size #{size}"    
        end
      end

      @size = size
    end

    def set_fields_order # vectors more than specified fields
      @fields = @fields & @vectors.keys
      @fields += @vectors.keys.sort - @fields
    end

    # Writes names specified in the hash to the actual name of the vector.
    # Will over-ride any previous name assigned to the vector.
    def set_vector_names      
      @fields.each do |name|
        @vectors[name].name = name
      end
    end

    def set_default_opts
      # Future proofing
    end

    def set_missing_vectors
      missing_fields = @fields - @vectors.keys

      missing_fields.each do |field|
        @vectors[field] = ([nil]*@size).dv
        @fields << field
      end
    end

    def create_empty_vectors_with fields
      @vectors = fields.inject({}) do |a,x| 
        a[x.to_sym] = Daru::Vector.new [], x.to_sym 
        a
      end

      @fields  = fields.map { |f| f.to_sym}
    end
  end
end