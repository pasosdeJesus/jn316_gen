# encoding: UTF-8
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
          #    ['Sip', 'etiqueta'],
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

	end
end
