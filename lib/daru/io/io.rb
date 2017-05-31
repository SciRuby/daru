module Daru
  module IOHelpers
    class << self
      def process_row(row,empty)
        row.to_a.map do |c|
          if empty.include?(c)
            # FIXME: As far as I can guess, it will never work.
            # It is called only inside `from_plaintext`, and there
            # data is splitted by `\s+` -- there is no chance that
            # "empty" (currently just '') will be between data?..
            nil
          else
            try_string_to_number(c)
          end
        end
      end

      private

      INT_PATTERN = /^[-+]?\d+$/
      FLOAT_PATTERN = /^[-+]?\d+[,.]?\d*(e-?\d+)?$/

      def try_string_to_number(s)
        case s
        when INT_PATTERN
          s.to_i
        when FLOAT_PATTERN
          s.tr(',', '.').to_f
        else
          s
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
        headers      = ArrayHelper.recode_repeated(worksheet.row(0)).map(&:to_sym)

        df = Daru::DataFrame.new({})
        headers.each_with_index do |h,i|
          col = worksheet.column(i).to_a
          col.delete_at 0
          df[h] = col
        end

        df
      end

      def dataframe_write_excel dataframe, path, _opts={}
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
        daru_options, opts = from_csv_prepare_opts opts
        # Preprocess headers for detecting and correcting repetition in
        # case the :headers option is not specified.
        hsh =
          if opts[:headers]
            from_csv_hash_with_headers(path, opts)
          else
            from_csv_hash(path, opts)
              .tap { |hash| daru_options[:order] = hash.keys }
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
      # @param dbh [DBI::DatabaseHandle, String] A DBI connection OR Path to a SQlite3 database.
      # @param query [String] The query to be executed
      #
      # @return A dataframe containing the data resulting from the query
      def from_sql(db, query)
        require 'daru/io/sql_data_source'
        SqlDataSource.make_dataframe(db, query)
      end

      def dataframe_write_sql ds, dbh, table
        require 'dbi'
        query = "INSERT INTO #{table} ("+ds.vectors.to_a.join(',')+') VALUES ('+(['?']*ds.vectors.size).join(',')+')'
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

        vectors = fields.map { |name| [name, Daru::Vector.new([], name: name)] }.to_h

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

      def from_html path, opts
        page = Mechanize.new.get(path)
        page.search('table').map { |table| html_parse_table table }
            .keep_if { |table| html_search table, opts[:match] }
            .compact
            .map { |table| html_decide_values table, opts }
            .map { |table| html_table_to_dataframe table }
      rescue LoadError
        STDERR.puts '\nInstall the mechanize gem version 2.7.5 for using'\
        ' from_html function.'
      end

      private

      DARU_OPT_KEYS = %i[clone order index name].freeze

      def from_csv_prepare_opts opts
        opts[:col_sep]           ||= ','
        opts[:converters]        ||= :numeric

        daru_options = opts.keys.each_with_object({}) do |k, hash|
          hash[k] = opts.delete(k) if DARU_OPT_KEYS.include?(k)
        end
        [daru_options, opts]
      end

      def from_csv_hash_with_headers(path, opts)
        opts[:header_converters] ||= :symbol
        ::CSV
          .parse(open(path), opts)
          .tap { |c| yield c if block_given? }
          .by_col.map { |col_name, values| [col_name, values] }.to_h
      end

      def from_csv_hash(path, opts)
        csv_as_arrays =
          ::CSV
          .parse(open(path), opts)
          .tap { |c| yield c if block_given? }
          .to_a
        headers       = ArrayHelper.recode_repeated(csv_as_arrays.shift)
        csv_as_arrays = csv_as_arrays.transpose
        headers.each_with_index.map { |h, i| [h, csv_as_arrays[i]] }.to_h
      end

      def html_parse_table(table)
        headers, headers_size = html_scrape_tag(table,'th')
        data, size = html_scrape_tag(table, 'td')
        data = data.keep_if { |x| x.count == size }
        order, indice = html_parse_hash(headers, size, headers_size) if headers_size >= size
        return unless (indice.nil? || indice.count == data.count) && !order.nil? && order.count>0
        {data: data.compact, index: indice, order: order}
      end

      def html_scrape_tag(table, tag)
        arr  = table.search('tr').map { |row| row.search(tag).map { |val| val.text.strip } }
        size = arr.map(&:count).max
        [arr, size]
      end

      # Splits headers (all th tags) into order and index. Wherein,
      # Order : All <th> tags on first proper row of HTML table
      # index : All <th> tags on first proper column of HTML table
      def html_parse_hash(headers, size, headers_size)
        headers_index = headers.find_index { |x| x.count == headers_size }
        order = headers[headers_index]
        order_index = order.count - size
        order = order[order_index..-1]
        indice = headers[headers_index+1..-1].flatten
        indice = nil if indice.to_a.empty?
        [order, indice]
      end

      def html_search(table, match=nil)
        match.nil? ? true : (table.to_s.include? match)
      end

      # Allows user to override the scraped order / index / data
      def html_decide_values(scraped_val={}, user_val={})
        %I[data index name order].each do |key|
          user_val[key] ||= scraped_val[key]
        end
        user_val
      end

      def html_table_to_dataframe(table)
        Daru::DataFrame.rows table[:data],
          index: table[:index],
          order: table[:order],
          name: table[:name]
      end
    end
  end
end
