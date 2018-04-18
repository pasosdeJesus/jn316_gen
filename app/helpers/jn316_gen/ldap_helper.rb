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
      lusuario = []
      ldap_conadmin = Net::LDAP.new( opcon )
      ldap_conadmin.open do |ldap|
        filter = Net::LDAP::Filter.eq( "objectClass", 'posixAccount') &
          Net::LDAP::Filter.eq( "cn", nusuario ) 
        lusuario.concat(ldap.search(
          :base => Rails.application.config.x.jn316_basegente, 
          :filter => filter ))
      end
      if lusuario.length != 1
        prob << 'Usuario no encontrado'
      end
      return lusuario[0]
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_busca_como_admin). '+
        ldap.get_operation_result.code.to_s + '-' +
        ldap.get_operation_result.message.to_s + '.  Excepción: ' + 
        exception.to_s
      puts prob
      return nil
    end

    # Retorna valor de un campo ldap de un registro r
    def valor_campo_ldap(r, campo)
      return nil unless r.respond_to?(campo.to_sym)
      return r[campo.to_sym][0] if r[campo.to_sym].kind_of?(Array)
      return r[campo.to_sym]
    end

    # Actualiza en base de datos informacion de usuario sacada de LDAP
    # usuario es modelo de usuario por actualizar
    # ldapus es entrada en LDAP del usuario
    # grupos es arreglo con ids en base de datos de los grupos a los
    # que debe pertenecer el usuario
    # prob es colchon de errores
    def actualizar_usuario(usuario, ldapus, grupos, prob, clave=nil)
      usuario.nombres = valor_campo_ldap(ldapus, :givenname)
      usuario.apellidos = valor_campo_ldap(ldapus, :sn)
      usuario.email = valor_campo_ldap(ldapus, :mail)
      usuario.uidNumber = valor_campo_ldap(ldapus, :uidNumber)
      if !ldapus.respond_to?(:userPassword)
        # deshabilitado en LDAP
        # Si falta deshabilitar en base
        if usuario.fechadeshabilitacion.nil?
          usuario.fechadeshabilitacion = Date.today
        end
      else 
        # habilitado en LDAP, habilitar y guardar clave si hay
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
      usuario.email = valor_campo_ldap(ldapus, :mail)
      usuario.email = nusuario + '@porcompletar.org' unless usuario.email
      usuario.encrypted_password = 'x'
      usuario.encrypted_password = BCrypt::Password.create( clave, {
        cost: Rails.application.config.devise.stretches
      }) if !clave.nil?
      usuario.fechacreacion = Date.today
      usuario.no_modificar_ldap = "1"
      persona = Sip::Persona.new
      usuario.nombres = persona.nombres = valor_campo_ldap(ldapus, :givenname)
      usuario.apellidos = persona.apellidos = valor_campo_ldap(ldapus, :sn)
      persona.sexo = 'S'
      persona.save
      usuario.persona_id = persona.id
      usuario.save
      if (usuario.errors.messages.length > 0)
        prob << usuario.errors.messages.to_s
        return nil
      end

      return usuario
    end


    # crea un usuario y/o lo actualiza si ya existe
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
      grupo.gidNumber = valor_campo_ldap(ldapgr, :gidNumber)
      grupo.ultimasincldap = Date.today
      grupo.fechadeshabilitacion = nil
      grupo.save
      if (grupo.errors.messages.length > 0)
        prob << grupo.errors.messages.to_s
        return nil
      end
      return grupo
    end

       

    #  Se conecta a LDAP como admin y busca grupos a los que pertence un 
    #  usuario
    def ldap_busca_grupos_usuario_como_admin(uid, gidnumber, prob)
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
      if lgrupos.nil?
        prob << 'No se pudieron cargar grupos: '+
          ldap_conadmin.get_operation_result.code.to_s +
          ' - ' + ldap_conadmin.get_operation_result.message 
        return nil
      end
      lgrupos.each do |entry|
        if (entry.gidnumber && gidnumber && 
            entry.gidnumber[0] == gidnumber) || 
          (uid && entry[:memberuid].include?(uid))
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
      prob << 'Problema conectando a servidor LDAP '+
        '(ldap_busca_grupos_usuario_como_admin). Excepción: ' + exception.to_s
      puts prob
      return nil
    end


    # Sincroniza de LDAP a base (sin grupos) y retorna vector
    # [usuarios, deshab]
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
      if lusuarios.nil?
          prob << ldap_conadmin.get_operation_result.code.to_s +
            ' - ' + ldap_conadmin.get_operation_result.message 
          return nil
      end
      lusuarios.each do |entry|
        #byebug
        u = crear_actualizar_usuario(entry.cn[0], entry, nil, prob)
        if (u.nil?)
          return [usuarios, []]
        end
        usuarios << u.id
      end
      puts "Actualizados " + usuarios.length.to_s + " registros de usuarios"
      # Si se eliminaron registros del LDAP (que no se recomienda) 
      # deshabilitar en base
      ::Usuario.habilitados.where('ultimasincldap IS NOT NULL').each do |u|
        unless usuarios.include?(u.id)
          u.fechadeshabilitacion = Date.today
          u.ultimasincldap = nil
          u.save
          deshab << u.id
        end
      end
      puts "Deshabilitados " + deshab.length.to_s + 
        " registros de usuarios que estuvieron en LDAP pero ya no"
      
      return [usuarios, deshab]
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP ' +
        '(ldap_sincroniza_usuarios). Excepción: ' + exception.to_s
      puts prob
      return [usuarios, deshab]
    end


    def actualizar_miembros_grupos(grupo, entry, prob)
      buenos = []
      sobran = []
      grupo.sip_grupo_usuario.each do |gu|
        if entry.respond_to?(:memberuid) && 
          entry[:memberuid].include?(gu.usuario.nusuario)
          buenos << gu.usuario.nusuario
        else
          sobran << gu.usuario_id
        end
      end
      sobran.each do |uid|
        Sip::GrupoUsuario.connection.execute <<-SQL
          DELETE FROM sip_grupo_usuario WHERE sip_grupo_id=#{grupo.id}
            AND usuario_id=#{uid};
        SQL
      end
      # Los que faltan
      muid = entry.respond_to?(:memberuid) ? entry[:memberuid] : []
      muid.each do |nu|
        unless buenos.include?(nu)
          u = ::Usuario.find_by(nusuario: nu)
          if u
            Sip::GrupoUsuario.create(sip_grupo_id: grupo.id, usuario_id: u.id)
          else
            prob << "  No se encontró en base al usuario #{nu} referenciando en grupo #{entry.cn[0]}."
          end
        end
      end
    end

    # Sincroniza grupos después de haber sincronizado usuarios
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
        actualizar_miembros_grupos(g, entry, prob)
        grupos << g.id
      end
      puts "Actualizados " + grupos.length.to_s + " registros de grupos"
      # Si se eliminaron registros (que no se recomienda) deshabilitar en
      # base
      Sip::Grupo.habilitados.where('ultimasincldap IS NOT NULL').each do |g|
        unless grupos.include?(g.id)
          g.fechadeshabilitacion = Date.today
          g.ultimasincldap = nil
          g.save
          deshab << g.id
        end
      end
      puts "Deshabilitados " + deshab.length.to_s + " registros de grupo que ya no estan en LDAP"
      
      return [grupos, deshab]
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_sincroniza_grupos).' +
        ' Excepción: ' + exception.to_s
      puts prob
      return [grupos, deshab]

    end

    def ldap_cambia_clave(nusuario, claveactual, nuevaclave, prob)
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para cambiar clave'
        return nil
      end
      opcon = {
        host: Rails.application.config.x.jn316_servidor,
        port: Rails.application.config.x.jn316_puerto,
        auth: {
          method: :simple, 
          username: "cn=#{nusuario}," +
            "#{Rails.application.config.x.jn316_basegente}",
          password: claveactual
        }
      }.merge(Rails.application.config.x.jn316_opcon)
      ldap_con = Net::LDAP.new( opcon )
      if !ldap_con.bind
        prob << 'Clave actual errada'
        return false
      end
      ldap_con.open do |ldap|
        dn="cn=#{nusuario},#{Rails.application.config.x.jn316_basegente}"
        #hash = "{SHA}" + Base64.encode64(
        #  Digest::SHA1.digest(nuevaclave)
        #).chomp! 
        hash =  Net::LDAP::Password.generate(:sha, nuevaclave)
        puts 'userPassword: '+hash+"\n" 
        unless ldap.replace_attribute dn, :userPassword, hash
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          puts "OJO prob=#{prob}"
          return false
        end
      end
      return true
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_cambia_clave).' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end

    # Agrega al directorio LDAP un usuario como miembro de varios grupos
    def ldap_agrega_membresia(ldap, nusuario, grupos, prob)
      grupos.each do |g|
        dn="cn=#{g},#{Rails.application.config.x.jn316_basegrupos}"
        unless ldap.add_attribute(dn, 'memberUid', nusuario)
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          return nil
        end
      end
      return grupos
    end


    # Crea un usuario LDAP con las convenciones descritas en README.md
    # Referencias: 
    # https://github.com/schaary/cronSyncInformatikLDAP/blob/master/bin/sync_informatik_ldap
    # http://www.zytrax.com/books/ldap/ape/#posixaccount
    def ldap_crea_usuario(usuario, clave, hash, prob)
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para agregar usuario'
        return nil
      end
      if Rails.application.config.x.jn316_gidgenerico.nil?
        prob << 'No ha asignado gid de grupo generico config.x.jn316_gidgenerico'
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
      cn = limpia_cn(usuario.nusuario)
      dn = "cn=#{cn},#{Rails.application.config.x.jn316_basegente}"
      if !clave.nil? && clave != ''
        hash =  Net::LDAP::Password.generate(:sha, clave)
      end
      if usuario.uidNumber.nil?
        usuario.uidNumber = Usuario.maximum('uidNumber')
        if usuario.uidNumber.nil?
          prob << "No pudo obtenerse uidNumber máximo.  Parece que no ha sincronizado (cree algún usuario en LDAP antes)"
          return false
        end
        usuario.uidNumber += 1
      end
      attr = {
        cn: cn,
        uid: cn,
        mail: usuario.email,
        gidNumber: Rails.application.config.x.jn316_gidgenerico.to_s,
        givenName: usuario.nombres,
        sn: usuario.apellidos,
        homeDirectory: "/home/#{cn}",
        loginShell: "/bin/ksh",
        userPassword: hash,
        uidNumber: usuario.uidNumber.to_s,
        objectclass: ["top", "inetOrgPerson", "posixAccount"]
      }
      grupos = usuario.sip_grupo.map(&:cn)
      ldap_conadmin.open do |ldap|
        if !ldap.add(:dn => dn, :attributes => attr)
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          return false
        end
        if ldap_agrega_membresia(ldap, usuario.nusuario, 
                                         grupos, prob).nil?
          return false
        end
      end
      return true
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_crea_usuario). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end


    # Elimina un usuario LDAP
    def ldap_elimina_usuario(nusuario, prob)
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para eliminar usuario'
        return false
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
      cn = limpia_cn(nusuario)
      dn = "cn=#{cn},#{Rails.application.config.x.jn316_basegente}"
      ldap_conadmin = Net::LDAP.new( opcon )
      ldap_conadmin.open do |ldap|
        unless ldap.delete(dn: dn)
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          puts prob
          return false
        end
        filter = Net::LDAP::Filter.eq( "objectClass", 'posixGroup')
        lgrupos = ldap.search(
          base: Rails.application.config.x.jn316_basegrupos, 
          filter: filter 
        )
        lgrupos.each do |entry|
          if entry.respond_to?(:memberuid) && 
            entry[:memberuid].include?(nusuario)
            unless ldap.replace_attribute(
              entry.dn, 'memberUid', 
              entry[:memberuid] - [nusuario])
              prob << ldap.get_operation_result.code.to_s +
                ' - ' + ldap.get_operation_result.message 
              return false
            end
          end
        end
      end

      return true
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_elimina_usuario). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end

      
    def ldap_actualiza_si_falta(ldap, dn, campo, atr, cambios, val, prob)
      if cambios.include?(campo.to_s)
        unless ldap.replace_attribute dn, atr, val
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          return false
        end
      end
      return true
    end

    # Actualiza un usuario LDAP
    # Soporta renombramiento en caso LDAPv2 eliminando anterior y agregando
    # nuevo (incluyendo actualización a grupos).
    # Hace lo mismo en caso de cambios en grupo que puede mejorarse
    # Otros atributos los remplaza.
    def ldap_actualiza_usuario(nusuarioini, usuario, clave, cambios, prob)
      if cambios.include?('nusuario') ||
        cambios.include?('grupos')
        hash = nil
        if clave.nil? || clave == ""
          entry1 = ldap_busca_como_admin(nusuarioini, prob)
          if entry1.nil?
            return false
          end
          hash = entry1.userPassword[0] if entry1.respond_to?(:userPassword)
        end
        if ldap_elimina_usuario(nusuarioini, prob)
          if ldap_crea_usuario(usuario, clave, hash, prob)
            return true
          end
        end
      end
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para agregar usuario'
        return false
      end
      ret = true # valor por retornar
      dn = "cn=#{limpia_cn(usuario.nusuario)}," +
        "#{Rails.application.config.x.jn316_basegente}"
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
      ldap_conadmin.open do |ldap|
        if cambios.include?('encrypted_password')
          hash = Net::LDAP::Password.generate(:sha, clave)
          ret=false unless ldap_actualiza_si_falta(
            ldap, dn, :encrypted_password, :userPassword, cambios, hash, prob)
        end
        if !ret || !ldap_actualiza_si_falta(ldap, dn, :email, :mail,cambios, 
                               usuario.email, prob) || 
          !ldap_actualiza_si_falta(ldap, dn, :nombres, :givenName, cambios, 
                              usuario.nombres, prob) || 
          !ldap_actualiza_si_falta(ldap, dn, :apellidos, :sn, cambios, 
                              usuario.apellidos, prob) || 
          !ldap_actualiza_si_falta(ldap, dn, :uidNumber, :uidNumber, cambios, 
                              usuario.uidNumber, prob)
          ret = false
        end
        # Deshabilitar en LDAP si está deshabilitado en base
        if !usuario.fechadeshabilitacion.nil?
            unless ldap.delete_attribute dn, 'userPassword'
              prob << ldap.get_operation_result.code.to_s +
                ' - ' + ldap.get_operation_result.message 
              ret = false
            end
        end
      end

      return ret
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_actualiza_usuario). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end

    # Actualiza un grupo LDAP
    # Soporta renombramiento en caso LDAPv2 eliminando anterior y agregando
    # nuevo (incluyendo usuarios).
    # Hace lo mismo en caso de cambios en grupo que puede mejorarse
    # Otros atributos los remplaza.
    def ldap_actualiza_grupo(cnini, grupo, cambios, prob)
      if cambios.include?('cn') || cambios.include?('usuarios')
        if ldap_elimina_grupo(cnini, prob)
          if ldap_crea_grupo(grupo, prob)
            return true
          end
        end
      end
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para agregar usuario'
        return false
      end
      ret = true # valor por retornar
      dn = "cn=#{limpia_cn(grupo.cn)}," +
        "#{Rails.application.config.x.jn316_basegrupos}"
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
      ldap_conadmin.open do |ldap|
        if !ret || !ldap_actualiza_si_falta(ldap, dn, :nombre, :description,
                                            cambios, grupo.nombre, prob)
          ret = false
        end
      end

      return ret
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_actualiza_grupo). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end

    # Un cn portable solo puede tener letras del alfabet inglés, digitos y _
    # Evitamos escapar pues https://www.ietf.org/rfc/rfc4514.txt no
    # parece implementado en phpldapmin+ldapd (no es posible crear un
    # cn con coma, aunque si con espacios y caracteres de español)
    def limpia_cn(u)
      r = ""
      if u.nil?
        return r
      end
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

    # Crea un grupo LDAP con las convenciones descritas en README.md
    def ldap_crea_grupo(grupo, prob)
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para agregar grupo'
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
      cn = limpia_cn(grupo.cn)
      dn = "cn=#{cn},#{Rails.application.config.x.jn316_basegrupos}"
      if grupo.gidNumber.nil?
        grupo.gidNumber = Sip::Grupo.maximum('gidNumber')
        if grupo.gidNumber.nil?
          prob << "No pudo obtenerse gidNumber máximo.  Parece que no ha sincronizado (cree algún usuario en LDAP antes)"
          return false
        end
        grupo.gidNumber += 1
      end
      attr = {
        cn: cn,
        gidNumber: grupo.gidNumber.to_s,
        description: grupo.nombre,
        objectclass: ["top", "posixGroup"]
      }
      gusuarios = grupo.usuario.map(&:nusuario).sort.uniq
      ldap_conadmin.open do |ldap|
        if !ldap.add(:dn => dn, :attributes => attr)
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          return false
        end
        gusuarios.each do |nusuario|
          unless ldap.add_attribute(dn, 'memberUid', nusuario)
            prob << ldap.get_operation_result.code.to_s +
              ' - ' + ldap.get_operation_result.message 
            return nil
          end
        end
      end
      return true
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_crea_grupo). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end

    # Elimina un grupo LDAP
    def ldap_elimina_grupo(cn, prob)
      if !ENV['JN316_CLAVE']
        prob << 'Falta clave LDAP para eliminar usuario'
        return false
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
      cn = limpia_cn(cn)
      dn = "cn=#{cn},#{Rails.application.config.x.jn316_basegrupos}"
      ldap_conadmin = Net::LDAP.new( opcon )
      ldap_conadmin.open do |ldap|
        unless ldap.delete(dn: dn)
          prob << ldap.get_operation_result.code.to_s +
            ' - ' + ldap.get_operation_result.message 
          puts prob
          return false
        end
      end

      return true
    rescue Exception => exception
      prob << 'Problema conectando a servidor LDAP (ldap_elimina_grupo). ' +
        ' Excepción: ' + exception.to_s
      puts prob
      return false
    end


  end
end
