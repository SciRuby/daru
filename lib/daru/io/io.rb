module Daru
  module IO
    class << self
      def from_csv path, opts={}
        opts[:col_sep]           ||= ','
        opts[:headers]           ||= true
        opts[:converters]        ||= :numeric
        opts[:header_converters] ||= :symbol

        csv = CSV.read(path, 'r', opts)

        yield csv if block_given?

        hsh = {}
        csv.by_col!.each do |col_name, values|
          hsh[col_name] = values
        end

        Daru::DataFrame.new(hsh)
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