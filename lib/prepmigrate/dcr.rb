require 'nokogiri'
require 'uri'

module Prepmigrate
  class DCR

    attr_reader :doc, :url

    def initialize (doc, url)
      @doc = doc
      @url = url
    end

    def mkalias
      unless @alias
        uri = URI(url)
        uri.scheme = nil
        uri.hostname = nil                
        uri.path = uri.path.sub /\.html?\z/, ''
        @alias = uri.to_s
      end
      @alias
    end

    def record
      @record ||= doc.at_xpath("/record")
    end

    def title
      @title ||= record.at_xpath("item[@name='title']/value/text()")
    end

    def heading
      @heading ||= record.at_xpath("item[@name='heading']/value/text()")
    end

    def subheading
      unless @subheading
        @subheading = nil
        if (value = record.at_xpath("item[@name='subheading']/value"))
          @subheading = value.content().gsub /<\/?[^>]+>/, ''
        end
      end
      @subheading
    end

    def build (xml)
      xml.exhibition do
        xml.source { xml.text url }
        xml.alias { xml.text mkalias }
        xml.title { xml.text title }
        xml.heading { xml.text heading }
        xml.subheading { xml.text subheading }
      end
    end

  end
end