# Results of dieharder randomness test

See http://www.phy.duke.edu/~rgb/General/dieharder.php for details about
the dieharder utility.

The test consumes a large amount of data, several orders of magnitude
more than the target use of PoolOfEntropy. It is a thorough test
for hidden bias, short cycles and patterns that may occur as faults
in "weak" PRNGs. No test of randomness can be 100% certain though.

All modern cryptographic PRNGs should be expected to pass Dieharder. Although
passing the test does not imply a secure random number generator, failing
it consistently implies an insceure one, that could be predicted.
Ruby's built-in rand(), an implementation of the Mersenne Twister algorithm,
should also pass.

Note that there are over 100 tests, and a test that scores a p-value below
0.01 would be marked "WEAK". For a perfect PRNG it is reasonable to expect
maybe one to five "WEAK" results in a single run. It was just chance -
there is roughly a 32% chance that a perfect PRNG gets all Dieharder tests to
cleanly pass. The usual way to deal with WEAK results is to repeat the offending
tests and show that other p-values are just as likely.

Generally, when a PRNG fails a Dieharder test systematically, you see a
very strong signal, p-value below 0.00001 for several related tests.

The test report below implies PoolOfEntropy is free from a variety
of detectable faults that would prevent it being used as a source of
statistically random numbers. As it happens, there were no "WEAK" results
this time.

## Date run: 9-12 May 2014

Completing all the tests took roughly 3 days.

## Command used

PoolOfEntropy::CorePRNG was used in its default, simplest state to
create a continuous stream of pseudo-random bytes, and this was
fed into the dieharder test running the "all tests" option:

    ruby -rpool_of_entropy -e \
      'r=PoolOfEntropy::CorePRNG.new;loop do;print r.read_bytes;end' \
      | dieharder -g 200 -a

