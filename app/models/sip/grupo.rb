require 'jn316_gen/concerns/models/grupo'

module Sip
  class Grupo < ActiveRecord::Base
    include Jn316Gen::Concerns::Models::Grupo
  end
end
