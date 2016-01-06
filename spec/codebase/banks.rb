require 'byebug'

describe Scrapper, 'module' do
	context 'BPD' do
		it 'makes an instance of the object' do
			expect { $bpd = Scrapper::BPD.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($bpd.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($bpd.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($bpd.euro[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($bpd.euro[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end
	end

	context 'BLH' do
		it 'makes an instance of the object' do
			expect { $blh = Scrapper::BLH.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($blh.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($blh.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($blh.euro[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($blh.euro[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end
	end

	context 'Progress' do
		it 'makes an instance of the object' do
			expect { $progress = Scrapper::Progress.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($progress.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($progress.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($progress.euro[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($progress.euro[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end
	end

	context 'Reservas' do
		it 'makes an instance of the object' do
			expect { $reservas = Scrapper::Reservas.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($reservas.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($reservas.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($reservas.euro[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($reservas.euro[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end
	end

	context 'Central Bank' do
		it 'makes an instance of the object' do
			$central_bank = Scrapper::CentralBank.new
		end

		it 'parses the BUYING rate of the Dollar' do
			unless $central_bank.can_parse?
				pending 'please make sure gocr/ocrad/djpeg is installed.'
			end

			expect($central_bank.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			unless $central_bank.can_parse?
				pending 'please make sure gocr/ocrad/djpeg is installed.'
			end

			expect($central_bank.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'serializes the SELLING and BUYING rates of the Dollar.' do
			expect($central_bank.serialize.class).to eq(String)

			hsh = nil
			expect { hsh = JSON.parse($central_bank.serialize) }.not_to raise_error

			# NOTE: after +JSON.pretty_generate+ symbols can not longer be used as keys, this is because JSON
			# lacks a symbol data type representation.
			expect(hsh['dollar']['buying_rate']).not_to  eq(nil)
			expect(hsh['dollar']['selling_rate']).not_to eq(nil)

			expect(hsh['dollar']['buying_rate']).to  match(/\d{2}.\d{1,2}/)
			expect(hsh['dollar']['selling_rate']).to match(/\d{2}.\d{1,2}/)
		end
	end
end

