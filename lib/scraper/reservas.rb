# Banco del Reservas
require_relative 'scraper'

class Scraper::Reservas
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
      @agent.get @url
    rescue SocketError
      $stderr.puts $!
      return
    end

    values = @agent.page.search('//table[@class="currency-box-table"]/tbody/tr[@class="even"]/td').map(&:text)

    return if values.to_a.empty?

    if values.first =~ /USD/i
      @dollar[:buying_rate], @dollar[:selling_rate] = values[1,2]
    end

    values = @agent.page.search('//table[@class="currency-box-table"]/tbody/tr[@class="odd"][2]/td').map(&:text)

    return if values.to_a.empty?

    if values.first =~ /EUR/i
      @euro[:buying_rate], @euro[:selling_rate]    = values[1,2]
    end
  end

  DATA_URI = URI('http://www.banreservas.com/Pages/index.aspx')
end
