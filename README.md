# PoolOfEntropy
[![Gem Version](https://badge.fury.io/rb/pool_of_entropy.png)](http://badge.fury.io/rb/pool_of_entropy)
[![Build Status](https://travis-ci.org/neilslater/pool_of_entropy.png?branch=master)](http://travis-ci.org/neilslater/pool_of_entropy)
[![Coverage Status](https://coveralls.io/repos/neilslater/pool_of_entropy/badge.png?branch=master)](https://coveralls.io/r/neilslater/pool_of_entropy?branch=master)
[![Code Climate](https://codeclimate.com/github/neilslater/pool_of_entropy.png)](https://codeclimate.com/github/neilslater/pool_of_entropy)
[![Dependency Status](https://gemnasium.com/neilslater/pool_of_entropy.png)](https://gemnasium.com/neilslater/pool_of_entropy)

PoolOfEntropy is a pseudo random number generator (PRNG) based on secure hashes,
intended to bring back the feeling of 'personal agency' that some gamers may feel when rolling
their *own* dice. An instance of the PoolOfEntropy class could be assigned to a player, or
to each die in a game, and it can be influenced (similar to throwing a die differently), or
personalised by feeding in arbitrary data (e.g. a picture of the player, a favourite saying).
It can handle these influences whilst remaining unbiased and fair on each roll.

PoolOfEntropy is *probably* secure when used appropriately, and in a very limited sense.
However, cryptographic security is not its purpose. The core purpose is for playing with
random number generation and non-standard sources of entropy. The choice of name is
supposed to reflect this.

If you are looking for a secure PRNG in Ruby, good for generating session codes or
server-side secrets, use the standard library SecureRandom.

If you think that rolling all your dice on an anonymous server has removed a little bit of soul
from your game sessions, or if you want to generate unbiased random numbers using input from your
laptop's microphone or mobile's accellerometer as a source, then PoolOfEntropy might be for you.

## Installation

Add this line to your application's Gemfile:

    gem 'pool_of_entropy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pool_of_entropy

## Usage

Create a new generator:

    pool = PoolOfEntropy.new

Get a random number. Not feeding the generator with any customisation
means it is completely deterministic based on current internal state. The
analogy here might be "trusting to Fate":

    pool.rand( 20 )

Influence the next random number (but not any others). This is analogous to
shaking or throwing dice in a certain way. Only the next result from rand()
is affected:

    pool.modify_next( 'Shake the die.' )
    pool.rand( 20 )

    # Also
    pool.modify_next( 'Shake the die.' ).rand( 20 )

    # This next result will not be influenced,
    # we re-join the deterministic sequence of the PRNG:
    pool.rand

Influence the next three random numbers. Data supplied to modify_next is
put in a queue, first in, first out:

    pool.modify_next( 'Shake the die lots.' )
    pool.modify_next( 'Roll the die cautiously.' )
    pool.modify_next( 'Drop the die from a great height and watch it bounce.' )

    pool.rand  # influenced by 'Shake the die lots.'
    pool.rand  # etc
    pool.rand

    pool.rand #  . . . and back to main sequence

Influence all random numbers from this point forward. This is analogous to
having a personal style of throwing dice, or perhaps a different environment
to throw them in.

    pool.modify_all( 'Gawds help me in my hour of need!' )

    # All these are modified in same way
    pool.rand( 20 )
    pool.rand( 20 )

    # The two modifier types "stack", and this is modified twice
    pool.modify_next( 'And I really mean it!' ).rand( 20 )

Remove modfiers:

    # Just the "all" modifier
    pool.modify_all( nil )

    # Insert a pause into the "next" queue
    pool.modify_next( nil )

    # Re-set "next" and "all" modifiers
    pool.clear_all_modifiers

Alter internal state of pool. This mixes in any entropy in the supplied
data, and changes the deterministic sequence going forward. This is
analogous to long-term alterations to dice, the environment, or
person throwing the dice.

    pool.add_to_pool( 'Purple is my favourite colour.' )

All the inputs can be any length String, from any source. If the data
contains *any* "true randomness" (however you want to define it, and however
the String is formatted), then PoolOfEntropy
will process that (using SHA-512) into unbiased results. If you care
about your own source of randomness being more "important" than
the initial state of the PRNG, or its continued deterministic ticking,
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
