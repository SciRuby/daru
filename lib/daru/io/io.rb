module Daru
  module IOHelpers
    class << self

    end
  end

  module IO
    class << self
      def from_csv path, opts={}
        opts[:col_sep]           ||= ','
        opts[:converters]        ||= :numeric

        # Preprocess headers for detecting and correcting repetition in 
        # case the :headers option is not specified.
        unless opts[:headers]
          csv = ::CSV.open(path, 'rb', opts)
          yield csv if block_given?

          csv_as_arrays = csv.to_a
          headers       = csv_as_arrays[0].recode_repeated.map(&:to_sym)
          csv_as_arrays.delete_at 0
          csv_as_arrays = csv_as_arrays.transpose

          hsh = {}
          headers.each_with_index do |h, i|
            hsh[h] = csv_as_arrays[i]
          end
        else
          opts[:header_converters] ||= :symbol
          
          csv = ::CSV.read(path, 'rb',opts)
          yield csv if block_given?

          hsh = {}
          csv.by_col.each do |col_name, values|
            hsh[col_name] = values
          end
        end

        Daru::DataFrame.new(hsh,opts)
      end

      def dataframe_write_csv dataframe, path, opts={}
        options = {
          converters: :numeric
        }.merge(opts)

        writer = ::CSV.open(path, 'w', options)
        writer << dataframe.vectors.to_a

        dataframe.each_row do |row|
          if options[:convert_comma]
            writer << row.map { |v| v.to_s.gsub('.', ',') }
          else
            writer << row.to_a
          end
        end

        writer.close
      end

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