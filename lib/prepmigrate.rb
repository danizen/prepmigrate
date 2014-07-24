require "prepmigrate/version"
require "prepmigrate/crawler"
require "prepmigrate/page"

module Prepmigrate
	class Error < RuntimeError
	end

  	class UnknownContentTypeError < Error
  	end
end
