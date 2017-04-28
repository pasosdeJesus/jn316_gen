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
            @usuario.no_modificar_ldap = 
              request.params[:usuario][:no_modificar_ldap] == '1'
            @usuario.clave_ldap = usuario_params[:encrypted_password]
            prob = ''
            unless @usuario.no_modificar_ldap
              unless ldap_crea_usuario(
                @usuario, @usuario.clave_ldap, nil, prob)
                @usuario.errors.add(
                  :base, 'No pudo crear usuario en directorio LDAP:' +
                  prob + '. Saltando creación en base de datos')
                  render 'sip/usuarios/new', layout: 'application' 
                return
              end
              @usuario.ultimasincldap = Date.today
            end
            create_gen(@usuario)
          end


          def edit
            authorize! :manage, ::Usuario
            render 'sip/usuarios/edit', layout: '/application'
          end

          # PATCH/PUT /usuarios/1
          # PATCH/PUT /usuarios/1.json
          def update
            authorize! :manage, ::Usuario
            @usuario.no_modificar_ldap = 
              request.params[:usuario][:no_modificar_ldap] == '1'
            @usuario.clave_ldap = usuario_params[:encrypted_password]
            @usuario.nusuarioini = @usuario.nusuario
            @usuario.gruposini = Sip::GrupoUsuario.where(
              usuario_id: @usuario.id).map(&:sip_grupo_id).sort
            if (params[:usuario][:fechadeshabilitacion].nil? &&
                !params[:usuario][:encrypted_password].nil? &&
                params[:usuario][:encrypted_password] != "")
              params[:usuario][:encrypted_password] = BCrypt::Password.create(
                params[:usuario][:encrypted_password],
                {:cost => Rails.application.config.devise.stretches})
            elsif !params[:usuario][:fechadeshabilitacion].nil?
              @usuario.clave = params[:usuario][:encrypted_password] = ''
            else
              params[:usuario].delete(:encrypted_password)
            end
            respond_to do |format|
              if @usuario.update(usuario_params)
                format.html { redirect_to @usuario, notice: 'Usuario actualizado con éxito.' }
                format.json { head :no_content }
              else
                format.html { render action: 'edit', layout: '/application' }
                format.json { render json: @usuario.errors, status: :unprocessable_entity }
              end
            end
          end


          # Elimina un usuario de base (pero no de LDAP)
          def destroy
            authorize! :manage, ::Usuario
            @usuario.destroy
            respond_to do |format|
              format.html { redirect_to main_app.usuarios_url }
              format.json { head :no_content }
            end
          end

          # Elimina un usuario del LDAP y de la base
          def destroyldap
            authorize! :manage, ::Usuario
            set_usuario
            prob = ""
            if ldap_elimina_usuario(@usuario.nusuario, prob)
              destroy
              #@usuario.destroy
              #respond_to do |format|
             #   format.html { redirect_to main_app.usuarios_url }
             #   format.json { head :no_content }
             # end
            else
              flash[:error] = 'No pudo eliminar usuario de LDAP: ' + prob +
                '.  Saltando eliminado de base de datos'
              redirect_to main_app.usuario_url(@usuario), layout: 'application'
            end
          end


          def sincronizarug
            authorize! :manage, ::Usuario

            @uactualizados = []
            @udeshabilitados = []
            @uprob = ""
            vu = ldap_sincroniza_usuarios(@uprob)
            if vu
              @uactualizados = vu[0]
              @udeshabilitados = vu[1]
            end

            @gprob = ""
            @gactualizados = []
            @gdeshabilitados = []
            vg = ldap_sincroniza_grupos(@gprob)
            if vg
              @gactualizados = vg[0]
              @gdeshabilitados = vg[1]
            end

            render 'jn316_gen/usuarios/sincronizarug', layout: '/application'
          end


          def usuario_params
            p = params.require(:usuario).permit(
              :id, :nusuario, :password, 
              :nombres, :apellidos, :descripcion, :oficina_id,
              :uidNumber,
              :rol, :idioma, :email, :encrypted_password, 
              :fechacreacion_localizada, :fechadeshabilitacion_localizada, 
              :reset_password_token, 
              :reset_password_sent_at, :remember_created_at, :sign_in_count, 
              :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, 
              :failed_attempts, :unlock_token, :locked_at,
              :last_sign_in_ip, :etiqueta_ids => [],
              :sip_grupo_ids => []
            )
            return p
          end

        end  # included

      end
    end
  end
end
