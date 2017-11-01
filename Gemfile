source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0'
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'

gem 'colorize'
# Use SCSS for stylesheets
gem 'sass'
gem 'sass-rails'
gem 'compass-rails'

# Campos de selección bonitos
gem 'chosen-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Ambiente de CSS
gem "twitter-bootstrap-rails"
gem "bootstrap-datepicker-rails"
gem "font-awesome-rails"

# Formularios simples 
gem "simple_form"

# Formularios anidados (algunos con ajax)
gem "cocoon", git: "https://github.com/vtamara/cocoon.git"

# Autenticación y roles
gem "devise"
gem "devise-i18n"
gem "cancancan"
gem "bcrypt"

# Listados en páginas
gem "will_paginate"

# ICU con CLDR
gem 'twitter_cldr'

# Maneja adjuntos
gem "paperclip"#, "~> 4.1"


# Zonas horarias
gem "tzinfo"

gem 'net-ldap'

# Motor de sistemas de información estilo Pasos de Jesús
gem 'sip', git: "https://github.com/pasosdeJesus/sip.git", branch: 'bas_modelo'
#gem 'sip', path: '../sip'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #gem 'byebug', platform: :mri
end

group :test do

  gem 'simplecov'
  # Envia resultados de pruebas desde travis a codeclimate
  gem "codeclimate-test-reporter"

end 

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

