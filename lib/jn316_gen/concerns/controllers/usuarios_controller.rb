require 'msip/concerns/controllers/usuarios_controller'

module Jn316Gen
  module Concerns
    module Controllers
      module UsuariosController

        extend ActiveSupport::Concern

        included do
          include Msip::Concerns::Controllers::UsuariosController
          include Jn316Gen::LdapHelper

          def atributos_index
            [ "id",
              "nusuario",
              "nombres",
              "apellidos",
              "rol",
              "email",
              "created_at_localizada"
            ]
          end

          def atributos_form
            r = [
              "nusuario",
              "nombres",
              "apellidos",
              "descripcion",
              "rol",
              "email",
            ]
            if can?(:manage, Msip::Grupo)
              r += ["msip_grupo"]
            end
            r += [
              "idioma",
              "encrypted_password",
              "ultimasincldap_localizada",
              "no_modificar_ldap",
              "uidNumber",
              "fechacreacion_localizada",
              "fechadeshabilitacion_localizada",
              "failed_attempts",
              "unlock_token",
              "locked_at"
            ]
          end

          def medio_create(usuario)
          end

          def create
            authorize! :edit, ::Usuario
            if !usuario_params[:encrypted_password] ||
                usuario_params[:encrypted_password] == ''
              params['usuario']['encrypted_password'] = (0...50).map {
                ('a'..'z').to_a[rand(26)]
              }.join
            end
            @registro = @usuario = ::Usuario.new(usuario_params)
            @usuario.no_modificar_ldap =
              request.params[:usuario][:no_modificar_ldap] == '1'
            @usuario.clave_ldap = usuario_params[:encrypted_password]
            prob = ''
            medio_create(@usuario)
            if !@usuario.valid?
              mens = 'Usuario no valido'
              @usuario.errors.add( :base, mens)
              render action: "new", layout: 'application'
              #redirect_back fallback_location: root_path,
              return
            end
            @usuario.encrypted_password = BCrypt::Password.create(
              @usuario.clave_ldap,
              {:cost => Rails.application.config.devise.stretches}
            )
            unless @usuario.no_modificar_ldap
              unless ldap_crea_usuario(
                @usuario, @usuario.clave_ldap, nil, prob)
                mens = 'No pudo crear usuario en directorio LDAP:' +
                  prob + '. Saltando creación en base de datos'
                @usuario.errors.add( :base, mens)
                render action: "new", layout: 'application'
                return
              end
              @usuario.ultimasincldap = Date.today
            end
            create_gen(@usuario)
          end


          def edit
            authorize! :edit, ::Usuario
            render layout: 'application'
          end

          def medio_update(usuario)
          end

          # PATCH/PUT /usuarios/1
          # PATCH/PUT /usuarios/1.json
          def update
            authorize! :edit, ::Usuario
            @usuario.no_modificar_ldap =
              request.params[:usuario][:no_modificar_ldap] == '1'
            @usuario.clave_ldap = usuario_params[:encrypted_password]
            @usuario.nusuarioini = @usuario.nusuario
            @usuario.gruposini = Msip::GrupoUsuario.where(
              usuario_id: @usuario.id).map(&:grupo_id).sort
            if (params[:usuario][:fechadeshabilitacion].nil? &&
                !params[:usuario][:encrypted_password].nil? &&
                params[:usuario][:encrypted_password] != "")
              params[:usuario][:encrypted_password] = BCrypt::Password.create(
                params[:usuario][:encrypted_password],
                {:cost => Rails.application.config.devise.stretches})
            elsif !params[:usuario][:fechadeshabilitacion].nil?
              @usuario.clave_ldap = @usuario.clave =
                params[:usuario][:encrypted_password] = ''
            else
              params[:usuario].delete(:encrypted_password)
            end
            medio_update(@usuario)
            @registro = @usuario
            respond_to do |format|
              if @usuario.update(usuario_params)
                format.html { redirect_to @usuario, notice: 'Usuario actualizado con éxito.' }
                format.json { head :no_content }
              else
                format.html {
                  if !@usuario.valid?
                    #redirect_back fallback_location: root_path
                    render action: "edit", layout: 'application'
                  else
                    redirect_back fallback_location: root_path,
                      flash: {error: "No pudo actualizar usuario"}
                  end
                }
                format.json { render json: @usuario.errors, status: :unprocessable_entity }
              end
            end
          end


          # Elimina un usuario del LDAP y de la base
          def destroyldap
            authorize! :manage, ::Usuario
            set_usuario
            prob = ""
            if ldap_elimina_usuario(@usuario.nusuario, prob)
              @usuario.update_attribute('uidNumber', nil)
              @registro = @usuario
              @registro.destroy
            else
              flash[:error] = 'No pudo eliminar usuario de LDAP: ' + prob +
                '.  Saltando eliminación de base de datos'
              redirect_to main_app.usuario_url(@usuario), layout: 'application'
              return
            end
            respond_to do |format|
              format.html { redirect_to main_app.usuarios_path,
                            notice: 'Usuario eliminado con éxito.' }
              format.json { head :no_content }
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


          private

          def usuario_params
            p = params.require(:usuario).permit(
              :id, :nusuario, :password,
              :nombres, :apellidos, :descripcion,
              :rol, :idioma, :email, :encrypted_password,
              :no_modificar_ldap, :uidNumber,
              :fechacreacion_localizada, :fechadeshabilitacion_localizada,
              :reset_password_token,
              :reset_password_sent_at, :remember_created_at, :sign_in_count,
              :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip,
              :failed_attempts, :unlock_token, :locked_at,
              :last_sign_in_ip, :etiqueta_ids => [],
              :grupo_ids => []
            )
            return p
          end


        end  # included

      end
    end
  end
end
