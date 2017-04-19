# encoding: UTF-8

require 'sip/concerns/models/grupo'

module Jn316Gen
  module Concerns
    module Models
      module Grupo
        extend ActiveSupport::Concern

        include Sip::Basica
        include Sip::Concerns::Models::Grupo

        included do

          validates :cn, uniqueness: true, 
            unless: Proc.new { |g| g.cn.nil? || g.cn == '' }
          'cn.nil?'

        end # included

      end
    end
  end
end



