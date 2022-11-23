conexion = ActiveRecord::Base.connection();

# De motores
Msip::carga_semillas_sql(conexion, 'msip', :datos)
motor = ['jn316_gen', '../..']
motor.each do |m|
    Msip::carga_semillas_sql(conexion, m, :cambios)
    Msip::carga_semillas_sql(conexion, m, :datos)
end


# Usuario para primer ingreso jn316, jn316
conexion.execute("INSERT INTO public.usuario 
	(nusuario, email, encrypted_password, password, 
  fechacreacion, created_at, updated_at, rol) 
	VALUES ('jn316', 'jn316@localhost', 
	'$2a$10$cuVDpUSmX9LZUQPJZgwrL.8xV4vtA15EpTMSGcPSzdHsoDzFohh1C',
	'', '2014-08-14', '2014-08-14', '2014-08-14', 1);")

