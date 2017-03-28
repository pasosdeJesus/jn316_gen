# encoding: UTF-8

require 'jn316_gen/concerns/models/usuario.rb'

module Jn316Gen
  class Usuario < ActiveRecord::Base

    include Jn316Gen::Concerns::Models::Usuario

  end
end
