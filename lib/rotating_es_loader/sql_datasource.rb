# frozen_string_literal: true

require 'xmlsimple'

# :nodoc
class SqlDatasource
  include Enumerable

  def initialize(sql:, ar_connection:)
    @sql = sql
    @ar_connection = ar_connection
    raise unless @sql
  end

  def normalize(o)
    o
  end

  def data
    queries = @sql.is_a?(String) ? [@sql] : @sql

    queries.flat_map do |query|
      records_array = @ar_connection.execute(@sql)
      fields = records_array.fields.map(&:to_sym)

      records_array.map do |row_array|
        normalize(fields.zip(row_array).to_h)
      end
    end
  end

  def each(&block)
    return to_enum(:each) unless block

    data.each(&block)

    self
  end
end
