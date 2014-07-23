require 'nokogiri'

module Prepmigrate
	class Page

		def initialize(body)
			@doc = Nokogiri::HTML::Document.parse (body)
			@body = false
			@primary = false
			@secondary = false
			@relatedbar = false
			@notes = Array.new
		end

		def body
			if @body == false
				@body = @doc.at_xpath "//div[@id='body']"
			end
			@body
		end

		def primary
			if @primary == false
				@primary = body ? body.at_xpath "div[@id='primary']" : nil
			end
			@secondary
		end

		def secondary
			if @secondary == false
				@secondary = body ? body.at_xpath "div[@id='secondary']" : nil
			end
			@secondary
		end

		def relatedbar
			if @relatedbar == false
				@relatedbar = secondary ? secondary.at_xpath "div[@id='relatedBar']" : nil
			end
			@relatedBar
		end

		def is_sidebar?
			not (primary.nil? or primary == false)
		end

		def is_page?
			(not (body.nil? or body == false)) and not primary
		end
	end
end