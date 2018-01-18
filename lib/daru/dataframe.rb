require 'daru/accessors/dataframe_by_row.rb'
require 'daru/maths/arithmetic/dataframe.rb'
require 'daru/maths/statistics/dataframe.rb'
require 'daru/plotting/gruff.rb'
require 'daru/plotting/nyaplot.rb'
require 'daru/io/io.rb'

module Daru
  class DataFrame # rubocop:disable Metrics/ClassLength
    include Daru::Maths::Arithmetic::DataFrame
    include Daru::Maths::Statistics::DataFrame
    # TODO: Remove this line but its causing erros due to unkown reason
    include Daru::Plotting::DataFrame::NyaplotLibrary if Daru.has_nyaplot?
    extend Gem::Deprecate

    class << self
      # Load data from a CSV file. Specify an optional block to grab the CSV
      # object and pre-condition it (for example use the `convert` or
      # `header_convert` methods).
      #
      # == Arguments
      #
      # * path - Local path / Remote URL of the file to load specified as a String.
      #
      # == Options
      #
      # Accepts the same options as the Daru::DataFrame constructor and CSV.open()
      # and uses those to eventually construct the resulting DataFrame.
      #
      # == Verbose Description
      #
      # You can specify all the options to the `.from_csv` function that you
      # do to the Ruby `CSV.read()` function, since this is what is used internally.
      #
      # For example, if the columns in your CSV file are separated by something
      # other that commas, you can use the `:col_sep` option. If you want to
      # convert numeric values to numbers and not keep them as strings, you can
      # use the `:converters` option and set it to `:numeric`.
      #
      # The `.from_csv` function uses the following defaults for reading CSV files
      # (that are passed into the `CSV.read()` function):
      #
      #   {
      #     :col_sep           => ',',
      #     :converters        => :numeric
      #   }
      def from_csv path, opts={}, &block
        Daru::IO.from_csv path, opts, &block
      end

      # Read data from an Excel file into a DataFrame.
      #
      # == Arguments
      #
      # * path - Path of the file to be read.
      #
      # == Options
      #
      # *:worksheet_id - ID of the worksheet that is to be read.
      def from_excel path, opts={}, &block
        Daru::IO.from_excel path, opts, &block
      end

      # Read a database query and returns a Dataset
      #
      # @param dbh [DBI::DatabaseHandle, String] A DBI connection OR Path to a SQlite3 database.
      # @param query [String] The query to be executed
      #
      # @return A dataframe containing the data resulting from the query
      #
      # USE:
      #
      #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
      #  Daru::DataFrame.from_sql(dbh, "SELECT * FROM test")
      #
      #  #Alternatively
      #
      #  require 'dbi'
      #  Daru::DataFrame.from_sql("path/to/sqlite.db", "SELECT * FROM test")
      def from_sql dbh, query
        Daru::IO.from_sql dbh, query
      end

      # Read a dataframe from AR::Relation
      #
      # @param relation [ActiveRecord::Relation] An AR::Relation object from which data is loaded
      # @param fields [Array] Field names to be loaded (optional)
      #
      # @return A dataframe containing the data loaded from the relation
      #
      # USE:
      #
      #   # When Post model is defined as:
      #   class Post < ActiveRecord::Base
      #     scope :active, -> { where.not(published_at: nil) }
      #   end
      #
      #   # You can load active posts into a dataframe by:
      #   Daru::DataFrame.from_activerecord(Post.active, :title, :published_at)
      def from_activerecord relation, *fields
        Daru::IO.from_activerecord relation, *fields
      end

      # Read the database from a plaintext file. For this method to work,
      # the data should be present in a plain text file in columns. See
      # spec/fixtures/bank2.dat for an example.
      #
      # == Arguments
      #
      # * path - Path of the file to be read.
      # * fields - Vector names of the resulting database.
      #
      # == Usage
      #
      #   df = Daru::DataFrame.from_plaintext 'spec/fixtures/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6]
      def from_plaintext path, fields
        Daru::IO.from_plaintext path, fields
      end

      # Read the table data from a remote html file. Please note that this module
      # works only for static table elements on a HTML page, and won't work in
      # cases where the data is being loaded into the HTML table by Javascript.
      #
      # By default - all <th> tag elements in the first proper row are considered
      # as the order, and all the <th> tag elements in the first column are
      # considered as the index.
      #
      # == Arguments
      #
      # * path [String] - URL of the target HTML file.
      # * fields [Hash] -
      #
      #   +:match+ - A *String* to match and choose a particular table(s) from multiple tables of a HTML page.
      #
      #   +:order+ - An *Array* which would act as the user-defined order, to override the parsed *Daru::DataFrame*.
      #
      #   +:index+ - An *Array* which would act as the user-defined index, to override the parsed *Daru::DataFrame*.
      #
      #   +:name+ - A *String* that manually assigns a name to the scraped *Daru::DataFrame*, for user's preference.
      #
      # == Returns
      # An Array of +Daru::DataFrame+s, with each dataframe corresponding to a
      # HTML table on that webpage.
      #
      # == Usage
      #   dfs = Daru::DataFrame.from_html("http://www.moneycontrol.com/", match: "Sun Pharma")
      #   dfs.count
      #   # => 4
      #
      #   dfs.first
      #   #
      #   # => <Daru::DataFrame(5x4)>
      #   #          Company      Price     Change Value (Rs
      #   #     0 Sun Pharma     502.60     -65.05   2,117.87
      #   #     1   Reliance    1356.90      19.60     745.10
      #   #     2 Tech Mahin     379.45     -49.70     650.22
      #   #     3        ITC     315.85       6.75     621.12
      #   #     4       HDFC    1598.85      50.95     553.91
      def from_html path, fields={}
        Daru::IO.from_html path, fields
      end

      # Create DataFrame by specifying rows as an Array of Arrays or Array of
      # Daru::Vector objects.
      def rows source, opts={}
        raise SizeError, 'All vectors must have same length' \
          unless source.all? { |v| v.size == source.first.size }

        opts[:order] ||= guess_order(source)

        if ArrayHelper.array_of?(source, Array) || source.empty?
          DataFrame.new(source.transpose, opts)
        elsif ArrayHelper.array_of?(source, Vector)
          from_vector_rows(source, opts)
        else
          raise ArgumentError, "Can't create DataFrame from #{source}"
        end
      end

      # Generates a new dataset, using three vectors
      # - Rows
      # - Columns
      # - Values
      #
      # For example, you have these values
      #
      #   x   y   v
      #   a   a   0
      #   a   b   1
      #   b   a   1
      #   b   b   0
      #
      # You obtain
      #   id  a   b
      #    a  0   1
      #    b  1   0
      #
      # Useful to process outputs from databases
      def crosstab_by_assignation rows, columns, values
        raise 'Three vectors should be equal size' if
          rows.size != columns.size || rows.size!=values.size

        data = Hash.new { |h, col|
          h[col] = rows.factors.map { |r| [r, nil] }.to_h
        }
        columns.zip(rows, values).each { |c, r, v| data[c][r] = v }

        # FIXME: in fact, WITHOUT this line you'll obtain more "right"
        # data: with vectors having "rows" as an index...
        data = data.map { |c, r| [c, r.values] }.to_h
        data[:_id] = rows.factors

        DataFrame.new(data)
      end

      private

      def guess_order source
        case source.first
        when Vector # assume that all are Vectors
          source.first.index.to_a
        when Array
          Array.new(source.first.size, &:to_s)
        end
      end

      def from_vector_rows source, opts
        index = source.map(&:name)
                      .each_with_index.map { |n, i| n || i }
        index = ArrayHelper.recode_repeated(index)

        DataFrame.new({}, opts).tap do |df|
          source.each_with_index do |row, idx|
            df[index[idx] || idx, :row] = row
          end
        end
      end
    end

    # The vectors (columns) index of the DataFrame
    attr_reader :vectors
    # TOREMOVE
    attr_reader :data

    # The index of the rows of the DataFrame
    attr_reader :index

    # The name of the DataFrame
    attr_reader :name

    # The number of rows present in the DataFrame
    attr_reader :size

    # DataFrame basically consists of an Array of Vector objects.
    # These objects are indexed by row and column by vectors and index Index objects.
    #
    # == Arguments
    #
    # * source - Source from the DataFrame is to be initialized. Can be a Hash
    # of names and vectors (array or Daru::Vector), an array of arrays or
    # array of Daru::Vectors.
    #
    # == Options
    #
    # +:order+ - An *Array*/*Daru::Index*/*Daru::MultiIndex* containing the order in
    # which Vectors should appear in the DataFrame.
    #
    # +:index+ - An *Array*/*Daru::Index*/*Daru::MultiIndex* containing the order
    # in which rows of the DataFrame will be named.
    #
    # +:name+  - A name for the DataFrame.
    #
    # +:clone+ - Specify as *true* or *false*. When set to false, and Vector
    # objects are passed for the source, the Vector objects will not duplicated
    # when creating the DataFrame. Will have no effect if Array is passed in
    # the source, or if the passed Daru::Vectors have different indexes.
    # Default to *true*.
    #
    # == Usage
    #
    #   df = Daru::DataFrame.new
    #   # =>
    #   # <Daru::DataFrame(0x0)>
    #   # Creates an empty DataFrame with no rows or columns.
    #
    #   df = Daru::DataFrame.new({}, order: [:a, :b])
    #   #<Daru::DataFrame(0x2)>
    #     a   b
    #   # Creates a DataFrame with no rows and columns :a and :b
    #
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
    #
    #   df = Daru::DataFrame.new([[1,2,3,4],[6,7,8,9]], name: :bat_man)
    #
    #   # =>
    #   # #<Daru::DataFrame: bat_man (4x2)>
    #   #             0          1
    #   #  0          1          6
    #   #  1          2          7
    #   #  2          3          8
    #   #  3          4          9
    #
    #   # Dataframe having Index name
    #
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [6,7,8,9]}, order: [:b, :a],
    #     index: Daru::Index.new([:a, :b, :c, :d], name: 'idx_name'),
    #     name: :spider_man)
    #
    #   # =>
    #   # <Daru::DataFrame:80766980 @name = spider_man @size = 4>
    #   # idx_name            b          a
    #   #        a          6          1
    #   #        b          7          2
    #   #        c          8          3
    #   #        d          9          4
    #
    #
    #   idx = Daru::Index.new [100, 99, 101, 1, 2], name: "s1"
    #   => #<Daru::Index(5): s1 {100, 99, 101, 1, 2}>
    #
    #   df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5],
    #     c: [11,22,33,44,55]},
    #     order: [:a, :b, :c],
    #     index: idx)
    #    # =>
    #    #<Daru::DataFrame(5x3)>
    #    #   s1   a   b   c
    #    #  100   1  11  11
    #    #   99   2  12  22
    #    #  101   3  13  33
    #    #    1   4  14  44
    #    #    2   5  15  55

    def initialize source={}, opts={} # rubocop:disable Metrics/MethodLength
      vectors, index = opts[:order], opts[:index] # FIXME: just keyword arges after Ruby 2.1
      @data = []
      @name = opts[:name]

      case source
      when ->(s) { s.empty? }
        @vectors = Index.coerce vectors
        @index   = Index.coerce index
        create_empty_vectors
      when Array
        initialize_from_array source, vectors, index, opts
      when Hash
        initialize_from_hash source, vectors, index, opts
      end

      set_size
      validate
      update
      self.plotting_library = Daru.plotting_library
    end

    def plotting_library= lib
      case lib
      when :gruff, :nyaplot
        @plotting_library = lib
        if Daru.send("has_#{lib}?".to_sym)
          extend Module.const_get(
            "Daru::Plotting::DataFrame::#{lib.to_s.capitalize}Library"
          )
        end
      else
        raise ArguementError, "Plotting library #{lib} not supported. "\
          'Supported libraries are :nyaplot and :gruff'
      end
    end

    # Access row or vector. Specify name of row/vector followed by axis(:row, :vector).
    # Defaults to *:vector*. Use of this method is not recommended for accessing
    # rows. Use df.row[:a] for accessing row with index ':a'.
    def [](*names)
      axis = extract_axis(names, :vector)
      dispatch_to_axis axis, :access, *names
    end

    # Retrive rows by positions
    # @param [Array<Integer>] positions of rows to retrive
    # @return [Daru::Vector, Daru::DataFrame] vector for single position and dataframe for multiple positions
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'b', 'c']
    #   })
    #   df.row_at 1, 2
    #   # => #<Daru::DataFrame(2x2)>
    #   #       a   b
    #   #   1   2   b
    #   #   2   3   c
    def row_at *positions
      original_positions = positions
      positions = coerce_positions(*positions, nrows)
      validate_positions(*positions, nrows)

      if positions.is_a? Integer
        return Daru::Vector.new @data.map { |vec| vec.at(*positions) },
          index: @vectors
      else
        new_rows = @data.map { |vec| vec.at(*original_positions) }
        return Daru::DataFrame.new new_rows,
          index: @index.at(*original_positions),
          order: @vectors
      end
    end

    # Set rows by positions
    # @param [Array<Integer>] positions positions of rows to set
    # @param [Array, Daru::Vector] vector vector to be assigned
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'b', 'c']
    #   })
    #   df.set_row_at [0, 1], ['x', 'x']
    #   df
    #   #=> #<Daru::DataFrame(3x2)>
    #   #       a   b
    #   #   0   x   x
    #   #   1   x   x
    #   #   2   3   c
    def set_row_at positions, vector
      validate_positions(*positions, nrows)
      vector =
        if vector.is_a? Daru::Vector
          vector.reindex @vectors
        else
          Daru::Vector.new vector
        end

      raise SizeError, 'Vector length should match row length' if
        vector.size != @vectors.size

      @data.each_with_index do |vec, pos|
        vec.set_at(positions, vector.at(pos))
      end
      @index = @data[0].index
      set_size
    end

    # Retrive vectors by positions
    # @param [Array<Integer>] positions of vectors to retrive
    # @return [Daru::Vector, Daru::DataFrame] vector for single position and dataframe for multiple positions
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'b', 'c']
    #   })
    #   df.at 0
    #   # => #<Daru::Vector(3)>
    #   #       a
    #   #   0   1
    #   #   1   2
    #   #   2   3
    def at *positions
      if AXES.include? positions.last
        axis = positions.pop
        return row_at(*positions) if axis == :row
      end

      original_positions = positions
      positions = coerce_positions(*positions, ncols)
      validate_positions(*positions, ncols)

      if positions.is_a? Integer
        @data[positions].dup
      else
        Daru::DataFrame.new positions.map { |pos| @data[pos].dup },
          index: @index,
          order: @vectors.at(*original_positions),
          name: @name
      end
    end

    # Set vectors by positions
    # @param [Array<Integer>] positions positions of vectors to set
    # @param [Array, Daru::Vector] vector vector to be assigned
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'b', 'c']
    #   })
    #   df.set_at [0], ['x', 'y', 'z']
    #   df
    #   #=> #<Daru::DataFrame(3x2)>
    #   #       a   b
    #   #   0   x   a
    #   #   1   y   b
    #   #   2   z   c
    def set_at positions, vector
      if positions.last == :row
        positions.pop
        return set_row_at(positions, vector)
      end

      validate_positions(*positions, ncols)
      vector =
        if vector.is_a? Daru::Vector
          vector.reindex @index
        else
          Daru::Vector.new vector
        end

      raise SizeError, 'Vector length should match index length' if
        vector.size != @index.size

      positions.each { |pos| @data[pos] = vector }
    end

    # Insert a new row/vector of the specified name or modify a previous row.
    # Instead of using this method directly, use df.row[:a] = [1,2,3] to set/create
    # a row ':a' to [1,2,3], or df.vector[:vec] = [1,2,3] for vectors.
    #
    # In case a Daru::Vector is specified after the equality the sign, the indexes
    # of the vector will be matched against the row/vector indexes of the DataFrame
    # before an insertion is performed. Unmatched indexes will be set to nil.
    def []=(*args)
      vector = args.pop
      axis = extract_axis(args)
      names = args

      dispatch_to_axis axis, :insert_or_modify, names, vector
    end

    def add_row row, index=nil
      self.row[*(index || @size)] = row
    end

    def add_vector n, vector
      self[n] = vector
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
    #
    # == Arguments
    #
    # * +vectors_to_dup+ - An Array specifying the names of Vectors to
    # be duplicated. Will duplicate the entire DataFrame if not specified.
    def dup vectors_to_dup=nil
      vectors_to_dup = @vectors.to_a unless vectors_to_dup

      src = vectors_to_dup.map { |vec| @data[@vectors.pos(vec)].dup }
      new_order = Daru::Index.new(vectors_to_dup)

      Daru::DataFrame.new src, order: new_order, index: @index.dup, name: @name, clone: true
    end

    # Only clone the structure of the DataFrame.
    def clone_structure
      Daru::DataFrame.new([], order: @vectors.dup, index: @index.dup, name: @name)
    end

    # Returns a 'view' of the DataFrame, i.e the object ID's of vectors are
    # preserved.
    #
    # == Arguments
    #
    # +vectors_to_clone+ - Names of vectors to clone. Optional. Will return
    # a view of the whole data frame otherwise.
    def clone *vectors_to_clone
      vectors_to_clone.flatten! if ArrayHelper.array_of?(vectors_to_clone, Array)
      vectors_to_clone = @vectors.to_a if vectors_to_clone.empty?

      h = vectors_to_clone.map { |vec| [vec, self[vec]] }.to_h
      Daru::DataFrame.new(h, clone: false, order: vectors_to_clone, name: @name)
    end

    # Returns a 'shallow' copy of DataFrame if missing data is not present,
    # or a full copy of only valid data if missing data is present.
    def clone_only_valid
      if include_values?(*Daru::MISSING_VALUES)
        reject_values(*Daru::MISSING_VALUES)
      else
        clone
      end
    end

    # Creates a new duplicate dataframe containing only rows
    # without a single missing value.
    def dup_only_valid vecs=nil
      rows_with_nil = @data.map { |vec| vec.indexes(*Daru::MISSING_VALUES) }
                           .inject(&:concat)
                           .uniq

      row_indexes = @index.to_a
      (vecs.nil? ? self : dup(vecs)).row[*(row_indexes - rows_with_nil)]
    end
    deprecate :dup_only_valid, :reject_values, 2016, 10

    # Returns a dataframe in which rows with any of the mentioned values
    #   are ignored.
    # @param [Array] values to reject to form the new dataframe
    # @return [Daru::DataFrame] Data Frame with only rows which doesn't
    #   contain the mentioned values
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
    #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
    #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
    #   }, index: 11..18)
    #   df.reject_values nil, Float::NAN
    #   # => #<Daru::DataFrame(2x3)>
    #   #       a   b   c
    #   #   11   1   a   a
    #   #   18   7   8   7
    def reject_values(*values)
      positions =
        size.times.to_a - @data.flat_map { |vec| vec.positions(*values) }
      # Handle the case when positions size is 1 and #row_at wouldn't return a df
      if positions.size == 1
        pos = positions.first
        row_at(pos..pos)
      else
        row_at(*positions)
      end
    end

    # Replace specified values with given value
    # @param [Array] old_values values to replace with new value
    # @param [object] new_value new value to replace with
    # @return [Daru::DataFrame] Data Frame itself with old values replace
    #   with new value
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
    #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
    #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
    #   }, index: 11..18)
    #   df.replace_values nil, Float::NAN
    #   # => #<Daru::DataFrame(8x3)>
    #   #       a   b   c
    #   #   11   1   a   a
    #   #   12   2   b NaN
    #   #   13   3 NaN   3
    #   #   14 NaN NaN   4
    #   #   15 NaN NaN   3
    #   #   16 NaN   3   5
    #   #   17   1   5 NaN
    #   #   18   7   8   7
    def replace_values old_values, new_value
      @data.each { |vec| vec.replace_values old_values, new_value }
      self
    end

    # Rolling fillna
    # replace all Float::NAN and NIL values with the preceeding or following value
    #
    # @param direction [Symbol] (:forward, :backward) whether replacement value is preceeding or following
    #
    # @example
    #   df = Daru::DataFrame.new({
    #    a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
    #    b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   nil],
    #    c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
    #   })
    #
    #   => #<Daru::DataFrame(8x3)>
    #        a   b   c
    #    0   1   a   a
    #    1   2   b NaN
    #    2   3 nil   3
    #    3 nil NaN   4
    #    4 NaN nil   3
    #    5 nil   3   5
    #    6   1   5 nil
    #    7   7 nil   7
    #
    #   2.3.3 :068 > df.rolling_fillna(:forward)
    #   => #<Daru::DataFrame(8x3)>
    #        a   b   c
    #    0   1   a   a
    #    1   2   b   a
    #    2   3   b   3
    #    3   3   b   4
    #    4   3   b   3
    #    5   3   3   5
    #    6   1   5   5
    #    7   7   5   7
    #
    def rolling_fillna!(direction=:forward)
      @data.each { |vec| vec.rolling_fillna!(direction) }
      self
    end

    def rolling_fillna(direction=:forward)
      dup.rolling_fillna!(direction)
    end

    # Return unique rows by vector specified or all vectors
    #
    # @param vtrs [String][Symbol] vector names(s) that should be considered
    #
    # @example
    #
    #    => #<Daru::DataFrame(6x2)>
    #         a   b
    #     0   1   a
    #     1   2   b
    #     2   3   c
    #     3   4   d
    #     2   3   c
    #     3   4   f
    #
    #    2.3.3 :> df.unique
    #    => #<Daru::DataFrame(5x2)>
    #         a   b
    #     0   1   a
    #     1   2   b
    #     2   3   c
    #     3   4   d
    #     3   4   f
    #
    #    2.3.3 :> df.unique(:a)
    #    => #<Daru::DataFrame(5x2)>
    #         a   b
    #     0   1   a
    #     1   2   b
    #     2   3   c
    #     3   4   d
    #
    def uniq(*vtrs)
      vecs = vtrs.empty? ? vectors.map(&:to_s) : Array(vtrs)
      grouped = group_by(vecs)
      indexes = grouped.groups.values.map { |v| v[0] }.sort
      row[*indexes]
    end

    # Iterate over each index of the DataFrame.
    def each_index &block
      return to_enum(:each_index) unless block_given?

      @index.each(&block)

      self
    end

    # Iterate over each vector
    def each_vector(&block)
      return to_enum(:each_vector) unless block_given?

      @data.each(&block)

      self
    end

    alias_method :each_column, :each_vector

    # Iterate over each vector alongwith the name of the vector
    def each_vector_with_index
      return to_enum(:each_vector_with_index) unless block_given?

      @vectors.each do |vector|
        yield @data[@vectors[vector]], vector
      end

      self
    end

    alias_method :each_column_with_index, :each_vector_with_index

    # Iterate over each row
    def each_row
      return to_enum(:each_row) unless block_given?

      @index.size.times do |pos|
        yield row_at(pos)
      end

      self
    end

    def each_row_with_index
      return to_enum(:each_row_with_index) unless block_given?

      @index.each do |index|
        yield access_row(index), index
      end

      self
    end

    # Iterate over each row or vector of the DataFrame. Specify axis
    # by passing :vector or :row as the argument. Default to :vector.
    #
    # == Description
    #
    # `#each` works exactly like Array#each. The default mode for `each`
    # is to iterate over the columns of the DataFrame. To iterate over
    # rows you must pass the axis, i.e `:row` as an argument.
    #
    # == Arguments
    #
    # * +axis+ - The axis to iterate over. Can be :vector (or :column)
    # or :row. Default to :vector.
    def each axis=:vector, &block
      dispatch_to_axis axis, :each, &block
    end

    # Iterate over a row or vector and return results in a Daru::Vector.
    # Specify axis with :vector or :row. Default to :vector.
    #
    # == Description
    #
    # The #collect iterator works similar to #map, the only difference
    # being that it returns a Daru::Vector comprising of the results of
    # each block run. The resultant Vector has the same index as that
    # of the axis over which collect has iterated. It also accepts the
    # optional axis argument.
    #
    # == Arguments
    #
    # * +axis+ - The axis to iterate over. Can be :vector (or :column)
    # or :row. Default to :vector.
    def collect axis=:vector, &block
      dispatch_to_axis_pl axis, :collect, &block
    end

    # Map over each vector or row of the data frame according to
    # the argument specified. Will return an Array of the resulting
    # elements. To map over each row/vector and get a DataFrame,
    # see #recode.
    #
    # == Description
    #
    # The #map iterator works like Array#map. The value returned by
    # each run of the block is added to an Array and the Array is
    # returned. This method also accepts an axis argument, like #each.
    # The default is :vector.
    #
    # == Arguments
    #
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def map axis=:vector, &block
      dispatch_to_axis_pl axis, :map, &block
    end

    # Destructive map. Modifies the DataFrame. Each run of the block
    # must return a Daru::Vector. You can specify the axis to map over
    # as the argument. Default to :vector.
    #
    # == Arguments
    #
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def map! axis=:vector, &block
      if %i[vector column].include?(axis)
        map_vectors!(&block)
      elsif axis == :row
        map_rows!(&block)
      end
    end

    # Maps over the DataFrame and returns a DataFrame. Each run of the
    # block must return a Daru::Vector object. You can specify the axis
    # to map over. Default to :vector.
    #
    # == Description
    #
    # Recode works similarly to #map, but an important difference between
    # the two is that recode returns a modified Daru::DataFrame instead
    # of an Array. For this reason, #recode expects that every run of the
    # block to return a Daru::Vector.
    #
    # Just like map and each, recode also accepts an optional _axis_ argument.
    #
    # == Arguments
    #
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    def recode axis=:vector, &block
      dispatch_to_axis_pl axis, :recode, &block
    end

    # Retain vectors or rows if the block returns a truthy value.
    #
    # == Description
    #
    # For filtering out certain rows/vectors based on their values,
    # use the #filter method. By default it iterates over vectors and
    # keeps those vectors for which the block returns true. It accepts
    # an optional axis argument which lets you specify whether you want
    # to iterate over vectors or rows.
    #
    # == Arguments
    #
    # * +axis+ - The axis to map over. Can be :vector (or :column) or :row.
    # Default to :vector.
    #
    # == Usage
    #
    #   # Filter vectors
    #
    #   df.filter do |vector|
    #     vector.type == :numeric and vector.median < 50
    #   end
    #
    #   # Filter rows
    #
    #   df.filter(:row) do |row|
    #     row[:a] + row[:d] < 100
    #   end
    def filter axis=:vector, &block
      dispatch_to_axis_pl axis, :filter, &block
    end

    def recode_vectors
      block_given? or return to_enum(:recode_vectors)

      dup.tap do |df|
        df.each_vector_with_index do |v, i|
          df[*i] = should_be_vector!(yield(v))
        end
      end
    end

    def recode_rows
      block_given? or return to_enum(:recode_rows)

      dup.tap do |df|
        df.each_row_with_index do |r, i|
          df.row[i] = should_be_vector!(yield(r))
        end
      end
    end

    # Map each vector and return an Array.
    def map_vectors &block
      return to_enum(:map_vectors) unless block_given?

      @data.map(&block)
    end

    # Destructive form of #map_vectors
    def map_vectors!
      return to_enum(:map_vectors!) unless block_given?

      vectors.dup.each do |n|
        self[n] = should_be_vector!(yield(self[n]))
      end

      self
    end

    # Map vectors alongwith the index.
    def map_vectors_with_index &block
      return to_enum(:map_vectors_with_index) unless block_given?

      each_vector_with_index.map(&block)
    end

    # Map each row
    def map_rows &block
      return to_enum(:map_rows) unless block_given?

      each_row.map(&block)
    end

    def map_rows_with_index &block
      return to_enum(:map_rows_with_index) unless block_given?

      each_row_with_index.map(&block)
    end

    def map_rows!
      return to_enum(:map_rows!) unless block_given?

      index.dup.each do |i|
        row[i] = should_be_vector!(yield(row[i]))
      end

      self
    end

    # Retrieves a Daru::Vector, based on the result of calculation
    # performed on each row.
    def collect_rows &block
      return to_enum(:collect_rows) unless block_given?

      Daru::Vector.new(each_row.map(&block), index: @index)
    end

    def collect_row_with_index &block
      return to_enum(:collect_row_with_index) unless block_given?

      Daru::Vector.new(each_row_with_index.map(&block), index: @index)
    end

    # Retrives a Daru::Vector, based on the result of calculation
    # performed on each vector.
    def collect_vectors &block
      return to_enum(:collect_vectors) unless block_given?

      Daru::Vector.new(each_vector.map(&block), index: @vectors)
    end

    def collect_vector_with_index &block
      return to_enum(:collect_vector_with_index) unless block_given?

      Daru::Vector.new(each_vector_with_index.map(&block), index: @vectors)
    end

    # Generate a matrix, based on vector names of the DataFrame.
    #
    # @return {::Matrix}
    # :nocov:
    # FIXME: Even not trying to cover this: I can't get, how it is expected
    # to work.... -- zverok
    def collect_matrix
      return to_enum(:collect_matrix) unless block_given?

      vecs = vectors.to_a
      rows = vecs.collect { |row|
        vecs.collect { |col|
          yield row,col
        }
      }

      Matrix.rows(rows)
    end
    # :nocov:

    # Delete a vector
    def delete_vector vector
      raise IndexError, "Vector #{vector} does not exist." unless @vectors.include?(vector)

      @data.delete_at @vectors[vector]
      @vectors = Daru::Index.new @vectors.to_a - [vector]

      self
    end

    # Deletes a list of vectors
    def delete_vectors *vectors
      Array(vectors).each { |vec| delete_vector vec }

      self
    end

    # Delete a row
    def delete_row index
      idx = named_index_for index

      raise IndexError, "Index #{index} does not exist." unless @index.include? idx
      @index = Daru::Index.new(@index.to_a - [idx])
      each_vector do |vector|
        vector.delete_at idx
      end

      set_size
    end

    # Creates a DataFrame with the random data, of n size.
    # If n not given, uses original number of rows.
    #
    # @return {Daru::DataFrame}
    def bootstrap(n=nil)
      n ||= nrows
      Daru::DataFrame.new({}, order: @vectors).tap do |df_boot|
        n.times do
          df_boot.add_row(row[rand(n)])
        end
        df_boot.update
      end
    end

    def keep_row_if
      @index
        .reject { |idx| yield access_row(idx) }
        .each { |idx| delete_row idx }
    end

    def keep_vector_if
      @vectors.each do |vector|
        delete_vector(vector) unless yield(@data[@vectors[vector]], vector)
      end
    end

    # creates a new vector with the data of a given field which the block returns true
    def filter_vector vec, &block
      Daru::Vector.new(each_row.select(&block).map { |row| row[vec] })
    end

    # Iterates over each row and retains it in a new DataFrame if the block returns
    # true for that row.
    def filter_rows
      return to_enum(:filter_rows) unless block_given?

      keep_rows = @index.map { |index| yield access_row(index) }

      where keep_rows
    end

    # Iterates over each vector and retains it in a new DataFrame if the block returns
    # true for that vector.
    def filter_vectors &block
      return to_enum(:filter_vectors) unless block_given?

      dup.tap { |df| df.keep_vector_if(&block) }
    end

    # Test each row with one or more tests.
    # @param tests [Proc]  Each test is a Proc with the form
    #                      *Proc.new {|row| row[:age] > 0}*
    # The function returns an array with all errors.
    #
    # FIXME: description here is too sparse. As far as I can get,
    # it should tell something about that each test is [descr, fields, block],
    # and that first value may be column name to output. - zverok, 2016-05-18
    def verify(*tests)
      id = tests.first.is_a?(Symbol) ? tests.shift : @vectors.first

      each_row_with_index.map do |row, i|
        tests.reject { |*_, block| block.call(row) }
             .map { |test| verify_error_message row, test, id, i }
      end.flatten
    end

    # DSL for yielding each row and returning a Daru::Vector based on the
    # value each run of the block returns.
    #
    # == Usage
    #
    #   a1 = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7])
    #   a2 = Daru::Vector.new([10, 20, 30, 40, 50, 60, 70])
    #   a3 = Daru::Vector.new([100, 200, 300, 400, 500, 600, 700])
    #   ds = Daru::DataFrame.new({ :a => a1, :b => a2, :c => a3 })
    #   total = ds.vector_by_calculation { a + b + c }
    #   # <Daru::Vector:82314050 @name = nil @size = 7 >
    #   #   nil
    #   # 0 111
    #   # 1 222
    #   # 2 333
    #   # 3 444
    #   # 4 555
    #   # 5 666
    #   # 6 777
    def vector_by_calculation &block
      a = each_row.map { |r| r.instance_eval(&block) }

      Daru::Vector.new a, index: @index
    end

    # Reorder the vectors in a dataframe
    # @param [Array] order_array new order of the vectors
    # @example
    #   df = Daru::DataFrame({
    #     a: [1, 2, 3],
    #     b: [4, 5, 6]
    #   }, order: [:a, :b])
    #   df.order = [:b, :a]
    #   df
    #   # => #<Daru::DataFrame(3x2)>
    #   #       b   a
    #   #   0   4   1
    #   #   1   5   2
    #   #   2   6   3
    def order=(order_array)
      raise ArgumentError, 'Invalid order' unless
        order_array.sort == vectors.to_a.sort
      initialize(to_h, order: order_array)
    end

    # Returns a vector, based on a string with a calculation based
    # on vector.
    #
    # The calculation will be eval'ed, so you can put any variable
    # or expression valid on ruby.
    #
    # For example:
    #   a = Daru::Vector.new [1,2]
    #   b = Daru::Vector.new [3,4]
    #   ds = Daru::DataFrame.new({:a => a,:b => b})
    #   ds.compute("a+b")
    #   => Vector [4,6]
    def compute text, &block
      return instance_eval(&block) if block_given?
      instance_eval(text)
    end

    # Return a vector with the number of missing values in each row.
    #
    # == Arguments
    #
    # * +missing_values+ - An Array of the values that should be
    # treated as 'missing'. The default missing value is *nil*.
    def missing_values_rows missing_values=[nil]
      number_of_missing = each_row.map do |row|
        row.indexes(*missing_values).size
      end

      Daru::Vector.new number_of_missing, index: @index, name: "#{@name}_missing_rows"
    end

    # TODO: remove next version
    alias :vector_missing_values :missing_values_rows

    def has_missing_data?
      @data.any? { |vec| vec.include_values?(*Daru::MISSING_VALUES) }
    end
    alias :flawed? :has_missing_data?
    deprecate :has_missing_data?, :include_values?, 2016, 10
    deprecate :flawed?, :include_values?, 2016, 10

    # Check if any of given values occur in the data frame
    # @param [Array] values to check for
    # @return [true, false] true if any of the given values occur in the
    #   dataframe, false otherwise
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1,    2,          3,   nil,        Float::NAN, nil, 1,   7],
    #     b: [:a,  :b,          nil, Float::NAN, nil,        3,   5,   8],
    #     c: ['a',  Float::NAN, 3,   4,          3,          5,   nil, 7]
    #   }, index: 11..18)
    #   df.include_values? nil
    #   # => true
    def include_values?(*values)
      @data.any? { |vec| vec.include_values?(*values) }
    end

    # Return a nested hash using vector names as keys and an array constructed of
    # hashes with other values. If block provided, is used to provide the
    # values, with parameters +row+ of dataset, +current+ last hash on
    # hierarchy and +name+ of the key to include
    def nest *tree_keys, &_block
      tree_keys = tree_keys[0] if tree_keys[0].is_a? Array

      each_row.each_with_object({}) do |row, current|
        # Create tree
        *keys, last = tree_keys
        current = keys.inject(current) { |c, f| c[row[f]] ||= {} }
        name = row[last]

        if block_given?
          current[name] = yield(row, current, name)
        else
          current[name] ||= []
          current[name].push(row.to_h.delete_if { |key,_value| tree_keys.include? key })
        end
      end
    end

    def vector_count_characters vecs=nil
      vecs ||= @vectors.to_a

      collect_rows do |row|
        vecs.map { |v| row[v].to_s.size }.inject(:+)
      end
    end

    def add_vectors_by_split(name,join='-',sep=Daru::SPLIT_TOKEN)
      self[name]
        .split_by_separator(sep)
        .each { |k,v| self["#{name}#{join}#{k}".to_sym] = v }
    end

    # Return the number of rows and columns of the DataFrame in an Array.
    def shape
      [nrows, ncols]
    end

    # The number of rows
    def nrows
      @index.size
    end

    # The number of vectors
    def ncols
      @vectors.size
    end

    # Check if a vector is present
    def has_vector? vector
      @vectors.include? vector
    end

    # Works like Array#any?.
    #
    # @param [Symbol] axis (:vector) The axis to iterate over. Can be :vector or
    #   :row. A Daru::Vector object is yielded in the block.
    # @example Using any?
    #   df = Daru::DataFrame.new({a: [1,2,3,4,5], b: ['a', 'b', 'c', 'd', 'e']})
    #   df.any?(:row) do |row|
    #     row[:a] < 3 and row[:b] == 'b'
    #   end #=> true
    def any? axis=:vector, &block
      if %i[vector column].include?(axis)
        @data.any?(&block)
      elsif axis == :row
        each_row do |row|
          return true if yield(row)
        end
        false
      else
        raise ArgumentError, "Unidentified axis #{axis}"
      end
    end

    # Works like Array#all?
    #
    # @param [Symbol] axis (:vector) The axis to iterate over. Can be :vector or
    #   :row. A Daru::Vector object is yielded in the block.
    # @example Using all?
    #   df = Daru::DataFrame.new({a: [1,2,3,4,5], b: ['a', 'b', 'c', 'd', 'e']})
    #   df.all?(:row) do |row|
    #     row[:a] < 10
    #   end #=> true
    def all? axis=:vector, &block
      if %i[vector column].include?(axis)
        @data.all?(&block)
      elsif axis == :row
        each_row.all?(&block)
      else
        raise ArgumentError, "Unidentified axis #{axis}"
      end
    end

    # The first ten elements of the DataFrame
    #
    # @param [Fixnum] quantity (10) The number of elements to display from the top.
    def head quantity=10
      row.at 0..(quantity-1)
    end

    alias :first :head

    # The last ten elements of the DataFrame
    #
    # @param [Fixnum] quantity (10) The number of elements to display from the bottom.
    def tail quantity=10
      start = [-quantity, -size].max
      row.at start..-1
    end

    alias :last :tail

    # Sum all numeric/specified vectors in the DataFrame.
    #
    # Returns a new vector that's a containing a sum of all numeric
    # or specified vectors of the DataFrame. By default, if the vector
    # contains a nil, the sum is nil.
    # With :skipnil argument set to true, nil values are assumed to be
    # 0 (zero) and the sum vector is returned.
    #
    # @param args [Array] List of vectors to sum. Default is nil in which case
    #   all numeric vectors are summed.
    #
    # @option opts [Boolean] :skipnil Consider nils as 0. Default is false.
    #
    # @return Vector with sum of all vectors specified in the argument.
    #   If vecs parameter is empty, sum all numeric vector.
    #
    # @example
    #    df = Daru::DataFrame.new({
    #       a: [1, 2, nil],
    #       b: [2, 1, 3],
    #       c: [1, 1, 1]
    #     })
    #    => #<Daru::DataFrame(3x3)>
    #           a   b   c
    #       0   1   2   1
    #       1   2   1   1
    #       2 nil   3   1
    #    df.vector_sum [:a, :c]
    #    => #<Daru::Vector(3)>
    #       0   2
    #       1   3
    #       2 nil
    #    df.vector_sum
    #    => #<Daru::Vector(3)>
    #       0   4
    #       1   4
    #       2 nil
    #    df.vector_sum skipnil: true
    #    => #<Daru::Vector(3)>
    #           c
    #       0   4
    #       1   4
    #       2   4
    #
    def vector_sum(*args)
      defaults = {vecs: nil, skipnil: false}
      options = args.last.is_a?(::Hash) ? args.pop : {}
      options = defaults.merge(options)
      vecs = args[0] || options[:vecs]
      skipnil = args[1] || options[:skipnil]

      vecs ||= numeric_vectors
      sum = Daru::Vector.new [0]*@size, index: @index, name: @name, dtype: @dtype
      vecs.inject(sum) { |memo, n| self[n].add(memo, skipnil: skipnil) }
    end

    # Calculate mean of the rows of the dataframe.
    #
    # == Arguments
    #
    # * +max_missing+ - The maximum number of elements in the row that can be
    # zero for the mean calculation to happen. Default to 0.
    def vector_mean max_missing=0
      # FIXME: in vector_sum we preserve created vector dtype, but
      # here we are not. Is this by design or ...? - zverok, 2016-05-18
      mean_vec = Daru::Vector.new [0]*@size, index: @index, name: "mean_#{@name}"

      each_row_with_index.each_with_object(mean_vec) do |(row, i), memo|
        memo[i] = row.indexes(*Daru::MISSING_VALUES).size > max_missing ? nil : row.mean
      end
    end

    # Group elements by vector to perform operations on them. Returns a
    # Daru::Core::GroupBy object.See the Daru::Core::GroupBy docs for a detailed
    # list of possible operations.
    #
    # == Arguments
    #
    # * vectors - An Array contatining names of vectors to group by.
    #
    # == Usage
    #
    #   df = Daru::DataFrame.new({
    #     a: %w{foo bar foo bar   foo bar foo foo},
    #     b: %w{one one two three two two one three},
    #     c:   [1  ,2  ,3  ,1    ,3  ,6  ,3  ,8],
    #     d:   [11 ,22 ,33 ,44   ,55 ,66 ,77 ,88]
    #   })
    #   df.group_by([:a,:b,:c]).groups
    #   #=> {["bar", "one", 2]=>[1],
    #   # ["bar", "three", 1]=>[3],
    #   # ["bar", "two", 6]=>[5],
    #   # ["foo", "one", 1]=>[0],
    #   # ["foo", "one", 3]=>[6],
    #   # ["foo", "three", 8]=>[7],
    #   # ["foo", "two", 3]=>[2, 4]}
    def group_by *vectors
      vectors.flatten!
      missing = vectors - @vectors.to_a
      unless missing.empty?
        raise(ArgumentError, "Vector(s) missing: #{missing.join(', ')}")
      end

      vectors = [@vectors.first] if vectors.empty?

      Daru::Core::GroupBy.new(self, vectors)
    end

    def reindex_vectors new_vectors
      unless new_vectors.is_a?(Daru::Index)
        raise ArgumentError, 'Must pass the new index of type Index or its '\
          "subclasses, not #{new_index.class}"
      end

      cl = Daru::DataFrame.new({}, order: new_vectors, index: @index, name: @name)
      new_vectors.each_with_object(cl) do |vec, memo|
        memo[vec] = @vectors.include?(vec) ? self[vec] : [nil]*nrows
      end
    end

    def get_vector_anyways(v)
      @vectors.include?(v) ? self[v].to_a : [nil] * size
    end

    # Concatenate another DataFrame along corresponding columns.
    # If columns do not exist in both dataframes, they are filled with nils
    def concat other_df
      vectors = (@vectors.to_a + other_df.vectors.to_a).uniq

      data = vectors.map do |v|
        get_vector_anyways(v).dup.concat(other_df.get_vector_anyways(v))
      end

      Daru::DataFrame.new(data, order: vectors)
    end

    # Concatenates another DataFrame as #concat.
    # Additionally it tries to preserve the index. If the indices contain
    # common elements, #union will overwrite the according rows in the
    # first dataframe.
    def union other_df
      index = (@index.to_a + other_df.index.to_a).uniq
      df = row[*(@index.to_a - other_df.index.to_a)]

      df = df.concat(other_df)
      df.index = Daru::Index.new(index)
      df
    end

    # Set a particular column as the new DF
    def set_index new_index, opts={}
      raise ArgumentError, 'All elements in new index must be unique.' if
        @size != self[new_index].uniq.size

      self.index = Daru::Index.new(self[new_index].to_a)
      delete_vector(new_index) unless opts[:keep]

      self
    end

    # Change the index of the DataFrame and preserve the labels of the previous
    # indexing. New index can be Daru::Index or any of its subclasses.
    #
    # @param [Daru::Index] new_index The new Index for reindexing the DataFrame.
    # @example Reindexing DataFrame
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [11,22,33,44]},
    #     index: ['a','b','c','d'])
    #   #=>
    #   ##<Daru::DataFrame:83278130 @name = b19277b8-c548-41da-ad9a-2ad8c060e273 @size = 4>
    #   #                    a          b
    #   #         a          1         11
    #   #         b          2         22
    #   #         c          3         33
    #   #         d          4         44
    #   df.reindex Daru::Index.new(['b', 0, 'a', 'g'])
    #   #=>
    #   ##<Daru::DataFrame:83177070 @name = b19277b8-c548-41da-ad9a-2ad8c060e273 @size = 4>
    #   #                    a          b
    #   #         b          2         22
    #   #         0        nil        nil
    #   #         a          1         11
    #   #         g        nil        nil
    def reindex new_index
      unless new_index.is_a?(Daru::Index)
        raise ArgumentError, 'Must pass the new index of type Index or its '\
          "subclasses, not #{new_index.class}"
      end

      cl = Daru::DataFrame.new({}, order: @vectors, index: new_index, name: @name)
      new_index.each_with_object(cl) do |idx, memo|
        memo.row[idx] = @index.include?(idx) ? row[idx] : [nil]*ncols
      end
    end

    # Reassign index with a new index of type Daru::Index or any of its subclasses.
    #
    # @param [Daru::Index] idx New index object on which the rows of the dataframe
    #   are to be indexed.
    # @example Reassgining index of a DataFrame
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [11,22,33,44]})
    #   df.index.to_a #=> [0,1,2,3]
    #
    #   df.index = Daru::Index.new(['a','b','c','d'])
    #   df.index.to_a #=> ['a','b','c','d']
    #   df.row['a'].to_a #=> [1,11]
    def index= idx
      @index = Index.coerce idx
      @data.each { |vec| vec.index = @index }

      self
    end

    # Reassign vectors with a new index of type Daru::Index or any of its subclasses.
    #
    # @param new_index [Daru::Index] idx The new index object on which the vectors are to
    #   be indexed. Must of the same size as ncols.
    # @example Reassigning vectors of a DataFrame
    #   df = Daru::DataFrame.new({a: [1,2,3,4], b: [:a,:b,:c,:d], c: [11,22,33,44]})
    #   df.vectors.to_a #=> [:a, :b, :c]
    #
    #   df.vectors = Daru::Index.new([:foo, :bar, :baz])
    #   df.vectors.to_a #=> [:foo, :bar, :baz]
    def vectors= new_index
      unless new_index.is_a?(Daru::Index)
        raise ArgumentError, 'Can only reindex with Index and its subclasses'
      end

      if new_index.size != ncols
        raise ArgumentError, "Specified index length #{new_index.size} not equal to"\
          "dataframe size #{ncols}"
      end

      @vectors = new_index
      @data.zip(new_index.to_a).each do |vect, name|
        vect.name = name
      end
      self
    end

    # Renames the vectors
    #
    # == Arguments
    #
    # * name_map - A hash where the keys are the exising vector names and
    #              the values are the new names.  If a vector is renamed
    #              to a vector name that is already in use, the existing
    #              one is overwritten.
    #
    # == Usage
    #
    #   df = Daru::DataFrame.new({ a: [1,2,3,4], b: [:a,:b,:c,:d], c: [11,22,33,44] })
    #   df.rename_vectors :a => :alpha, :c => :gamma
    #   df.vectors.to_a #=> [:alpha, :b, :gamma]
    def rename_vectors name_map
      existing_targets = name_map.reject { |k,v| k == v }.values & vectors.to_a
      delete_vectors(*existing_targets)

      new_names = vectors.to_a.map { |v| name_map[v] ? name_map[v] : v }
      self.vectors = Daru::Index.new new_names
    end

    # Return the indexes of all the numeric vectors. Will include vectors with nils
    # alongwith numbers.
    def numeric_vectors
      # FIXME: Why _with_index ?..
      each_vector_with_index
        .select { |vec, _i| vec.numeric? }
        .map(&:last)
    end

    def numeric_vector_names
      @vectors.select { |v| self[v].numeric? }
    end

    # Return a DataFrame of only the numerical Vectors. If clone: false
    # is specified as option, only a *view* of the Vectors will be
    # returned. Defaults to clone: true.
    def only_numerics opts={}
      cln = opts[:clone] == false ? false : true
      arry = numeric_vectors.map { |v| self[v] }

      order = Index.new(numeric_vectors)
      Daru::DataFrame.new(arry, clone: cln, order: order, index: @index)
    end

    # Generate a summary of this DataFrame based on individual vectors in the DataFrame
    # @return [String] String containing the summary of the DataFrame
    def summary
      summary = "= #{name}"
      summary << "\n  Number of rows: #{nrows}"
      @vectors.each do |v|
        summary << "\n  Element:[#{v}]\n"
        summary << self[v].summary(1)
      end
      summary
    end

    # Sorts a dataframe (ascending/descending) in the given pripority sequence of
    # vectors, with or without a block.
    #
    # @param vector_order [Array] The order of vector names in which the DataFrame
    #   should be sorted.
    # @param opts [Hash] opts The options to sort with.
    # @option opts [TrueClass,FalseClass,Array] :ascending (true) Sort in ascending
    #   or descending order. Specify Array corresponding to *order* for multiple
    #   sort orders.
    # @option opts [Hash] :by (lambda{|a| a }) Specify attributes of objects to
    #   to be used for sorting, for each vector name in *order* as a hash of
    #   vector name and lambda expressions. In case a lambda for a vector is not
    #   specified, the default will be used.
    # @option opts [TrueClass,FalseClass,Array] :handle_nils (false) Handle nils
    #   automatically or not when a block is provided.
    #   If set to True, nils will appear at top after sorting.
    #
    # @example Sort a dataframe with a vector sequence.
    #
    #
    #   df = Daru::DataFrame.new({a: [1,2,1,2,3], b: [5,4,3,2,1]})
    #
    #   df.sort [:a, :b]
    #   # =>
    #   # <Daru::DataFrame:30604000 @name = d6a9294e-2c09-418f-b646-aa9244653444 @size = 5>
    #   #                   a          b
    #   #        2          1          3
    #   #        0          1          5
    #   #        3          2          2
    #   #        1          2          4
    #   #        4          3          1
    #
    # @example Sort a dataframe without a block. Here nils will be handled automatically.
    #
    #   df = Daru::DataFrame.new({a: [-3,nil,-1,nil,5], b: [4,3,2,1,4]})
    #
    #   df.sort([:a])
    #   # =>
    #   # <Daru::DataFrame:14810920 @name = c07fb5c7-2201-458d-b679-6a1f7ebfe49f @size = 5>
    #   #                    a          b
    #   #         1        nil          3
    #   #         3        nil          1
    #   #         0         -3          4
    #   #         2         -1          2
    #   #         4          5          4
    #
    # @example Sort a dataframe with a block with nils handled automatically.
    #
    #   df = Daru::DataFrame.new({a: [nil,-1,1,nil,-1,1], b: ['aaa','aa',nil,'baaa','x',nil] })
    #
    #   df.sort [:b], by: {b: lambda { |a| a.length } }
    #   # NoMethodError: undefined method `length' for nil:NilClass
    #   # from (pry):8:in `block in __pry__'
    #
    #   df.sort [:b], by: {b: lambda { |a| a.length } }, handle_nils: true
    #
    #   # =>
    #   # <Daru::DataFrame:28469540 @name = 5f986508-556f-468b-be0c-88cc3534445c @size = 6>
    #   #                    a          b
    #   #         2          1        nil
    #   #         5          1        nil
    #   #         4         -1          x
    #   #         1         -1         aa
    #   #         0        nil        aaa
    #   #         3        nil       baaa
    #
    # @example Sort a dataframe with a block with nils handled manually.
    #
    #   df = Daru::DataFrame.new({a: [nil,-1,1,nil,-1,1], b: ['aaa','aa',nil,'baaa','x',nil] })
    #
    #   # To print nils at the bottom one can use lambda { |a| (a.nil?)[1]:[0,a.length] }
    #   df.sort [:b], by: {b: lambda { |a| (a.nil?)?[1]:[0,a.length] } }, handle_nils: true
    #
    #   # =>
    #   #<Daru::DataFrame:22214180 @name = cd7703c7-1dca-4560-840b-5ea51a852ef9 @size = 6>
    #   #                 a          b
    #   #      4         -1          x
    #   #      1         -1         aa
    #   #      0        nil        aaa
    #   #      3        nil       baaa
    #   #      2          1        nil
    #   #      5          1        nil

    def sort! vector_order, opts={}
      raise ArgumentError, 'Required atleast one vector name' if vector_order.empty?

      # To enable sorting with categorical data,
      # map categories to integers preserving their order
      old = convert_categorical_vectors vector_order
      block = sort_prepare_block vector_order, opts

      order = @index.size.times.sort(&block)
      new_index = @index.reorder order

      # To reverse map mapping of categorical data to integers
      restore_categorical_vectors old

      @data.each do |vector|
        vector.reorder! order
      end

      self.index = new_index

      self
    end

    # Non-destructive version of #sort!
    def sort vector_order, opts={}
      dup.sort! vector_order, opts
    end

    # Pivots a data frame on specified vectors and applies an aggregate function
    # to quickly generate a summary.
    #
    # == Options
    #
    # +:index+ - Keys to group by on the pivot table row index. Pass vector names
    # contained in an Array.
    #
    # +:vectors+ - Keys to group by on the pivot table column index. Pass vector
    # names contained in an Array.
    #
    # +:agg+ - Function to aggregate the grouped values. Default to *:mean*. Can
    # use any of the statistics functions applicable on Vectors that can be found in
    # the Daru::Statistics::Vector module.
    #
    # +:values+ - Columns to aggregate. Will consider all numeric columns not
    # specified in *:index* or *:vectors*. Optional.
    #
    # == Usage
    #
    #   df = Daru::DataFrame.new({
    #     a: ['foo'  ,  'foo',  'foo',  'foo',  'foo',  'bar',  'bar',  'bar',  'bar'],
    #     b: ['one'  ,  'one',  'one',  'two',  'two',  'one',  'one',  'two',  'two'],
    #     c: ['small','large','large','small','small','large','small','large','small'],
    #     d: [1,2,2,3,3,4,5,6,7],
    #     e: [2,4,4,6,6,8,10,12,14]
    #   })
    #   df.pivot_table(index: [:a], vectors: [:b], agg: :sum, values: :e)
    #
    #   #=>
    #   # #<Daru::DataFrame:88342020 @name = 08cdaf4e-b154-4186-9084-e76dd191b2c9 @size = 2>
    #   #            [:e, :one] [:e, :two]
    #   #     [:bar]         18         26
    #   #     [:foo]         10         12
    def pivot_table opts={}
      raise ArgumentError, 'Specify grouping index' if Array(opts[:index]).empty?

      index               = opts[:index]
      vectors             = opts[:vectors] || []
      aggregate_function  = opts[:agg] || :mean
      values              = prepare_pivot_values index, vectors, opts
      raise IndexError, 'No numeric vectors to aggregate' if values.empty?

      grouped = group_by(index)
      return grouped.send(aggregate_function) if vectors.empty?

      super_hash = make_pivot_hash grouped, vectors, values, aggregate_function

      pivot_dataframe super_hash
    end

    # Merge vectors from two DataFrames. In case of name collision,
    # the vectors names are changed to x_1, x_2 ....
    #
    # @return {Daru::DataFrame}
    def merge other_df # rubocop:disable Metrics/AbcSize
      unless nrows == other_df.nrows
        raise ArgumentError,
          "Number of rows must be equal in this: #{nrows} and other: #{other_df.nrows}"
      end

      new_fields = (@vectors.to_a + other_df.vectors.to_a)
      new_fields = ArrayHelper.recode_repeated(new_fields)
      DataFrame.new({}, order: new_fields).tap do |df_new|
        (0...nrows).each do |i|
          df_new.add_row row[i].to_a + other_df.row[i].to_a
        end
        df_new.index = @index if @index == other_df.index
        df_new.update
      end
    end

    # Join 2 DataFrames with SQL style joins. Currently supports inner, left
    # outer, right outer and full outer joins.
    #
    # @param [Daru::DataFrame] other_df Another DataFrame on which the join is
    #   to be performed.
    # @param [Hash] opts Options Hash
    # @option :how [Symbol] Can be one of :inner, :left, :right or :outer.
    # @option :on [Array] The columns on which the join is to be performed.
    #   Column names specified here must be common to both DataFrames.
    # @option :indicator [Symbol] The name of a vector to add to the resultant
    #   dataframe that indicates whether the record was in the left (:left_only),
    #   right (:right_only), or both (:both) joining dataframes.
    # @return [Daru::DataFrame]
    # @example Inner Join
    #   left = Daru::DataFrame.new({
    #     :id   => [1,2,3,4],
    #     :name => ['Pirate', 'Monkey', 'Ninja', 'Spaghetti']
    #   })
    #   right = Daru::DataFrame.new({
    #     :id => [1,2,3,4],
    #     :name => ['Rutabaga', 'Pirate', 'Darth Vader', 'Ninja']
    #   })
    #   left.join(right, how: :inner, on: [:name])
    #   #=>
    #   ##<Daru::DataFrame:82416700 @name = 74c0811b-76c6-4c42-ac93-e6458e82afb0 @size = 2>
    #   #                 id_1       name       id_2
    #   #         0          1     Pirate          2
    #   #         1          3      Ninja          4
    def join(other_df,opts={})
      Daru::Core::Merge.join(self, other_df, opts)
    end

    # Creates a new dataset for one to many relations
    # on a dataset, based on pattern of field names.
    #
    # for example, you have a survey for number of children
    # with this structure:
    #   id, name, child_name_1, child_age_1, child_name_2, child_age_2
    # with
    #   ds.one_to_many([:id], "child_%v_%n"
    # the field of first parameters will be copied verbatim
    # to new dataset, and fields which responds to second
    # pattern will be added one case for each different %n.
    #
    # @example
    #   cases=[
    #     ['1','george','red',10,'blue',20,nil,nil],
    #     ['2','fred','green',15,'orange',30,'white',20],
    #     ['3','alfred',nil,nil,nil,nil,nil,nil]
    #   ]
    #   ds=Daru::DataFrame.rows(cases, order:
    #     [:id, :name,
    #      :car_color1, :car_value1,
    #      :car_color2, :car_value2,
    #      :car_color3, :car_value3])
    #   ds.one_to_many([:id],'car_%v%n').to_matrix
    #   #=> Matrix[
    #   #   ["red", "1", 10],
    #   #   ["blue", "1", 20],
    #   #   ["green", "2", 15],
    #   #   ["orange", "2", 30],
    #   #   ["white", "2", 20]
    #   #   ]
    def one_to_many(parent_fields, pattern)
      vars, numbers = one_to_many_components(pattern)

      DataFrame.new([], order: [*parent_fields, '_col_id', *vars]).tap do |ds|
        each_row do |row|
          verbatim = parent_fields.map { |f| [f, row[f]] }.to_h
          numbers.each do |n|
            generated = one_to_many_row row, n, vars, pattern
            next if generated.values.all?(&:nil?)

            ds.add_row(verbatim.merge(generated).merge('_col_id' => n))
          end
        end
        ds.update
      end
    end

    def add_vectors_by_split_recode(nm, join='-', sep=Daru::SPLIT_TOKEN)
      self[nm]
        .split_by_separator(sep)
        .each_with_index do |(k, v), i|
          v.rename "#{nm}:#{k}"
          self["#{nm}#{join}#{i + 1}".to_sym] = v
        end
    end

    # Create a sql, basen on a given Dataset
    #
    # == Arguments
    #
    # * table - String specifying name of the table that will created in SQL.
    # * charset - Character set. Default is "UTF8".
    #
    # @example
    #
    #  ds = Daru::DataFrame.new({
    #   :id   => Daru::Vector.new([1,2,3,4,5]),
    #   :name => Daru::Vector.new(%w{Alex Peter Susan Mary John})
    #  })
    #  ds.create_sql('names')
    #   #=>"CREATE TABLE names (id INTEGER,\n name VARCHAR (255)) CHARACTER SET=UTF8;"
    #
    def create_sql(table,charset='UTF8')
      sql    = "CREATE TABLE #{table} ("
      fields = vectors.to_a.collect do |f|
        v = self[f]
        f.to_s + ' ' + v.db_type
      end

      sql + fields.join(",\n ")+") CHARACTER SET=#{charset};"
    end

    # Returns the dataframe.  This can be convenient when the user does not
    # know whether the object is a vector or a dataframe.
    # @return [self] the dataframe
    def to_df
      self
    end

    # Convert all numeric vectors to GSL::Matrix
    def to_gsl
      numerics_as_arrays = numeric_vectors.map { |n| self[n].to_a }

      GSL::Matrix.alloc(*numerics_as_arrays.transpose)
    end

    # Convert all vectors of type *:numeric* into a Matrix.
    def to_matrix
      Matrix.columns each_vector.select(&:numeric?).map(&:to_a)
    end

    # Return a Nyaplot::DataFrame from the data of this DataFrame.
    # :nocov:
    def to_nyaplotdf
      Nyaplot::DataFrame.new(to_a[0])
    end
    # :nocov:

    # Convert all vectors of type *:numeric* and not containing nils into an NMatrix.
    def to_nmatrix
      each_vector.select do |vector|
        vector.numeric? && !vector.include_values?(*Daru::MISSING_VALUES)
      end.map(&:to_a).transpose.to_nm
    end

    # Converts the DataFrame into an array of hashes where key is vector name
    # and value is the corresponding element. The 0th index of the array contains
    # the array of hashes while the 1th index contains the indexes of each row
    # of the dataframe. Each element in the index array corresponds to its row
    # in the array of hashes, which has the same index.
    def to_a
      [each_row.map(&:to_h), @index.to_a]
    end

    # Convert to json. If no_index is false then the index will NOT be included
    # in the JSON thus created.
    def to_json no_index=true
      if no_index
        to_a[0].to_json
      else
        to_a.to_json
      end
    end

    # Converts DataFrame to a hash (explicit) with keys as vector names and values as
    # the corresponding vectors.
    def to_h
      @vectors
        .each_with_index
        .map { |vec_name, idx| [vec_name, @data[idx]] }.to_h
    end

    # Convert to html for IRuby.
    def to_html(threshold=30)
      table_thead = to_html_thead
      table_tbody = to_html_tbody(threshold)
      path = if index.is_a?(MultiIndex)
               File.expand_path('../iruby/templates/dataframe_mi.html.erb', __FILE__)
             else
               File.expand_path('../iruby/templates/dataframe.html.erb', __FILE__)
             end
      ERB.new(File.read(path).strip).result(binding)
    end

    def to_html_thead
      table_thead_path =
        if index.is_a?(MultiIndex)
          File.expand_path('../iruby/templates/dataframe_mi_thead.html.erb', __FILE__)
        else
          File.expand_path('../iruby/templates/dataframe_thead.html.erb', __FILE__)
        end
      ERB.new(File.read(table_thead_path).strip).result(binding)
    end

    def to_html_tbody(threshold=30)
      table_tbody_path =
        if index.is_a?(MultiIndex)
          File.expand_path('../iruby/templates/dataframe_mi_tbody.html.erb', __FILE__)
        else
          File.expand_path('../iruby/templates/dataframe_tbody.html.erb', __FILE__)
        end
      ERB.new(File.read(table_tbody_path).strip).result(binding)
    end

    def to_s
      "#<#{self.class}#{': ' + @name.to_s if @name}(#{nrows}x#{ncols})>"
    end

    # Method for updating the metadata (i.e. missing value positions) of the
    # after assingment/deletion etc. are complete. This is provided so that
    # time is not wasted in creating the metadata for the vector each time
    # assignment/deletion of elements is done. Updating data this way is called
    # lazy loading. To set or unset lazy loading, see the .lazy_update= method.
    def update
      @data.each(&:update) if Daru.lazy_update
    end

    # Rename the DataFrame.
    def rename new_name
      @name = new_name
      self
    end

    alias_method :name=, :rename

    # Write this DataFrame to a CSV file.
    #
    # == Arguements
    #
    # * filename - Path of CSV file where the DataFrame is to be saved.
    #
    # == Options
    #
    # * convert_comma - If set to *true*, will convert any commas in any
    # of the data to full stops ('.').
    # All the options accepted by CSV.read() can also be passed into this
    # function.
    def write_csv filename, opts={}
      Daru::IO.dataframe_write_csv self, filename, opts
    end

    # Write this dataframe to an Excel Spreadsheet
    #
    # == Arguments
    #
    # * filename - The path of the file where the DataFrame should be written.
    def write_excel filename, opts={}
      Daru::IO.dataframe_write_excel self, filename, opts
    end

    # Insert each case of the Dataset on the selected table
    #
    # == Arguments
    #
    # * dbh - DBI database connection object.
    # * query - Query string.
    #
    # == Usage
    #
    #  ds = Daru::DataFrame.new({:id=>Daru::Vector.new([1,2,3]), :name=>Daru::Vector.new(["a","b","c"])})
    #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
    #  ds.write_sql(dbh,"test")
    def write_sql dbh, table
      Daru::IO.dataframe_write_sql self, dbh, table
    end

    # Use marshalling to save dataframe to a file.
    def save filename
      Daru::IO.save self, filename
    end

    def _dump(_depth)
      Marshal.dump(
        data:  @data,
        index: @index.to_a,
        order: @vectors.to_a,
        name:  @name
      )
    end

    def self._load data
      h = Marshal.load data
      Daru::DataFrame.new(h[:data],
        index: h[:index],
        order: h[:order],
        name:  h[:name])
    end

    # Change dtypes of vectors by supplying a hash of :vector_name => :new_dtype
    #
    # == Usage
    #   df = Daru::DataFrame.new({a: [1,2,3], b: [1,2,3], c: [1,2,3]})
    #   df.recast a: :nmatrix, c: :nmatrix
    def recast opts={}
      opts.each do |vector_name, dtype|
        self[vector_name].cast(dtype: dtype)
      end
    end

    # Transpose a DataFrame, tranposing elements and row, column indexing.
    def transpose
      Daru::DataFrame.new(
        each_vector.map(&:to_a).transpose,
        index: @vectors,
        order: @index,
        dtype: @dtype,
        name: @name
      )
    end

    # Pretty print in a nice table format for the command line (irb/pry/iruby)
    def inspect spacing=10, threshold=15
      name_part = @name ? ": #{@name} " : ''

      "#<#{self.class}#{name_part}(#{nrows}x#{ncols})>\n" +
        Formatters::Table.format(
          each_row.lazy,
          row_headers: row_headers,
          headers: headers,
          threshold: threshold,
          spacing: spacing
        )
    end

    # Query a DataFrame by passing a Daru::Core::Query::BoolArray object.
    def where bool_array
      Daru::Core::Query.df_where self, bool_array
    end

    def == other
      self.class == other.class   &&
        @size    == other.size    &&
        @index   == other.index   &&
        @vectors == other.vectors &&
        @vectors.to_a.all? { |v| self[v] == other[v] }
    end

    # Converts the specified non category type vectors to category type vectors
    # @param [Array] names of non category type vectors to be converted
    # @return [Daru::DataFrame] data frame in which specified vectors have been
    #   converted to category type
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'a', 'b']
    #   })
    #   df.to_category :b
    #   df[:b].type
    #   # => :category
    def to_category *names
      names.each { |n| self[n] = self[n].to_category }
      self
    end

    def method_missing(name, *args, &block)
      case
      when name =~ /(.+)\=/
        name = name[/(.+)\=/].delete('=')
        name = name.to_sym unless has_vector?(name)
        insert_or_modify_vector [name], args[0]
      when has_vector?(name)
        self[name]
      when has_vector?(name.to_s)
        self[name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private=false)
      name.to_s.end_with?('=') || has_vector?(name) || super
    end

    def interact_code vector_names, full
      dfs = vector_names.zip(full).map do |vec_name, f|
        self[vec_name].contrast_code(full: f).each.to_a
      end

      all_vectors = recursive_product(dfs)
      Daru::DataFrame.new all_vectors,
        order: all_vectors.map(&:name)
    end

    # Split the dataframe into many dataframes based on category vector
    # @param [object] cat_name name of category vector to split the dataframe
    # @return [Array] array of dataframes split by category with category vector
    #   used to split not included
    # @example
    #   df = Daru::DataFrame.new({
    #     a: [1, 2, 3],
    #     b: ['a', 'a', 'b']
    #   })
    #   df.to_category :b
    #   df.split_by_category :b
    #   # => [#<Daru::DataFrame: a (2x1)>
    #   #       a
    #   #   0   1
    #   #   1   2,
    #   # #<Daru::DataFrame: b (1x1)>
    #   #       a
    #   #   2   3]
    def split_by_category cat_name
      cat_dv = self[cat_name]
      raise ArguementError, "#{cat_name} is not a category vector" unless
        cat_dv.category?

      cat_dv.categories.map do |cat|
        where(cat_dv.eq cat)
          .rename(cat)
          .delete_vector cat_name
      end
    end

    # returns array of row tuples at given index(s)
    def access_row_tuples_by_indexs *indexes
      positions = @index.pos(*indexes)
      if positions.is_a? Numeric
        row = populate_row_for(positions)
        row.first.is_a?(Array) ? row : [row]
      else
        new_rows = @data.map { |vec| vec[*indexes] }
        indexes.map { |index| new_rows.map { |r| r[index] } }
      end
    end

    # Function to use for aggregating the data.
    #
    # @param options [Hash] options for column, you want in resultant dataframe
    #
    # @return [Daru::DataFrame]
    #
    # @example
    #   df = Daru::DataFrame.new(
    #      {col: [:a, :b, :c, :d, :e], num: [52,12,07,17,01]})
    #   => #<Daru::DataFrame(5x2)>
    #        col num
    #      0   a  52
    #      1   b  12
    #      2   c   7
    #      3   d  17
    #      4   e   1
    #
    #    df.aggregate(num_100_times: ->(df) { df.num*100 })
    #   => #<Daru::DataFrame(5x1)>
    #               num_100_ti
    #             0       5200
    #             1       1200
    #             2        700
    #             3       1700
    #             4        100
    #
    #   When we have duplicate index :
    #
    #   idx = Daru::CategoricalIndex.new [:a, :b, :a, :a, :c]
    #   df = Daru::DataFrame.new({num: [52,12,07,17,01]}, index: idx)
    #   => #<Daru::DataFrame(5x1)>
    #        num
    #      a  52
    #      b  12
    #      a   7
    #      a  17
    #      c   1
    #
    #   df.aggregate(num: :mean)
    #   => #<Daru::DataFrame(3x1)>
    #                      num
    #             a 25.3333333
    #             b         12
    #             c          1
    #
    # Note: `GroupBy` class `aggregate` method uses this `aggregate` method
    # internally.
    def aggregate(options={})
      colmn_value, index_tuples = aggregated_colmn_value(options)
      Daru::DataFrame.new(
        colmn_value, index: index_tuples, order: options.keys
      )
    end

    private

    # Do the `method` (`method` can be :sum, :mean, :std, :median, etc or
    # lambda), on the column.
    def apply_method_on_colmns colmn, index_tuples, method
      rows = []
      index_tuples.each do |indexes|
        # If single element then also make it vector.
        slice = Daru::Vector.new(Array(self[colmn][*indexes]))
        case method
        when Symbol
          rows << (slice.is_a?(Daru::Vector) ? slice.send(method) : slice)
        when Proc
          rows << method.call(slice)
        end
      end
      rows
    end

    def apply_method_on_df index_tuples, method
      rows = []
      index_tuples.each do |indexes|
        slice = row[*indexes]
        rows << method.call(slice)
      end
      rows
    end

    def headers
      Daru::Index.new(Array(index.name) + @vectors.to_a)
    end

    def row_headers
      index.is_a?(MultiIndex) ? index.sparse_tuples : index.to_a
    end

    def convert_categorical_vectors names
      names.map do |n|
        next unless self[n].category?
        old = [n, self[n]]
        self[n] = Daru::Vector.new(self[n].to_ints)
        old
      end.compact
    end

    def restore_categorical_vectors old
      old.each { |name, vector| self[name] = vector }
    end

    def recursive_product dfs
      return dfs.first if dfs.size == 1

      left = dfs.first
      dfs.shift
      right = recursive_product dfs
      left.product(right).map do |dv1, dv2|
        (dv1*dv2).rename "#{dv1.name}:#{dv2.name}"
      end
    end

    def should_be_vector! val
      return val if val.is_a?(Daru::Vector)
      raise TypeError, "Every iteration must return Daru::Vector not #{val.class}"
    end

    def dispatch_to_axis(axis, method, *args, &block)
      if %i[vector column].include?(axis)
        send("#{method}_vector", *args, &block)
      elsif axis == :row
        send("#{method}_row", *args, &block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    def dispatch_to_axis_pl(axis, method, *args, &block)
      if %i[vector column].include?(axis)
        send("#{method}_vectors", *args, &block)
      elsif axis == :row
        send("#{method}_rows", *args, &block)
      else
        raise ArgumentError, "Unknown axis #{axis}"
      end
    end

    AXES = %i[row vector].freeze

    def extract_axis names, default=:vector
      if AXES.include?(names.last)
        names.pop
      else
        default
      end
    end

    def access_vector *names
      if names.first.is_a?(Range)
        dup(@vectors.subset(names.first))
      elsif @vectors.is_a?(MultiIndex)
        access_vector_multi_index(*names)
      else
        access_vector_single_index(*names)
      end
    end

    def access_vector_multi_index *names
      pos = @vectors[names]

      return @data[pos] if pos.is_a?(Integer)

      new_vectors = pos.map { |tuple| @data[@vectors[tuple]] }

      pos = pos.drop_left_level(names.size) if names.size < @vectors.width

      Daru::DataFrame.new(new_vectors, index: @index, order: pos)
    end

    def access_vector_single_index *names
      if names.count < 2
        begin
          pos = @vectors.is_a?(Daru::DateTimeIndex) ? @vectors[names.first] : @vectors.pos(names.first)
        rescue IndexError
          raise IndexError, "Specified vector #{names.first} does not exist"
        end
        return @data[pos] if pos.is_a?(Numeric)
        names = pos
      end

      new_vectors = names.map { |name| [name, @data[@vectors.pos(name)]] }.to_h

      order = names.is_a?(Array) ? Daru::Index.new(names) : names
      Daru::DataFrame.new(new_vectors, order: order,
                                       index: @index, name: @name)
    end

    def access_row *indexes
      positions = @index.pos(*indexes)

      if positions.is_a? Numeric
        return Daru::Vector.new populate_row_for(positions),
          index: @vectors,
          name: indexes.first
      else
        new_rows = @data.map { |vec| vec[*indexes] }
        return Daru::DataFrame.new new_rows,
          index: @index.subset(*indexes),
          order: @vectors
      end
    end

    def populate_row_for pos
      @data.map { |vector| vector.at(*pos) }
    end

    def insert_or_modify_vector name, vector
      name = name[0] unless @vectors.is_a?(MultiIndex)

      if @index.empty?
        insert_vector_in_empty name, vector
      else
        vec = prepare_for_insert name, vector

        assign_or_add_vector name, vec
      end
    end

    def assign_or_add_vector name, v
      # FIXME: fix this jugaad. need to make changes in Indexing itself.
      begin
        pos = @vectors[name]
      rescue IndexError
        pos = name
      end

      case
      when pos.is_a?(Daru::Index)
        assign_multiple_vectors pos, v
      when pos == name &&
        (@vectors.include?(name) || (pos.is_a?(Integer) && pos < @data.size))

        @data[pos] = v
      else
        assign_or_add_vector_rough name, v
      end
    end

    def assign_multiple_vectors pos, v
      pos.each do |p|
        @data[@vectors[p]] = v
      end
    end

    def assign_or_add_vector_rough name, v
      @vectors |= [name] unless @vectors.include?(name)
      @data[@vectors[name]] = v
    end

    def insert_vector_in_empty name, vector
      vec = Vector.coerce(vector.to_a, name: coerce_name(name))

      @index = vec.index
      assign_or_add_vector name, vec
      set_size

      @data.map! { |v| v.empty? ? v.reindex(@index) : v }
    end

    def prepare_for_insert name, arg
      if arg.is_a? Daru::Vector
        prepare_vector_for_insert name, arg
      elsif arg.respond_to?(:to_a)
        prepare_enum_for_insert name, arg
      else
        prepare_value_for_insert name, arg
      end
    end

    def prepare_vector_for_insert name, vector
      # so that index-by-index assignment is avoided when possible.
      return vector.dup if vector.index == @index
      Daru::Vector.new([], name: coerce_name(name), index: @index).tap { |v|
        @index.each do |idx|
          v[idx] = vector.index.include?(idx) ? vector[idx] : nil
        end
      }
    end

    def prepare_enum_for_insert name, enum
      if @size != enum.size
        raise "Specified vector of length #{enum.size} cannot be inserted in DataFrame of size #{@size}"
      end
      Daru::Vector.new(enum, name: coerce_name(name), index: @index)
    end

    def prepare_value_for_insert name, value
      Daru::Vector.new(Array(value) * @size, name: coerce_name(name), index: @index)
    end

    def insert_or_modify_row indexes, vector
      vector = coerce_vector vector

      raise SizeError, 'Vector length should match row length' if
        vector.size != @vectors.size

      @data.each_with_index do |vec, pos|
        vec.send(:set, indexes, vector.at(pos))
      end
      @index = @data[0].index

      set_size
    end

    def create_empty_vectors
      @data = @vectors.map do |name|
        Daru::Vector.new([], name: coerce_name(name), index: @index)
      end
    end

    def validate_labels
      if @vectors && @vectors.size != @data.size
        raise IndexError, "Expected equal number of vector names (#{@vectors.size}) " \
          "for number of vectors (#{@data.size})."
      end

      return unless @index && @data[0] && @index.size != @data[0].size
      raise IndexError, 'Expected number of indexes same as number of rows'
    end

    def validate_vector_sizes
      @data.each do |vector|
        raise IndexError, 'Expected vectors with equal length' if vector.size != @size
      end
    end

    def validate
      validate_labels
      validate_vector_sizes
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
      vectors = source.keys if vectors.nil?

      @vectors =
        if vectors.is_a?(Index) || vectors.is_a?(MultiIndex)
          vectors
        else
          Daru::Index.new((vectors + (source.keys - vectors)).uniq)
        end
    end

    def all_vectors_have_equal_indexes? source
      idx = source.values[0].index

      source.values.all? { |vector| idx == vector.index }
    end

    def coerce_name potential_name
      potential_name.is_a?(Array) ? potential_name.join : potential_name
    end

    def initialize_from_array source, vectors, index, opts
      raise ArgumentError, 'All objects in data source should be same class' \
        unless source.map(&:class).uniq.size == 1

      case source.first
      when Array
        vectors ||= (0..source.size-1).to_a
        initialize_from_array_of_arrays source, vectors, index, opts
      when Vector
        vectors ||= (0..source.size-1).to_a
        initialize_from_array_of_vectors source, vectors, index, opts
      when Hash
        initialize_from_array_of_hashes source, vectors, index, opts
      else
        raise ArgumentError, "Can't create DataFrame from #{source}"
      end
    end

    def initialize_from_array_of_arrays source, vectors, index, _opts
      if source.size != vectors.size
        raise ArgumentError, "Number of vectors (#{vectors.size}) should " \
          "equal order size (#{source.size})"
      end

      @index   = Index.coerce(index || source[0].size)
      @vectors = Index.coerce(vectors)

      update_data source, vectors
    end

    def initialize_from_array_of_vectors source, vectors, index, opts
      clone = opts[:clone] != false
      hsh = vectors.each_with_index.map do |name, idx|
        [name, source[idx]]
      end.to_h
      initialize(hsh, index: index, order: vectors, name: @name, clone: clone)
    end

    def initialize_from_array_of_hashes source, vectors, index, _opts
      names =
        if vectors.nil?
          source[0].keys
        else
          (vectors + source[0].keys).uniq
        end
      @vectors = Daru::Index.new(names)
      @index = Daru::Index.new(index || source.size)

      @data = @vectors.map do |name|
        v = source.map { |h| h.fetch(name) { h[name.to_s] } }
        Daru::Vector.new(v, name: coerce_name(name), index: @index)
      end
    end

    def initialize_from_hash source, vectors, index, opts
      create_vectors_index_with vectors, source

      if ArrayHelper.array_of?(source.values, Vector)
        initialize_from_hash_with_vectors source, index, opts
      else
        initialize_from_hash_with_arrays source, index, opts
      end
    end

    def initialize_from_hash_with_vectors source, index, opts
      vectors_have_same_index = all_vectors_have_equal_indexes?(source)

      clone = opts[:clone] != false
      clone = true unless index || vectors_have_same_index

      @index = deduce_index index, source, vectors_have_same_index

      if clone
        @data = clone_vectors source, vectors_have_same_index
      else
        @data.concat source.values
      end
    end

    def deduce_index index, source, vectors_have_same_index
      if !index.nil?
        Index.coerce index
      elsif vectors_have_same_index
        source.values[0].index.dup
      else
        all_indexes = source
                      .values.map { |v| v.index.to_a }
                      .flatten.uniq.sort # sort only if missing indexes detected

        Daru::Index.new all_indexes
      end
    end

    def clone_vectors source, vectors_have_same_index
      @vectors.map do |vector|
        # avoids matching indexes of vectors if all the supplied vectors
        # have the same index.
        if vectors_have_same_index
          source[vector].dup
        else
          Daru::Vector.new([], name: vector, index: @index).tap do |v|
            @index.each do |idx|
              v[idx] = source[vector].index.include?(idx) ? source[vector][idx] : nil
            end
          end
        end
      end
    end

    def initialize_from_hash_with_arrays source, index, _opts
      @index = Index.coerce(index || source.values[0].size)

      @vectors.each do |name|
        @data << Daru::Vector.new(source[name].dup, name: coerce_name(name), index: @index)
      end
    end

    def sort_build_row vector_locs, by_blocks, ascending, handle_nils, r1, r2 # rubocop:disable  Metrics/ParameterLists
      # Create an array to be used for comparison of two rows in sorting
      vector_locs
        .zip(by_blocks, ascending, handle_nils)
        .map do |vector_loc, by, asc, handle_nil|
        value = @data[vector_loc].data[asc ? r1 : r2]

        value = by.call(value) rescue nil if by

        sort_handle_nils value, asc, handle_nil || !by
      end
    end

    def sort_handle_nils value, asc, handle_nil
      case
      when !handle_nil
        value
      when asc
        [value.nil? ? 0 : 1, value]
      else
        [value.nil? ? 1 : 0, value]
      end
    end

    def sort_coerce_boolean opts, symbol, default, size
      val = opts[symbol]
      case val
      when true, false
        Array.new(size, val)
      when nil
        Array.new(size, default)
      when Array
        raise ArgumentError, "Specify same number of vector names and #{symbol}" if
          size != val.size
        val
      else
        raise ArgumentError, "Can't coerce #{symbol} from #{val.class} to boolean option"
      end
    end

    def sort_prepare_block vector_order, opts
      ascending   = sort_coerce_boolean opts, :ascending, true, vector_order.size
      handle_nils = sort_coerce_boolean opts, :handle_nils, false, vector_order.size

      by_blocks = vector_order.map { |v| (opts[:by] || {})[v] }
      vector_locs = vector_order.map { |v| @vectors[v] }

      lambda do |index1, index2|
        # Build left and right array to compare two rows
        left  = sort_build_row vector_locs, by_blocks, ascending, handle_nils, index1, index2
        right = sort_build_row vector_locs, by_blocks, ascending, handle_nils, index2, index1

        # Resolve conflict by Index if all attributes are same
        left  << index1
        right << index2
        left <=> right
      end
    end

    def verify_error_message row, test, id, i
      description, fields, = test
      values =
        if fields.empty?
          ''
        else
          ' (' + fields.collect { |k| "#{k}=#{row[k]}" }.join(', ') + ')'
        end
      "#{i+1} [#{row[id]}]: #{description}#{values}"
    end

    def prepare_pivot_values index, vectors, opts
      case opts[:values]
      when nil # values not specified at all.
        (@vectors.to_a - (index | vectors)) & numeric_vector_names
      when Array # multiple values specified.
        opts[:values]
      else # single value specified.
        [opts[:values]]
      end
    end

    def make_pivot_hash grouped, vectors, values, aggregate_function
      grouped.groups.map { |n, _| [n, {}] }.to_h.tap do |super_hash|
        values.each do |value|
          grouped.groups.each do |group_name, row_numbers|
            row_numbers.each do |num|
              arry = [value, *vectors.map { |v| self[v][num] }]
              sub_hash = super_hash[group_name]
              sub_hash[arry] ||= []

              sub_hash[arry] << self[value][num]
            end
          end
        end

        setup_pivot_aggregates super_hash, aggregate_function
      end
    end

    def setup_pivot_aggregates super_hash, aggregate_function
      super_hash.each_value do |sub_hash|
        sub_hash.each do |group_name, aggregates|
          sub_hash[group_name] = Daru::Vector.new(aggregates).send(aggregate_function)
        end
      end
    end

    def pivot_dataframe super_hash
      df_index   = Daru::MultiIndex.from_tuples super_hash.keys
      df_vectors = Daru::MultiIndex.from_tuples super_hash.values.flat_map(&:keys).uniq

      Daru::DataFrame.new({}, index: df_index, order: df_vectors).tap do |pivoted_dataframe|
        super_hash.each do |row_index, sub_h|
          sub_h.each do |vector_index, val|
            pivoted_dataframe[vector_index][row_index] = val
          end
        end
      end
    end

    def one_to_many_components pattern
      re = Regexp.new pattern.gsub('%v','(.+?)').gsub('%n','(\\d+?)')

      vars, numbers =
        @vectors
        .map { |v| v.scan(re) }
        .reject(&:empty?).flatten(1).transpose

      [vars.uniq, numbers.map(&:to_i).sort.uniq]
    end

    def one_to_many_row row, number, vars, pattern
      vars
        .map { |v|
          name = pattern.sub('%v', v).sub('%n', number.to_s)
          [v, row[name]]
        }.to_h
    end

    # Raises IndexError when one of the positions is not a valid position
    def validate_positions *positions, size
      positions = [positions] if positions.is_a? Integer
      positions.each do |pos|
        raise IndexError, "#{pos} is not a valid position." if pos >= size
      end
    end

    # Accepts hash, enumerable and vector and align it properly so it can be added
    def coerce_vector vector
      case vector
      when Daru::Vector
        vector.reindex @vectors
      when Hash
        Daru::Vector.new(vector).reindex @vectors
      else
        Daru::Vector.new vector
      end
    end

    def update_data source, vectors
      @data = @vectors.each_with_index.map do |_vec, idx|
        Daru::Vector.new(source[idx], index: @index, name: vectors[idx])
      end
    end

    def aggregated_colmn_value(options)
      colmn_value = []
      index_tuples = Array(@index).uniq
      options.keys.each do |vec|
        do_this_on_vec = options[vec]
        colmn_value << if @vectors.include?(vec)
                         apply_method_on_colmns(
                           vec, index_tuples, do_this_on_vec
                         )
                       else
                         apply_method_on_df(
                           index_tuples, do_this_on_vec
                         )
                       end
      end
      [colmn_value, index_tuples]
    end

    # coerce ranges, integers and array in appropriate ways
    def coerce_positions *positions, size
      if positions.size == 1
        case positions.first
        when Integer
          positions.first
        when Range
          size.times.to_a[positions.first]
        else
          raise ArgumentError, 'Unkown position type.'
        end
      else
        positions
      end
    end
  end
end
