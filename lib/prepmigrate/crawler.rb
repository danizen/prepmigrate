require 'net/http'
require 'uri'
require 'csv'

module Prepmigrate
	class Crawler
		def initialize
			@http = Net::HTTP.new 'www.nlm.nih.gov'
		end

		def crawl (origurl)
	    	res = @http.request_get origurl
	    	unless (res.is_a? Net::HTTPSuccess)
	    		STDERR.puts "HTTP ERROR: #{origurl}: #{res.code} #{res.msg}"
	    		return nil
	    	else
		    	page = Prepmigrate::Page.new origurl, res.body
		    	yield page if block_given?
		    	return page
		    end
		end
	end
end