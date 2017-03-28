# encoding: UTF-8

require 'sip/concerns/models/usuario'

module Jn316Gen
  module Concerns
    module Models
      module Usuario
        extend ActiveSupport::Concern
        include Sip::Concerns::Models::Usuario

        included do
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
        end

      end
    end
  end
end

