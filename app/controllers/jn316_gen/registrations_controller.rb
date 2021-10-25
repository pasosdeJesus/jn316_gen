require 'devise/registrations_controller'

class Jn316Gen::RegistrationsController < ::Devise::RegistrationsController
  include Jn316Gen::LdapHelper

  def after_update_path_for(resource)
    Rails.configuration.relative_url_root
  end

  def update
    if params[:usuario] && params[:usuario][:password] &&
      params[:usuario][:password_confirmation] &&
      params[:usuario][:current_password] &&
      params[:usuario][:password] != '' && 
      params[:usuario][:password_confirmation] == params[:usuario][:password]
      prob = ''
      if current_usuario && !current_usuario.ultimasincldap
        # no está en LDAP se maneja como si no hubiera LDAP
        super
        return
      end
      if ldap_cambia_clave(current_usuario.nusuario, 
          params[:usuario][:current_password],
          params[:usuario][:password], prob)
        flash[:notice] = 'Clave cambiada en directorio LDAP'
        puts "Jn316Gen::RegistrationsController#update si cambio clave en ldap"
        # Para salir super usará after_update_path_for(resource)
        super
        puts "Jn316Gen::RegistrationsController#update paso super"
         #redirect_to Rails.configuration.relative_url_root
        return
      else
        puts "Jn316Gen::RegistrationsController#update no cambió clave en ldap prob=#{prob}"
        flash[:error] = 'No pudo cambiar clave en directorio LDAP: ' + prob
        redirect_to Rails.configuration.relative_url_root
        return
      end
      puts "Jn316Gen::RegistrationsController#update no deberia llegar aqui"
    end
    flash[:error] = 'Claves incorrectas'
    redirect_to request.referrer
    puts "Jn316Gen::RegistrationsController#update no deberia llegar aqui"
    return
  rescue Exception => exception
    flash[:error] = 'No pudo cambiar clave en directorio LDAP: ' + 
      exception.to_s
    puts "Jn316Gen::RegistrationsController#update excepcion #{exception.to_s}"
    redirect_to Rails.configuration.relative_url_root
    return
  end

end
