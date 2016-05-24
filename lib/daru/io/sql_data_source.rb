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

        def result_hash
          columns = result.column_names.map(&:to_sym)
          data = result.to_a.map(&:to_a).transpose
          columns.zip(data).to_h
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

        def result_hash
          columns = result.columns.map(&:to_sym)
          data = result.cast_values.transpose

          columns.zip(data).to_h
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
        df = Daru::DataFrame.new(@adapter.result_hash)

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
