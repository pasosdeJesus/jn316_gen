class UsuarioUidnumber < ActiveRecord::Migration[5.0]
  def change
    add_column :sip_grupo, :gidNumber, :integer
    add_column :usuario, :uidNumber, :integer
  end
end
