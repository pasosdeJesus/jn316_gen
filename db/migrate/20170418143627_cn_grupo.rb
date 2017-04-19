class CnGrupo < ActiveRecord::Migration[5.0]
  def change
    add_column :sip_grupo, :cn, :string, limit: 255
  end
end
