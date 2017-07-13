module Daru
  module Formatters
    class Table
      def self.format data, options={}
        new(data, options[:headers], options[:row_headers])
          .format(options[:threshold], options[:spacing])
      end

      def initialize(data, headers, row_headers)
        @data = data || []
        @headers = (headers || []).to_a
        @row_headers = (row_headers || []).to_a
        @row_headers = [''] * @data.to_a.size if @row_headers.empty?
      end

      DEFAULT_SPACING = 10
      DEFAULT_THRESHOLD = 15

      def format threshold=nil, spacing=nil
        rows = build_rows(threshold || DEFAULT_THRESHOLD)

        formatter = construct_formatter rows, spacing || DEFAULT_SPACING

        rows.map { |r| formatter % r }.join("\n")
      end

      private

      def build_rows threshold # rubocop:disable Metrics/AbcSize
        @row_headers.first(threshold).zip(@data).map do |(r, datarow)|
          [*[r].flatten.map(&:to_s), *(datarow || []).map(&method(:pretty_to_s))]
        end.tap do |rows|
          unless @headers.empty?
            spaces_to_add = rows.empty? ? 0 : rows.first.size - @headers.size
            rows.unshift [''] * spaces_to_add + @headers.map(&:to_s)
          end

          rows << ['...'] * rows.first.count if @row_headers.count > threshold
        end
      end

      def construct_formatter rows, spacing
        width = rows.flatten.map(&:size).max || 0
        width = [3, width].max # not less than 'nil'
        width = [width, spacing].min # not more than max width

        " %#{width}.#{width}s" * rows.first.size if rows.first
      end

      def pretty_to_s(val)
        val.nil? ? 'nil' : val.to_s
      end
    end
  end
end
