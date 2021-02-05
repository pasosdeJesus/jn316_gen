Dummy::Application.config.relative_url_root = ENV.fetch(
  'RUTA_RELATIVA', '/jn316')
Dummy::Application.config.assets.prefix = ENV.fetch(
  'RUTA_RELATIVA', '/jn316') + '/assets'
