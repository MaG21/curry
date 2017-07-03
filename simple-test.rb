#!/usr/bin/env ruby
# By: MaG
#
require_relative 'lib/curry'

info = Scraper::Info.new()
puts "Popular Bank rates:"
p info.bpd.dollar
p info.bpd.euro

puts "\nProgress Bank Rates:"
p info.progress.dollar
p info.progress.euro

puts "\nLopez de Haro Bank rates:"
p info.blh.dollar
p info.blh.euro

puts "\nBHD Leon Bank rates:"
p info.bhdleon.dollar
p info.bhdleon.euro

puts "\nBanReservas Bank rates:"
p info.reservas.dollar
p info.reservas.euro

puts "\nCentral Bank rates:"
p info.central_bank.dollar

puts "\nEuro mean:"
p info.euro_mean

puts "\nDollar mean:"
p info.dollar_mean

puts "\nSerialized:"
puts info.serialize