## Report from dieharder

    #=============================================================================#
    #            dieharder version 3.31.1 Copyright 2003 Robert G. Brown          #
    #=============================================================================#
       rng_name    |rands/second|   Seed   |
    stdin_input_raw|  2.40e+05  |3475765104|
    #=============================================================================#
            test_name   |ntup| tsamples |psamples|  p-value |Assessment
    #=============================================================================#
       diehard_birthdays|   0|       100|     100|0.70127033|  PASSED
          diehard_operm5|   0|   1000000|     100|0.49443406|  PASSED
      diehard_rank_32x32|   0|     40000|     100|0.58788457|  PASSED
        diehard_rank_6x8|   0|    100000|     100|0.08410111|  PASSED
       diehard_bitstream|   0|   2097152|     100|0.97953152|  PASSED
            diehard_opso|   0|   2097152|     100|0.97485622|  PASSED
            diehard_oqso|   0|   2097152|     100|0.70397562|  PASSED
             diehard_dna|   0|   2097152|     100|0.76551419|  PASSED
    diehard_count_1s_str|   0|    256000|     100|0.95727516|  PASSED
    diehard_count_1s_byt|   0|    256000|     100|0.42576929|  PASSED
     diehard_parking_lot|   0|     12000|     100|0.08478625|  PASSED
        diehard_2dsphere|   2|      8000|     100|0.27022174|  PASSED
        diehard_3dsphere|   3|      4000|     100|0.37750039|  PASSED
         diehard_squeeze|   0|    100000|     100|0.84447931|  PASSED
            diehard_sums|   0|       100|     100|0.07148373|  PASSED
            diehard_runs|   0|    100000|     100|0.84129944|  PASSED
            diehard_runs|   0|    100000|     100|0.01135930|  PASSED
           diehard_craps|   0|    200000|     100|0.08034019|  PASSED
           diehard_craps|   0|    200000|     100|0.62929296|  PASSED
     marsaglia_tsang_gcd|   0|  10000000|     100|0.56434071|  PASSED
     marsaglia_tsang_gcd|   0|  10000000|     100|0.28872723|  PASSED
             sts_monobit|   1|    100000|     100|0.80991806|  PASSED
                sts_runs|   2|    100000|     100|0.91086458|  PASSED
              sts_serial|   1|    100000|     100|0.88204963|  PASSED
              sts_serial|   2|    100000|     100|0.77896528|  PASSED
              sts_serial|   3|    100000|     100|0.99012882|  PASSED
              sts_serial|   3|    100000|     100|0.57917534|  PASSED
              sts_serial|   4|    100000|     100|0.29749662|  PASSED
              sts_serial|   4|    100000|     100|0.91618340|  PASSED
              sts_serial|   5|    100000|     100|0.61310658|  PASSED
              sts_serial|   5|    100000|     100|0.70187732|  PASSED
              sts_serial|   6|    100000|     100|0.63483611|  PASSED
              sts_serial|   6|    100000|     100|0.63638375|  PASSED
              sts_serial|   7|    100000|     100|0.87933422|  PASSED
              sts_serial|   7|    100000|     100|0.92340602|  PASSED
              sts_serial|   8|    100000|     100|0.08379368|  PASSED
              sts_serial|   8|    100000|     100|0.30058991|  PASSED
              sts_serial|   9|    100000|     100|0.47909085|  PASSED
              sts_serial|   9|    100000|     100|0.99388217|  PASSED
              sts_serial|  10|    100000|     100|0.62723409|  PASSED
              sts_serial|  10|    100000|     100|0.04085355|  PASSED
              sts_serial|  11|    100000|     100|0.40703003|  PASSED
              sts_serial|  11|    100000|     100|0.07446698|  PASSED
              sts_serial|  12|    100000|     100|0.45945558|  PASSED
              sts_serial|  12|    100000|     100|0.50603459|  PASSED
              sts_serial|  13|    100000|     100|0.19977550|  PASSED
              sts_serial|  13|    100000|     100|0.22347592|  PASSED
              sts_serial|  14|    100000|     100|0.68014498|  PASSED
              sts_serial|  14|    100000|     100|0.38635200|  PASSED
              sts_serial|  15|    100000|     100|0.44640327|  PASSED
              sts_serial|  15|    100000|     100|0.65586709|  PASSED
              sts_serial|  16|    100000|     100|0.97546459|  PASSED
              sts_serial|  16|    100000|     100|0.84301307|  PASSED
             rgb_bitdist|   1|    100000|     100|0.28629993|  PASSED
             rgb_bitdist|   2|    100000|     100|0.56483445|  PASSED
             rgb_bitdist|   3|    100000|     100|0.62133888|  PASSED
             rgb_bitdist|   4|    100000|     100|0.81437794|  PASSED
             rgb_bitdist|   5|    100000|     100|0.98632962|  PASSED
             rgb_bitdist|   6|    100000|     100|0.97669342|  PASSED
             rgb_bitdist|   7|    100000|     100|0.30828120|  PASSED
             rgb_bitdist|   8|    100000|     100|0.66955561|  PASSED
             rgb_bitdist|   9|    100000|     100|0.94528798|  PASSED
             rgb_bitdist|  10|    100000|     100|0.90457257|  PASSED
             rgb_bitdist|  11|    100000|     100|0.85673195|  PASSED
             rgb_bitdist|  12|    100000|     100|0.22076625|  PASSED
    rgb_minimum_distance|   2|     10000|    1000|0.53379172|  PASSED
    rgb_minimum_distance|   3|     10000|    1000|0.43597963|  PASSED
    rgb_minimum_distance|   4|     10000|    1000|0.31259419|  PASSED
    rgb_minimum_distance|   5|     10000|    1000|0.61615392|  PASSED
        rgb_permutations|   2|    100000|     100|0.95732489|  PASSED
        rgb_permutations|   3|    100000|     100|0.78107574|  PASSED
        rgb_permutations|   4|    100000|     100|0.64034376|  PASSED
        rgb_permutations|   5|    100000|     100|0.89199822|  PASSED
          rgb_lagged_sum|   0|   1000000|     100|0.63905487|  PASSED
          rgb_lagged_sum|   1|   1000000|     100|0.16144850|  PASSED
          rgb_lagged_sum|   2|   1000000|     100|0.66997505|  PASSED
          rgb_lagged_sum|   3|   1000000|     100|0.54744094|  PASSED
          rgb_lagged_sum|   4|   1000000|     100|0.15684876|  PASSED
          rgb_lagged_sum|   5|   1000000|     100|0.06950708|  PASSED
          rgb_lagged_sum|   6|   1000000|     100|0.04118395|  PASSED
          rgb_lagged_sum|   7|   1000000|     100|0.62558494|  PASSED
          rgb_lagged_sum|   8|   1000000|     100|0.06955632|  PASSED
          rgb_lagged_sum|   9|   1000000|     100|0.80323801|  PASSED
          rgb_lagged_sum|  10|   1000000|     100|0.95324347|  PASSED
          rgb_lagged_sum|  11|   1000000|     100|0.92104340|  PASSED
          rgb_lagged_sum|  12|   1000000|     100|0.68759225|  PASSED
          rgb_lagged_sum|  13|   1000000|     100|0.21127858|  PASSED
          rgb_lagged_sum|  14|   1000000|     100|0.97290617|  PASSED
          rgb_lagged_sum|  15|   1000000|     100|0.33770624|  PASSED
          rgb_lagged_sum|  16|   1000000|     100|0.14037461|  PASSED
          rgb_lagged_sum|  17|   1000000|     100|0.42891060|  PASSED
          rgb_lagged_sum|  18|   1000000|     100|0.01741981|  PASSED
          rgb_lagged_sum|  19|   1000000|     100|0.01825942|  PASSED
          rgb_lagged_sum|  20|   1000000|     100|0.82574915|  PASSED
          rgb_lagged_sum|  21|   1000000|     100|0.55886738|  PASSED
          rgb_lagged_sum|  22|   1000000|     100|0.96301438|  PASSED
          rgb_lagged_sum|  23|   1000000|     100|0.35504422|  PASSED
          rgb_lagged_sum|  24|   1000000|     100|0.86742325|  PASSED
          rgb_lagged_sum|  25|   1000000|     100|0.97050104|  PASSED
          rgb_lagged_sum|  26|   1000000|     100|0.45785583|  PASSED
          rgb_lagged_sum|  27|   1000000|     100|0.91905828|  PASSED
          rgb_lagged_sum|  28|   1000000|     100|0.53348048|  PASSED
          rgb_lagged_sum|  29|   1000000|     100|0.19985210|  PASSED
          rgb_lagged_sum|  30|   1000000|     100|0.63540309|  PASSED
          rgb_lagged_sum|  31|   1000000|     100|0.88671466|  PASSED
          rgb_lagged_sum|  32|   1000000|     100|0.87499608|  PASSED
         rgb_kstest_test|   0|     10000|    1000|0.94490633|  PASSED
         dab_bytedistrib|   0|  51200000|       1|0.21636554|  PASSED
                 dab_dct| 256|     50000|       1|0.35659461|  PASSED
            dab_filltree|  32|  15000000|       1|0.49053255|  PASSED
            dab_filltree|  32|  15000000|       1|0.24508716|  PASSED
           dab_filltree2|   0|   5000000|       1|0.27633380|  PASSED
           dab_filltree2|   1|   5000000|       1|0.93106328|  PASSED
            dab_monobit2|  12|  65000000|       1|0.21748673|  PASSED
