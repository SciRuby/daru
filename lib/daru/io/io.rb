module Daru
  module IOHelpers
    class << self
      def process_row(row,empty)
        row.to_a.map do |c|
          if empty.include?(c)
            nil
          elsif c.is_a? String and c.is_number?
            c =~ /^\d+$/ ? c.to_i : c.tr(',','.').to_f
          else
            c
          end
        end
      end
    end
  end

  module IO
    class << self
      # Functions for loading/writing Excel files.

      def from_excel path, opts={}
        opts = {
          worksheet_id: 0
        }.merge opts

        worksheet_id = opts[:worksheet_id]
        book         = Spreadsheet.open path
        worksheet    = book.worksheet worksheet_id
        headers      = worksheet.row(0).recode_repeated.map(&:to_sym)

        df = Daru::DataFrame.new({})
        headers.each_with_index do |h,i|
          col = worksheet.column(i).to_a
          col.delete_at 0
          df[h] = col
        end

        df
      end

      def dataframe_write_excel dataframe, path, opts={}
        book   = Spreadsheet::Workbook.new
        sheet  = book.create_worksheet
        format = Spreadsheet::Format.new color: :blue, weight: :bold

        sheet.row(0).concat(dataframe.vectors.to_a.map(&:to_s)) # Unfreeze strings
        sheet.row(0).default_format = format
        i = 1
        dataframe.each_row do |row|
          sheet.row(i).concat(row.to_a)
          i += 1
        end

        book.write(path)
      end

      # Functions for loading/writing CSV files
      def from_csv path, opts={}
        opts[:col_sep]           ||= ','
        opts[:converters]        ||= :numeric

        daru_options = opts.keys.each_with_object({}) do |hash, k|
          if [:clone, :order, :index, :name].include?(k)
            hash[k] = opts[k]
            opts.delete k
          end
        end

        # Preprocess headers for detecting and correcting repetition in
        # case the :headers option is not specified.
        if opts[:headers]
          opts[:header_converters] ||= :symbol

          csv = ::CSV.read(path, 'rb',opts)
          yield csv if block_given?

          hsh = {}
          csv.by_col.each do |col_name, values|
            hsh[col_name] = values
          end
        else
          csv = ::CSV.open(path, 'rb', opts)
          yield csv if block_given?

          csv_as_arrays = csv.to_a
          headers       = csv_as_arrays[0].recode_repeated.map
          csv_as_arrays.delete_at 0
          csv_as_arrays = csv_as_arrays.transpose

          hsh = {}
          headers.each_with_index do |h, i|
            hsh[h] = csv_as_arrays[i]
          end

          # Order columns as given in CSV
          daru_options[:order] = headers.to_a
        end

        Daru::DataFrame.new(hsh,daru_options)
      end

      def dataframe_write_csv dataframe, path, opts={}
        options = {
          converters: :numeric
        }.merge(opts)

        writer = ::CSV.open(path, 'w', options)
        writer << dataframe.vectors.to_a unless options[:headers] == false

        dataframe.each_row do |row|
          writer << if options[:convert_comma]
                      row.map { |v| v.to_s.tr('.', ',') }
                    else
                      row.to_a
                    end
        end

        writer.close
      end

      # Execute a query and create a data frame from the result
      #
      # @param dbh [DBI::DatabaseHandle] A DBI connection to be used to run the query
      # @param query [String] The query to be executed
      #
      # @return A dataframe containing the data resulting from the query

      def from_sql(db, query)
        require 'daru/io/sql_data_source'
        SqlDataSource.make_dataframe(db, query)
      end

      def dataframe_write_sql ds, dbh, table
        require 'dbi'
        query = "INSERT INTO #{table} ("+ds.vectors.to_a.join(',')+') VALUES ('+((['?']*ds.vectors.size).join(','))+')'
        sth   = dbh.prepare(query)
        ds.each_row { |c| sth.execute(*c.to_a) }
        true
      end

      # Load dataframe from AR::Relation
      #
      # @param relation [ActiveRecord::Relation] A relation to be used to load the contents of dataframe
      #
      # @return A dataframe containing the data in the given relation
      def from_activerecord(relation, *fields)
        if fields.empty?
          records = relation.map do |record|
            record.attributes.symbolize_keys
          end
          return Daru::DataFrame.new(records)
        else
          fields = fields.map(&:to_sym)
        end

        vectors = Hash[*fields.map { |name|
          [
            name,
            Daru::Vector.new([]).tap {|v| v.rename name }
          ]
        }.flatten]

        Daru::DataFrame.new(vectors, order: fields).tap do |df|
          relation.pluck(*fields).each do |record|
            df.add_row(Array(record))
          end
          df.update
        end
      end

      # Loading data from plain text files

      def from_plaintext filename, fields
        ds = Daru::DataFrame.new({}, order: fields)
        fp = File.open(filename,'r')
        fp.each_line do |line|
          row = Daru::IOHelpers.process_row(line.strip.split(/\s+/),[''])
          next if row == ["\x1A"]
          ds.add_row(row)
        end
        ds.update
        fields.each { |f| ds[f].rename f }
        ds
      end

      # Loading and writing Marshalled DataFrame/Vector
      def save klass, filename
        fp = File.open(filename, 'w')
        Marshal.dump(klass, fp)
        fp.close
      end

      def load filename
        if File.exist? filename
          o = false
          File.open(filename, 'r') { |fp| o = Marshal.load(fp) }
          o
        else
          false
        end
      end
    end
  end
end
