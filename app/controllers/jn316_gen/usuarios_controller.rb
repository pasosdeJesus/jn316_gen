require 'jn316_gen/concerns/controllers/usuarios_controller'

module Jn316Gen
  class UsuariosController < Sip::ModelosController

    include Jn316Gen::Concerns::Controllers::UsuariosController

  end
end
