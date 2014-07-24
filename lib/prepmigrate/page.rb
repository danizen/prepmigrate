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
        !@title.nil? && @title = @title.content.strip
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

    def branding
      unless @branding
        barbranding = doc.at_xpath("//div[@id='barbranding']")
        if barbranding.nil? or barbranding.child.nil?
          @branding = nil
        else
          h3brand = barbranding.at_xpath("h3")
          h3content = h3brand.nil? ? '' : h3brand.content
          case h3brand.content
          when /Bibliographic Services/
            @branding = 'BSD'
          when /Extramural Funding/
            @branding = 'EP'
          when /History/
            @branding = 'HMD'
          when /Public Services/
            @branding = 'PSD'
          when /Acquisitions/
            @branding = 'TSD Acquisitions'
          when /Cataloging/
            @branding = 'TSD Cataloging'
          when /APIs/
            @branding = 'API'
          when /UMLS/
            @branding = 'UMLS'
          when /Medical Subject Headings/
            @branding = 'MeSH'
          when nil
            @branding = nil
            migrate_note "barbranding non-empty but h3 missing"
          else
            @branding = nil
            migrate_note "barbranding non-empty but h3 blank or unrecognized"
          end
        end
      end
      @branding
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
        xml.branding { xml.text branding }
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