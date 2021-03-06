require 'uri'
require 'open-uri'
require 'json'
require 'thwait'
require 'bigdecimal'
require 'mechanize'
require 'fileutils'
require 'simple-spreadsheet'

module Scraper
	USER_AGENTS = ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
	               'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393',
		       'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
		       'Mozilla/5.0 (iPad; CPU OS 10_3_2 like Mac OS X) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.0 Mobile/14F89 Safari/602.1']
end

class Scraper::Info
	attr_reader :euro_mean,
		    :dollar_mean

	attr_reader :bpd,
		    :blh,
		    :reservas,
		    :central_bank

	def initialize
		threads = []

		threads << Thread.new { @bpd          = Scraper::BPD.new() }
		threads << Thread.new { @blh          = Scraper::BLH.new() }
		threads << Thread.new { @bhdleon      = Scraper::BHDLeon.new() }
		threads << Thread.new { @reservas     = Scraper::Reservas.new() }
		threads << Thread.new { @central_bank = Scraper::CentralBank.new }

		ThreadsWait.all_waits(*threads)

		@entities = [@bpd, @blh, @bhdleon, @reservas]

		@euro_mean   = { :buying_rate  => compute_mean(:euro, :buying_rate),
		                 :selling_rate => compute_mean(:euro, :selling_rate)}

		@dollar_mean = { :buying_rate  => compute_mean(:dollar, :buying_rate),
		                 :selling_rate => compute_mean(:dollar, :selling_rate)}
	end

	# => {date => String(DDMMYYYY), data => String(JSON)}
	def serialize
		return @serialized_info if @serialized_info

		tmp_info = {
		    :bpd         => {:euro   => @bpd.euro,
				     :dollar => @bpd.dollar,
		                     :source => @bpd.url},

		    :blh         => {:euro   => @blh.euro,
				     :dollar => @blh.dollar,
		                     :source => @blh.url},

		    :bhdleon     => {:euro   => @bhdleon.euro,
				     :dollar => @bhdleon.dollar,
		                     :source => @bhdleon.url},

		    :banreservas => {:euro   => @reservas.euro,
				     :dollar => @reservas.dollar,
				     :source => @reservas.url},

		    :euro_mean   => @euro_mean,
		    :dollar_mean => @dollar_mean
		}

		@serialized_info = JSON.pretty_generate(tmp_info)
	end

	private

	def compute_mean(currency, rate_type)
		n   = BigDecimal(0)
		sum = BigDecimal(0)

		@entities.each do|entity|
			next unless entity

			rate = entity.send(currency)[rate_type]

			next unless rate

			n   += 1
			sum += BigDecimal(1) / BigDecimal(rate)
		end

		("%.04f" % (n/sum))[/\d+\.\d{2}/].to_s
	end
end

# Central Bank of the Dominican Republic
class Scraper::CentralBank
	attr_reader :dollar
	def initialize(url=DATA_URI)
		@url    = url
		@dollar = Hash.new { String.new }

		parse_data()
	end

	def serialize
		return @serialized_info if @serialized_info

		tmp_info = {
			:dollar => {
				:buying_rate  => @dollar[:buying_rate].to_s,
				:selling_rate => @dollar[:selling_rate].to_s
			}
		}

		@serialized_info = JSON.pretty_generate(tmp_info)
	end

	private

	def parse_data
		get_data(DATA_URI) do|file|
			path = "#{file.path}.xls"

			FileUtils.mv(file.path, path)

			xls  = SimpleSpreadsheet::Workbook.read(path)

			xls.selected_sheet = xls.sheets.first

			row  = xls.last_row

			@dollar[:buying_rate]  = xls.cell(row, 4)
			@dollar[:selling_rate] = xls.cell(row, 5)
		end
	end

	# yields file
	def get_data(url, &block)
		mutex       = Mutex.new
		file_length = 0

		opts = {}

		# This lambda gets called once. The argument is the
		# length of the file as per the HTTP header sent by
		# the server.
		opts[:content_length_proc] = lambda do|len|
			file_length = len
			mutex.lock
		end

		# This lambda could be called multiple times. Each time,
		# it passes the actual number of bytes downloaded.
		opts[:progress_proc] = lambda do|delta|
			mutex.unlock if delta >= file_length
		end

		open(url, opts) do|file|

			# Attempts to grab the lock and waits if it isn't available
			# We want to wait if the file isn't fully downloaded.
			mutex.lock

			block.call(file)
		end
	end

	DATA_URI         = URI('https://bcrdgdcprod.blob.core.windows.net/documents/estadisticas/mercado-cambiario/documents/TASA_DOLAR_REFERENCIA_MC.xls')
	BUYING_RATE_IDX  = 0
	SELLING_RATE_IDX = 1
end

# Dominican Popular Bank
class Scraper::BPD
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro  = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent             = Scraper::USER_AGENTS.sample
		@agent.ssl_version            = :TLSv1_2
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

# Lopez de Haro Bank
class Scraper::BLH
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent             = Scraper::USER_AGENTS.sample
		@agent.ssl_version            = :TLSv1_2
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

		node  = @agent.page.search("//div[@class='iwithtext']/div[@class='iwt-text']/p")

		@dollar[:buying_rate], @dollar[:selling_rate] = node.text[/DÓLAR.*[\d.]+/].to_s.scan(/[\d.]+/)
		@euro[:buying_rate], @euro[:selling_rate]     = node.text[/EUROS.*[\d.]+/].to_s.scan(/[\d.]+/)
	end

	DATA_URI = URI('https://www.blh.com.do/')
end

class Scraper::BHDLeon
	attr_reader :url,
		:euro,
		:dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent             = Scraper::USER_AGENTS.sample
		@agent.ssl_version            = :TLSv1_2
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

		body = @agent.page.body.sub('<![CDATA[', '')
		xml  = Nokogiri.XML(body)

		if node = xml.css('tr:nth-child(2)/td:nth-child(2)').first
			@dollar[:buying_rate] = node.text[/[\d.]+/].to_s
		end

		if node = xml.css('tr:nth-child(2)/td:nth-child(3)').first
			@dollar[:selling_rate] = node.text[/[\d.]+/].to_s
		end

		if node = xml.css('tr:nth-child(3)/td:nth-child(2)').first
			@euro[:buying_rate] = node.text[/[\d.]+/].to_s
		end

		if node = xml.css('tr:nth-child(3)/td:nth-child(3)').first
			@euro[:selling_rate] = node.text[/[\d.]+/].to_s
		end
	end

	DATA_URI = URI('https://www.bhdleon.com.do/wps/contenthandler/!ut/p/wcmrest/LibraryRichTextComponent/de81dd85-a711-4ef6-ba80-1992e9db7fd0')
end

class Scraper::Reservas
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent = Scraper::USER_AGENTS.sample
		@agent.ssl_version            = :TLSv1_2
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

	DATA_URI = URI('https://www.banreservas.com/')
end
