# encoding: utf-8

require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable


      # Busca usuario nusuario como admin y retorna toda la información 
      def ldap_busca_como_admin(nusuario, prob)
        prob = ""
        if !ENV['JN316_CLAVE']
          prob='Falta clave LDAP para buscar'
          return nil
        end
        opcon = {
          host: Rails.application.config.x.jn316_servidor,
          port: Rails.application.config.x.jn316_puerto,
          auth: {
            method: :simple, 
            username: Rails.application.config.x.jn316_admin,
            password: ENV['JN316_CLAVE']
          }
        }.merge(Rails.application.config.x.jn316_opcon)
        ldap_con = Net::LDAP.new( opcon )
        filter = Net::LDAP::Filter.eq( "cn", nusuario )
        ldap_con.search(:base => Rails.application.config.x.jn316_base, 
                         :filter => filter ) do |entry|
          return entry
#          puts "DN: #{entry.dn}"
#          entry.each do |attribute, values|
#            puts "   #{attribute}:"
#            values.each do |value|
#              puts "      --->#{value}"
#            end
#          end
        end
        prob = 'Credenciales de administracion LDAP invalidas'
        return nil
      rescue
        prob = 'Problema conectando a servidor LDAP'
        return nil
      end


      def actualiza_usuario(usuario, ldapus, clave=nil)
        usuario.nombres=ldapus.givenname if ldapus.givenname
        usuario.apellidos=ldapus.sn if ldapus.sn
        usuario.email=ldapus.mail if ldapus.mail
        usuario.email=ldapus.mail[0] if is_array?(ldapus.mail)
      end

      def authenticate!
        if params[:usuario]
          nusuario = limpia_usuario(params[:usuario][:nusuario])
          username="cn=#{nusuario},#{Rails.application.config.x.jn316_base}"
          password = params[:usuario][:password]
          opcon = {
            host: Rails.application.config.x.jn316_servidor,
            port: Rails.application.config.x.jn316_puerto,
            auth: {
              method: :simple, 
              username: username, 
              password: password 
            }
          }.merge(Rails.application.config.x.jn316_opcon)
          ldap_con = Net::LDAP.new( opcon )

          if ldap_con.bind
            usuario = Usuario.find_or_create_by(nusuario: nusuario)
            ldapus = ldap_busca_como_admin(nusuario, prob)
            actualiza_usuario(usuario, ldapus, password)

            if (!usuario.email) then
              usuario.email = 'x' # aqui completar registro de usuario con información de LDAP considerar tambien el tema de sincronizar
            end
            success!(usuario)
          else
            # No se logró autenticar, bien porque el usuario no existe 
            #   o bien porque la clave es errada
            #byebug
            prob = ""
            ldapus = ldap_busca_como_admin(nusuario, prob)
            unless ldapus.nil?
              usuario = Usuario.find_or_create_by(nusuario: nusuario)
              actualiza_usuario(usuario, ldapus)
              if ldapus.userpassword == '' && 
                usuario.fechadeshabiltiacion == ''
                # si está deshabilitado en LDAP pero no en base 
                # también deshabilita en base
                usuario.fechadeshabilitacion = Date.today
              end
              prob = "No pudo autenticar: " + prob
              puts prob
              self.errors.add :nusuario, prob
              fail(:invalid_login)
              return nil
            end

            # No se encontró usuario en LDAP pasar a usuarios locales en base
            return pass
          end
        end
        rescue Exception => exception
        puts "No pudo conectarse a servido LDAP"
        fail('No pudo conectarse a servidor LDAP')
        self.errors.add :nusuario, "Servidor LDAP no opera?"  
        return pass
      end

      # Un usuario solo puede tener letras, digitos y _
      def limpia_usuario(u)
        r = ""
        u.split("").each do |c|
          r += case c
          when 'a'..'z' then c
          when 'A'..'Z' then c
          when '0'..'9' then c
          when '_' then '_'
          else ''
          end
        end
        return r
      end
            
    end
  end
end

Warden::Strategies.add( :ldap_authenticatable, 
                       Devise::Strategies::LdapAuthenticatable)
