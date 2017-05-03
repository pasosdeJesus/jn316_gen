# encoding: utf-8

require 'devise/registrations_controller'

class Jn316Gen::RegistrationsController < ::Devise::RegistrationsController
  include Jn316Gen::LdapHelper

  def update
    if params[:usuario] && params[:usuario][:password] &&
      params[:usuario][:password_confirmation] &&
      params[:usuario][:current_password] &&
      params[:usuario][:password] != '' && 
      params[:usuario][:password_confirmation] == params[:usuario][:password]
      prob = ''
      if ldap_cambia_clave(current_usuario.nusuario, 
                           params[:usuario][:current_password],
                           params[:usuario][:password], prob)
        flash[:notice] = 'Clave cambiada en directorio LDAP'
      else
        flash[:error] = 'No pudo cambiar clave en directorio LDAP: ' + prob
        redirect_to Rails.configuration.relative_url_root
        return
      end
    end
    super
  rescue Exception => exception
    flash[:error] = 'No pudo cambiar clave en directorio LDAP: ' + 
      exception.to_s
    redirect_to Rails.configuration.relative_url_root
  end

end
