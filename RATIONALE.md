# Rationale for PoolOfEntropy

## Properties of Software Random Numbers

Software PRNGs available are designed to produce data that cannot be statistically separated
from an ideal unbiased "truly random" source. There are quite a few algorithms that can do that,
with differing degrees of success. Current best-in-class generators are pretty good at creating
psuedo random data that has no discernable pattern.

Generators used for games also need another trait - they need to be unpredictable to the end users.
Often that is not strictly true in the academic sense, for example a well-informed user with enough
time and skill could predict the next output from Ruby's rand() method. However, when this really
needs to be true, you can use a Crytogaphically Secure PRNG (CSPRNG). Ruby's SecureRandom cannot
be predicted from outside the system. Part of how CSPRNGs achieve unpredicatbility is by collecting
entropy from sources within the computer - this might be timing of events from network cards and
keyboard presses, or by sampling from deliberately noisy circuits.

## Properties of Dice

A humble 6-sided die achieves similar statistics and unpredictability, but in a different way.
Unbiased statistical randomness is achieved by making the shape and density as regular as possible.
It also assumes the user has "rolled well enough", which is quite tricky to define, but obviously just
placing the die with the number you want facing up does not count.

Unpredictability for the physical die comes from lack of precise control. Imperfections and
microscopic details of where the die is rolling have a large impact. Quantum mechanics may
also have an impact if a die collides and bounces enough. Also, a huge influence is how the
die is thrown, and that comes from the person throwing it. No-one can control their nerves
and muscles to a degree where they "roll well enough" but can consciously choose the
exact result on the die. However, the impulse you give to a die when you throw it caused
by your nerves, bones and muscles. This gives many people a feeling of agency and relationship
to the end result. It may just be a random number, but in some sense it is *your random
number because you generated it*.

## Normal PRNGs Used To Simulate Dice

When it comes to finding computer-based sources of randomness, you will find many systems
that excel at producing results that are statistically random. Ruby's rand() is already
very good at that. Computer-based PRNGs can apparently be made closer to ideal unbiased
randomness than physical dice (or at least beyond any realistic ability to measure it).

Truly unpredictable sources are also easy enough to find. They make themselves unpredictable
by collecting entropy from sources on the machines where they run, that no-one can predict.

However, there has been a cost to the user's agency. If I was playing a game
using one of these sources, even though it was fair in the sense that the outcomes could
well be the same, it gives me the same feeling as if another player was rolling all the dice.
In a role-playing game, it feels the same as if the DM was rolling all the dice. Now sometimes
and for some (many/most?) people that's OK. But other times, part of the fun is in rolling
the dice yourself. I would be happy rolling computer dice, but only if somehow it was
"me" rolling them.

## What PoolOfEntropy Attempts To Do

That is the mission of this gem: To create a simple PRNG where the results are connected as much
as possible to the end user. This has to be achieved without compromising the
good features of fairness and unpredictability that PRNGs and CSPRNGs have in general.

Luckily this can be achieved using an approach that many CSPRNGs already use - using a
data source to seed number generation. The main difference between PoolOfEntropy and
regular CSPRNGs used to protect your computer on the internet is how this "entropy" is sourced.
In a secure system, entropy is sourced from multiple places - anywhere that data can be
gathered that an imagined attacker will have a hard time guessing the value. In PoolOfEntropy
this is subverted - the end user supplies any data they like, and the gem treats it
as "entropy". Technically, if you were an attacker, this would not be called entropy at
all (because you know it) - however, to the machinery of the PRNG, or to me as a fellow
player in a dice game, it counts just fine.

By default PoolOfEntropy objects start off with some machine-collected entropy from SecureRandom
to avoid trivial attacks (of always using the dice in the exact same way). You could view this
as representing the environment or the die itself (all the scratches and imperfections that
you cannot control, and have no influence over). Or, under an honour system of not repeating
yourself you can switch off that default.