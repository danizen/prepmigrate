require 'nokogiri'
require 'addressable/uri'

module Prepmigrate
  class DCR

    class TooManyValues < RuntimeError
    end

    attr_reader :doc, :url

    def initialize (doc, url)
      @doc = doc
      @url = url
    end

    def mkalias
      unless @alias
        uri = Addressable::URI.parse(url)
        uri.scheme = nil
        uri.hostname = nil                
        uri.path = uri.path.sub /\.html?\z/, ''
        @alias = uri.to_s
      end
      @alias
    end

    def items
      @items ||= Prepmigrate::ItemMap.new doc.xpath("/record/item")
    end

    def to_xml (xml)
      xml.dcr do
        items.to_xml xml
      end
    end

  end
end