# Uses for PoolOfEntropy

## DO NOT USE FOR: Monte-Carlo Simulations

Although PoolOfEntropy can be seeded for repeatable sequences, and produces random numbers of
suitable quality, it is a lot slower than other equally good options. Use Ruby's built in
rand() or the Random class instead.

## DO NOT USE FOR: Communications Security

Although PoolOfEntropy can produce numbers of suitable quality, and is based
on a secure hash design, it is not proven secure and is never likely to be. In
addition, it operates on the application level in a Ruby process, and direct access
to that process would allow it to be compromised very easily. Use SecureRandom
instead.

## Dice for Play-by-Mail

This was one of the original design goals for the gem. One problem with games
played where events happen offline is that random numbers may be required when
a player is not present. By assigning an instance of PoolOfEntropy to each
player, and letting the player provide data for modifiers or the pool, it
allows the game to simulate fair dice rolls, and for the players to have influenced
those rolls in advance. In a philosophical sense you could say the players
have rolled the dice themselves.

To create and use a pool for a player:

    # Depending on how many dice rolls will be made offline, I recommend
    # a largish pool here. This 4KB pool, if completely filled with
    # quality random data for a player, could generate over 6500 rolls of a d20
    # that you might consider to be "rolled by the player" (in the sense that
    # an infinitely powerful machine that knew the initial state before user
    # data was added would need to see the results from that many rolls before it
    # could figure out what the new state was)

    freds_entropy = PoolOfEntropy.new :size => 64

    # Add Fred's data, assuming freds_input is an Array of Strings. Ideally you
    # have at least same number of strings as :size param above. You can split
    # large files into chunks for processing e.g. images or videos

    freds_input.each do |data|
       freds_entropy.add_to_pool( data )
    end

    # Save the pool for later use (example to file, but binary blob in database
    # is also fine). Note you should encrypt this if players have access to the
    # data and would know how to use PoolOfEntropy themselves.

    File.open( 'fred.pool', 'wb' ) { |file| file.write Marshal.dump( freds_entropy ) }

    # Open the pool up later to use it

    freds_entropy = File.open( 'fred.pool', 'rb' ) { |file| Marshal.load( file.read ) }

    # During the game, Fred rolls a die:

    result = freds_entropy.rand( 20 ) + 1

The gem games_dice will accept a PoolOfEntropy object as a generator for a dice object:

    require 'games_dice'

    freds_attack = GamesDice.create '1d20 + 6', freds_entropy

    freds_attack.roll
    # => 21
    freds_attack.explain_result
    # => "1d20: 15. 15 + 6 = 21"
