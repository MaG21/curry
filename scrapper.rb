require 'uri'
require 'open-uri'
require 'json'
require 'thwait'
require 'bigdecimal'
require 'mkmf'
require 'mechanize'

# Don't create mkmf.log files
module MakeMakefile::Logging
	  @logfile = File::NULL
end

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
		n   = BigDecimal.new(0)
		sum = BigDecimal.new(0)

		@entities.each do|entity|
			next unless entity

			rate = entity.send(currency)[rate_type]

			next unless rate

			n   += 1
			sum += BigDecimal.new(1) / BigDecimal.new(rate)
		end

		("%.04f" % (n/sum))[/\d+\.\d{2}/].to_s
	end
end

# Central Bank of the Dominican Republic
class Scrapper::CentralBank
	attr_reader :dollar
	def initialize(url=DATA_URI)
		@url    = url
		@dollar = Hash.new { String.new }

		@has_gocr  = !!find_executable('gocr')
		@has_djpeg = !!find_executable('djpeg')
		@has_ocrad = !!find_executable('ocrad')

		if can_parse?
			parse_data()
		end
	end

	def serialize
		return @serialized_info if @serialized_info

		tmp_info = {
		     :dollar => {:buying_rate  => @dollar[:buying_rate],
		                 :selling_rate => @dollar[:selling_rate]}
		}

		@serialized_info = JSON.pretty_generate(tmp_info)
	end

	def can_parse?
		@has_gocr and @has_ocrad and @has_djpeg
	end

	private

	# parallelism may speed things up a little :)
	def parse_data
		pdf_file   = open(DATA_URI)
		r_fd, w_fd = IO.pipe

		# spawn new process
		pid        = fork()

		engine = pid ? :gocr : :ocrad

		data   = get_data(pdf_file.path, engine)

		values = parse_values(data)

		unless pid
			w_fd.write(values.join(','))
			exit 0
		end

		Process.wait pid

		w_fd.close
		pdf_file.close
		pdf_file.unlink

		values_alternative = r_fd.read.split ','

		@dollar[:buying_rate]  = values.fetch(BUYING_RATE_IDX, '')
		@dollar[:selling_rate] = values.fetch(SELLING_RATE_IDX, '')

		if @dollar[:buying_rate].empty?
			@dollar[:buying_rate]  = values_alternative.fetch(BUYING_RATE_IDX, '')
		end

		if @dollar[:selling_rate].empty?
			@dollar[:selling_rate] = values_alternative.fetch(SELLING_RATE_IDX, '')
		end
	end

	def parse_values(data)
		values = data.scan(/(?<=D.)..\.../)

		buying_rate  = ''
		selling_rate = ''

		tmp_buying_rate, tmp_selling_rate = values.collect {|rate| rate.tr('lIOS', '1105').tr ' ', ''}

		if tmp_buying_rate =~ /\d{2}\.\d{2}+/
			buying_rate = tmp_buying_rate[/\d+\.\d{2}/]
		end

		if tmp_selling_rate =~ /\d{2}\.\d{2}+/
			selling_rate = tmp_selling_rate[/\d+\.\d{2}/]
		end

		ret = []
		ret[BUYING_RATE_IDX]  = buying_rate
		ret[SELLING_RATE_IDX] = selling_rate

		ret
	end

	def get_data(path, engine=:ocrad)
		r_fd, w_fd = IO.pipe

		pdftojpeg_str = pdftojpeg_command(path)

		if engine == :ocrad and @has_ocrad
			spawn "#{pdftojpeg_str} | ocrad -F utf8", :out => w_fd
		elsif engine == :gocr and @has_gocr
			spawn "#{pdftojpeg_str} | gocr -f UTF8 -v 0 -", :out => w_fd
		else
			return ''
		end

		w_fd.close
		data = r_fd.read
		r_fd.close
		data
	end

	def pdftojpeg_command(image_path)
		   "convert -density 300 -trim -quality 100 #{image_path} jpeg:fd:1 | djpeg -scale 1/2 -grayscale -pnm"
	end

	DATA_URI         = URI('http://www.bancentral.gov.do/tasas_cambio/tasaus_mc.pdf')
	BUYING_RATE_IDX  = 0
	SELLING_RATE_IDX = 1
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

