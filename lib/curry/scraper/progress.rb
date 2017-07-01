# Banco del Progreso
require "mechanize"

module Scraper
  class Progress
    attr_reader :url,
      :euro,
      :dollar

    def initialize(url=DATA_URI)
      @url    = url
      @euro   = {}
      @dollar = {}

      @agent = Mechanize.new

      @agent.user_agent = Scraper::USER_AGENTS.sample

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
end
