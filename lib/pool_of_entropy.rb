# frozen_string_literal: true

require 'pool_of_entropy/version'
require 'pool_of_entropy/core_prng'

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
#  prng = PoolOfEntropy.new :size => 4, :blank => true, :seeds = [ 'My Name' ]
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
  def initialize(options = {})
    raise TypeError, "Expecting an options hash, got #{options.inspect}" unless options.is_a? Hash

    size = size_from_options(options)

    initial_state = state_from_options(options, size)

    @core_prng = CorePRNG.new(size, initial_state)

    seed_from_options(options)

    @next_modifier_queue = []
    @fixed_modifier = nil
  end

  # Cloning creates a deep copy with identical PRNG state and modifiers
  # @return [PoolOfEntropy]
  def clone
    copy = super
    copy.instance_variable_set(:@core_prng, @core_prng.clone)
    copy.instance_variable_set(:@fixed_modifier, @fixed_modifier.clone) if @fixed_modifier
    copy.instance_variable_set(:@next_modifier_queue, @next_modifier_queue.map(&:clone))
    copy
  end

  # Same functionality as Kernel#rand or Random#rand, but using
  # current pool state to generate number, and including zero, one or
  # two modifiers that are in effect.
  # @param [Integer,Range] max if 0 then will return a Float
  # @return [Float,Fixnum,Bignum] type depends on value of max
  def rand(max = 0)
    if max.is_a? Range
      bottom = max.first
      top = max.last
      return(nil) if top < bottom

      bottom + generate_integer((top - bottom + 1))
    else
      effective_max = max.to_i.abs
      if effective_max.zero?
        generate_float
      else
        generate_integer(effective_max)
      end
    end
  end

  # Stores the hash of one or more string modifiers that will be used
  # just once each to modify results of calls to #rand. Temporary "next"
  # modifiers and the "all" modifier are combined if both are in effect.
  # Modifiers change the end result of a call to #rand(), but do *not*
  # affect the internal state of the data pool used by the generator.
  # @param [Array<String>] modifiers
  # @return [PoolOfEntropy] self
  def modify_next(*modifiers)
    modifiers.each do |modifier|
      @next_modifier_queue << if modifier.nil?
                                nil
                              else
                                Digest::SHA512.digest(modifier.to_s)
                              end
    end
    self
  end

  # Stores the hash of a single string modifier that will be used
  # to modify results of calls to #rand, until this modifier is
  # reset. Temporary "next" modifiers and the "all" modifier are
  # combined if both are in effect.  Modifiers change the end result
  # of a call to #rand(), but do *not*
  # affect the internal state of the data pool used by the generator.
  # @param [String,nil] modifier
  # @return [PoolOfEntropy] self
  def modify_all(modifier)
    @fixed_modifier = modifier
    @fixed_modifier = Digest::SHA512.digest(@fixed_modifier.to_s) unless @fixed_modifier.nil?
    self
  end

  # Changes the internal state of the data pool used by the generator,
  # by "mixing in" user-supplied data. This affects all future values
  # from #rand() and cannot be undone.
  # @param [String] data
  # @return [PoolOfEntropy] self
  def add_to_pool(data)
    @core_prng.update(data)
    self
  end

  # Empties the "next" modifier queue and clears the "all" modifier.
  # @return [PoolOfEntropy] self
  def clear_all_modifiers
    @next_modifier_queue = []
    @fixed_modifier = nil
    self
  end

  private

  def use_adjustments
    [@fixed_modifier, @next_modifier_queue.shift].compact
  end

  def generate_float
    @core_prng.read_float(*use_adjustments)
  end

  def generate_integer(max)
    @core_prng.generate_integer(max, *use_adjustments)
  end

  def state_from_options(options, size)
    if options[:blank]
      "\x0" * size * 64
    else
      SecureRandom.random_bytes(size * 64)
    end
  end

  def size_from_options(options)
    size = 1
    if options[:size]
      size = Integer(options[:size])
      raise ArgumentError, "Size of pool must be in Range 1..256, got #{size}" if size < 1 || size > 256
    end
    size
  end

  def seed_from_options(options)
    if options[:seeds]
      unless options[:seeds].is_a? Array
        raise TypeError, "Expected value for :seeds to be an Array, got #{options[:seeds].inspect}"
      end

      options[:seeds].each do |seed|
        add_to_pool(seed)
      end
    end
  end
end
