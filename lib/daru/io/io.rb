module Daru
  module IO
    class << self
      def from_csv path, opts={}
        opts[:col_sep]           ||= ','
        opts[:headers]           ||= true
        opts[:converters]        ||= :numeric
        opts[:header_converters] ||= :symbol

        csv = CSV.open(path, 'r', opts)

        yield csv if block_given?

        first = true
        df    = nil

        csv.each_with_index do |row, index|
          if first
            df    = Daru::DataFrame.new({}, csv.headers)
            first = false
          end

          df.row[index] = row.fields
        end

        df
      end
    end
  end
end