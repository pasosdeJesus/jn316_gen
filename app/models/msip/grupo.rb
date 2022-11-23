require 'jn316_gen/concerns/models/grupo'

module Msip
  class Grupo < ActiveRecord::Base
    include Jn316Gen::Concerns::Models::Grupo
  end
end
