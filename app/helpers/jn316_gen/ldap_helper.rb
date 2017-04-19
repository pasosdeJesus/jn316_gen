#encoding: UTF-8 

require 'digest/sha1'
require 'base64'

module Jn316Gen
  module LdapHelper


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
      filter = Net::LDAP::Filter.eq( "objectClass", 'posixAccount') &
        Net::LDAP::Filter.eq( "cn", nusuario ) 
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

    # Actualiza en base de datos informacion de usuario sacada de LDAP
    # usuario es modelo de usuario por actualizar
    # ldapus es entrada en LDAP del usuario
    # grupos es arreglo con ids en base de datos de los grupos a los
    # que debe pertenecer el usuario
    # prob es colchon de errores
    def actualizar_usuario(usuario, ldapus, grupos, prob, clave=nil)
      usuario.nombres = ldapus.givenname if ldapus.givenname
      usuario.nombres = ldapus.givenname[0] if ldapus.givenname.kind_of?(Array)
      usuario.apellidos = ldapus.sn if ldapus.sn
      usuario.apellidos = ldapus.sn[0] if ldapus.givenname.kind_of?(Array)
      usuario.email = ldapus.mail if ldapus.mail
      usuario.email = ldapus.mail[0] if ldapus.mail.kind_of?(Array)
      if (!ldapus.respond_to?(:userPassword) && 
          usuario.fechadeshabilitacion.nil?)
        # deshabilitar
        usuario.fechadeshabilitacion = Date.today
      else 
        # habilitado, guardar clave si hay
        usuario.fechadeshabilitacion = nil
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

      if grupos
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
      end

      return usuario
    end


    # Crea un usuario con datos mínimos
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


    # crea un grupo y/o actualiza si ya existe
    def crear_actualizar_grupo(ldapgr, prob)
      cn = ldapgr.cn[0]
      d = ldapgr.respond_to?(:description) ? ldapgr.description[0] : cn
      grupo = Sip::Grupo.where(cn: cn).take
      if grupo.nil?
        grupo = Sip::Grupo.new(fechacreacion: Date.today)
        if grupo.nil?
          prob << 'No pudo crear grupo: ' + prob
          return nil
        end
      end
      grupo.cn = cn
      grupo.nombre = d
      grupo.ultimasincldap = Date.today
      grupo.fechadeshabilitacion = nil
      grupo.save
      if (grupo.errors.messages.length > 0)
        prob << grupo.errors.messages.to_s
        return nil
      end
      return grupo
    end

       
    # Sincroniza en base membresia de usuarios en grupo id entry (LDAP)
    # Retorna usuarios del grupo como queda en base tras verificaciones
    def actualizar_miembros_grupo(gid, entry, prob) 

      usl = []
      cn = entry.cn[0]
      # Los usuarios se debieron sincronizar antes
      entry[:memberuid].each do |n|
        u = ::Usuario.find_by(nusuario: n)
        if u.nil?
          puts "Problema en grupo #{cn} porque miembro #{n} no es usuario"
        else
          usl << u.id
        end
      end
 
      usb = []
      Sip::GrupoUsuario.where(sip_grupo_id: gid).map do |gu|
        usb << gu.usuario_id
      end
      pore = usb-usl
      pora = usl-usb
      usf = usb
      pore.each do |u|
        mg = Sip::GrupoUsuario.find_by(usuario_id: u, sip_grupo_id: gid)
        mg.delete
        usf = usf - [u]
      end
      pora.each do |u|
        n = Sip::GrupoUsuario.new(usuario_id: u, sip_grupo_id: gid)
        n.save
        usf = usf + [u]
      end

      return usf
    end


    #  Se conecta a LDAP como admin y busca grupos a los que pertence un usuario
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
          g = crear_actualizar_grupo(entry, prob)
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


    # Sincroniza de LDAP a base y retorna vector [usuarios, deshab]
    # donde usuarios es vector de ids de usuarios creados/actualizados
    # y deshab es vector de los deshabilitados
    def ldap_sincroniza_usuarios(prob)
      usuarios = []
      deshab = []
      opcon = {
        host: Rails.application.config.x.jn316_servidor,
        port: Rails.application.config.x.jn316_puerto,
        auth: {
          method: :simple, 
          username: Rails.application.config.x.jn316_admin,
          password: ENV['JN316_CLAVE']
        }
      }.merge(Rails.application.config.x.jn316_opcon)
      filter = Net::LDAP::Filter.eq( "objectClass", 'posixAccount')
      ldap_conadmin = Net::LDAP.new( opcon )
      lusuarios = ldap_conadmin.search(
        base: Rails.application.config.x.jn316_basegente, 
        filter: filter 
      )
      lusuarios.each do |entry|
        u = crear_actualizar_usuario(entry.cn[0], entry, nil, prob)
        if (u.nil?)
          return [usuarios, []]
        end
        usuarios << u.id
      end
      puts "Actualizados " + usuarios.length.to_s + " registros de usuarios"
      # Si se eliminaron registros (que no se recomienda) deshabilitar en
      # base
      ::Usuario.habilitados.where('ultimasincldap IS NOT NULL').each do |u|
        unless usuarios.include?(u.id)
          u.fechadeshabilitacion = Date.today
          u.save
          deshab << u.id
        end
      end
      puts "Deshabilitados " + deshab.length.to_s + " registros de usuarios que ya no estan en LDAP"
      
      return [usuarios, deshab]
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP. Excepción: ' + 
        exception.to_s
      return [usuarios, deshab]
    end



    def ldap_sincroniza_grupos(prob)
      grupos = []
      deshab = []
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
        g = crear_actualizar_grupo(entry, prob)
        if (g.nil?)
          return [grupos, []]
        end
        #miembros = actualizar_miembros_grupos(g.id, entry, prob)
        #if (miembros.nil?)
        #  return nil
        #end
        grupos << g.id
      end
      puts "Actualizados " + grupos.length.to_s + " registros de grupos"
      # Si se eliminaron registros (que no se recomienda) deshabilitar en
      # base
      Sip::Grupo.habilitados.where('ultimasincldap IS NOT NULL').each do |g|
        unless grupos.include?(g.id)
          g.fechadeshabilitacion = Date.today
          g.save
          deshab << g.id
        end
      end
      puts "Deshabilitados " + deshab.length.to_s + " registros de grupo que ya no estan en LDAP"
      
      return [grupos, deshab]
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP. Excepción: ' + 
        exception.to_s
      return [grupos, deshab]

    end

    def ldap_cambia_clave(nusuario, claveactual, nuevaclave, prob)
      if !ENV['JN316_CLAVE']
        prob='Falta clave LDAP para cambiar clave'
        return nil
      end
      opcon = {
        host: Rails.application.config.x.jn316_servidor,
        port: Rails.application.config.x.jn316_puerto,
        auth: {
          method: :simple, 
          username: "cn=#{nusuario},#{Rails.application.config.x.jn316_basegente}",
          password: claveactual
        }
      }.merge(Rails.application.config.x.jn316_opcon)
      ldap_con = Net::LDAP.new( opcon )
      if !ldap_con.bind
        prob = 'Clave actual errada'
        return false
      end
      ldap_con.open do |ldap|
        dn="cn=#{nusuario},#{Rails.application.config.x.jn316_basegente}"
        hash = "{SHA}" + Base64.encode64(
          Digest::SHA1.digest(nuevaclave)
        ).chomp! 
        puts 'userPassword: '+hash+"\n" 
        ldap.replace_attribute dn, :userPassword, hash
      end
      return true
    rescue Exception => exception
      prob = 'Problema conectando a servidor LDAP. Excepción: ' + 
        exception.to_s
      return false
    end

    # Un cn portable solo puede tener letras del alfabet inglés, digitos y _
    # Evitamos escapar pues https://www.ietf.org/rfc/rfc4514.txt no
    # parece implementado en phpldapmin+ldapd (no es posible crear un
    # cn con coma, aunque si con espacios y caracteres de español)
    def limpia_cn(u)
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
