module Jn316Gen
  class Ability  < Msip::Ability

    BASICAS_PROPIAS = []

    def tablasbasicas 
      Msip::Ability::BASICAS_PROPIAS + 
        Jn316Gen::Ability::BASICAS_PROPIAS - [
          ['Msip', 'pais'],
          ['Msip', 'departamento'],
          ['Msip', 'municipio'],
          ['Msip', 'clase'],
          ['Msip', 'fuenteprensa'],
          ['Msip', 'oficina'],
          ['Msip', 'tclase'],
          ['Msip', 'tdocumento'],
          ['Msip', 'trelacion'],
          ['Msip', 'tsitio']
        ] 
    end


    BASICAS_ID_NOAUTO = []
    # Hereda basicas_id_noauto de sip

    NOBASICAS_INDSEQID =  []
    # Hereda nobasicas_indice_seq_con_id de sip

    BASICAS_PRIO = []
    # Hereda tablasbasicas_prio de sip

    def acciones_plantillas 
      {}
    end

    # Se definen habilidades con cancancan
    # Util en motores y aplicaciones de prueba
    # En aplicaciones es mejor escribir completo el modelo de autorización
    # para facilitar su análisis
    # @usuario Usuario que hace petición
    def initialize_jn316_gen(usuario = nil)
      initialize_msip(usuario)
    end

  end

end
