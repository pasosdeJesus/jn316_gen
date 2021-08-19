source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec


gem "bcrypt"

gem 'bigdecimal'

gem 'bootsnap', '>=1.1.0', require: false # Arranque rapido

gem "cancancan" # Roles

gem 'coffee-rails', '~> 4.2'

gem "cocoon", git: "https://github.com/vtamara/cocoon.git", 
  branch: 'new_id_with_ajax' # Formularios anidados (algunos con ajax)

gem "devise" # Autenticación 

gem "devise-i18n"

gem 'jbuilder', '~> 2.5'

gem 'kt-paperclip',                 # Anexos
  git: 'https://github.com/kreeti/kt-paperclip.git'

gem 'net-ldap'

gem 'nokogiri', '>=1.11.1'

gem 'pg'

gem 'rails', '~> 6.1'
  #git: 'https://github.com/rails/rails.git', branch: '6-1-stable'

gem 'sassc-rails'

gem "simple_form" # Formularios simples 

gem 'twitter_cldr' # ICU con CLDR

gem "tzinfo" # Zonas horarias

gem 'webpacker', '~> 6.0.0.rc.1'       # Traduce y compila modulos Javascript

gem "will_paginate" # Listados en páginas


#####
# Motores que se sobrecargan vistas (deben ponerse en orden de apilamiento 
# lógico y no alfabetico como las gemas anteriores)

gem 'sip', # Motor generico
  git: 'https://github.com/pasosdeJesus/sip.git', branch: :main
  #gem 'sip', path: '../sip'


group :development, :test do
  #gem 'byebug', platform: :mri
 
  gem 'colorize'

  gem 'dotenv-rails'
end


group :test do

  gem 'rails-controller-testing'

  # Problemas con 0.18 que en travis genera:
  # Error: json: cannot unmarshal object into Go struct field input.coverage of type []formatters.NullInt
  # https://github.com/codeclimate/test-reporter/issues/418
  gem 'simplecov', '~> 0.10', '< 0.18'

end 


group :development do
  gem 'puma'

  gem 'spring'

  gem 'web-console'
end

