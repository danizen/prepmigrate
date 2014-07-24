require 'nokogiri'

module Prepmigrate
	class Page

		attr_reader :url, :path, :doc, :notes

		def initialize(url, body)
			@url = url
			@path = url.sub(/\.html?\Z/, '')
			@doc = Nokogiri::HTML::Document.parse (body)
			@notes = Array.new
		end

		def body
			@body ||= @doc.at_xpath("//div[@id='body']")
		end

		def title
			unless @title
				@title = (!body.nil?) ? @title = body.at_xpath("h1/text()") : nil
				@title.nil? && @title = doc.at_xpath("//head/title/text()")
			end
			@title
		end

		def type
			if sidebar? 
				"page_with_sidebar"
			elsif basic?
				"page"
			else
				raise Prepmigrate::UnknownContentTypeError.new path
			end
		end

		def primary
			unless @primary
				@primary = (!body.nil?) ? body.at_xpath("div[@id='primary']") : nil
			end
			@primary
		end

		def secondary
			unless @secondary
				@secondary = (!body.nil?) ? body.at_xpath("div[@id='secondary']") : nil
			end
			@secondary
		end

		def sidebar?
			!primary.nil?
		end

		def build (xml)
			xml.page do
				xml.path { xml.text path }
				xml.type { xml.text type }
				xml.title { xml.text title }
			end
		end

		def basic?
			!body.nil? and primary.nil?
		end
	end
end