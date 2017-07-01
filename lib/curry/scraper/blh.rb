# Lopez de Haro Bank
require "mechanize"
module Scraper
  class BLH
    attr_reader :url,
      :euro,
      :dollar

    def initialize(url=DATA_URI)
      @url    = url
      @euro   = {}
      @dollar = {}

      @agent = Mechanize.new

      @agent.user_agent             = Scraper::USER_AGENTS.sample
      @agent.ssl_version            = :TLSv1
      @agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

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
end
