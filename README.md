# Motor Jn316 para autenticar con directorio LDAP y administración básica de usuarios y grupos
[![Esado Construcción](https://api.travis-ci.org/pasosdeJesus/jn316_gen.svg?branch=master)](https://travis-ci.org/pasosdeJesus/jn316_gen) [![Clima del Código](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/gpa.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![Cobertura de Pruebas](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/coverage.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![security](https://hakiri.io/github/pasosdeJesus/jn316_gen/master.svg)](https://hakiri.io/github/pasosdeJesus/jn316_gen/master) [![Dependencias](https://gemnasium.com/pasosdeJesus/jn316_gen.svg)](https://gemnasium.com/pasosdeJesus/jn316_gen) 

Este es un motor de Jn316 para manejar documentos y plantillas

Aplican practicamente las mismas instrucciones de otro motor genérico
basado en sip:
	https://github.com/pasosdeJesus/sal7711_gen

Para incluirlo en su aplicación rails:
1. Agregue las gemas necesarias en Gemfile:

gem 'jn316_gen', git: 'https://github.com/pasosdeJesus/jn316_gen.git'
gem 'font-awesome-rails'
gem 'chosen-rails'

2. Cree un directorio que será la raíz del sistema de archivos y que
debe poder ser escrito por el usuario que ejecute la aplicación, e.g
mkdir public/jn316/

3. Configure esa ruta en su aplicación en config/application.rb con
config.x.jn316_ruta = Rails.root.join('public', 'jn316')

4. Agregue un menú o enlaces a los urls de , por ejemplo en
   app/views/layouts/application:
<%= menu_item "Nube", jn316_gen.sisini_path %>

5. Configure rutas en config/routes.rb
	mount Jn316Gen::Engine => "/", as: 'jn316_gen'

6. Si hace falta agregue en su application_helper.rb
	include FontAwesome::Rails::IconHelper 
