require 'byebug'

describe Scraper, 'module' do
	context 'BPD' do
		it 'makes an instance of the object' do
			expect { $bpd = Scraper::BPD.new }.not_to raise_error
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
			expect { $blh = Scraper::BLH.new }.not_to raise_error
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

	context 'BHD León' do
		it 'makes an instance of the object' do
			expect { $bhdleon = Scraper::BHDLeon.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($bhdleon.dollar[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($bhdleon.dollar[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($bhdleon.euro[:buying_rate]).to match(/\d{2}.\d{1,2}/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($bhdleon.euro[:selling_rate]).to match(/\d{2}.\d{1,2}/)
		end
	end

	context 'Progress' do
		it 'makes an instance of the object' do
			expect { $progress = Scraper::Progress.new }.not_to raise_error
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
			expect { $reservas = Scraper::Reservas.new }.not_to raise_error
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($reservas.dollar[:buying_rate]).to match(/\d{2}(\.\d{1,2})?/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($reservas.dollar[:selling_rate]).to match(/\d{2}(\.\d{1,2})?/)
		end

		it 'parses the BUYING rate of the Euro' do
			expect($reservas.euro[:buying_rate]).to match(/\d{2}(\.\d{1,2})?/)
		end

		it 'parses the SELLING rate of the Euro' do
			expect($reservas.euro[:selling_rate]).to match(/\d{2}(\.\d{1,2})?/)
		end
	end

	context 'Central Bank' do
		it 'makes an instance of the object' do
			$central_bank = Scraper::CentralBank.new
		end

		it 'parses the BUYING rate of the Dollar' do
			expect($central_bank.dollar[:buying_rate].to_s).to match(/\A\d{2}\.\d{1,4}\z/)
		end

		it 'parses the SELLING rate of the Dollar' do
			expect($central_bank.dollar[:selling_rate].to_s).to match(/\A\d{2}\.\d{1,4}\z/)
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

