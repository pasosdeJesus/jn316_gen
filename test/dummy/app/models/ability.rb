class Ability  < Jn316Gen::Ability

  # Autorizacion con CanCanCan
  def initialize(usuario = nil)
    initialize_jn316_gen(usuario)
  end

end

