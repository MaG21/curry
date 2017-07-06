# Banco del Progreso
require_relative 'scraper'

class Scraper::Progress
  attr_reader :url,
              :euro,
              :dollar

  def initialize(url=DATA_URI)
    @url    = url
    @euro   = {}
    @dollar = {}
    @agent  = Scraper.initialize_agent

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

    if node = @agent.page.search('//div[@id="compra_rd"]').first
      @dollar[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="venta_rd"]').first
      @dollar[:selling_rate]= node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="compra_rd_euro"]').first
      @euro[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = @agent.page.search('//div[@id="venta_rd_euro"]').first
      @euro[:selling_rate]= node.text[/[\d.]+/]
    end
  end

  DATA_URI     = URI('http://www.progreso.com.do/index.php')
end
