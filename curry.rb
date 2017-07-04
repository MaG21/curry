#!/usr/bin/env ruby
# By: MaG
#

# Get port before sinatra
port = ARGV.first =~ /\A\d+\z/ ? ARGV.first.to_i : 8080

require 'bundler/setup'
Bundler.require(:default)
Bundler.require(:production)
Bundler.require(:curry)        # This line is important, in case curry is embedded in other project
                               # with it's own Gemfile (like Rails)

require 'thread'
require_relative 'scraper'

set :port, port
set :bind, '0.0.0.0'
set :environment, :production

# semver
VERSION = '1.6'

$mutex   = Mutex.new
$info    = Scraper::Info.new
$counter = 0

Thread.new do
	loop do
		sleep 10_800 # update every three ours
		info = Scraper::Info.new

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

	send_file 'README.md'
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

	rnc.gsub!(/\D/, '')
	len = rnc.length

	return {valid: false}.to_json unless len == 9 or len == 11

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

	keyword.gsub!(/\D/, '')
	len = keyword.length

	return {}.to_json unless len == 9 or len == 11

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

