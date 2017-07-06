# Central Bank of the Dominican Republic

require 'uri'
require 'json'
require 'open-uri'
require 'simple-spreadsheet'

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

  DATA_URI         = URI('https://www.bancentral.gov.do/tasas_cambio/TASA_DOLAR_REFERENCIA_MC.XLS')
  BUYING_RATE_IDX  = 0
  SELLING_RATE_IDX = 1
end
