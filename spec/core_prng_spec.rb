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

      end
    end
  end

end
