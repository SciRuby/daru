module Daru
  module IO
    class SqlDataSource
      # Private adapter class for DBI::DatabaseHandle
      # @private
      class DbiAdapter
        def initialize(dbh, query)
          @dbh = dbh
          @query = query
        end

        def each_column_name
          result.column_names.each do |column_name|
            yield(column_name.to_sym)
          end
        end

        def each_row
          result.fetch do |row|
            yield(row.to_a)
          end
        end

        private

        def result
          @result ||= @dbh.execute(@query)
        end
      end

      # Private adapter class for connections of ActiveRecord
      # @private
      class ActiveRecordConnectionAdapter
        def initialize(conn, query)
          @conn = conn
          @query = query
        end

        def each_column_name
          result.columns.each do |column_name|
            yield(column_name.to_sym)
          end
        end

        def each_row
          result.each do |row|
            yield(row.values)
          end
        end

        private

        def result
          @result ||= @conn.exec_query(@query)
        end
      end

      private_constant :DbiAdapter
      private_constant :ActiveRecordConnectionAdapter

      def self.make_dataframe(db, query)
        new(db, query).make_dataframe
      end

      def initialize(db, query)
        @adapter = init_adapter(db, query)
      end

      def make_dataframe
        vectors = {}
        fields = []
        @adapter.each_column_name do |column_name|
          vectors[column_name] = Daru::Vector.new([])
          vectors[column_name].rename column_name
          fields.push column_name
        end

        df = Daru::DataFrame.new(vectors, order: fields)
        @adapter.each_row do |row|
          df.add_row(row)
        end

        df.update

        df
      end

      private

      def init_adapter(db, query)
        begin
          query = query.to_str
        rescue
          raise ArgumentError, 'query must be a string'
        end

        case
        when check_dbi(db)
          DbiAdapter.new(db, query)
        when check_active_record_connection(db)
          ActiveRecordConnectionAdapter.new(db, query)
        else
          raise ArgumentError, 'unknown database type'
        end
      end

      def check_dbi(obj)
        obj.is_a?(DBI::DatabaseHandle)
      end

      def check_active_record_connection(obj)
        obj.is_a?(ActiveRecord::ConnectionAdapters::AbstractAdapter)
      end
    end
  end
end
