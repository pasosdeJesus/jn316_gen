# Motor Jn316 para autenticar con directorio LDAP y administración básica de usuarios y grupos
[![Esado Construcción](https://api.travis-ci.org/pasosdeJesus/jn316_gen.svg?branch=master)](https://travis-ci.org/pasosdeJesus/jn316_gen) [![Clima del Código](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/gpa.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![Cobertura de Pruebas](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/coverage.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![security](https://hakiri.io/github/pasosdeJesus/jn316_gen/master.svg)](https://hakiri.io/github/pasosdeJesus/jn316_gen/master) [![Dependencias](https://gemnasium.com/pasosdeJesus/jn316_gen.svg)](https://gemnasium.com/pasosdeJesus/jn316_gen) 

Este es un motor para autenticar con directorio LDAP y realizar operaciones 
básicas de administración de usuarios y grupos

# Invariatnes

* El directorio LDAP es autoridad respecto a identificación y autenticacion
	- Se usa prioritariamente
	- Un usuario típico no puede modificarlo excepto cambiar su clave,
	  sólo administradores (o por ejemplo un  grupo con privilegios 
	  como recurso humanos).

* Se usan tablas para usuarios y grupos en la base de datos que replican
  información del LDAP, aunque puede haber usuarios y grupos solo en
  base (los que tienen su campo ultimasincldap en NULL).  
  Esto permite renombrar usuarios y grupos con facilidad (que es soportado 
  por LDAPv3, pero no por LDAPv2 que es el protocolo soportado por algunos 
  motores LDAP como ldapd de OpenBSD).

* El directorio LDAP se basa en la propuesta de grupos y usuarios para 
  LDAP del RFC2307 https://www.ietf.org/rfc/rfc2307.txt.  Pero agregando:
	- Se requiere un grupo genérico (digamos usuarios con gid 500) que 
	  se utilice como grupo principal de todos los usuarios. 
	- Mayores restricciones para las identificaciones (cn) de usuarios y 
   	  grupos para evitar incompatibilidades[^1].  Una identificación  (cn)
	  puede constar sólo de letras mínusculas del alfabeto 
  	  inglés, mayúsculas del alfabeto ingles, digitos del 0 a 9 y `_`

[^1] Por ejemplo hay problema entre phpldapadmin y ldapd para 
	escapar caracteres en un cn como la coma aunque es lo esperado 
 	de acuerdo a  https://www.ietf.org/rfc/rfc4514.txt. 

# Características 

* Un usuario LDAP tiene los objectClass top, posixAccount e inetOrgPerson,
  en base de datos usa el modelo ::Usuario con campos que corresponden asi:

	cn y uid (iguales) 	<-> nusuario (máximo 63 caracteres)
	userPassword 		<-> encrypted_password
	mail 			<-> email
	givenName		<-> nombres en UTF-8 máximo 50 
	sn			<-> apellidos en UTF-8 máximo 50
	uidNumber		<-> uidNumber

  gidNumber debe corresponder al gid del grupo genérico.
  El dn usa el cn. El cn debe ser igual al uid y en base de datos es el mismo 
  campo nusuario de modelo Usuario, su longitud máxima es 63.
  Un usuario está desactivado en LDAP cuando su campo userPassword no está
  y en base de datos cuando el campo fechadeshabilitacion
  no es NULL (además en base de datos se borra clave cuando fechadeshabilitacion
  no es NULL).


* Un grupo LDAP tiene los objectClass top y posixGroup. En base de datos
  usamos Sip::Grupo y Sip::GrupoUsuario así:
	cn 			<-> cn (255)
	gidNumber		<-> gidNumber
	description		<-> nombre en UTF-8 máximo 500
	memberUid	        <-> registros de Sip::GrupoUsuario	
  El dn usa el cn.  El cn se limita a 255 caracteres.  Para facilitar 
  compatibilidad recomendamos usar capitalización camello con el nombre 
  completo del grupo (cambiando tildes, eñes y sin espacios).  

* Esta gema emplea Devise y la tabla usuario de sip, pone la estrategía 
  ```ldap_authenticable``` después de la estrategía que usa cookies 
  ```rememberable``` y antes de la estrategía que usa los datos de la base
  (```database_authenticable```),
  de forma que primero se usan las credenciales almacenadas en cookies,
  después las del directorio LDAP y si el usuario no está en el LDAP o si 
  no se puede establecer la conexión con el directorio LDAP se usan las 
  que estén almacenadas en la base de datos (más parecido a la forma como 
  hace un cliente en un dominio Windows que a la forma que usa por ejemplo
  GLPI al usar un directorio LDAP).  Así que la prioridad la tiene el 
  directorio LDAP mientras esté disponible, pero se usa base de datos local 
  para respaldar el LDAP y para permitir usuarios que no estén en el LDAP.

* Tras cada conexión con el directorio LDAP para autenticar un usuario
  se actualizan datos del usuario de la base de datos (siempre y cuando
  el usuario esté en el directorio LDAP). Esto se hace bien si la clave
  es correcta como si no.    Cuando es exitosa el condensando bcrypt de la
  clave también se almacena en la base de datos (para permitir ingresos 
  futuros si hay disrupción del LDAP).    Este tipo de operación (búsqueda
  y extración de datos de un usuario) requiere privilegios especiales
  en LDAP por lo que la aplicación debe tener configurado un usuario con
  estos privilegios

* La aplicación permite cambiar clave a un usuario, este cambio se intenta
  primero en el directorio LDAP mientras el usuario esté activo (si no 
  está activo debe sincronizar y sacar de la cuenta al usuario).  Si el
  usuario está en el directorio LDAP se pone la nueva clave y en 
  base de datos.  Si el usuario no está en el directorio LDAP sólo se 
  actualiza clave en base de datos.  

* Grupos.  Se  implementó en sip primero, un grupo referencia varios
  usuarios. No maneja concepto de grupo principal. 
  Cuando un usuario se autentica, se actualiza la información de 
  grupos a los que pertenece sincronizandola en base.  Si un grupo del LDAP
  no está en la base de datos se crear para poder agregar el usuario.
  Después se actualizan los grupos del usuario para asegurar que está
  sólo en los del directorio LDAP.

# Aún no implementado

* Aún nos falta creación, eliminación, actualización de grupos
* Se puede mejorar implementación de actualización en LDAP de un
  usuario cuando sus grupos cambian
  (en el momento se hace igual que renombrabiento, borrando 
  todo y agregando todo, pero podría: ver grupos eliminados
  y grupos nuevos, sacar de eliminados, agregar a nuevos)
* Mejorar deshabilitación de usuarios (en base) para que se 
  trasmita a LDAP (tanto al editar, como al crear, como 
  al sincronizar).
* Diseñar e implementar deshabilitación de grupos

* Sería bueno tener bitácora de conexiones e intentos.  Junto con cada
  usuario mantener fecha de la última sincronización exitosa desde el
  LDAP.


# Configuración de este motor en su aplicación


1. Asegurese de que su aplicación use el motor sip para manejar
   usuarios y grupos

2. LDAP utilizable con las convenciones descritas al comienzo. La
  funcionalidad de sincronizar puede ayudarle a detectar problemas en
  su directorio LDAP respecto a esas convenciones.

  La conexión LDAP si la hace cifrada requiere un certificao firmado cuyo
  subject sea el nombre del servidor al que se conecta y con una autoridad
  ceritificadora reconocida por el servidor donde reside la aplicación.
  Si usa su propia autoridad certificadora asegurese de incluir la llave
  pública entre las conocidas por el sistema (en adJ /etc/ssl/cert.pem).

3. Agregue la gema en Gemfile:

gem 'jn316_gen', git: 'https://github.com/pasosdeJesus/jn316_gen.git'

bundle install

4. Ejecute migraciones para hacer cambios a modelos usuario y sip::grupo
rake db:migrate

5. Especificar datos de conexión LDAP agregando a config/application.rb

    config.x.jn316_basegente = "ou=gente,dc=miorg,dc=net"
    config.x.jn316_basegrupos = "ou=grupos,dc=miorg,dc=net"
    config.x.jn316_admin = "cn=admin,dc=miorg,dc=net"
    config.x.jn316_servidor = "apbd2.miorg.net"
    config.x.jn316_puerto = 389
    config.x.jn316_gidgenerico = 500  #gid de grupo genérico existente en LDAP
    config.x.jn316_opcon = {
      encryption: {
        method: :start_tls,
        tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
      }
    }

6. Amplie el modelo Usuario, el más simple sería en app/models/usuario:

```
# encoding: UTF-8

require 'jn316_gen/concerns/models/usuario'
require 'sip/concerns/models/usuario'

class Usuario < ActiveRecord::Base
  include Sip::Concerns::Models::Usuario
  include Jn316Gen::Concerns::Models::Usuario

end
```

Si hace validaciones adicionales, por ejemplo requerir nombre y apellido
asegurese de poner valores por omisión en la base de datos. Así mismo
asegurese de tener valores como rol, oficina y otros necesarios.  
Ver ejemplo en cor1440_cinep-ldap/db/migrate/nombres_apellidos_poromision

7. Extienda el controlador de usuarios, el más simple es 
   app/controllers/usuarios_controller.rb 

```
# encoding: UTF-8

class UsuariosController < Jn316Gen::UsuariosController

end
```

8. Para activar cambio de clave por parte de usuarios en directorio LDAP 
   en ```config/routes.rb``` agregar:
```
    devise_for :usuarios, :skip => [:registrations], module: :devise
as :usuario do
      get 'usuarios/edit' => 'devise/registrations#edit', 
        :as => 'editar_registro_usuario'    
    put 'usuarios/:id' => 'jn316_gen/registrations#update', 
    :as => 'registro_usuario'            
    end
    resources :usuarios, path_names: { new: 'nuevo', edit: 'edita' } 
```
 
   y agregue un menú o enlaces para permitirlo, por ejemplo en
   app/views/layouts/application:
  <%= menu_item "Clave", main_app.editar_registro_usuario_path %>

9. Cuando inicie el servidor especifique la clave del usuario
  especificado en config.x.jn316_admin en la variable
  de ambiente JN316_CLAVE por ejemplo

JN316_CLAVE=estaclave rails s

  Se requiere usuario y clave del administrador LDAP para realizar búsquedas
  en el directorio y para administrar usuarios.  Si no necesita la
  funcionalidad de administrar usuarios puede especificar un usuario
  sólo con privilegios de busqueda sobre grupos y usuarios del directorio.

10. Ingrese con un administrador que esté en base de datos pero no en LDAP
   y sincronice. 
