class CambiaNombreSip < ActiveRecord::Migration[5.0]
  def up
    add_column :usuario, :nombres, :string, limit: 50
    add_column :usuario, :apellidos, :string, limit: 50
    execute <<EOF
    ALTER TABLE usuario ALTER COLUMN apellidos TYPE VARCHAR(50) COLLATE es_co_utf_8;
    ALTER TABLE usuario ALTER COLUMN nombres TYPE VARCHAR(50) COLLATE es_co_utf_8;
    UPDATE usuario SET nombres=(SELECT CASE 
        WHEN array_length(a, 1) = 0 THEN 'N'
        WHEN array_length(a, 1) <= 2 THEN a[1]
        ELSE TRIM((a[1] || ' ' || a[2]))
      END), apellidos=(SELECT CASE
        WHEN array_length(a, 1) = 0 THEN 'N'
        WHEN array_length(a, 1) = 1 THEN ''
        WHEN array_length(a, 1) = 2 THEN a[2]
        ELSE TRIM(array_to_string(a[3:array_length(a, 1)],' ')) 
      END) 
      FROM (SELECT regexp_split_to_array(
                    TRIM(regexp_replace(nombre, '  *', ' ', 'g')), ' ') AS a 
        FROM usuario) AS s ;
EOF
    remove_column :usuario, :nombre
  end

  def down
    add_column :usuario, :nombre, :string, limit: 50
    execute <<EOF
    ALTER TABLE usuario ALTER COLUMN nombre TYPE VARCHAR(50) COLLATE es_co_utf_8;
EOF
    execute <<EOF
    UPDATE usuario SET nombre=TRIM(TRIM(nombres) || ' ' || TRIM(apellidos));
EOF
    remove_column :usuario, :nombres, :string, limit: 50
    remove_column :usuario, :apellidos, :string, limit: 50
  end

end
