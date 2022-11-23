require 'jn316_gen/concerns/controllers/usuarios_controller'

module Jn316Gen
  class UsuariosController < Msip::ModelosController

    # Sin autorización porque se requiere para autenticar
    
    include Jn316Gen::Concerns::Controllers::UsuariosController

  end
end
