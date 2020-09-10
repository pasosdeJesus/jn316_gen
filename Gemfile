source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec


gem "bcrypt"

gem 'bigdecimal'

gem 'bootsnap', '>=1.1.0', require: false # Arranque rapido

gem "cancancan" # Roles

gem 'coffee-rails', '~> 4.2', '>= 4.2.2'

gem "cocoon", git: "https://github.com/vtamara/cocoon.git", 
  branch: 'new_id_with_ajax' # Formularios anidados (algunos con ajax)

gem "devise" , ">= 4.7.2" # Autenticación 

gem "devise-i18n", ">= 1.9.2"

gem 'jbuilder', '~> 2.5'

gem 'net-ldap'

gem "paperclip" # Maneja adjuntos

gem 'pg'

gem 'puma'

gem "rails", "~> 6.0.3.3"

gem 'sassc-rails', '>= 2.1.2'

gem "simple_form" , ">= 5.0.2" # Formularios simples 

gem 'twitter_cldr' # ICU con CLDR

gem "tzinfo" # Zonas horarias

gem 'webpacker', '>= 5.2.1'

gem "will_paginate" # Listados en páginas


#####
# Motores que se sobrecargan vistas (deben ponerse en orden de apilamiento 
# lógico y no alfabetico como las gemas anteriores)

gem 'sip', # Motor generico
  git: 'https://github.com/pasosdeJesus/sip.git'
#gem 'sip', path: '../sip'


group :development, :test do
  #gem 'byebug', platform: :mri
 
  gem 'colorize'
end


group :test do

  gem 'rails-controller-testing', '>= 1.0.5'

  # Problemas con 0.18 que en travis genera:
  # Error: json: cannot unmarshal object into Go struct field input.coverage of type []formatters.NullInt
  # https://github.com/codeclimate/test-reporter/issues/418
  gem 'simplecov', '~> 0.10', '< 0.18'

end 


group :development do

  gem 'spring'

  gem 'web-console', '>= 4.0.4'
end

