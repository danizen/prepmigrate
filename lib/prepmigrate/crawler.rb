require 'net/http'
require 'uri'

module Prepmigrate
	class Crawler
		def initialize
			@http = Net::HTTP.new 'wwww.nlm.nih.gov'
		end

		def page (origurl)
			path = origurl.sub %r/\Ahttp:\/\/www\.nlm\.nih\.gov\//, '/'
    		path.sub! %r/\Awww\.nlm\.nih\.gov\//, '/'

	    	res = http.request_get path
	    	unless (res.is_a? Net::HTTPSuccess)
	    		STDERR.puts "HTTP ERROR: #{origurl}: #{res.code} #{res.msg}"
	    		return nil
	    	else
		    	doc = Nokogiri::HTML::Document.parse(res.body)
		    	page = Prepmigrate::Page.new res.body
		    	yield page if block_given?
		    	return page
		    end
		end
	end
end