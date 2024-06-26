# Motor Jn316 para autenticar con directorio LDAP y administración básica de usuarios y grupos


[![Revisado por Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com) Pruebas y seguridad: [![Pruebas y seguridad](https://gitlab.com/pasosdeJesus/jn316_gen/badges/main/pipeline.svg)](https://gitlab.com/pasosdeJesus/jn316_gen/-/pipelines) [![Clima del Código](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/gpa.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) [![Cobertura de Pruebas](https://codeclimate.com/github/pasosdeJesus/jn316_gen/badges/coverage.svg)](https://codeclimate.com/github/pasosdeJesus/jn316_gen) 




![Logo de jn316_gen](https://gitlab.com/pasosdeJesus/jn316_gen/-/raw/main/test/dummy/app/assets/images/logo.jpg)

Este es un motor para autenticar con un directorio LDAP y realizar operaciones 
básicas de administración de usuarios y grupos en el directorio LDAP y/o en
un directorio activo.

# Invariantes

* El directorio LDAP es autoridad respecto a identificación y autenticación
	- Se usa prioritariamente
	- Un usuario típico no puede modificarlo excepto cambiar su clave,
	  sólo administradores (o por ejemplo un  grupo con privilegios 
	  como recurso humanos).

* Se usan tablas para usuarios y grupos en la base de datos que replican
  información del LDAP, aunque puede haber usuarios y grupos solo en
  base (los que tienen su campo `ultimasincldap` en NULL).  
  Esto permite renombrar usuarios y grupos con facilidad en servidores LDAPv2
  que no lo soportan (como ocurre con `ldapd` de OpenBSD/adJ).

* El directorio LDAP se basa en la propuesta de grupos y usuarios para 
  LDAP del RFC2307 https://www.ietf.org/rfc/rfc2307.txt.  Pero agregando:
	- Se requiere un grupo genérico (digamos `usuarios` con gid 500) que 
	  se utilice como grupo principal de todos los usuarios. 
	- Mayores restricciones para las identificaciones (`cn`) de usuarios y 
   	  grupos para evitar incompatibilidades[^1]:  Una identificación  (`cn`)
	  puede constar sólo de letras mínusculas del alfabeto 
  	  inglés, mayúsculas del alfabeto ingles, digitos del 0 a 9 y `_`

[^1] Por ejemplo hay problema entre phpldapadmin y ldapd para 
	escapar caracteres en un `cn` como la coma, aun cuando es válido
	tener una coma en un `cn` de acuerdo a https://www.ietf.org/rfc/rfc4514.txt. 

# Características 

* Un usuario LDAP tiene los `objectClass`: `top`, `posixAccount` e `inetOrgPerson`.
  En base de datos usa el modelo `::Usuario` con campos que corresponden asi:

	|LDAP                   | Base de Datos                    |
	|-----------------------|----------------------------------|
	|`cn` y `uid` (iguales) | `nusuario` (máximo 63 caracteres)|
	|`userPassword` (sha)   | `encrypted_password` (bcrypt)    |
	|`mail`                 | `email`                          |
	|`givenName`            | `nombres` en UTF-8 máximo 50     |
	|`sn`                   | `apellidos` en UTF-8 máximo 50   |
	|`uidNumber`            | `uidNumber`                      |

  `gidNumber` debe corresponder al `gid` del grupo genérico, por ejemplo: 
        `500`  del grupo `usuario`.
  El `dn` de un usuario usa el `cn` (en lugar del `uid`), por ejemplo: 
	`cn=nombre,ou=gente,dc=miorg,dc=net`
  Un usuario está desactivado en LDAP cuando su campo `userPassword` no está
  y en base de datos cuando el campo `fechadeshabilitacion`
  no es `NULL` (además en base de datos se borra clave cuando `fechadeshabilitacion`
  no es `NULL`).

* Un grupo LDAP tiene los `objectClass`: `top` y `posixGroup`. En base de datos
  usamos `Msip::Grupo` y `Msip::GrupoUsuario` así:
  
  	|LDAP          | Base de datos                  |
	|--------------|--------------------------------|
	|`cn`          | `cn` máximo 255 caracteres     |
	|`gidNumber`   | `gidNumber`                    |
	|`description` | `nombre` en UTF-8 máximo 500   |
	|`memberUid`   | registros de Msip::GrupoUsuario |
	
  El `dn` usa el `cn`.  El `cn` se limita a 255 caracteres.  Para facilitar 
  compatibilidad recomendamos usar capitalización camello con el nombre 
  completo del grupo (cambiando tildes, eñes y sin espacios).  

* Esta gema emplea Devise y la tabla `usuario` de msip, pone la estrategía 
  ```ldap_authenticable``` después de la estrategía que usa cookies 
  ```rememberable``` y antes de la estrategía que usa los datos de la base
  (```database_authenticable```),
  de forma que primero se usan las credenciales almacenadas en cookies,
  después las del directorio LDAP y si el usuario no está en el LDAP o si 
  no se puede establecer la conexión con el directorio LDAP se usan las 
  que estén almacenadas en la base de datos (más parecido a la forma como 
  hace un cliente en un dominio Windows que a la forma que usa por ejemplo
  GLPI al usar un directorio LDAP).  Así que la prioridad la tiene el 
  directorio LDAP mientras esté disponible, pero se usa base de datos 
  para respaldar el LDAP y para permitir usuarios que no estén en el LDAP.

* Tras cada conexión con el directorio LDAP para autenticar un usuario
  se actualizan datos del usuario de la base de datos (siempre y cuando
  el usuario esté en el directorio LDAP). Esto se hace bien si la clave
  es correcta como si no.    Cuando la autenticación es exitosa el 
  condensando bcrypt de la clave también se almacena en la base de datos 
  (para permitir ingresos futuros si hay disrupción del LDAP).    
  Este tipo de operación (búsqueda y extración de datos de un usuario) 
  requiere privilegios especiales en LDAP por lo que la aplicación debe 
  tener configurado un usuario con estos privilegios

* La aplicación permite cambiar clave a un usuario, este cambio se intenta
  primero en el directorio LDAP mientras el usuario esté activo (si no 
  está activo debe sincronizar y sacar de la cuenta al usuario).  Si el
  usuario está en el directorio LDAP se pone la nueva clave y en 
  base de datos.  Si el usuario no está en el directorio LDAP sólo se 
  actualiza clave en base de datos.   El directorio LDAP debe permitir
  este cambio, en el caso de `ldapd` se logra con una configuración como esta
  en ```/etc/ldapd.conf```:

```
  deny access to any by any
  allow bind access to children of "ou=gente,dc=miorg,dc=net" by any
  allow read access to any by self
  allow write access to children of "ou=gente,dc=miorg,dc=net" by self
```

* Grupos.  Se  usa modelo de `msip`, un grupo referencia varios
  usuarios. En base de datos no maneja concepto de grupo principal. 
  Cuando un usuario se autentica, se actualiza la información de 
  grupos a los que pertenece sincronizandola en base.  Si un grupo del LDAP
  no está en la base de datos se crear para poder agregar el usuario.
  Después se actualizan los grupos del usuario para asegurar que está
  sólo en los del directorio LDAP.


# Operaciones en un Directorio Activo

Es posible realizar diversas operaciones en un directorio activo pero
se requiere:
1. Que esté configurado para recibir conexiones SSL
2. Contar con cuenta y clave de administrador y configurarlas en 
   secrets.yml (se recomienda cifrado):

# Aún no implementado

* Se puede mejorar implementación de actualización en LDAP de un
  usuario cuando sus grupos cambian
  (en el momento se hace igual que renombrabiento, borrando 
  todo y agregando todo, pero podría: ver grupos eliminados
  y grupos nuevos, sacar de eliminados, agregar a nuevos)
* Diseñar e implementar deshabilitación de grupos
* Implementar subgrupos (se ha hecho en CRECER)
* Sería bueno tener bitácora de conexiones e intentos. 


# Configuración de este motor en su aplicación

1. Asegurese de que su aplicación use el motor `msip` para manejar
   usuarios y grupos (ver <https://gitlab.com/pasosdeJesus/msip> )

2. LDAP utilizable con las convenciones descritas al comienzo. La
  funcionalidad de sincronizar puede ayudarle a detectar problemas en
  su directorio LDAP respecto a esas convenciones.

  La conexión LDAP si la hace cifrada requiere un certificado firmado cuyo
  `subject` sea el nombre del servidor al que se conecta y con una autoridad
  ceritificadora reconocida por el servidor donde reside la aplicación.
  Si usa su propia autoridad certificadora asegurese de incluir la llave
  pública entre las conocidas por el sistema (en adJ en `/etc/ssl/cert.pem`).

  Un ejemplo de configuración en el caso de ldapd es:

```
schema "/etc/ldap/core.schema"
schema "/etc/ldap/inetorgperson.schema"
schema "/etc/ldap/nis.schema"
schema "/etc/ldap/misc.schema"
schema "/etc/ldap/courier.schema"
schema "/etc/ldap/mozillaOrgPerson.schema"
schema "/etc/ldap/cosine.schema"
schema "/etc/ldap/samba3.schema"

if1="em0"
listen on $if1 tls certificate apbd1.miorg.org.co 
#TLS es recomendado, pero para pruebas también usamos ldaps:
listen on $if1 ldaps certificate apbd1.miorg.org.co 
listen on "/var/run/ldapi"

namespace "dc=miorg,dc=net" {
	rootdn		"cn=admin,dc=miorg,dc=net"
	rootpw		"{SHA}aTUzMjd3ryR2UjC8xAk1/TEL5h0="
	index		sn
	index		givenName
	index		cn
	index		mail
	index           objectClass

        fsync           on

	deny access to any by any
        allow bind access to children of "ou=gente,dc=miorg,dc=net" by any
	allow read access to any by self
        allow write access to children of "ou=gente,dc=miorg,dc=net" by self
}
```

3. Agregue la gema en Gemfile:
```
gem 'jn316_gen', git: 'https://gitlab.com/pasosdeJesus/jn316_gen.git'
```
y ejecute:
```
bundle install
```

4. Ejecute migraciones para hacer cambios a modelos usuario y msip::grupo
```
rake db:migrate
```

5. Especifique datos de conexión LDAP agregando a `config/application.rb` 

```
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
```

Note que esa configuración usa TLS para agregar cifrado a una conexión
inicialmente no cifrada sobre el puerto 389.

Si prefiere usar LDAPS (LDAP sobre SSL) cambie el puerto por el 636
y `:start_tls` por `:simple_tls`.
Ver detalles en documentación de net-ldap:
<https://www.rubydoc.info/github/ruby-ldap/ruby-net-ldap/Net%2FLDAP:initialize>


6. Amplie el modelo Usuario, el más simple sería en `app/models/usuario`:

```
# encoding: UTF-8

require 'jn316_gen/concerns/models/usuario'
require 'msip/concerns/models/usuario'

class Usuario < ActiveRecord::Base
  include Msip::Concerns::Models::Usuario
  include Jn316Gen::Concerns::Models::Usuario

end
```

Si hace validaciones adicionales, por ejemplo requerir nombre y apellido
asegurese de poner valores por omisión en la base de datos. Así mismo
asegurese de tener valores como rol y otros necesarios.  
Ver ejemplo en `cor1440_cinep-ldap/db/migrate/nombres_apellidos_poromision`

7. Extienda el controlador de usuarios, el 
   `app/controllers/usuarios_controller.rb` más simple es: 

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
   `app/views/layouts/application`:
```
  <%= menu_item "Clave", main_app.editar_registro_usuario_path %>
```

9. Cuando inicie el servidor especifique la clave del usuario
  especificado en `config.x.jn316_admin` en la variable
  de ambiente `JN316_CLAVE` por ejemplo

```
JN316_CLAVE=estaclave bin/rails s
```

  Se requiere usuario y clave del administrador LDAP para realizar búsquedas
  en el directorio y para administrar usuarios.  Si no necesita la
  funcionalidad de administrar usuarios puede especificar un usuario
  sólo con privilegios de busqueda sobre grupos y usuarios del directorio.

10. Si necesita ralizar operaciones con un Directorio Activo configure, por 
   ejemplo:

```
$ EDITOR=vim bin/rails secrets:edit

development:
  secret_key_base: ed9fd425a3763ae83f2ef9d507ddc2e16e7a478d6a9fd45c2865871f4b3997a7f529c8682a48fca0b7bee7d2e6b8806b4a44ea6f744302e9c4a6863e29a0b02a
  JN316_LDAP_CLAVE: 'facil'
  JN316_DA_MAQUINA: 'SDOMINIO.MIDOMINIO.local'
  JN316_DA_PUERTO: 636
  JN316_DA_BASE: 'OU=MIORG,DC=MIDOMINIO,DC=local'
  JN316_DA_BASE_USUARIOS: 'OU=USUARIOS,OU=MIORG,DC=MIDOMINIO,DC=local'
  JN316_DA_BASE_GRUPOS: 'OU=GRUPOS,OU=MIORG,DC=MIDOMINIO,DC=local'
  JN316_DA_CUENTA: 'MIDOMINIO\Administrador'
  JN316_DA_CLAVE: 'AquiLaClaveDeAdministrador'
```


10. Ingrese con un administrador que esté en base de datos pero no en LDAP
   y sincronice. 

# Personalizaciones y apoyo para usar en una organización

Si necesita usar este motor en una organización y eventualmente 
personalizarlo, desde Pasos de Jesús podemos apoyar  por horas (contacto vtamara@pasosdeJesus.org).
