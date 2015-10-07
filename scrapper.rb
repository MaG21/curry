require 'uri'
require 'json'
require 'thwait'
require 'bigdecimal'

module Scrapper
	USER_AGENTS = ['Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.13+ (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2',
	               'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.2 Safari/537.36',
		       'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0',
		       'Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko']
end

class Scrapper::Info
	attr_reader :euro_mean,
		    :dollar_mean

	attr_reader :bpd,
		    :blh,
		    :progress,
		    :reservas,
		    :central_bank

	def initialize
		threads = []

		threads << Thread.new { @bpd          = Scrapper::BPD.new() }
		threads << Thread.new { @blh          = Scrapper::BLH.new() }
		threads << Thread.new { @progress     = Scrapper::Progress.new() }
		threads << Thread.new { @reservas     = Scrapper::Reservas.new() }
		threads << Thread.new { @central_bank = Scrapper::CentralBank.new }

		ThreadsWait.all_waits(*threads)

		@entities = [@bpd, @blh, @progress, @reservas]

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

		    :progress    => {:euro   => @progress.euro,
				     :dollar => @progress.dollar,
				     :source => @progress.url},

		    :bareservas  => {:euro   => @reservas.euro,
				     :dollar => @reservas.dollar,
				     :source => @reservas.url},

		    :euro_mean   => @euro_mean,
		    :dollar_mean => @dollar_mean
		}

		@serialized_info = JSON.pretty_generate(tmp_info)
	end

	private

	def compute_mean(currency, rate_type)
		n   = BigDecimal.new(0)
		sum = BigDecimal.new(0)

		@entities.each do|entity|
			next unless entity

			rate = entity.send(currency)[rate_type]

			next unless rate

			n   += 1
			sum += BigDecimal.new(1) / BigDecimal.new(rate)
		end

		(n / sum).to_f.to_s[/\d+\.\d{2}/].to_s   # do not round
	end

end

# Central Bank of the Dominican Republic
class Scrapper::CentralBank
	attr_reader :dollar
	def initialize(url=DATA_URL)
		@url    = url
		@dollar = {}

		parse_data()
	end

	def serialize
		return @serialized_info if @serialized_info

		tmp_info = {
		     :dollar => {:buying_rate  => @dollar[:buying_rate],
		                 :selling_rate => @dollar[:selling_rate]}
		}

		@serialized_info = JSON.pretty_generate(tmp_info)
	end

	private

	def parse_data
		buying_rate  = nil
		selling_rate = nil

		[:gocr, :ocrad].each do|engine|
			data   = get_data(@url, engine)
			values = data.scan(/(?<=D.)..\.../)

			tmp_buying_rate, tmp_selling_rate = values.collect {|rate| rate.tr('lIOS', '1105').tr ' ', ''}

			if buying_rate.nil?  and tmp_buying_rate =~ /\d{2}\.\d{2}+/
				buying_rate = tmp_buying_rate.strip
			end

			if selling_rate.nil? and tmp_selling_rate =~ /\d{2}\.\d{2}+/
				selling_rate = tmp_selling_rate.strip
			end

			break unless buying_rate.to_s.empty? or selling_rate.to_s.empty?
		end

		@dollar[:buying_rate]  = buying_rate.to_s[/\d+\.\d{2}/].to_s
		@dollar[:selling_rate] = selling_rate.to_s[/\d+\.\d{2}/].to_s
	end

	def get_data(url, engine=:ocrad)
		r_fd, w_fd = IO.pipe

		case engine
		when :ocrad
			spawn "curl -s #{@url}| djpeg -grayscale -pnm | ocrad -F utf8", :out => w_fd
		when :gocr
			spawn "curl -s #{@url}| djpeg -grayscale -pnm | gocr -f UTF8 -", :out => w_fd
		else
			return ''
		end

		w_fd.close
		data = r_fd.read
		r_fd.close
		data
	end

	DATA_URL = 'http://www.bancentral.gov.do/tasas_cambio/tasaus_mc.jpg'
	DATA_URI = URI(DATA_URL)
end

# Dominican Popular Bank
class Scrapper::BPD
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro  = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent             = Scrapper::USER_AGENTS.sample
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

		nodes = @agent.page.search(XPATH_STRING)

		text = nodes.map(&:text).join

		# The order in wich euros and dollars are placed it's unknown, by general,
		# the dollar's rate comes first, however, that can't be taken for granted.
		# Otherwise the resulting regular expressions would be much simpler.
		# Actually these regular expressions can be used against the entire site and still
		# they will yield the desired result.
		text[/d.ll?ar\s+(:?[\d.]+\s[CV]\s*){2}/i].to_s.scan(/([\d.]+)\s([CV])/i) do|value, type|
			if type.upcase == 'C'
				@dollar[:buying_rate] = value
			else
				@dollar[:selling_rate]= value
			end
		end

		text[/euro\s+(:?[\d.]+\s[CV]\s*){2}/i].to_s.scan(/([\d.]+)\s([CV])/i) do|value, type|
			if type.upcase == 'C'
				@euro[:buying_rate] = value
			else
				@euro[:selling_rate]= value
			end
		end
	end

	DATA_URI     = URI('https://www.popularenlinea.com/personas/Paginas/Home.aspx')
	XPATH_STRING = '//div[@class="divisa"]'
end

class Scrapper::Progress
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent = Scrapper::USER_AGENTS.sample

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

# Lopez de Haro Bank
class Scrapper::BLH
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent = Scrapper::USER_AGENTS.sample

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

	DATA_URI = URI('http://www.blh.com.do/Inicio.aspx')
end


class Scrapper::Reservas
	attr_reader :url,
		    :euro,
		    :dollar

	def initialize(url=DATA_URI)
		@url    = url
		@euro   = {}
		@dollar = {}

		@agent = Mechanize.new

		@agent.user_agent = Scrapper::USER_AGENTS.sample

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

		values = @agent.page.search('//table[@class="tabla-divisas"]/tbody/tr/td').map(&:text)

		return if values.empty?

		if values.first =~ /d.l?lar/i
			@dollar[:buying_rate], @dollar[:selling_rate] = values[1,2]
		end
		
		if values[4] =~ /euro/i
			@euro[:buying_rate], @euro[:selling_rate]     = values[5,2]
		end
	end

	DATA_URI = URI('http://www.banreservas.com/Pages/index.aspx')
end

