require_relative 'scraper/bhdleon'
require_relative 'scraper/blh'
require_relative 'scraper/bpd'
require_relative 'scraper/central_bank'
require_relative 'scraper/progress'
require_relative 'scraper/reservas'

require_relative 'version'

module Curry
  include Scraper
end

