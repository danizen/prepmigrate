#!/usr/bin/env ruby
require 'nokogiri'

begin
  $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
  require 'prepmigrate'
rescue IOError
end

if (ARGV.size != 2) 
  STDERR.puts "Usage: #{$0} type CSV_path"
  exit 1
end

type, csvpath = ARGV

crawler = Prepmigrate::Crawler.new

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
  xml.pages do
    CSV.foreach csvpath do |row|
      url = row[0]
      automatic = row[1]
      if (url != 'URL' and automatic == 'Yes') 
        crawler.crawl url do |page|
          if page.type.eql?(type)
            page.build xml
          end
        end
      end
    end
  end
end
puts builder.to_xml