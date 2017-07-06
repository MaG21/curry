# BHD León Bank
require_relative 'scraper'

class Scraper::BHDLeon
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

    body = @agent.page.body.sub('<![CDATA[', '')
    xml  = Nokogiri.XML(body)

    if node = xml.css('tr:nth-child(2)/td:nth-child(2)').first
      @dollar[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = xml.css('tr:nth-child(2)/td:nth-child(3)').first
      @dollar[:selling_rate] = node.text[/[\d.]+/]
    end

    if node = xml.css('tr:nth-child(3)/td:nth-child(2)').first
      @euro[:buying_rate] = node.text[/[\d.]+/]
    end

    if node = xml.css('tr:nth-child(3)/td:nth-child(3)').first
      @euro[:selling_rate] = node.text[/[\d.]+/]
    end
  end

  DATA_URI = URI('https://www.bhdleon.com.do/wps/contenthandler/!ut/p/wcmrest/LibraryRichTextComponent/de81dd85-a711-4ef6-ba80-1992e9db7fd0')
end
