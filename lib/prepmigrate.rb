require "prepmigrate/version"
require "prepmigrate/crawler"
require "prepmigrate/page"
require "prepmigrate/item_map"
require "prepmigrate/dcr"

module Prepmigrate

  # My code does not go here
  def self.parse_dcr (dcr_path, url)

    # open the file
    f = File.new dcr_path, "r"
    raise RuntimeError, "Unable to open file #{dcr_path}" unless f

    # parse the file
    dcr = Prepmigrate::DCR.new Nokogiri::XML(f), url
    yield dcr if block_given?

    # close the file
    f.close

    return dcr
  end

end
