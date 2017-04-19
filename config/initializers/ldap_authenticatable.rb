# encoding: utf-8

require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable

      include Jn316Gen::LdapHelper


      def authenticate!
        if params[:usuario]
          nusuario = limpia_cn(params[:usuario][:nusuario])
          username="cn=#{nusuario},#{Rails.application.config.x.jn316_basegente}"
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
          ldapus = ldap_busca_como_admin(nusuario, prob)
          if ldapus.nil?
            # Usuario no pudo encontrarse en LDAP (falla o no está).
            # Intentar con otra estrategia.
            return pass
          end
          grupos = ldap_busca_grupos_usuario_como_admin(ldapus, prob)
          if grupos.nil?
            prob = 'No pudo adquirir grupos. ' + prob
            puts prob
            @halted = true
            self.error.add :nusuario, prob
            fail(prob)
            #raise Exception(prob)
            return nil
          end
          ldap_con = Net::LDAP.new( opcon )
          if ldap_con.bind
            usuario = crear_actualizar_usuario(
              nusuario, ldapus, grupos, prob, password)
            if usuario.nil?
              prob = "No pudo crear/actualizar usuario en base de datos" + prob
              puts prob
              self.errors.add :nusuario, prob
              @halted = true
              fail(prob)
              #raise Exception(prob)
              return nil
            end
            success!(usuario) 
          else
            # No se logró autenticar, bien porque el usuario no existe en LDAP
            #   o bien porque la clave es errada
            # el usuario existe en el LDAP, crear o actualizar en base
            # pero sin clave porque fue errada
            usuario = crear_actualizar_usuario(nusuario, ldapus, grupos, prob)
            prob = "No pudo autenticar: " + prob
            puts prob
            self.errors.add :nusuario, prob
            @halted = true
            fail(prob)
            #raise Exception(prob)
            return nil
          end
        end
      rescue Exception => exception
        prob = "¿Opera el servidor LDAP? " + ' Excepción: ' + 
          exception.to_s
        puts prob
        self.errors.add :nusuario, prob
        return pass
      end

           
    end
  end
end

Warden::Strategies.add( :ldap_authenticatable, 
                       Devise::Strategies::LdapAuthenticatable)
