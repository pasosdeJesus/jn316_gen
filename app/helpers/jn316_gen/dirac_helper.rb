#econding: UTF-8

# Operaciones básicas en un directorio activo
# - Recuperar datos de un usuario
# - Crea un usuario
# - Cambia clave de un usuario
# - Elimina un usuario
# - Recuperar datos de un grupo
# - Crea un grupo
# - Agrega un usuario a un grupo
# - Saca a un usuario de un grupo
# - Agrega un subgrupo a un grupo
# - Saca a un subgrupo de un grupo
# - Elimina un grupo


# Basado en:
# https://gist.github.com/jeffjohnson9046/7012167
# https://stackoverflow.com/questions/24708113/net-ldap-create-user-with-password
# https://msdn.microsoft.com/en-us/library/cc223248.aspx
# https://github.com/w0de/active_directory/blob/master/lib/active_directory/user.rb

require 'net/ldap'

module Jn316Gen
  module DiracHelper
 
    def self.respuesta_ldap(ldap, prob)
      if ldap.get_operation_result.code != 0
        prob += "Código de respuesta: " +
          "#{ ldap.get_operation_result.code }, " +
          "Mensaje: #{ ldap.get_operation_result.message }"
      end
    end

    def self.codifica_clave(clave)
      return "\"#{clave}\"".encode(Encoding::UTF_16LE).
        force_encoding(Encoding::ASCII_8BIT)
    end

    def self.nombrecompleto(f, l)
      "#{f.strip} #{l.strip}".strip
    end

    def self.buscar_usuario(ldap, usuario, prob)
      filtro_busqueda = Net::LDAP::Filter.eq(:objectClass, 'person') &
        Net::LDAP::Filter.eq("sAMAccountName", usuario)

      ldap.search(:filter => filtro_busqueda) { |elemento| 
        return elemento
      }
      respuesta_ldap(ldap, prob)
      return nil
    end

    def self.buscar_grupo(ldap, grupo, prob)
      filtro_busqueda = Net::LDAP::Filter.eq(:objectClass, 'group') &
        Net::LDAP::Filter.eq("sAMAccountName", grupo)
      #Net::LDAP::Filter.eq(:name, grupo)

      ldap.search(:filter => filtro_busqueda) { |elemento| 
        return elemento
      }
      respuesta_ldap(ldap, prob)
      return nil
    end


    def self.agregar_usuario(ldap, nombres, apellidos, usuario, clave, prob)
      attrs = {
        objectclass: ["top", "person", "organizationalPerson", "user"],
        cn: nombrecompleto(nombres, apellidos),
        sn: apellidos.capitalize,
        givenname: nombres.capitalize,
        displayname: nombrecompleto(nombres, apellidos),
        name: nombrecompleto(nombres, apellidos),
        samaccountname: usuario,
        unicodePwd: codifica_clave(clave),
        lockoutTime: '0',
        userAccountControl: '512',
        pwdLastSet: '-1'
      }
      dn = "cn=#{attrs[:cn]},#{Rails.application.secrets['JN316_DA_BASE_USUARIOS']}"
      ldap.add(:dn => dn, :attributes => attrs)

      if ldap.get_operation_result.code != 0
        prob += "Falló añadir usuario #{usuario}"
        respuesta_ldap(ldap, prob)
      end
    end 

    def self.eliminar_usuario(ldap, usuario, prob)
      u = buscar_usuario(ldap, usuario, prob)
      if u.nil?
        prob += "No existe usuario #{usuario}"
        return
      end
      dnu = u[:dn][0]
      ldap.delete(dn: dnu)
      if ldap.get_operation_result.code != 0
        prob += "Falló al elimina usuario #{usuario}. "
        respuesta_ldap(ldap, prob)
      end
    end


    def self.agregar_grupo(ldap, nombre, prob)
      attrs = {
        objectclass: ["top", "group"],
        cn: nombre,
        name: nombre,
        samaccountname: nombre,
      }
      dn = "cn=#{nombre},#{Rails.application.secrets['JN316_DA_BASE_GRUPOS']}"
      ldap.add(:dn => dn, :attributes => attrs)

      if ldap.get_operation_result.code != 0
        prob += "Falló añadir grupo #{nombre}. "
        respuesta_ldap(ldap, prob)
      end
    end 

    def self.eliminar_grupo(ldap, grupo, prob)
      g = buscar_grupo(ldap, grupo)
      if g.nil?
        prob += "No existe grupo #{grupo}"
        return
      end
      dng = g[:dn][0]
      ldap.delete(dn: dng)
      if ldap.get_operation_result.code != 0
        prob += "Falló al elimina grupo #{grupo}"
        respuesta_ldap(ldap, prob)
      end
    end


    def self.cambiar_clave(ldap, usuario, nuevaclave, prob)
      e = buscar_usuario(ldap, usuario, prob)
      dn = e[:dn][0]
      ldap.replace_attribute(dn, :lockoutTime, '0')
      ldap.replace_attribute(dn, :unicodePwd, codifica_clave(nuevaclave))
      ldap.replace_attribute(dn, 'userAccountControl', '512')
      ldap.replace_attribute(dn, 'pwdLastSet', '-1')

      if ldap.get_operation_result.code != 0
        prob += "Falló cambiar clave de #{usuario}"
        respuesta_ldap(ldap, prob)
      end
    end 


    def self.agregar_usuario_a_grupo(ldap, usuario, grupo, prob)
      u = buscar_usuario(ldap, usuario, prob)
      if u.nil?
        prob += "No existe usuario #{usuario}. "
        return
      end
      dnu = u[:dn][0]
      g = buscar_grupo(ldap, grupo, prob)
      if g.nil?
        prob += "No se encontró grupoe #{grupo}. "
        return
      end
      dng = g[:dn][0]
      if !g[:member].include?(dnu)
        ldap.add_attribute(dng, 'member', dnu)
      end
      respuesta_ldap(ldap, prob)
    end

    def self.sacar_usuario_de_grupo(ldap, usuario, grupo, prob)
      u = buscar_usuario(ldap, usuario, prob)
      if u.nil?
        puts "No existe usuario #{usuario}"
        return
      end
      dnu = u[:dn][0]
      g = buscar_grupo(ldap, grupo)
      if g.nil?
        puts "No se encontró grupoe #{grupo}"
        return
      end
      dng = g[:dn][0]
      if g[:member].include?(dnu)
        nm = g[:member] - [dnu]
        ldap.replace_attribute(dng, 'member', nm)
      end
      respuesta_ldap(ldap)
    end


    def self.agregar_subgrupo_a_grupo(ldap, grupo, subgrupo, prob)
      g = buscar_grupo(ldap, grupo, prob)
      if g.nil?
        prob += "No existe grupo #{grupo}. "
        return
      end
      dng = g[:dn][0]
      s = buscar_grupo(ldap, subgrupo, prob)
      if s.nil?
        prob += "No se encontró grupo #{subgrupo}"
        return
      end
      dns = s[:dn][0]
      if !g[:member].include?(dns)
        ldap.add_attribute(dng, 'member', dns)
      end
      respuesta_ldap(ldap, prob)
    end

    def self.sacar_subgrupo_de_grupo(ldap, grupo, subgrupo, prob)
      g = buscar_grupo(ldap, grupo, prob)
      if g.nil?
        prob += "No existe grupo #{grupo}. "
        return
      end
      dng = g[:dn][0]
      s = buscar_grupo(ldap, subgrupo, prob)
      if s.nil?
        prob += "No se encontró grupo #{subgrupo}. "
        return
      end
      dns = s[:dn][0]
      if g[:member].include?(dns)
        nm = g[:member] - [dns]
        ldap.replace_attribute(dng, 'member', nm)
      end
      respuesta_ldap(ldap, prob)
    end

    def self.conectar
      Net::LDAP.open(
        host:  Rails.application.secrets['JN316_DA_MAQUINA'], 
        port:  Rails.application.secrets['JN316_DA_PUERTO'], 
        base:  Rails.application.secrets['JN316_DA_BASE'],  
        auth:  {
          :method => :simple,
          # Importante que comience con el dominio e.g MIDOMINIO\Administrador
          :username => Rails.application.secrets['JN316_DA_CUENTA'],  
          :password => Rails.application.secrets['JN316_DA_CLAVE'],  
        },
        encryption: {
          method: :simple_tls
        }) do |ldap|
        yield ldap
      end
    end

  end
end
