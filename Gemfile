source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec


gem "bcrypt"

gem 'bigdecimal'

gem 'bootsnap', '>=1.1.0', require: false # Arranque rapido

gem "bootstrap-datepicker-rails"

gem "cancancan" # Roles

gem 'chosen-rails', git: "https://github.com/vtamara/chosen-rails.git", branch: 'several-fixes' # Campos de selección bonitos

gem 'coffee-rails', '~> 4.2'

gem "cocoon", git: "https://github.com/vtamara/cocoon.git", branch: 'new_id_with_ajax' # Formularios anidados (algunos con ajax)

gem 'colorize'

gem "devise" # Autenticación 

gem "devise-i18n"

gem "font-awesome-rails"

gem 'jbuilder', '~> 2.5'

gem 'jquery-rails'

gem 'jquery-ui-rails'

gem 'net-ldap'

gem "paperclip" # Maneja adjuntos

gem 'pg'

gem 'pick-a-color-rails' # Facilita elegir colores en tema

gem 'puma'

gem "rails", '~> 6.0.0.rc1'

gem 'sass-rails'

gem "simple_form" # Formularios simples 

gem 'tiny-color-rails'

gem 'turbolinks'

gem "twitter-bootstrap-rails" # Ambiente de CSS

gem 'twitter_cldr' # ICU con CLDR

gem "tzinfo" # Zonas horarias

gem 'uglifier', '>= 1.3.0'

gem 'webpacker'

gem "will_paginate" # Listados en páginas


#####
# Motores que se sobrecargan vistas (deben ponerse en orden de apilamiento 
# lógico y no alfabetico como las gemas anteriores) para que sobrecarguen
# bien vistas

gem 'sip', # Motor generico
  git: 'https://github.com/pasosdeJesus/sip.git'
#gem 'sip', path: '../sip'


group :development, :test do
  #gem 'byebug', platform: :mri
end


group :test do

  gem 'rails-controller-testing'

  gem 'simplecov'

end 


group :development do

  gem 'spring'

  gem 'web-console'
end

