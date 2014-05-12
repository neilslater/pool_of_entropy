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

class PoolOfEntropy

  # Creates a new random number source. All parameters are optional.
  # @param [Hash] options
  # @param [String] initial_state Sets contents of state pool (default uses SecureRandom)
  # @param [Integer] mix_block_id
  # @return [PoolOfEntropy]
  def initialize options
    @core_prng = CorePRNG.new( size, initial_state, mix_block_id )
    @next_modifier_queue = []
    @fixed_modifier = nil
  end

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
      next if modifier.nil?
      @next_modifier_queue << Digest::SHA512.digest( modifier.to_s )
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
