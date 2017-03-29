class AgregaFechaSinc < ActiveRecord::Migration[5.0]
  def change
    add_column :usuario, :ultimasincldap, :date
  end
end
