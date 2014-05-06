require 'digest/sha2'
require 'securerandom'

class PoolOfEntropy::CorePRNG

  def initialize size = 1, initial_state = SecureRandom.random_bytes( 64 * size ), mix_block_id = 0
    @size = Integer( size )
    if @size < 1 || @size > 64
      raise ArgumentError, "Size of pool must be in Range 1..64, got #{@size}"
    end
    unless initial_state.is_a? String
      raise TypeError, "Initial state must be a String, got #{initial_state.inspect}"
    end
    @state = initial_state.clone
    @state.force_encoding( 'BINARY' )

    if @state.size != size * 64
      raise ArgumentError, "Initial state wrong - expected #{size * 64} bytes, got #{@state.size} bytes"
    end

    @mix_block_id = Integer( mix_block_id ) % @size
  end

  attr_reader :size

  attr_reader :mix_block_id

  def state
    @state.clone
  end

  def clone
    PoolOfEntropy::CorePRNG.new( self.size, self.state, self.mix_block_id )
  end

  # Mixes supplied data into the curent state
  # @param [String] data adjustments
  # @return [nil]
  def update data
    new_block = Digest::SHA512.digest( @state + data.to_s )
    @state[64*@mix_block_id,64] = new_block
    @mix_block_id = (@mix_block_id + 1) % @size
    nil
  end

  # Statistically flat distribution of 128 bits (16 bytes)
  # @param [Array<String>] adjustments
  # @return [String] 16 characters in ASCII-8BIT encoding
  def read_bytes *adjustments
    raw_digest = Digest::SHA512.digest( @state )
    self.update( raw_digest )
    adjustments.compact.each do |adjust|
      raw_digest = Digest::SHA512.digest( raw_digest + adjust )
    end
    fold_bits( fold_bits( raw_digest ) )
  end

  # Statistically flat distribution from range 0...2**128
  # @param [Array<String>] adjustments
  # @return [Fixnum,Bignum] between 0 and 0xffffffffffffffffffffffffffffffff
  def read_bignum *adjustments
    nums = read_bytes( *adjustments ).unpack('Q>*')
    nums.inject(0) { |sum,v| (sum << 64) + v }
  end

  # Statistically flat distribution from interval 0.0...1.0, with 53-bit precision
  # @param [Array<String>] adjustments
  # @return [Float] between 0.0 and 0.9999999999999999
  def read_float *adjustments
    num = read_bytes( *adjustments ).unpack('Q>*').first << 11
    num.to_f / 2 ** 53
  end

  private

  # NB only works for messages which are multiples of 8 bytes long
  def fold_bits msg
    l = msg.length/2
    numeric_return = msg[0,l].unpack('L>*').zip( msg[l,l].unpack('L>*') ).map do |x,y|
      x ^ y
    end
    numeric_return.pack('L>*')
  end

end
