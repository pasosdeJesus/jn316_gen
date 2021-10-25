conexion = ActiveRecord::Base.connection();

# De motores
Sip::carga_semillas_sql(conexion, 'sip', :datos)
motor = ['jn316_gen', '../..']
motor.each do |m|
    Sip::carga_semillas_sql(conexion, m, :cambios)
    Sip::carga_semillas_sql(conexion, m, :datos)
end


# Usuario para primer ingreso sal7711, sal7711
conexion.execute("INSERT INTO public.usuario 
	(nusuario, email, encrypted_password, password, 
  fechacreacion, created_at, updated_at, rol) 
	VALUES ('jn316', 'jn316@localhost', 
	'$2a$10$cuVDpUSmX9LZUQPJZgwrL.8xV4vtA15EpTMSGcPSzdHsoDzFohh1C',
	'', '2014-08-14', '2014-08-14', '2014-08-14', 1);")

