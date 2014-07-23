#!/usr/bin/env ruby
require 'csv'
require 'uri'
require 'net/http'
require 'nokogiri'

if (ARGV.size != 1) 
	STDERR.puts "Usage: #{$0} CSV_path"
	exit 1
end

http = Net::HTTP.new "www.nlm.nih.gov"

CSV.foreach ARGV[0] do |row|
	origurl = row[0]
	automatic = row[1]
	if (origurl != 'URL' and automatic == 'Yes') 
		path = origurl.sub %r/\Ahttp:\/\/www\.nlm\.nih\.gov\//, '/'
    	path.sub! %r/\Awww\.nlm\.nih\.gov\//, '/'

	    res = http.request_get path
	    unless (res.is_a? Net::HTTPSuccess)
	    	STDERR.puts "HTTP ERROR: #{origurl}: #{res.code} #{res.msg}"
	    end

	    doc = Nokogiri::HTML::Document.parse(res.body)
	    if (body = doc.at_xpath("//div[@id='body']"))
	    	if (secondary = body.at_xpath("div[@id='secondary']"))
	    		STDOUT.puts "#{origurl}"
	    	end
	    end
	end
end