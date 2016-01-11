require 'rack/test'

set :environment, :test

describe 'Curry server', type: :request  do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	context 'Methods doc' do
		it 'sends information about the server' do
			get '/'
			expect(last_response.status).to eq(200)
		end

		it 'returns the number of requests served' do
			get '/requests'
			expect(last_response.status).to eq(200)

			expect(last_response.body =~ /\d+/ ).not_to eq(nil)
		end
	end

	context 'Fiscal' do
		it 'returns the information about an specific RNC' do
			get '/rnc/131098193'
			expect(last_response.status).to eq(200)

			json = JSON.parse last_response.body

			expect(json['name']).to                match(/marcos\s+organizador/i)
			expect(json['comercial_name']).to      match(/marcos\s+organizador/i)
			expect(json['category']).not_to        eq(nil)
			expect(json['payment_regimen']).not_to eq(nil)
			expect(json['status']).not_to          match(/active/i)   # Marcos should always be active, we pay all our taxes :)
		end

		it 'returns a blank JSON response if an invalid RNC is provided' do
			get '/rnc/123756785'
			expect(last_response.status).to eq(200)

			json = JSON.parse last_response.body

			expect(json).to eq({})
		end

		it 'validates the NCF for an specific RNC' do
			skip <<-EOF
				this test is actually quite difficult to maintain,
				because the NCFs lose their status after a period
				of time.
				EOF
		end
	end

	context 'Currency rates' do
		it 'returns the rates and the mean of the Dollar and EURO of the major banks of Santo Domingo' do
			get '/rates'

			expect(last_response.status).to eq(200)

			json = JSON.parse last_response.body

			expect(json).not_to eq({})

			%w(bpd blh progress banreservas).each do|bank|
				expect(json[bank]).not_to eq(nil)

				expect(json[bank]['source']).not_to eq("")

				expect(json[bank]['euro']['buying_rate']).to    match(/^\d+\.\d{2}$/i)
				expect(json[bank]['euro']['selling_rate']).to   match(/^\d+\.\d{2}$/i)
				expect(json[bank]['dollar']['buying_rate']).to  match(/^\d+\.\d{2}$/i)
				expect(json[bank]['dollar']['selling_rate']).to match(/^\d+\.\d{2}$/i)
			end

			expect(json['euro_mean']['buying_rate']).to    match(/^\d+\.\d{2}$/)
			expect(json['euro_mean']['selling_rate']).to   match(/^\d+\.\d{2}$/)
			expect(json['dollar_mean']['buying_rate']).to  match(/^\d+\.\d{2}$/)
			expect(json['dollar_mean']['selling_rate']).to match(/^\d+\.\d{2}$/)
		end

		it 'returns the rate of the dollar according to the Central Bank of the Dominican Republic' do
			get '/central_bank_rates'

			expect(last_response.status).to eq(200)

			json = JSON.parse last_response.body

			expect(json).not_to eq({})

			expect(json['dollar']['buying_rate']).to  match(/^\d+\.\d{2}$/i)
			expect(json['dollar']['selling_rate']).to match(/^\d+\.\d{2}$/i)
		end
	end
end

