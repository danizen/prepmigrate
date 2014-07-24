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
            migrate_note "barbranding non-empty but h3 unrecognized"
          end
        end
      end
      @branding
    end

    ##
    # There's a lot to do here:
    #  - blah, blah 
    # 
    def check_content node
      if (classyul = node.at_xpath(".//ul[@class]")) 
        migrate_note "Found ul with class at #{classyul.line}"
      end

      if (anydiv = node.at_xpath(".//div"))
        migrate_note "Found div within content at #{anydiv.line}"
      end

      # look for relative images and make them absolute
      node.xpath('.//img[@src]').each do |img|
        src = URI(img.attr('src'))
        if (src.relative?) 
          src.scheme = 'http'
          src.hostname = 'www.nlm.nih.gov'
          img.src = src.to_s
        end
      end

      # look for absolute links and make them relative
      node.xpath('.//a[@href]').each do |link|
        href = URI(link.attr('href'))
        if (href.absolute? && href.scheme.eql?('http') && href.hostname.eql?("www.nlm.nih.gov"))
          href.scheme = nil
          href.hostname = nil
          link.href = href.to_s
        end
      end
    end

    def build_body node
      check_content node
      if (atitle = node.at_xpath('h1')) 
        atitle.remove
      end
      @htmltype = 'filtered'

      node.inner_html.strip
    end

    ## 
    # We don't do basicbody as lazy initialization because we only expect ever to use it once,
    # when building the new XML content.
    def newbody
      unless @newbody
        if basic?
          @newbody = build_body body
        elsif sidebar?
          @newbody = build_body primary
        else
          migrate_note "unknown document type"
          @newbody = nil
        end
      end
      @newbody
    end

    def newsidebar
      unless @newsidebar
        if sidebar?
          relbar = secondary.at_xpath("div[@id='relatedBar']")
          if relbar.nil?
            check_content secondary
            @newsidebar = secondary.inner_html.strip
            migrate_note "Sidebar content was not a related bar"
          else
            firstitem = relbar.at_xpath("ul/li")
            if (firstitem && (blueitem = firstitem.at_xpath(".//img")))
              @blueitem_src = blueitem.attr('src');
              @blueitem_alt = blueitem.attr('alt');
              firstitem.remove
            end
            frags = Array.new
            relbar.xpath("ul/li").each do |item|
              check_content item
              frags << item.inner_html.strip
            end
            @newsidebar = frags.join('')
          end
        else
          @newsidebar = nil
        end
      end
      @newsidebar
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
        unless branding .nil?
          xml.branding { xml.text branding }
        end
        if sidebar?
          xml.body { xml.text newbody }
          xml.sidebar { xml.text newsidebar }
        else
          xml.body { xml.text newbody }
        end
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