#!/usr/bin/env ruby
require 'nokogiri'
require 'ostruct'

begin
  $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
  require 'prepmigrate'
rescue IOError
end

if (ARGV.size != 2) 
  STDERR.puts "Usage: #{$0} <type> { <CSV_path> | <url> }"
  STDERR.puts "type must be one of 'page', 'page_with_sidebar', 'factsheets', 'exhibition'"
  exit 1
end

type, csvpath = ARGV

crawler = Prepmigrate::Crawler.new

case type
  when 'factsheets' 
    fshash = Hash.new { |h,k| h[k] = Array.new }
    crawler.crawl csvpath do |page|
      fshash = page.factsheets_hash
    end
    unless fshash.empty?
      puts "Factsheet,Category"
      fshash.each_pair do |path,list|
        list.each do |item|
          puts "#{path},#{item}"
        end
      end
    end
  when 'exhibition'
    if (ARGV.size != 2) 
      STDERR.puts "Usage: #{$0} type [CSV_path]"
      STDERR.puts "CSV_path is required with type 'exhibition'"
      exit 1
    end
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.pages do
        CSV.foreach csvpath do |row|
          dcr_path = row[0]
          url = row[1]
          real_path = File.expand_path(dcr_path, File.dirname(csvpath))

          dcr = Prepmigrate.parse_dcr(real_path, url)
          raise RuntimeError, "What Happened" unless dcr

          xml.exhibition do 
            xml.filename { xml.text real_path }
            xml.source { xml.text url }
            xml.alias { xml.text dcr.mkalias }
            dcr.to_xml xml
          end
        end
      end
    end
    puts builder.to_xml
  when 'page',  'page_with_sidebar'
    if (ARGV.size != 2) 
      STDERR.puts "Usage: #{$0} type [CSV_path]"
      STDERR.puts "CSV_path is required with type 'page' or 'page_with_sidebar'"
      exit 1
    end
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.pages do
        CSV.foreach csvpath do |row|
          url = row[0]
          automatic = row[1]
          if (url != 'URL' and automatic == 'Yes') 
            crawler.crawl url do |page|
              if page.type.eql?(type)
                page.migrate_note row[2] unless (row[2].nil? || row[2].empty?)
                page.build xml
              end
            end
          end
        end
      end
    end
    puts builder.to_xml
  else
    STDERR.puts "Unknown type: \"#{type}\""
    STDERR.puts "type must be one of 'page', 'page_with_sidebar', 'exhibition', or 'factsheets'"
    exit 1
end
