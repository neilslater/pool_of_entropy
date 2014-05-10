# Results of dieharder randomness test

See http://www.phy.duke.edu/~rgb/General/dieharder.php for details about
the dieharder utility.

Date run: 9 May 2014

Command used:

    ruby -rpool_of_entropy -e \
      'r=PoolOfEntropy::CorePRNG.new;loop do;print r.read_bytes;end' \
      | dieharder -g 200 -a

Report from dieharder:

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