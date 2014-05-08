require 'digest/sha2'
require 'securerandom'

# This class implements a random number generator based on SHA-512
#
# An object of the class has internal state that is modified on each call to
# #update or any #read_... method (internally the #read_... methods call #update).
# The #read_... methods generate a pseudo-random number from the current
# state pool using SHA-512 and use it in the return value. It is not feasible to
# determine the internal state from the pseudo-random data received, and not
# possible to manipulate results from the PRNG in a predictable manner without
# knowing the internal state.
#
# @example Using default internal state, initialised using SecureRandom.random_bytes
#  prng = PoolOfEntropy::CorePRNG.new
#  prng.read_bytes
#  # E.g. => "]\x12\x9E\xF5\x17\xF3\xC2\x1A\x15\xDFu]\x95\nd\x12"
#  prng.read_hex
#  # E.g. => "a0e00d2848242ec49e0a15ef411ba647"
#  prng.read_bignum
#  # E.g. => 33857278877368906880463811096418580004
#  prng.read_float
#  # E.g. => 0.6619838265836278
#  prng.generate_integer( 20 )
#  # E.g. => 7
#

class PoolOfEntropy::CorePRNG

  # Creates a new random number source. All parameters are optional.
  # @param [Integer] size Number of 64-byte blocks, between 1 and 256 (16KB)
  # @param [String] initial_state Sets contents of state pool (default uses SecureRandom)
  # @param [Integer] mix_block_id
  # @return [PoolOfEntropy::CorePRNG]
  def initialize size = 1, initial_state = SecureRandom.random_bytes( 64 * Integer(size) ), mix_block_id = 0
    @size = Integer( size )
    if @size < 1 || @size > 256
      raise ArgumentError, "Size of pool must be in Range 1..256, got #{@size}"
    end
    unless initial_state.is_a? String
      raise TypeError, "Initial state must be a String, got #{initial_state.inspect}"
    end
    @state = initial_state.clone
    @state.force_encoding( 'BINARY' )

    if @state.size != size * 64
      raise ArgumentError, "Initial state bad size - expected #{size * 64} bytes, got #{@state.size} bytes"
    end

    @mix_block_id = Integer( mix_block_id ) % @size
  end

  # The number of 64-byte blocks used in the internal state pool.
  # @return [Integer]
  attr_reader :size

  # Identifies the next 64-byte block in the pool that will be altered
  # by a read or update process.
  # @return [Integer]
  attr_reader :mix_block_id

  # A clone of the internal state pool. In combination with #mix_block_id, describes
  # the whole PRNG. If this value is supplied to an end user, then they can easily
  # predict future values of the PRNG.
  # @return [PoolOfEntropy::CorePRNG]
  def state
    @state.clone
  end

  # The clone of a PoolOfEntropy::CorePRNG object includes separate copy of internal state
  # @return [PoolOfEntropy::CorePRNG]
  def clone
    PoolOfEntropy::CorePRNG.new( self.size, self.state, self.mix_block_id )
  end

  # Mixes supplied data into the curent state. This is called
  # internally by #read_... methods as well.
  # @param [String] data Data to be mixed. Note empty string '' and nil are equivalent and *do* change the state.
  # @return [nil]
  def update data
    new_block = Digest::SHA512.digest( @state + data.to_s )
    @state[64*@mix_block_id,64] = new_block
    @mix_block_id = (@mix_block_id + 1) % @size
    nil
  end

  # Statistically flat distribution of 128 bits (16 bytes)
  # @param [Array<String>] adjustments mixed in using SHA-512, so that they affect return value, but not internal state
  # @return [String] 16 characters in ASCII-8BIT encoding
  def read_bytes *adjustments
    raw_digest = Digest::SHA512.digest( @state )
    self.update( raw_digest )
    adjustments.compact.each do |adjust|
      raw_digest = Digest::SHA512.digest( raw_digest + adjust )
    end
    fold_bits( fold_bits( raw_digest ) )
  end

  # Statistically flat distribution of 32 hex digits
  # @param [Array<String>] adjustments mixed in using SHA-512, so that they affect return value, but not internal state
  # @return [String] 32 hex digits
  def read_hex *adjustments
    read_bytes( *adjustments ).unpack('H*').first
  end

  # Statistically flat distribution from range 0...2**128
  # @param [Array<String>] adjustments mixed in using SHA-512, so that they affect return value, but not internal state
  # @return [Bignum,Fixnum] between 0 and 0xffffffffffffffffffffffffffffffff
  def read_bignum *adjustments
    nums = read_bytes( *adjustments ).unpack('Q>*')
    nums.inject(0) { |sum,v| (sum << 64) + v }
  end

  # Statistically flat distribution from interval 0.0...1.0, with 53-bit precision
  # @param [Array<String>] adjustments mixed in using SHA-512, so that they affect return value, but not internal state
  # @return [Float] between 0.0 and 0.9999999999999999
  def read_float *adjustments
    num = read_bytes( *adjustments ).unpack('Q>*').first >> 11
    num.to_f / 2 ** 53
  end

  # Statistically flat distribution from range (0...top).
  # If necessary, it will read more data to ensure absolute fairness. This method
  # can generate an unbiased distribution of Bignums up to roughly half the maximum bit size
  # allowed by Ruby (i.e. much larger than 2**128 generated in a single read)
  # @param [Fixnum,Bignum] top upper bound of distribution, not inclusive
  # @param [Array<String>] adjustments mixed in using SHA-512, so that they affect return value, but not internal state
  # @return [Fixnum,Bignum] between 0 and top-1 inclusive
  def generate_integer top, *adjustments
    power = 1
    sum = 0
    lower_bound = 0
    words = []

    loop do
      words = read_bytes( *adjustments ).unpack('L>*') if words.empty?
      sum = 2**32 * sum + words.shift
      power *= 2**32
      lower_bound = sum * top / power
      upper_bound = ( (sum + 1) * top ) / power
      break if lower_bound == upper_bound
    end

    lower_bound
  end

  private

  # Xors first half of a message with second half. Only works for messages
  # which are multiples of 8 bytes long.
  # @param [String] msg bytes to fold
  # @return [String] folded message, half the length of original
  def fold_bits msg
    l = msg.length/2
    folded_32bits = msg[0,l].unpack('L>*').zip( msg[l,l].unpack('L>*') ).map do |x,y|
      x ^ y
    end
    folded_32bits.pack('L>*')
  end

end
