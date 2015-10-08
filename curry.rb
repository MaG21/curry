#!/usr/bin/env ruby
# By: MaG
#
require 'bundler/setup'
Bundler.require(:default)
Bundler.require(:production)
Bundler.require(:curry)        # This line is important, in case curry is embedded in other project
                               # with it's own Gemfile (like Rails)

require 'thread'
require_relative 'scrapper'

set :port, 8080
set :bind, '0.0.0.0'
set :environment, :production

VERSION = '1.5.2'

$mutex   = Mutex.new
$info    = Scrapper::Info.new
$counter = 0

Thread.new do
	loop do
		sleep 10_800 # update every three ours
		info = Scrapper::Info.new

		$mutex.synchronize do
			$info = info
		end
	end
end

before do
	$counter += 1 unless request.path_info =~ /^\/(?:requests)?$/
end

get '/' do
	headers({'Content-Type' => 'text/plain'})

	<<-EOF
	Available methods:

	GET /rnc/:rnc
	Returns information about the RNC specified by :rnc. [JSON serialized]

	GET /ncf/:rnc/:ncf
	Returns true or false, depending if the RNC and the NCF specified by :rnc and
	:ncf respectively belongs to the entity associated to :rnc.

	GET /rates
	Returns the exchange rate for euros and dollars from all major banks of the
	Dominican Republic. [JSON serialized]

	GET /central_bank_rates
	Returns the exchange rate for the dollar according to the Central Bank of the
	Dominican Republic. [JSON serialized]

	This is a simple service that provides the current currency exchange rate for
	the Dominican Republic. To do so, we feed our servers from the web pages of all
	the major banks of the Dominican Republic, these pages are updated on a daily
	basis by every bank.

	The method being used by this application to calculate the mean of the data is
	the Harmonic mean.

	This service is provided by: Marcos Organizador de Negocios S.R.L.
	Made with high programming standards to provide high availability.

	Something is wrong with this service? Please contact us at support@marcos.do.
	EOF
end

get '/rates' do
	headers({'Content-Type' => 'application/json'})

	$mutex.synchronize do
		$info.serialize
	end
end

get '/central_bank_rates' do
	headers({'Content-Type' => 'application/json'})

	$mutex.synchronize do
		$info.central_bank.serialize
	end
end

get '/requests' do
	headers({'Content-Type' => 'text/plain'})

	"#{$counter} requests."
end


get '/ncf/:rnc/:ncf' do|rnc, ncf|
	agent = Mechanize.new
	page = agent.get 'http://www.dgii.gov.do/app/WebApps/Consultas/NCF/ConsultaNCF.aspx'
	form = page.form id: 'form1'

	form.txtRNC = rnc
	form.txtNCF = ncf
	form.add_field! 'btnConsultar'
	form.add_field! '__EVENTTARGET'
	form.add_field! '__EVENTARGUMENT'
	form.add_field! '__LASTFOCUS'
	form.btnConsultar = 'Consultar'

	ret = form.submit

	ret.content =~ /Comprobante Fiscal digitado es v.{1,2}lido./
	{valid: !!$&}.to_json
end


get '/rnc/:keyword' do|keyword|
	content_type 'application/json'

	agent = Mechanize.new
	page  = agent.get 'http://www.dgii.gov.do/app/WebApps/Consultas/rnc/RncWeb.aspx'

	form = page.form name: 'Form1'

	form.add_field! '__EVENTTARGET'
	form.add_field! '__EVENTARGUMENT'
	form.add_field! '__LASTFOCUS'
	form.add_field! 'btnBuscaRncCed'

	form.txtRncCed      = keyword
	form.btnBuscaRncCed = 'Buscar'

	ret = form.submit

	return {}.to_json unless ret

	tmp = ret.search '//tr[@class="GridItemStyle"]'

	return {}.to_json unless tmp

	fields = tmp.children

	return {}.to_json if fields.empty?

	payload = {
		:rnc             => fields[1].text.strip,
		:name            => fields[2].text.strip,
		:comercial_name  => fields[3].text.strip,
		:category        => fields[4].text.strip,
		:payment_regimen => fields[5].text.strip,
		:status          => fields[6].text.strip
	}

	JSON.pretty_generate(payload)
end

not_found do
	redirect '/'
end

get '/__sinatra__/*' do
	headers({'Content-Type' => 'text/plain'})
	'Nope, this a Rails application, or maybe not, dunno.'
end

