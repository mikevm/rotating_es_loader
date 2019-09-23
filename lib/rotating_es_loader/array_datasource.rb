# frozen_string_literal: true

# :nodoc
class ArrayDatasource
  include Enumerable

  def initialize(data)
    @data = data
    @iter = data.each
  end

  def each(&block)
    return to_enum(:each) unless block

    @data.each(&block)
    self
  end

  def size
    @data.size
  end
end
