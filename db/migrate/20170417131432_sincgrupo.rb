class Sincgrupo < ActiveRecord::Migration[5.0]
  def change
    add_column :sip_grupo, :ultimasincldap, :date
  end
end
