# encoding: UTF-8

Jn316Gen::Engine.routes.draw do

  get '/sincronizarug' => 'usuarios#sincronizarug', as: 'sincronizarug'

  delete '/usuarioldap/:id' => 'usuarios#destroyldap', as: 'usuarioldap'

  namespace :admin do
    ab = ::Ability.new
    ab.tablasbasicas.each do |t|
      if (t[0] == "Jn316Gen") 
        c = t[1].pluralize
        resources c.to_sym, 
          path_names: { new: 'nueva', edit: 'edita' }
      end
    end
  end


end
