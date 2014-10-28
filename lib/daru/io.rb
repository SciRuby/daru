module Daru
  module IO
    class << self
      def from_csv path, opts={}
        opts[:col_sep]           ||= ','
        opts[:headers]           ||= true
        opts[:converters]        ||= :numeric
        opts[:header_converters] ||= :symbol
      end
    end
  end
end