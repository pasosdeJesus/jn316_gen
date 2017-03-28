# encoding: UTF-8

require 'jn316_gen/concerns/controllers/usuarios_controller'

module Sip
  class UsuariosController < ApplicationController

    include Jn316Gen::Concerns::Controllers::UsuariosController

  end
end
