require 'jn316_gen/concerns/controllers/grupos_controller'

module Sip
  module Admin
    class GruposController < Msip::Admin::BasicasController
      load_and_authorize_resource  class: Msip::Grupo
      include Jn316Gen::Concerns::Controllers::GruposController
    end
  end
end
