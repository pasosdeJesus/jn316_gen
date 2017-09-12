# encoding: UTF-8

require 'sip/concerns/models/usuario'

module Jn316Gen
  module Concerns
    module Models
      module Usuario
        extend ActiveSupport::Concern
        #include Sip::Concerns::Models::Usuario
        include Jn316Gen::LdapHelper 

        included do


          attr :no_modificar_ldap
          attr_accessor :no_modificar_ldap
          attr :clave_ldap
          attr_accessor :clave_ldap
          attr :nusuarioini
          attr_accessor :nusuarioini
          attr :gruposini
          attr_accessor :gruposini

          before_update do
            if !nusuarioini.nil?  && # Pasó por controlador
              !ultimasincldap.nil? &&  # Proviene de LDAP
              !no_modificar_ldap && # El usuario sabe del cambio LDAP
              (changed.include?('encrypted_password') || # Campo de LDAP
               changed.include?('nusuario') ||
               changed.include?('email') ||
               changed.include?('nombres') ||
               changed.include?('apellidos') ||
               changed.include?('uidNumber') ||
               sip_grupo_usuario.map(&:sip_grupo_id).sort != gruposini
              ) 
              prob = ''
              cambios = changed
              if sip_grupo_usuario.map(&:sip_grupo_id).sort != gruposini
                cambios << "grupos"
              end
              unless ldap_actualiza_usuario(
                nusuarioini, self, clave_ldap, cambios, prob)
                self.errors.add(
                  :base, 'No pudo actualizar usuario en directorio LDAP:' +
                  prob + '. Saltando actualización en base de datos')
                raise ActiveRecord::Rollback
              end
            end
          end

          belongs_to :oficina, class_name: 'Sip::Oficina',
            foreign_key: "oficina_id", validate: true

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

