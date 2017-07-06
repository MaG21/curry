require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name          = 'curry'
  spec.version       = Curry::VERSION
  spec.authors       = %w( MarcosCommunity MaG21 )
  spec.email         = %w( info@marcos.do )

  spec.summary       = 'Currency scraper for the Dominican Republic'
  spec.description   = 'Scrapes currency information from the major banks of the Dominincan Republic'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = %w( lib )

  spec.add_dependency 'mechanize'
  spec.add_dependency 'simple-spreadsheet', '~> 0.5.0'
  spec.add_dependency 'sinatra', '~> 2.0'

  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rack-test', '~> 0.6.3'
  spec.add_development_dependency 'byebug'
end

