module Jn316Gen
  class Ability  < Sip::Ability

    BASICAS_PROPIAS = []

    def tablasbasicas 
      Sip::Ability::BASICAS_PROPIAS + 
        Jn316Gen::Ability::BASICAS_PROPIAS - [
          ['Sip', 'pais'],
          ['Sip', 'departamento'],
          ['Sip', 'municipio'],
          ['Sip', 'clase'],
          ['Sip', 'fuenteprensa'],
          ['Sip', 'oficina'],
          ['Sip', 'tclase'],
          ['Sip', 'tdocumento'],
          ['Sip', 'trelacion'],
          ['Sip', 'tsitio']
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

    # Autorizacion con CanCanCan
    def initialize_jn316_gen(usuario = nil)
      initialize_sip(usuario)
    end

  end

end
