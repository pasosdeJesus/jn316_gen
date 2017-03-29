# encoding: utf-8

require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable


      # Busca usuario nusuario como admin y retorna toda la información 
      def ldap_busca_como_admin(nusuario, prob)
        if !ENV['JN316_CLAVE']
          prob << 'Falta clave LDAP para buscar'
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
        prob << 'Credenciales de administracion LDAP invalidas'
        return nil
      rescue
        prob << 'Problema conectando a servidor LDAP'
        return nil
      end


      def actualizar_usuario(usuario, ldapus, prob, clave=nil)
        usuario.nombres = ldapus.givenname if ldapus.givenname
        usuario.apellidos = ldapus.sn if ldapus.sn
        usuario.email = ldapus.mail if ldapus.mail
        usuario.email = ldapus.mail[0] if ldapus.mail.kind_of?(Array)
        if (ldapus.userPassword.nil? && usuario.fechadeshbilitacion.nil?)
          # deshabilitar
          usuario.fechadeshabilitacion = Date.today
        else 
          # habilitado, guardar clave si hay
          unless clave.nil?
            usuario.encrypted_password = BCrypt::Password.create(
              clave, 
              {:cost => Rails.application.config.devise.stretches}
            )
          end
        end
        usuario.ultimasincldap = Date.today
        usuario.save
        if (usuario.errors.messages.length > 0)
          prob << usuario.errors.messages.to_s
          return nil
        end
        return usuario
      end


      def crear_usuario_min(nusuario, ldapus, prob, clave)
        usuario = Usuario.new
        usuario.nusuario = nusuario
        usuario.email = nusuario + '@porcompletar.org'
        usuario.email = ldapus.mail if ldapus.mail
        usuario.email = ldapus.mail[0] if ldapus.mail.kind_of?(Array)
        usuario.encrypted_password = 'x'
        usuario.encrypted_password = BCrypt::Password.create( clave, {
          cost: Rails.application.config.devise.stretches}) if !clave.nil?
        usuario.fechacreacion = Date.today
        usuario.save
        if (usuario.errors.messages.length > 0)
          prob << usuario.errors.messages.to_s
          return nil
        end

        return usuario
      end


      # crea un usuario y/o actualizarlo si ya existe
      def crear_actualizar_usuario(nusuario, ldapus, prob, clave = nil)
        usuario = Usuario.where(nusuario: nusuario).take
        if usuario.nil?
          usuario = crear_usuario_min(nusuario, ldapus, prob, clave)
          if usuario.nil?
            prob << 'No pudo crear usuario: ' + prob
            return nil
          end
        end
        return actualizar_usuario(usuario, ldapus, prob, clave)
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
          prob = ""
          ldap_con = Net::LDAP.new( opcon )
          if ldap_con.bind
            ldapus = ldap_busca_como_admin(nusuario, prob)
            if ldapus.nil?
              prob = "No pudo obtenerse usuario de LDAP: " + prob
              puts prob
              self.errors.add :nusuario, prob
              fail(prob)
              @halted = true
              return nil
            end
            usuario = crear_actualizar_usuario(
              nusuario, ldapus, prob, password)
            if usuario.nil?
              prob = "No pudo crear/actualizar usuario en base de datos" + prob
              puts prob
              self.errors.add :nusuario, prob
              fail(prob)
              @halted = true
              return nil
            end
            success!(usuario) 
          else
            # No se logró autenticar, bien porque el usuario no existe en LDAP
            #   o bien porque la clave es errada
            ldapus = ldap_busca_como_admin(nusuario, prob)
            unless ldapus.nil?
              # el usuario existe en el LDAP, crear o actualizar en base
              # pero sin clave porque fue errada
              usuario = crear_actualizar_usuario(nusuario, ldapus, prob)
              prob = "No pudo autenticar: " + prob
              puts prob
              self.errors.add :nusuario, prob
              fail(prob)
              @halted = true
              return nil
            end

            # No se encontró usuario en LDAP pasar a usuarios locales en base
            return pass
          end
        end
      rescue Exception => exception
        prob = "¿Opera el servidor LDAP? " + prob + ' Excepción: ' + 
          exception.to_s
        puts prob
        self.errors.add :nusuario, prob
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
