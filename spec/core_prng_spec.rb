require 'pool_of_entropy'
require 'set'

describe PoolOfEntropy::CorePRNG do
  describe "class methods" do

    describe "#new" do
      it "should instantiate a default object" do
        prng = PoolOfEntropy::CorePRNG.new
        prng.should be_a PoolOfEntropy::CorePRNG
        prng.size.should == 1
      end

      it "should allow setting number of blocks in pool" do
        prng = PoolOfEntropy::CorePRNG.new( 10 )
        prng.should be_a PoolOfEntropy::CorePRNG
        prng.size.should == 10
      end

      it "should fail with incorrect block number" do
        expect { PoolOfEntropy::CorePRNG.new( -43 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( -1 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 0 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 257 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 1000) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( nil ) }.to raise_error TypeError
        expect { PoolOfEntropy::CorePRNG.new( '' ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( :foo => 2 ) }.to raise_error TypeError
      end

      it "should allow setting internal state" do
        prng = PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
        prng.should be_a PoolOfEntropy::CorePRNG
        prng.size.should == 1
        prng.state.should == "\x0" * 64
      end

      it "should fail with bad state data" do
        expect { PoolOfEntropy::CorePRNG.new( 1, '' ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 1, "\x0" * 63 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 1, "\x0" * 200 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy::CorePRNG.new( 2, "\x0" * 64  ) }.to raise_error ArgumentError
      end

      it "should allow setting mix_block_id" do
        prng = PoolOfEntropy::CorePRNG.new( 3, "\x12" * 192, 1 )
        prng.should be_a PoolOfEntropy::CorePRNG
        prng.size.should == 3
        prng.state.should == "\x12" * 192
        prng.mix_block_id.should == 1
      end
    end
  end

  describe "instance methods" do

    describe "#clone" do
      it "should copy all attributes" do
        prng_orig = PoolOfEntropy::CorePRNG.new
        prng_copy = prng_orig.clone

        prng_copy.size.should == prng_orig.size
        prng_copy.state.should == prng_orig.state
        prng_copy.mix_block_id.should == prng_orig.mix_block_id
      end

      it "should deep clone the internal state string" do
        prng_orig = PoolOfEntropy::CorePRNG.new
        prng_copy = prng_orig.clone
        prng_copy.state.should_not be prng_orig.state
      end
    end

    describe "#update" do
      it "should change the internal state" do
        prng = PoolOfEntropy::CorePRNG.new
        init_state = prng.state.clone
        prng.update( 'boo' )
        prng.state.should_not == init_state
      end

      it "should not change the length of the internal state" do
        prng = PoolOfEntropy::CorePRNG.new
        prng.update( 'boo' )
        prng.state.length.should == 64
        prng.update( 'boowgkjwrhqgioueqrhgiue2hguirhqwiughreuioghreuifhqwoifhr3iufghfwrgrwgetdfwd' )
        prng.state.length.should == 64

        prng = PoolOfEntropy::CorePRNG.new( 5 )
        prng.update( 'boo' )
        prng.state.length.should == 5 * 64
        prng.update( 'getdfwd' * 1000 )
        prng.state.length.should == 5 * 64
        prng.update( 'boefewfweo' )
        prng.state.length.should == 5 * 64
        prng.update( 'geefewftdfwd' * 1000 )
        prng.state.length.should == 5 * 64
      end

      it "should only change 64 bytes of state at a time" do
        prng = PoolOfEntropy::CorePRNG.new( 5 )
        init_state = prng.state.clone

        prng.update( 'boo' )
        prng.state[64,4*64].should == init_state[64,4*64]
        next_state = prng.state.clone

        prng.update( 'getdfwd' * 1000 )
        prng.state[128,3*64].should == init_state[128,3*64]
        prng.state[0,1*64].should == next_state[0,1*64]
        next_state = prng.state.clone

        prng.update( 'boefewfweo' )
        prng.state[192,2*64].should == init_state[192,2*64]
        prng.state[0,2*64].should == next_state[0,2*64]
        next_state = prng.state.clone

        prng.update( 'geefewftdfwd' * 1000 )
        prng.state[256,1*64].should == init_state[256,1*64]
        prng.state[0,3*64].should == next_state[0,3*64]
      end
    end

    instance01 = PoolOfEntropy::CorePRNG.new
    instance01.update( 'QWertyuiopp' )
    instance01.update( 'Asdfghjkjl' )
    instance01.update( 'Zxcvbnm' )

    pool_types = [
      [
        'default instance',
        PoolOfEntropy::CorePRNG.new
      ],
      [
        'instance with 2KB pool size',
        PoolOfEntropy::CorePRNG.new( 32 )
      ],
      [
        'instance with initial state all 0',
        PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
      ],
      [
        'instance with fixed initial state',
        PoolOfEntropy::CorePRNG.new( 5, "fiver" * 64, 3 )
      ],
      [
        'instance cloned from 2KB instance',
        PoolOfEntropy::CorePRNG.new( 32 ).clone
      ],
      [
        'instance that has been updated with user data',
        instance01
      ],
    ]

    # NB "probabilty" and "randomness" tests in the following block are very light, just
    # intended to capture high-level failures in logic.
    pool_types.each do |prng_name, prng|

      context "using #{prng_name}" do

        describe "#read_bytes" do
          it "always returns a 16 byte string" do
            100.times { prng.read_bytes.length.should == 16 }
          end

          it "has a high probability of returning a different string each time" do
            Set[ *(1..100).map {prng.read_bytes} ].size.should == 100
          end

          describe "with adjustments" do
            it "always returns a 16 byte string" do
              100.times { prng.read_bytes('654321').length.should == 16 }
            end

            it "has a high probability of returning a different string each time" do
              Set[ *(1..100).map {prng.read_bytes('654321')} ].size.should == 100
            end

            it "changes output, but does not include adjustments in changes to state" do
              prng_copy = prng.clone
              10.times do
                prng.read_bytes('Hello!').should == prng_copy.read_bytes('Hello!')
                prng.state.should == prng_copy.state
                prng.read_bytes('Hello!').should_not == prng_copy.read_bytes('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_bytes.should_not == prng_copy.read_bytes('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_bytes('Hello!').should_not == prng_copy.read_bytes
                prng.state.should == prng_copy.state
                prng.read_bytes('Hello','Goodbye').should_not == prng_copy.read_bytes
                prng.state.should == prng_copy.state
                # Verify that output remains same for next rolls
                prng.read_bytes('Foobar','Wibble').should == prng_copy.read_bytes('Foobar','Wibble')
                prng.state.should == prng_copy.state
                prng.read_bytes.should == prng_copy.read_bytes
                prng.state.should == prng_copy.state
              end
            end
          end
        end

        describe "#read_hex" do
          it "always returns a 32 digit hex string" do
            100.times do
              hex = prng.read_hex
              hex.length.should == 32
              hex.should match /\A[0-9a-f]{32}\z/
            end
          end

          it "has a high probability of returning a different string each time" do
            Set[ *(1..100).map {prng.read_hex} ].size.should == 100
          end

          describe "with adjustments" do
            it "always returns a 32 digit hex string" do
              100.times do
                hex = prng.read_hex('QWertyeu')
                hex.length.should == 32
                hex.should match /\A[0-9a-f]{32}\z/
              end
            end

            it "has a high probability of returning a different string each time" do
              Set[ *(1..100).map {prng.read_hex('654321')} ].size.should == 100
            end

            it "changes output, but does not include adjustments in changes to state" do
              prng_copy = prng.clone
              10.times do
                prng.read_hex('Hello!').should == prng_copy.read_hex('Hello!')
                prng.state.should == prng_copy.state
                prng.read_hex('Hello!').should_not == prng_copy.read_hex('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_hex.should_not == prng_copy.read_hex('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_hex('Hello!').should_not == prng_copy.read_hex
                prng.state.should == prng_copy.state
                prng.read_hex('Hello','Goodbye').should_not == prng_copy.read_hex
                prng.state.should == prng_copy.state
                # Verify that output remains same for next rolls
                prng.read_hex('Foobar','Wibble').should == prng_copy.read_hex('Foobar','Wibble')
                prng.state.should == prng_copy.state
                prng.read_hex.should == prng_copy.read_hex
                prng.state.should == prng_copy.state
              end
            end
          end
        end

        describe "#read_bignum" do
          it "always returns a 128-bit unsigned integer" do
            100.times do
              num = prng.read_bignum
              num.should >= 0
              num.should < 2**128
            end
          end

          it "has a high probability of returning a different number each time" do
            Set[ *(1..100).map {prng.read_bignum} ].size.should == 100
          end

          describe "with adjustments" do
            it "always returns a 128-bit unsigned integer" do
              100.times do
                num = prng.read_bignum( 'Biggest' )
                num.should >= 0
                num.should < 2**128
              end
            end

            it "has a high probability of returning a different number each time" do
              Set[ *(1..100).map {prng.read_bignum('654321')} ].size.should == 100
            end

            it "changes output, but does not include adjustments in changes to state" do
              prng_copy = prng.clone
              10.times do
                prng.read_bignum('Hello!').should == prng_copy.read_bignum('Hello!')
                prng.state.should == prng_copy.state
                prng.read_bignum('Hello!').should_not == prng_copy.read_bignum('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_bignum.should_not == prng_copy.read_bignum('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_bignum('Hello!').should_not == prng_copy.read_bignum
                prng.state.should == prng_copy.state
                prng.read_bignum('Hello','Goodbye').should_not == prng_copy.read_bignum
                prng.state.should == prng_copy.state
                # Verify that output remains same for next rolls
                prng.read_bignum('Foobar','Wibble').should == prng_copy.read_bignum('Foobar','Wibble')
                prng.state.should == prng_copy.state
                prng.read_bignum.should == prng_copy.read_bignum
                prng.state.should == prng_copy.state
              end
            end
          end
        end

        describe "#read_float" do
          it "always returns a Float between 0.0 (inclusive) and 1.0 (exclusive)" do
            100.times do
              num = prng.read_float
              num.should be_a Float
              num.should >= 0.0
              num.should < 1.0
            end
          end

          it "has a high probability of returning a different Float each time" do
            Set[ *(1..100).map {prng.read_float} ].size.should == 100
          end

          describe "with adjustments" do
            it "always returns a Float between 0.0 (inclusive) and 1.0 (exclusive)" do
              100.times do
                num = prng.read_float('Boom')
                num.should be_a Float
                num.should >= 0.0
                num.should < 1.0
              end
            end

            it "has a high probability of returning a different Float each time" do
              Set[ *(1..100).map {prng.read_float('654321')} ].size.should == 100
            end

            it "changes output, but does not include adjustments in changes to state" do
              prng_copy = prng.clone
              10.times do
                prng.read_float('Hello!').should == prng_copy.read_float('Hello!')
                prng.state.should == prng_copy.state
                prng.read_float('Hello!').should_not == prng_copy.read_float('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_float.should_not == prng_copy.read_float('Goodbye!')
                prng.state.should == prng_copy.state
                prng.read_float('Hello!').should_not == prng_copy.read_float
                prng.state.should == prng_copy.state
                prng.read_float('Hello','Goodbye').should_not == prng_copy.read_float
                prng.state.should == prng_copy.state
                # Verify that output remains same for next rolls
                prng.read_float('Foobar','Wibble').should == prng_copy.read_float('Foobar','Wibble')
                prng.state.should == prng_copy.state
                prng.read_float.should == prng_copy.read_float
                prng.state.should == prng_copy.state
              end
            end
          end
        end

        describe "#generate_integer" do
          it "always returns an integer between 0 (inclusive) and supplied top (exclusive)" do
            100.times do
              num = prng.generate_integer( 10 )
              num.should be_a Fixnum
              num.should >= 0
              num.should < 10
            end

            100.times do
              num = prng.generate_integer( 100 )
              num.should be_a Fixnum
              num.should >= 0
              num.should < 100
            end

            100.times do
              num = prng.generate_integer( 1000 )
              num.should be_a Fixnum
              num.should >= 0
              num.should < 1000
            end

            100.times do
              num = prng.generate_integer( 647218456 )
              num.should be_a Fixnum
              num.should >= 0
              num.should < 647218456
            end
          end

          it "can generate integers larger than 2**128" do
            results = (0..100).map do
              num = prng.generate_integer( 2 ** 1024 )
              num.should >= 0
              num.should < 2 ** 1024
              num
            end
            results.select { |n| n > 2 ** 1020 }.count.should > 50
          end

          it "with a large enough value for top, has a high probability of returning a different integer each time" do
            Set[ *(1..100).map {prng.generate_integer( 2**75 - 7 )} ].size.should == 100
          end

          it "covers a distribution 0...top" do
            Set[ *(1..100).map {prng.generate_integer(10)} ].size.should == 10
          end

          describe "with adjustments" do
            it "always returns an integer between 0 (inclusive) and supplied top (exclusive)" do
              100.times do
                num = prng.generate_integer( 10, 'jkffwe' )
                num.should be_a Fixnum
                num.should >= 0
                num.should < 10
              end

              100.times do
                num = prng.generate_integer( 100, 'jkffweefewg' )
                num.should be_a Fixnum
                num.should >= 0
                num.should < 100
              end

              100.times do
                num = prng.generate_integer( 1000, 'jkffweefewg', 'efhwjkfgw' )
                num.should be_a Fixnum
                num.should >= 0
                num.should < 1000
              end

              100.times do
                num = prng.generate_integer( 647218456, 'j*****g', 'efhwjkfgw' )
                num.should be_a Fixnum
                num.should >= 0
                num.should < 647218456
              end
            end

            it "with a large enough value for top, has a high probability of returning a different integer each time" do
              Set[ *(1..100).map {prng.generate_integer( 2**80 - 5, '654321')} ].size.should == 100
            end

            it "changes output, but does not include adjustments in changes to state" do
              prng_copy = prng.clone
              big = 2 ** 64 - 3
              small = 20
              10.times do
                prng.generate_integer( small, 'Hello!').should == prng_copy.generate_integer( small, 'Hello!')
                prng.state.should == prng_copy.state
                prng.generate_integer( big, 'Hello!').should_not == prng_copy.generate_integer( big, 'Goodbye!')
                prng.state.should == prng_copy.state
                prng.generate_integer( big ).should_not == prng_copy.generate_integer( big, 'Goodbye!')
                prng.state.should == prng_copy.state
                prng.generate_integer( big, 'Hello!').should_not == prng_copy.generate_integer( big )
                prng.state.should == prng_copy.state
                prng.generate_integer( big, 'Hello','Goodbye').should_not == prng_copy.generate_integer( big )
                prng.state.should == prng_copy.state
                # Verify that output remains same for next rolls
                prng.generate_integer( small, 'Foobar','Wibble').should == prng_copy.generate_integer( small, 'Foobar','Wibble')
                prng.state.should == prng_copy.state
                prng.generate_integer( big ).should == prng_copy.generate_integer( big )
                prng.state.should == prng_copy.state
              end
            end
          end
        end


        describe "all read methods" do

          it "generate higher and lower values in sync" do
            prngs = (0..4).map { prng.clone }
            results = (1..20).map do
              Hash[
                :bytes => prngs[0].read_bytes,
                :hex   => prngs[1].read_hex,
                :float => prngs[2].read_float,
                :num   => prngs[3].read_bignum,
                :int   => prngs[4].generate_integer( 1_000_000 ),
              ]
            end
            results.sort_by { |h| h[:int] }.should == results.sort_by { |h| h[:hex] }
            results.sort_by { |h| h[:float] }.should == results.sort_by { |h| h[:hex] }
            results.sort_by { |h| h[:num] }.should == results.sort_by { |h| h[:bytes] }
            results.sort_by { |h| h[:float] }.should == results.sort_by { |h| h[:int] }
          end
        end

      end
    end

    describe "using predictable sequences" do
      it "generates expected hex strings from simple zeroed pool" do
        prng = PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
        (0..24).map { prng.read_hex }.should == [ "da0cd77eb1c84458ddcc91e36b9dcb35",
          "498ec24d1126440047eed396d836b5e1", "0b90df55c5e7c1513b072367eae4a4ce",
          "f12b5b54b5594e785bbb9a4ac50ccec8", "d506bd4e201a00dc30499bd8e59a30d8",
          "2557893cf995fe43bd00721fce6ab16a", "41ee50244cdd02334bafc3e9d8f564d9",
          "8156c7c7bcfd856cb9d1012243cfc662", "1116f840e2aee924bd2c7d722c602635",
          "96cf31967465b83f5ef3476c60afe20a", "f041f6df72aa2eab7394f08e83d52a0c",
          "5ccbb30077f2433bd765ddc86840a880", "6a4339fd5d445024048ea8f91a3e02fd",
          "707e9499b9f0e9e906a0c0ddd0530803", "553704d95703284df323f0aa4244cf81",
          "cb1522ce0bdf2504fdd62df7416be73e", "05c4932cb9d3a7c0675b0228826e661a",
          "59606f23e34e726a7912dacfde533d97", "188cf17dde6947264ce05f8274874ffa",
          "24c184b56453891657953f557635b742", "a5f969e50228b2ee0f38cc37c5033541",
          "f1de0e5d149cc5a7f0e38c0ee501d7bc", "5ca3a6beb0b810568be83ab2179eb550",
          "756fb9c58277eb8c6092142224caecf4", "0ed9505eadb3def60ec42051f0bf15ef" ]
        end

      it "generates expected hex strings from simple zeroed pool and an adjustment" do
        prng = PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
        (0..24).map { prng.read_hex( 'bananas' ) }.should == [
          "fed9de9a612f4157ebb49582ca557a50", "a7adc2374a4df2ed67846ac09a3b6645",
          "cbdf8bbbe6145751fe14004719915160", "8cd84be95376f72918c305bdea43e36d",
          "9e08e80ff40c942f0cf4d479b5378fa0", "54d80c5330873f9733a0adef0197220f",
          "2abe07bd85d2066a624dd3630e59730a", "88b6a697fe74aeb8ec83845e103b7b63",
          "9c6c9d613855f6535adb419cc564fd10", "23f9b778b254035a0e4219423a52da77",
          "4cd50c14ee17fa29c8b1f209432a36b3", "2b5646b164d863de716f67adef653859",
          "fd81d0bbbd2828ecdfcba0b486ef786c", "08e6594fc277ff7fafbf37475ecadbf6",
          "5e2333ecc800eb9a06e347924ed42e94", "8a14e48013028b2c9f174a07ddd5ef49",
          "e9a5c331f54b155f570c2cf2bcd37209", "1ce84279195a5b23ffeb3063edbfab21",
          "7422e19e58f2fcf20805f601266bf676", "8df0226465b74d830360ea8609d181bf",
          "3e5d5e8cf8ad032fb4005826bdf7bb94", "65e3f9ab28c26bead6647c21bcc6245e",
          "8ed5d8892d464ebeaa8dcbcef0968936", "2f000bc1ab14d914196cc1d5055db189",
          "8e9c4b8152f14e47ac31f25a80765ebf" ]
      end

      it "generates expected hex strings from simple zeroed pool and alternating adjustments" do
        prng = PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
        (0..24).map { |x| x.odd? ? prng.read_hex( 'bananas', x.to_s ) : prng.read_hex }.should == [
          "da0cd77eb1c84458ddcc91e36b9dcb35", "de4b20a0560263090c6fe11ebba6256e",
          "0b90df55c5e7c1513b072367eae4a4ce", "0c92d534160cb268cb3282a9dd3f1efe",
          "d506bd4e201a00dc30499bd8e59a30d8", "089f799236a9cf64f22f1deafbe28214",
          "41ee50244cdd02334bafc3e9d8f564d9", "84477b9a3d51bb72868ccb85bea71cad",
          "1116f840e2aee924bd2c7d722c602635", "469e4bb2f38719c7f85d79c8900a8fa8",
          "f041f6df72aa2eab7394f08e83d52a0c", "e21bf2508b8e1755ae70c74c0d36ec2e",
          "6a4339fd5d445024048ea8f91a3e02fd", "a94a80c80c9edd95808a67775c2b42d4",
          "553704d95703284df323f0aa4244cf81", "edd6aea5bda7b2d9c494067c5cdbe410",
          "05c4932cb9d3a7c0675b0228826e661a", "cf81635ca2fa910fd11cf45508dc658b",
          "188cf17dde6947264ce05f8274874ffa", "bb4aaeb98e13400c1216c674a872ba93",
          "a5f969e50228b2ee0f38cc37c5033541", "1a795355f979575247b3fa9c92d97917",
          "5ca3a6beb0b810568be83ab2179eb550", "1a98419cca1dd1b370ce8a4a2ab721b7",
          "0ed9505eadb3def60ec42051f0bf15ef" ]
      end
    end
  end

end
