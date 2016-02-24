# PoolOfEntropy

This is a copy of the orignal project, used to test integration between Github and Jenkins.

You may prefer to fork from the original. The only differences in this version are tests due to
non-functional Pull Requests.

Testing PR/Jenkins integration #1.

## Installation

Add this line to your application's Gemfile:

    gem 'pool_of_entropy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pool_of_entropy

## Usage

### Create a new generator:

    pool = PoolOfEntropy.new

Or

    pool = PoolOfEntropy.new :size => 24

Or

    pool = PoolOfEntropy.new :size => 24, :blank => true

The :size parameter sets the amount of randomness that the pool
can store, in multiples of 512 bits (or 64 bytes). The default
size of 1 is fastest, and has a good distribution of values
statistically. Larger pool sizes (up to 256) will calculate a
little slower, but can be used to buffer more entropy from
the #add_to_pool method.

Setting :blank to true starts the pool with the entire pool
zero, so that repeatedly using the generator in exactly the
same way will return the same values.

### Get a random number.

Not feeding the generator with any customisation
means it is completely deterministic based on current internal state. The
analogy here might be "trusting to Fate":

    pool.rand( 20 )

### Influence the next random number (but not any others).

This is analogous to
shaking or throwing dice in a certain way. Only the next result from rand()
is affected:

    pool.modify_next( 'Shake the die.' )
    pool.rand( 20 )

    # Also
    pool.modify_next( 'Shake the die.' ).rand( 20 )

    # This next result will not be influenced,
    # we re-join the deterministic sequence of the PRNG:
    pool.rand

### Influence the next three random numbers.

Data supplied to modify_next is
put in a queue, first in, first out:

    pool.modify_next( 'Shake the die lots.' )
    pool.modify_next( 'Roll the die cautiously.' )
    pool.modify_next( 'Drop the die from a great height and watch it bounce.' )

    pool.rand  # influenced by 'Shake the die lots.'
    pool.rand  # etc
    pool.rand

    pool.rand #  . . . and back to main sequence

### Influence all random numbers from this point forward.

This is analogous to
having a personal style of throwing dice, or perhaps a different environment
to throw them in.

    pool.modify_all( 'Gawds help me in my hour of need!' )

    # All these are modified in same way
    pool.rand( 20 )
    pool.rand( 20 )

    # The two modifier types "stack", and this is modified twice
    pool.modify_next( 'And I really mean it!' ).rand( 20 )

### Remove modfiers.

    # Just the "all" modifier
    pool.modify_all( nil )

    # Insert a pause into the "next" queue
    pool.modify_next( nil )

    # Re-set "next" and "all" modifiers
    pool.clear_all_modifiers

### Alter internal state of pool.

This mixes in any entropy in the supplied
data, and changes the deterministic sequence going forward. This is
analogous to long-term alterations to dice, the environment, or
person throwing the dice.

    pool.add_to_pool( 'Purple is my favourite colour.' )

All the inputs can be any length String, from any source. If the data
contains *any* "true randomness" (however you want to define it, and however
the String is formatted), then PoolOfEntropy
will process that (using SHA-512) into unbiased results.

If you care
about your own source of randomness being more "important" than
the initial state of the PRNG or its deterministic progression,
then make use of the modifiers and/or add data to the pool frequently.

## More information

 * [Rationale](RATIONALE.md)
 * [Recipes and Suggestions](RECIPES.md)
 * [Dieharder test of statistical randomness](DIEHARDER_TEST.md)

## Contributing

1. Fork it ( http://github.com/neilslater/pool_of_entropy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
