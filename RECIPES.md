# Rationale for PoolOfEntropy

## Properties of Software Random Numbers

Software PRNGs available are designed to produce data that cannot be statistically separated
from an ideal unbiased "truly random" source. There are quite a few algorithms that can do that,
with differing degrees of success. Current best-in-class generators are pretty good at creating
psuedo random data that has no discernable pattern.

Generators used for games also need another trait - they need to be unpredictable to the end users.
Often that is not strictly true in the academic sense, for example a well-informed user with enough
time and skill could predict the next output from Ruby's rand() method. However, when your really
need secure numbers, you can use a Crytogaphically Secure PRNG (CSPRNG). Ruby's SecureRandom cannot
be predicted from outside the system. Part of how CSPRNGs achieve unpredicatbility is by collecting
entropy from sources within the computer - this might be timing of events from network cards and
keyboard presses, or by sampling from deliberately noisy circuits.

## Properties of Dice

A humble 6-sided die achieves similar statistics and unpredictability, but in a different way.
Unbiased statistical randomness is achieved by making the shape and density as regular as possible.
It also assumes the user has "rolled well enough", which is quite tricky to define, but obviously just
placing the die with the number you want facing up does not count.

Unpredictability for the physical die comes from lack of precise control. Imperfections and
microscopic details of where the die is rolling have an impact. Quantum mechanics, which
as far as we know is inherently probability-based, may also have an impact if a die collides
and bounces enough. Also, a big influence, mechanically and philosophically, is how the
die is thrown - and that comes from the person throwing it. No-one can control their nerves
and muscles to a degree where they "roll well enough" but can consciously choose the
exact result on the die. However, the impulse you give to a die when you throw it is caused
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
using one of these sources, even though it was fair in the sense that the outcomes were chosen
with equal chances, it gives me the same feeling as if another player was rolling all the dice.
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
as entropy. Technically, if you were an attacker, this would not be called entropy at
all (because you know the exact value) - however, to the machinery of the PRNG, or
to me as a fellow player in a dice game, it counts just fine.

By default PoolOfEntropy objects start off with some machine-collected entropy from SecureRandom
to avoid trivial attacks (of always using the dice in the exact same way). You could view this
as representing the environment or the die itself (all the scratches and imperfections that
you cannot control, and have no influence over). Or, under an honour system of not repeating
yourself you can switch off that default.

## What PoolOfEntropy Does Not Do: Superstition

PoolOfEntropy will happily eat any string data and use it to help generate random numbers. It
cannot tell, and therefore does not care, what the *meaning* of that data is. It cannot
tell what you wish for, it is not "lady luck" in code form.

Superstition is a natural human feeling. We blow on dice before throwing them to encourage results
that we want, we avoid saying things lest we "tempt fate", and perform a thousand other
minor rites in order to get supposed good luck. This is true even when intellectually we
understand that truly random events are unbiased and there is no predictable cause and effect.
You cannot be a "lucky person" in the sense that random number generators will somehow
favour you. But the feeling is persistent, it seems inherent to human nature.

You can bring superstition into your interactions with a computer PRNG; you may already do,
if you play any computer game that uses random numbers. In some ways this gem encourages that,
by giving you the ability to set things up with data that is meaningful for you. But bear
in mind, that like a well-rolled die, the computer doesn't understand or care. The difference
between PoolOfEntropy and most other PRNGs is supposed to be the difference between you
rolling a die and someone else rolling it for you.
