require 'msip/concerns/controllers/grupos_controller'

module Jn316Gen
  module Concerns
    module Controllers
      module GruposController

        extend ActiveSupport::Concern

        included do
          include Msip::Concerns::Controllers::GruposController
          include Jn316Gen::LdapHelper

          def atributos_index
            [ "id", "nombre", "cn", "gidNumber", "ultimasincldap_localizada" ] +
              [ :usuario_ids => [] ] +
              ["observaciones", "fechacreacion", "fechadeshabilitacion" ]
          end
 
          def atributos_form
            [ "nombre", "cn", "gidNumber", "ultimasincldap_localizada" ] +
              [ :usuario_ids => [] ] +
              ["observaciones", 
               "no_modificar_ldap",
               "fechacreacion_localizada", "fechadeshabilitacion_localizada" ]
          end

          def create
            authorize! :edit, Msip::Grupo
            @registro = @grupo = Msip::Grupo.new(grupo_params)
            @grupo.no_modificar_ldap = request.params[:grupo][:no_modificar_ldap] == '1'
            prob = ''
            if !@grupo.valid?
              mens = 'Grupo no valido'
              @grupo.errors.add(:base, mens)
              render action: 'new', layout: 'application'
              return
            end
            unless @grupo.no_modificar_ldap
              unless ldap_crea_grupo(@grupo, prob)
                mens = 'No pudo crear grupo en directorio LDAP: ' +
                  prob + '. Saltando creación en base de datos'
                @grupo.errors.add(:base, mens)
                render action: 'new', layout: 'application'
                return
              end
              @grupo.ultimasincldap = Date.today
            end
            create_gen(@grupo)
          end

          def edit
            authorize! :edit, Msip::Grupo
            render layout: '/application'
          end

          # PATCH/PUT /grupos/1
          # PATCH/PUT /grupos/1.json
          def update
            authorize! :edit, Msip::Grupo
            @grupo.no_modificar_ldap = 
              request.params[:grupo][:no_modificar_ldap] == '1'
            @grupo.cnini = @grupo.cn
            @grupo.usuariosini = @grupo.usuario.map(&:id).sort
            @registro = @grupo
            respond_to do |format|
              if @grupo.update(grupo_params)
                format.html { redirect_to modelo_path(@grupo), 
                              notice: 'Grupo actualizado con éxito.' }
                format.json { head :no_content }
              else
                format.html {
                  if !@grupo.valid?
                    render action: "edit", layout: 'application' 
                  else
                    redirect_back fallback_location: root_path,
                      flash: {error: "No pudo actualizar grupo"}
                  end
                }
                format.json { 
                  render json: @grupo.errors, status: :unprocessable_entity 
                }
              end
            end
          end


          # Elimina un grupo del LDAP y de la base
          def destroyldap
            authorize! :manage, Msip::Grupo
            set_grupo
            prob = ""
            if ldap_elimina_grupo(@grupo.cn, prob)
              @grupo.update_attribute('gidNumber', nil)
              @registro = @grupo
              @registro.destroy
            else
              flash[:error] = 'No pudo eliminar grupo de LDAP: ' + prob +
                '.  Saltando eliminación de base de datos'
              redirect_to modelos_path(@grupo), layout: 'application'
              return
            end
            respond_to do |format|
              format.html { redirect_to modelos_path(@grupo), 
                            notice: 'Grupo eliminado con éxito.' }
              format.json { head :no_content }
            end
          end

          private

          def grupo_params
            params.require(:grupo).permit(*atributos_form)
          end

        end  # included

      end
    end
  end
end
