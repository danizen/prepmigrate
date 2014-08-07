require 'nokogiri'

module Prepmigrate
  class ItemMap

    def initialize (items)
      @hash = Hash.new { |h,k| h[k] = Array.new }
      items.each do |item|
        name = item['name']
        item.xpath("value").each do |value|
          moreitems = value.xpath("item")
          if moreitems.size > 0 
            @hash[name] << Prepmigrate::ItemMap.new(moreitems)
          else
            content = value.content
            unless content.nil?
              content.strip!
              @hash[name] << content unless content.empty?
            end
          end
        end
      end
    end

    def [](name)
      @hash[name]
    end

    def size
      @hash.size
    end

    def each (&block)
      @hash.each block
    end

    def each_pair (&block)
      @hash.each_pair block
    end

    def to_xml (xml)
      @hash.each_pair do |key,values|
        unless values.empty?
          xml.send key do
            values.each do |value|
              if (value.is_a? Prepmigrate::ItemMap) 
                value.to_xml xml
              else
                xml.text value
              end
            end
          end
        end
      end
    end

  end
end