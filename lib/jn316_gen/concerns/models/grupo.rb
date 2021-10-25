require 'sip/concerns/models/grupo'

module Jn316Gen
  module Concerns
    module Models
      module Grupo
        extend ActiveSupport::Concern


        included do

          include Sip::Basica
          include Sip::Concerns::Models::Grupo
          include Jn316Gen::LdapHelper 

          attr :no_modificar_ldap
          attr_accessor :no_modificar_ldap
          attr :cnini
          attr_accessor :cnini
          attr :usuariosini
          attr_accessor :usuariosini

          campofecha_localizado :ultimasincldap

          before_update do
            if !nombre.nil?  && !cn.nil? && 
              !ultimasincldap.nil?  && 
              !(no_modificar_ldap && no_modificar_ldap != '0')
              i = changed & ['cn', 'nombre', 'gidNumber']
              usuariosd = usuario.map(&:id).sort 
              if i != [] || usuariosd != usuariosini
                prob = ''
                cambios = changed
                if usuario.map(&:id).sort != usuariosini
                  cambios << "usuarios"
                end
                if !self.valid?
                  m = 'Cambio no es válido. ' +
                    'Saltando actualización en LDAP y base de datos'
                  puts "* Error: #{m}"
                  self.errors.add(:base, m)
                  raise raise ActiveRecord::Rollback
                  return false
                end 
                unless ldap_actualiza_grupo(
                  cnini, self, cambios, prob)
                  m = 'No pudo actualizar grupo en directorio LDAP:' +
                    prob + '. Saltando actualización en base de datos'
                  puts "* Error: #{m}"
                  self.errors.add(:base, m)
                  raise raise ActiveRecord::Rollback
                  return false
                end
              end
            end
          end

          validates :cn, uniqueness: true, 
            unless: Proc.new { |g| g.cn.nil? || g.cn == '' }
          'cn.nil?'

        end # included

      end
    end
  end
end



