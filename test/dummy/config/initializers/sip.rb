require 'jn316_gen/version'

Sip.setup do |config|

  config.ruta_anexos = ENV.fetch('SIP_RUTA_ANEXOS', 
                                 "#{Rails.root}/archivos/anexos")
  config.ruta_volcados = ENV.fetch('SIP_RUTA_VOLCADOS',
                                   "#{Rails.root}/archivos/bd")
  # En heroku los anexos son super-temporales
  if !ENV["HEROKU_POSTGRESQL_GREEN_URL"].nil?
    config.ruta_anexos = "#{Rails.root}/tmp/"
  end
  config.titulo = "Jn316Gen #{Jn316Gen::VERSION}"
  config.descripcion = "Motor para manejar directorio LDAP"
  config.codigofuente = "https://github.com/pasosdeJesus/jn316_gen"
  config.urlcontribuyentes = "https://github.com/pasosdeJesus/jn316_gen/graphs/contributors"
  config.urlcreditos = "https://github.com/pasosdeJesus/jn316_gen/blob/master/CREDITOS.md"
  config.agradecimientoDios = "<p>
  Agradecemos a Dios por la salvación 
<blockquote>
<p>
Porque de tal manera amó Dios al mundo,
que ha dado su hijo unigénito, para que todo aquel 
que en Él cree, no se pierda, más tenga vida eterna.
</p>
<p>Juan 3:16</p>
</blockquote>".html_safe
end
