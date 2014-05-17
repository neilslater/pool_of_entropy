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

## Dice for Play By Mail

This was one of the original design goals for the gem
