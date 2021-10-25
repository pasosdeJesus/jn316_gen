require 'jn316_gen/concerns/controllers/grupos_controller'

module Sip
  module Admin
    class GruposController < Sip::Admin::BasicasController
      include Jn316Gen::Concerns::Controllers::GruposController
      load_and_authorize_resource  class: Sip::Grupo
    end
  end
end
