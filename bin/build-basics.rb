#!/usr/bin/env ruby
require 'nokogiri'

begin
  $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
  require 'prepmigrate'
rescue IOError
end

if (ARGV.size != 1) 
	STDERR.puts "Usage: #{$0} CSV_path"
	exit 1
end

crawler = Prepmigrate::Crawler.new

builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
	xml.pages do
		CSV.foreach ARGV[0] do |row|
			url = row[0]
			automatic = row[1]
			if (url != 'URL' and automatic == 'Yes') 
				crawler.crawl url do |page|
					if page.basic?
						page.build xml
					end
				end
			end
		end
	end
end
puts builder.to_xml