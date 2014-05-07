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

    pool_types = [
      [
        'default params',
        PoolOfEntropy::CorePRNG.new
      ],
      [
        'size of 20',
        PoolOfEntropy::CorePRNG.new( 20 )
      ],
      [
        'zeroed state',
        PoolOfEntropy::CorePRNG.new( 1, "\x0" * 64 )
      ],
      [
        'five blocks fixed state and initial mix block 3',
        PoolOfEntropy::CorePRNG.new( 5, "fiver" * 64, 3 )
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
        end

      end
    end
  end

end
