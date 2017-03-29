# encoding: UTF-8

require 'jn316_gen/concerns/models/usuario'
require 'sip/concerns/models/usuario'

class Usuario < ActiveRecord::Base
  include Sip::Concerns::Models::Usuario
  include Jn316Gen::Concerns::Models::Usuario

end

