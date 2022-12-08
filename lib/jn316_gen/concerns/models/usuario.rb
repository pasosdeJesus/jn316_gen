require 'msip/concerns/models/usuario'

module Jn316Gen
  module Concerns
    module Models
      module Usuario
        extend ActiveSupport::Concern

        included do
          include Msip::Concerns::Models::Usuario
          include Jn316Gen::LdapHelper 

          attr :no_modificar_ldap
          attr_accessor :no_modificar_ldap
          attr :clave_ldap
          attr_accessor :clave_ldap
          attr :nusuarioini
          attr_accessor :nusuarioini
          attr :gruposini
          attr_accessor :gruposini

          campofecha_localizado :ultimasincldap

          before_update do
            if !nusuarioini.nil?  && 
              !ultimasincldap.nil?  && 
              !(no_modificar_ldap && no_modificar_ldap != '0')
              i = changed & ['apellidos', 'email', 'encrypted_password', 
                             'fechadeshabilitacion', 
                             'nombres', 'nusuario', 'uidNumber']
              gruposd = grupo_ids.sort 
              if i != [] || gruposd != gruposini
                prob = ''
                cambios = changed
                if gruposd != gruposini
                  cambios << "grupos"
                end
                if !self.valid?
                  m = 'Cambio no es válido. ' +
                    'Saltando actualización en LDAP y base de datos'
                  puts "* Error: #{m}"
                  self.errors.add(:base, m)
                  raise raise ActiveRecord::Rollback
                  return false
                end 
                unless ldap_actualiza_usuario(
                  nusuarioini, self, clave_ldap, cambios, prob)
                  m = 'No pudo actualizar usuario en directorio LDAP:' +
                    prob + '. Saltando actualización en base de datos'
                  puts "* Error: #{m}"
                  self.errors.add(:base, m)
                  raise raise ActiveRecord::Rollback
                  return false
                end
              end
            end
          end

          belongs_to :oficina, class_name: 'Msip::Oficina',
            foreign_key: "oficina_id", validate: true, optional: true

          validates_format_of :nusuario, 
            with: /\A[a-zA-Z_0-9]+\z/

          validates_length_of :nombres, maximum: 50
          validates_length_of :apellidos, maximum: 50

          def presenta_nombre
            r = self.nusuario
            r += ' - ' + self.nombres if self.nombres
            r += ' ' + self.apellidos if self.apellidos
            r 
          end


          scope :filtro_nombres, lambda { |n|
              where("unaccent(nombres) ILIKE '%' || unaccent(?) || '%'", n)
          }

          scope :filtro_apellidos, lambda { |n|
              where("unaccent(apellidos) ILIKE '%' || unaccent(?) || '%'", n)
          }

        end

      end
    end
  end
end

