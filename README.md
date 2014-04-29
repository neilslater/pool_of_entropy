# PoolOfEntropy

PoolOfEntropy is a pseudo random number generator (PRNG) based on secure hashes,
intended to bring back the feeling of 'personal luck' that some gamers may feel when rolling
their *own* dice. An instance of the PoolOfEntropy class could be assigned to a player, or
to each die in a game, and it can be influenced (similar to throwing a die differently), or
personalised by feeding in arbitrary data (e.g. a picture of the player, a favourite saying).
It can handle these influences whilst remaining unbiased and fair on each roll.

PoolOfEntropy is *probably* secure when used appropriately. However, cryptographic security is
not its purpose. The core purpose is for playing with random number generation and non-standard
sources of entropy. The choice of name is supposed to reflect this.

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

Get a random number:

    pool.rand( 20 )

Influence the next random number (but not any others):

    pool.modify_next( 'I hope this works! Whatever!' )
    pool.rand( 20 )

    # Also
    pool.modify_next( 'I hope this works! Whatever!' ).rand( 20 )

Influence all random numbers until change mind (but do not alter internal state):

    pool.modify_all( 'Gawds help me in my hour of need!' )

    # All these are modified in same way, the two modifier types "stack"
    pool.rand( 20 )
    pool.rand( 20 )
    pool.rand( 20 )

Alter internal state of pool (aka customise or "collect entropy"):

    pool.add_state( 'Purple is my favourite colour.' )

## Rationale

TODO: Write usage instructions here

## Contributing

1. Fork it ( http://github.com/<my-github-username>/pool_of_entropy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
