# frozen_string_literal: true

require 'xmlsimple'

# :nodoc
class XmlFilesDatasource
  include Enumerable

  def initialize(glob)
    @files = Dir.glob(glob).to_a
  end

  def normalize(o)
    o
  end

  def each(&block)
    return to_enum(:each) unless block

    @files.each do |xml_file|
      hash = XmlSimple.xml_in(
        xml_file,
        ForceArray: false,
        SuppressEmpty: ''
      )
      Array(normalize(hash)).each(&block)
    end
    
    self
  end

  def size
    @files.size
  end
end
