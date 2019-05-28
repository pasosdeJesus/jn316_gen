# encoding: UTF-8

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'jn316_gen'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'America/Bogota'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :es

    config.active_record.schema_format = :sql

    config.x.formato_fecha = 'yyyy-mm-dd'

    config.x.jn316_basegente = "ou=gente,dc=miong,dc=org,dc=co"
    config.x.jn316_basegrupos = "ou=grupos,dc=miong,dc=org,dc=co"
    config.x.jn316_admin = "cn=admin,dc=miong,dc=org,dc=co"
    config.x.jn316_servidor = "miserv.miong.org.co"
    config.x.jn316_puerto = 389
    config.x.jn316_gidgenerico = 500
#    config.x.jn316_opcon = {
#      encryption: {
#        method: :start_tls,
#        tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
#      }
#    }

  end
end
