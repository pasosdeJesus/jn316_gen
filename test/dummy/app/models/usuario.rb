require 'jn316_gen/concerns/models/usuario'
require 'msip/concerns/models/usuario'

class Usuario < ActiveRecord::Base
  # Si extendemos Jn316Gen::Usuario al autenticar Devise falla diciendo
  # que no pudo hace mapping
  include Msip::Concerns::Models::Usuario
  include Jn316Gen::Concerns::Models::Usuario

end

