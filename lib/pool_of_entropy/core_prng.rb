require 'digest/sha2'

class PoolOfEntropy::CorePRNG

  Digest::SHA512.hexdigest( 'foo' )

end
