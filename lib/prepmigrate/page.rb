require 'nokogiri'

module Prepmigrate
	class Page

		def initialize(path, body)
			@path = path.sub(/\.html?\Z/, '')
			@doc = Nokogiri::HTML::Document.parse (body)
			@notes = Array.new
		end

		def path
			@path
		end

		def doc
			@doc
		end

		def body
			@body ||= @doc.at_xpath("//div[@id='body']")
		end

		def title
			unless @title
				# lazy initialization
				@title = (!body.nil?) ? @title = body.at_xpath("h1/text()") : nil
				@title.nil? && @title = doc.at_xpath("//head/title/text()")
			end
			@title
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
				xml.title { xml.text title }
			end
		end

		def basic?
			!body.nil? and primary.nil?
		end
	end
end