require 'nokogiri'
require 'uri'

module Prepmigrate
  class Page

    class UnknownContentTypeError < RuntimeError
    end

    class MissingTitleError < RuntimeError 
    end

    class NoteMustBeString < RuntimeError
    end

    attr_reader :url, :path, :doc, :notes

    def initialize(url, body)
      @url = url
      @path = URI(url).path.sub /\.html?\Z/, ''
      @doc = Nokogiri::HTML::Document.parse (body)
      @notes = Array.new
    end

    def migrate_note (msg)
      raise NoteMustBeStringError, "unexpected class #{msg.class}" unless msg.is_a? String
      @notes << msg
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
        raise UnknownContentTypeError, url
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

    def basic?
      !body.nil? and primary.nil?
    end

    def build (xml)
      look_for_styles_and_scripts

      xml.page do
        xml.path { xml.text path }
        xml.type { xml.text type }
        xml.title { xml.text title }
        if notes.size > 0
          xml.notes { notes.each { |note| xml.note { xml.text note } } }
        end
      end
    end

    def look_for_styles_and_scripts
      el = doc.at_xpath('//head/title')
      raise MissingTitleError, url unless el
      el = el.next
      until el.nil? do 
        case el.node_name
        when 'style'
          migrate_note "unsupported style element at line #{el.line}"
        when 'script'
          unless (el.attr('src') =~ /forsee-surveydef/) 
            migrate_note "Unsupported script element at line #{el.line}"
          end
        when 'link'
          if (el.attr('rel').eql?('stylesheet'))
            migrate_note "Unsupported stylesheet link at line #{el.line}"
          end
        end
        el = el.next
      end
    end
  end
end