#encoding: UTF-8 

require 'digest/sha1'
require 'base64'

module Jn316Gen
  module LdapHelper

    # https://www.ietf.org/rfc/rfc4514.txt
    def escapa_ldap
      
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

  end
end
