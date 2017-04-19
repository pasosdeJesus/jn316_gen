# encoding: UTF-8

require 'sip/concerns/controllers/usuarios_controller'

module Jn316Gen
  module Concerns
    module Controllers
      module UsuariosController

        extend ActiveSupport::Concern
        include Sip::Concerns::Controllers::UsuariosController
        include Jn316Gen::LdapHelper

        included do

          def create
            authorize! :edit, ::Usuario
            @usuario = ::Usuario.new(usuario_params)
            create_gen(@usuario)
          end

          def usuario_params
            p = params.require(:usuario).permit(
              :id, :nusuario, :password, 
              :nombres, :apellidos, :descripcion, :oficina_id,
              :rol, :idioma, :email, :encrypted_password, 
              :fechacreacion_localizada, :fechadeshabilitacion_localizada, 
              :reset_password_token, 
              :reset_password_sent_at, :remember_created_at, :sign_in_count, 
              :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, 
              :failed_attempts, :unlock_token, :locked_at,
              :last_sign_in_ip, :etiqueta_ids => []
            )
            return p
          end

          def sincronizarug
            authorize! :manage, ::Usuario
            @gprob = ""
            @gactualizados = []
            @gdeshabilitados = []
            vg = ldap_sincroniza_grupos(@gprob)
            if vg
              @gactualizados = vg[0]
              @gdeshabilitados = vg[1]
            end

            @uactualizados = []
            @udeshabilitados = []
            @uprob = ""
            vu = ldap_sincroniza_usuarios(@uprob)
            if vu
              @uactualizados = vu[0]
              @udeshabilitados = vu[1]
            end
            render :sincronizarug, layout: '/application'
          end


        end  # included

      end
    end
  end
end
