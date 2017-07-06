# Lopez de Haro Bank
require_relative 'scraper'

class Scraper::BLH
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

    if node = @agent.page.search('//div[@id="usdbuy"]').first
      @dollar[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="usdsell"]').first
      @dollar[:selling_rate] = node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="eurbuy"]').first
      @euro[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="eursell"]').first
      @euro[:selling_rate] = node.text[/[\d.]+/]
    end
  end

  DATA_URI = URI('https://www.blh.com.do/Inicio.aspx')
end
