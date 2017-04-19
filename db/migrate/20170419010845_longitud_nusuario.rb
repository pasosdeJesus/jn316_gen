class LongitudNusuario < ActiveRecord::Migration[5.0]
  def up
    change_column :usuario, :nusuario, :string, limit: 63
  end
  def down
    change_column :usuario, :nusuario, :string, limit: 15
  end
end
