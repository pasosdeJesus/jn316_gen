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
        ldap_conadmin = Net::LDAP.new( opcon )
        filter = Net::LDAP::Filter.eq( "cn", nusuario )
        ldap_conadmin.search(:base => Rails.application.config.x.jn316_basegente, 
                         :filter => filter ) do |entry|
          return entry
        end
        prob << 'Credenciales de administracion LDAP invalidas'
        return nil
      rescue Exception => exception
        prob << 'Problema conectando a servidor LDAP. Excepción: ' + 
          exception.to_s
        return nil
      end

      # usuario es modelo de usuario por actualizar
      # grupos es arreglo con ids en base de datos de los grupos a los
      # que debe pertenecer el usuario
      def actualizar_usuario(usuario, ldapus, grupos, prob, clave=nil)
        usuario.nombres = ldapus.givenname if ldapus.givenname
        usuario.apellidos = ldapus.sn if ldapus.sn
        usuario.email = ldapus.mail if ldapus.mail
        usuario.email = ldapus.mail[0] if ldapus.mail.kind_of?(Array)
        if (ldapus.userPassword.nil? && usuario.fechadeshabilitacion.nil?)
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

        # Los grupos debieron sincronizarse antes, ahora solo 
        # asegurar que están los de grupos y solo esos.
        grupobd = []
        Sip::GrupoUsuario.where(usuario_id: usuario.id).map do |gu|
          grupobd << gu.sip_grupo_id
        end
        pore = grupobd-grupos
        pora = grupos-grupobd
        pore.each do |g|
          mg = Sip::GrupoUsuario.find(usuario_id: usuario.id, sip_grupo_id: g)
          mg.delete
        end
        pora.each.each do |g|
          n = Sip::GrupoUsuario.new(usuario_id: usuario.id, sip_grupo_id: g)
          n.save
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
      def crear_actualizar_usuario(nusuario, ldapus, grupos, prob, 
                                        clave = nil)
        usuario = Usuario.where(nusuario: nusuario).take
        if usuario.nil?
          usuario = crear_usuario_min(nusuario, ldapus, prob, clave)
          if usuario.nil?
            prob << 'No pudo crear usuario: ' + prob
            return nil
          end
        end
        return actualizar_usuario(usuario, ldapus, grupos, prob, clave)
      end


      def actualizar_grupo(grupo, ldapgr, prob)
        grupo.nombre = ldapgr.cn[0]
        grupo.ultimasincldap = Date.today
        grupo.save
        if (grupo.errors.messages.length > 0)
          prob << grupo.errors.messages.to_s
          return nil
        end
        return grupo
      end


      def crear_grupo_min(cn, prob)
        grupo = Sip::Grupo.new(nombre: cn, fechacreacion: Date.today)
        grupo.save
        if (grupo.errors.messages.length > 0)
          prob << grupo.errors.messages.to_s
          return nil
        end

        return grupo
      end


      # crea un grupo y/o actualizarlo si ya existe
      def crear_actualizar_grupo(cn, ldapgr, prob)
        grupo = Sip::Grupo.where(nombre: cn).take
        if grupo.nil?
          grupo = crear_grupo_min(cn, prob)
          if grupo.nil?
            prob << 'No pudo crear grupo: ' + prob
            return nil
          end
        end
        return actualizar_grupo(grupo, ldapgr, prob)
      end


      def ldap_busca_grupos_usuario_como_admin(ldapus, prob)
        grupos = []
        opcon = {
          host: Rails.application.config.x.jn316_servidor,
          port: Rails.application.config.x.jn316_puerto,
          auth: {
            method: :simple, 
            username: Rails.application.config.x.jn316_admin,
            password: ENV['JN316_CLAVE']
          }
        }.merge(Rails.application.config.x.jn316_opcon)
        filter = Net::LDAP::Filter.eq( "objectClass", 'posixGroup')
        ldap_conadmin = Net::LDAP.new( opcon )
        lgrupos = ldap_conadmin.search(
          base: Rails.application.config.x.jn316_basegrupos, 
          filter: filter 
        )
        lgrupos.each do |entry|
          if (entry.gidnumber && ldapus.gidnumber && 
              entry.gidnumber[0] == ldapus.gidnumber[0]) || 
            (ldapus.uid && entry[:memberuid].include?(ldapus.uid[0]))
            puts "OJO gidnumber=#{entry.gidnumber}, cn=#{entry.cn}"
            cn = entry.cn[0]
            g = crear_actualizar_grupo(entry.cn[0], entry, prob)
            if (g.nil?)
              return nil
            end
            grupos << g.id
          end
        end
        return grupos
      rescue Exception => exception
        prob << 'Problema conectando a servidor LDAP. Excepción: ' + 
          exception.to_s
        return nil
      end


      def authenticate!
        if params[:usuario]
          nusuario = limpia_nusuario(params[:usuario][:nusuario])
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
        prob = "¿Opera el servidor LDAP? " + prob + ' Excepción: ' + 
          exception.to_s
        puts prob
        self.errors.add :nusuario, prob
        return pass
      end

      # Un usuario solo puede tener letras, digitos y _
      def limpia_nusuario(u)
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
