require "pool_of_entropy/version"
require "pool_of_entropy/core_prng"

# This class models a random number generator that can mix user input into
# the generation mechanism in a few different ways.
#
# An object of the class has an internal state for generating numbers, plus
# holds processed user data for "mixing" into the output.
#
# @example Using default internal state, initialised using SecureRandom.random_bytes
#  prng = PoolOfEntropy.new
#  prng.rand( 20 )
#  # E.g. => 12
#
# @example A customised PRNG, seeded with some user data, using webcam for "true" randomness
#  prng = PoolOfEntropy.new :size => 4, :blank => true, :seeds = ['Hello!',picture_bytes]
#  loop do
#    prng.add_to_pool( Webcam.image.bytes ) # Imagined Webcam interface
#    prng.rand( 20 )
#    # E.g. => 12
#    sleep 5
#  end
#

class PoolOfEntropy

  # Creates a new random number source. All parameters are optional.
  # @param [Hash] options
  # @option options [Integer] :size, number of 512-bit (64 byte) blocks to use as internal state, defaults to 1
  # @option options [Boolean] :blank, if true then initial state is all zeroes, otherwise use SecureRandom
  # @option options [Array<String>] :seeds, if provided these are sent to #add_to_pool during initialize
  # @return [PoolOfEntropy]
  def initialize options = {}
    unless options.is_a? Hash
      raise TypeError, "Expecting an options hash, got #{options.inspect}"
    end

    size = 1
    if options[:size]
      size = Integer( size )
      if size < 1 || size > 256
        raise ArgumentError, "Size of pool must be in Range 1..256, got #{size}"
      end
    end

    initial_state = if options[:blank]
      "\x0" * size * 64
    else
      SecureRandom.random_bytes( size * 64 )
    end

    @core_prng = CorePRNG.new( size, initial_state )

    if options[:seeds]
      unless options[:seeds].is_a? Array
        raise TypeError, "Expected value for :seeds to be an Array, got #{options[:seeds].inspect}"
      end
      options[:seeds].each do |seed|
        add_to_pool( seed )
      end
    end

    @next_modifier_queue = []
    @fixed_modifier = nil
  end

  # Cloning creates a deep copy with identical PRNG state and modifiers
  # @return [PoolOfEntropy]
  def clone
    Marshal.load( Marshal.dump( self ) )
  end

  # Same functionality as Kernel#rand or Random#rand, but using
  # current pool state to generate number, and including zero, one or
  # two modifiers that are in effect.
  # @param [Integer,Range] max use 0 to return
  # @return [Fixnum,Bignum,Float] type depends on value of max
  def rand max = 0
    if max.is_a? Range
      bottom, top = max.minmax
      return nil if top < bottom
      return bottom + generate_integer( ( top - bottom + 1 ) )
    else
      effective_max = max.to_i.abs
      if effective_max == 0
        return generate_float
      else
        return generate_integer( effective_max )
      end
    end
  end

  def modify_next *modifiers
    modifiers.each do |modifier|
      if modifier.nil?
        @next_modifier_queue << nil
      else
        @next_modifier_queue << Digest::SHA512.digest( modifier.to_s )
      end
    end
    self
  end

  def modify_all modifier
    @fixed_modifier = modifier
    unless @fixed_modifier.nil?
      @fixed_modifier = Digest::SHA512.digest( @fixed_modifier.to_s )
    end
    self
  end

  def add_to_pool data
    @core_prng.update( data )
    self
  end

  def clear_all_modifiers
    @next_modifier_queue = []
    @fixed_modifier = nil
    self
  end

  private

  def use_adjustments
    [ @fixed_modifier, @next_modifier_queue.shift ].compact
  end

  def generate_float
    @core_prng.read_float( *use_adjustments )
  end

  def generate_integer max
    @core_prng.generate_integer( max, *use_adjustments )
  end

end
