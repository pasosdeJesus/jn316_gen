# Motor Jn316 para autenticar con directorio LDAP y administración básica de usuarios y grupos
[![Esado Construcción](https://api.travis-ci.org/pasosdeJesus/jn316_gen.svg?branch=master)](https://travis-ci.org/pasosdeJesus/jn316_gen) [![Clima del Código](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/gpa.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![Cobertura de Pruebas](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/coverage.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![security](https://hakiri.io/github/pasosdeJesus/jn316_gen/master.svg)](https://hakiri.io/github/pasosdeJesus/jn316_gen/master) [![Dependencias](https://gemnasium.com/pasosdeJesus/jn316_gen.svg)](https://gemnasium.com/pasosdeJesus/jn316_gen) 

Este es un motor para autenticar con directorio LDAP y realizar operaciones 
básicas de adminsitración de usuarios y grupos

# Invariatnes

* El directorio LDAP es autoridad respecto a identificación y autenticacion
	- Se usa prioritariamente
	- No puede escribirse aunque un usuario puede cambiar su clave
	- Quien registra un usuario debe emplear el nombre preciso de nuevas
	  personas como aparece en el documento de identificación principal
* RFC2307 https://www.ietf.org/rfc/rfc2307.txt

# Características 

* Esta gema emplea Devise y la tabla usuario de sip, pone la estrategía 
  ```ldap_authenticable``` después de la estrategía que usa cookies 
  ```rememberable``` y antes de la estrategía que usa los datos de la base
  (```database_authenticable```),
  de forma que primero se usan las credenciales almacenadas en cookies,
  después las del directorio LDAP y si el usuario no está en el LDAP o si 
  no se puede establecer la conexión con el directorio LDAP se usan las 
  que estén almacenadas en la base de datos (más parecido a la forma como 
  hace un cliente en un dominio Windows que a la forma que usa GLPI al usar un 
  directorio LDAP).  Así que la prioridad la tiene el directorio LDAP
  mientras esté disponible, pero se usa base de datos local para respaldar
  el LDAP y para permitir usuarios que no estén en el LDAP.

* Tras cada conexión con el directorio LDAP para autenticar un usuario
  se actualizan datos del usuario de la base de datos (siempre y cuando
  el usuario esté en el directorio LDAP). Esto se hace bien si la clave
  es correcta como si no.    Cuando es exitosa el condensando bcrypt de la
  clave también se almacena en la base de datos (para permitir ingresos 
  futuros si hay disrupción del LDAP).    Este tipo de operación (búsqueda
  y extración de datos de un usuario) requiere privilegios especiales
  en LDAP por lo que la aplicación debe tener configurado un usuario con
  estos privilegios

* Sería bueno tener bitácora de conexiones e intentos.  Junto con cada
  usuario mantener fecha de la última sincronización exitosa desde el
  LDAP.

* La forma de deshabilitar usuarios es desde el directorio LDAP
  dejando la clave en blanco (es decir eliminando el atributo userPassword).
  Cuando se sincroniza LDAP en base de un usuario, a los deshabilitados
  se les pone fecha de deshabilitación.

* La aplicación permite cambiar clave a un usuario, este cambio se intenta
  primero en el directorio LDAP mientras el usuario esté activo (si no 
  está activo debe sincronizar y sacar de la cuenta al usuario).  Si el
  usuario está en el directorio LDAP se pone la nueva clave y en 
  base de datos.  Si el usuario no está en el directorio LDAP sólo se 
  actualiza clave en base de datos.  


* Grupos ....

# Configuración

* La conexión LDAP si la hace cifrada requiere un certificao firmado cuyo
  subject sea el nombre del servidor al que se conecta y con una autoridad
  ceritificadora reconocida por el servidor donde reside la aplicación.
  Si usa su propia autoridad certificadora asegurese de incluir la llave
  pública entre las conocidas por el sistema (en adJ /etc/ssl/cert.pem).

 
En el proyecto (que use el motor ```sip```  <https://github.com/pasosdeJesus/sip> ) donde quiera usarlo:

* Incluya la gema


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
