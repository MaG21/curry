require_relative 'scraper'

class Scraper::BPD
  attr_reader :url,
    :euro,
    :dollar

  def initialize(url=DATA_URI)
    @url    = url
    @euro   = {}
    @dollar = {}
    @agent  = Scraper.initialize_agent()

    parse_page()
  end

  def refresh
    parse_page()
    true
  end

  private

  def parse_page
    begin
      result = @agent.get @url
    rescue SocketError
      $stderr.puts $!
      return
    end

    xml = Nokogiri.XML(result.body)

    @dollar[:buying_rate]  = "%.02f" % xml.search(XPATH_DOLLAR_BUYING_RATE).first.text.to_f
    @dollar[:selling_rate] = "%.02f" % xml.search(XPATH_DOLLAR_SELLING_RATE).first.text.to_f

    @euro[:buying_rate]    = "%.02f" % xml.search(XPATH_EURO_BUYING_RATE).first.text.to_f
    @euro[:selling_rate]   = "%.02f" % xml.search(XPATH_EURO_SELLING_RATE).first.text.to_f
  end

  DATA_URI     = URI("https://www.popularenlinea.com/_api/web/lists/getbytitle('Rates')/items")

  XPATH_DOLLAR_BUYING_RATE  = '//d:DollarBuyRate'
  XPATH_DOLLAR_SELLING_RATE = '//d:DollarSellRate'

  XPATH_EURO_BUYING_RATE    = '//d:EuroBuyRate'
  XPATH_EURO_SELLING_RATE   = '//d:EuroSellRate'
end
