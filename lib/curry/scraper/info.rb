require "thwait"
require "bigdecimal"

require "curry/scraper/blh"
require "curry/scraper/bhdleon"
require "curry/scraper/bpd"
require "curry/scraper/central_bank"
require "curry/scraper/progress"
require "curry/scraper/reservas"

module Scraper
  class Info
    attr_reader :euro_mean,
      :dollar_mean

    attr_reader :bpd,
      :blh,
      :bhdleon,
      :progress,
      :reservas,
      :central_bank

    def initialize
      threads = []

      threads << Thread.new { @bpd          = Scraper::BPD.new() }
      threads << Thread.new { @blh          = Scraper::BLH.new() }
      threads << Thread.new { @bhdleon      = Scraper::BHDLeon.new() }
      threads << Thread.new { @progress     = Scraper::Progress.new() }
      threads << Thread.new { @reservas     = Scraper::Reservas.new() }
      threads << Thread.new { @central_bank = Scraper::CentralBank.new }

      ThreadsWait.all_waits(*threads)

      @entities = [@bpd, @blh, @bhdleon, @progress, @reservas]

      @euro_mean   = { :buying_rate  => compute_mean(:euro, :buying_rate),
                       :selling_rate => compute_mean(:euro, :selling_rate)}

      @dollar_mean = { :buying_rate  => compute_mean(:dollar, :buying_rate),
                       :selling_rate => compute_mean(:dollar, :selling_rate)}
    end

    # => {date => String(DDMMYYYY), data => String(JSON)}
    def serialize
      return @serialized_info if @serialized_info

      tmp_info = {
        :bpd  => {
          :euro   => @bpd.euro,
          :dollar => @bpd.dollar,
          :source => @bpd.url
        },
        :blh => {
          :euro   => @blh.euro,
          :dollar => @blh.dollar,
          :source => @blh.url
        },
        :bhdleon => {
          :euro   => @bhdleon.euro,
          :dollar => @bhdleon.dollar,
          :source => @bhdleon.url
        },
        :progress  => {
          :euro   => @progress.euro,
          :dollar => @progress.dollar,
          :source => @progress.url
        },
        :banreservas => {
          :euro   => @reservas.euro,
          :dollar => @reservas.dollar,
          :source => @reservas.url
        },
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
end

