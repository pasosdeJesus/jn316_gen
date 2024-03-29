require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
#require "action_cable/engine"
require "rails/test_unit/railtie"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require 'jn316_gen'

module Dummy
  class Application < Rails::Application

    config.load_defaults Rails::VERSION::STRING.to_f

    config.autoload_lib(ignore: %w(assets tasks))

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


    puts "CONFIG_HOSTS="+ENV.fetch('CONFIG_HOSTS', 'defensor.info').to_s
    config.hosts.concat(
      ENV.fetch('CONFIG_HOSTS', 'defensor.info').downcase.split(";"))

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
