require 'spec_helper'

describe PoolOfEntropy do
  describe "class methods" do

    describe "#new" do
      it "should instantiate a default object" do
        pool = PoolOfEntropy.new
        pool.should be_a PoolOfEntropy
      end

      it "should allow setting number of blocks in pool" do
        [1,3,5,8,13,21,34,55,89,144,233].each do |s|
          pool = PoolOfEntropy.new( :size => 12 )
          pool.should be_a PoolOfEntropy
          num = pool.rand()
          num.should be_a Float
          num.should >= 0.0
          num.should < 1.0
        end
      end

      it "should fail with incorrect :size param" do
        expect { PoolOfEntropy.new( :size => -12 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => -1 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => 0 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => 257 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => 1000 ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => '' ) }.to raise_error ArgumentError
        expect { PoolOfEntropy.new( :size => { :foo => 'bar' } ) }.to raise_error TypeError
      end

      it "should default to unpredicatble internal state" do
        pool = PoolOfEntropy.new()
        pool.should be_a PoolOfEntropy
        (10..20).map { |x| pool.rand(x) }.should_not == [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should accept { :blank => false } as explicit statement of default" do
        pool = PoolOfEntropy.new( :blank => false )
        pool.should be_a PoolOfEntropy
        (10..20).map { |x| pool.rand(x) }.should_not == [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should allow an initial blank internal state" do
        pool = PoolOfEntropy.new( :blank => true )
        pool.should be_a PoolOfEntropy
        (10..20).map { |x| pool.rand(x) }.should == [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should accept and use :seed array" do
        pool = PoolOfEntropy.new( :blank => true, :seeds => ['foo'] )
        pool.should be_a PoolOfEntropy
        (10..20).map { |x| pool.rand(x) }.should == [9, 1, 3, 7, 8, 12, 14, 5, 11, 5, 6]

        pool = PoolOfEntropy.new( :blank => true, :seeds => ['foo', 'bar'] )
        pool.should be_a PoolOfEntropy
        (10..20).map { |x| pool.rand(x) }.should == [8, 1, 5, 8, 2, 7, 11, 8, 8, 13, 14]
      end
    end
  end


  describe "instance methods" do
    pool_types = [
      [
        'default instance',
        PoolOfEntropy.new
      ],
      [
        'instance with 2KB pool size',
        PoolOfEntropy.new( :size => 32 )
      ],
      [
        'instance with 1KB pool size, blank start',
        PoolOfEntropy.new( :size => 16, :blank => true )
      ],
      [
        'instance with default size, seeded',
        PoolOfEntropy.new( :blank => true, :seeds => ['of change'] )
      ],
      [
        'instance cloned from another instance',
        PoolOfEntropy.new( :size => 3 ).clone
      ],
      [
        'instance with maximum size, 16KB pool',
        PoolOfEntropy.new( :size => 256, :blank => true, :seeds => ['dgeq','dsfsf','dsafsaf'] )
      ],
    ]

    # NB "probability" and "randomness" tests in the following block are very light, just
    # intended to capture high-level failures in logic. See DIEHARDER_TEST.md for thorough
    # checks on statistical randomness of PoolOfEntropy::CorePRNG
    pool_types.each do |pool_name, pool|

      context "using #{pool_name}" do
        before do
          pool.clear_all_modifiers
        end

        describe "#clone" do
          it "should return a deep copy with same state and modifiers" do
            pool.modify_next( *((0..4).map {|i| "foo" + i.to_s} ) )
            pool.modify_all( 'bar' )

            pool_copy = pool.clone
            100.times do
              pool_copy.rand().should == pool.rand()
            end
          end
        end

        describe "#rand" do

          context "with no param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { pool.rand.should == 0.12106507972838931 }
            end

            it "should return a Float between 0.0 and 1.0" do
              100.times do
                num = pool.rand
                num.should be_a Float
                num.should >= 0.0
                num.should < 1.0
              end
            end

            it "should return a different Float each time (with high probability) " do
              Set[ *(1..100).map{ pool.rand } ].size.should == 100
            end
          end

          context "with an Integer param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { pool.rand(20).should == 2 }
            end

            it "should return an Integer between 0 and x (excluding x)" do
              [ 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 ].each do |x|
                100.times do
                  num = pool.rand( x )
                  num.should be_a Fixnum
                  num.should >= 0
                  num.should < x
                end
              end
            end

            # This is a very weak test of randomness, see DIEHARDER_TEST.md
            it "should select values without obvious bias" do
              Set[ *(1..200).map{ pool.rand( 20 ) } ].size.should == 20
            end

            it "should return a different Integer each time (with high probability for large x) " do
              Set[ *(1..100).map{ pool.rand( 2**64 ) } ].size.should == 100
            end
          end

          context "with a Range param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { pool.rand( 7..28 ).should == 9 }
            end

            it "should return an Integer that is a member of the range" do
              [ 1..2, 2..5, 3..8, 5..13, 21..34, 55..89 ].each do |r|
                100.times do
                  num = pool.rand( r )
                  num.should be_a Fixnum
                  num.should >= r.min
                  num.should <= r.max
                end
              end
            end

            it "should return a different Integer each time (with high probability for large range) " do
              Set[ *(1..100).map{ pool.rand( 100000000000..200000000000 ) } ].size.should == 100
            end

          end

        end


        describe "#modify_next" do
          it "changes output value from next call to #rand" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              pool_copy.modify_next( modifier ).rand.should_not == pool.rand
            end
          end

          it "changes output value consistently" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              pool_copy.modify_next( modifier ).rand.should == pool.modify_next( modifier ).rand
            end
          end

          it "changes next output value but not future ones" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              pool_copy.modify_next( modifier ).rand.should_not == pool.rand
              pool_copy.rand.should == pool.rand
            end
          end

          it "can create a 'queue' of modifiers, used in turn" do
            pool_copy = pool.clone
            10.times do
              modifiers = (0..5).map { SecureRandom.hex }

              # Syntax for all-at-once
              pool_copy.modify_next( *modifiers )
              modifiers.each do |modifier|
                pool_copy.rand.should == pool.modify_next( modifier ).rand
              end
              # Assert we're back in sync without modifiers
              pool_copy.rand.should == pool.rand

              # Adding to queue one-at-a-time
              modifiers.each do |modifier|
                pool_copy.modify_next( modifier )
              end
              modifiers.each do |modifier|
                pool_copy.rand.should == pool.modify_next( modifier ).rand
              end
              # Assert we're back in sync without modifiers
              pool_copy.rand.should == pool.rand
            end
          end
        end # modify_next

        describe "#modify_all" do
          it "changes output value from future calls to #rand" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_all( modifier ).rand.should_not == pool.rand
              10.times do
                pool_copy.rand.should_not == pool.rand
              end
            end
          end

          it "changes output value consistently" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_all( modifier ).rand.should == pool.modify_all( modifier ).rand
              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end

          it "changes output value consistently with #modify_next" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              pool_copy.modify_all( modifier ).rand.should == pool.modify_next( modifier ).rand
            end
          end

          it "can be reset wih nil modifier" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_all( modifier ).rand.should_not == pool.rand
              pool_copy.rand.should_not == pool.rand
              pool_copy.modify_all( nil )
              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end

        end

        describe "#clear_all_modifiers" do

          it "removes a queue of 'next' modifiers" do
            pool_copy = pool.clone
            10.times do
              modifiers = (0..5).map { SecureRandom.hex }
              pool_copy.modify_next( *modifiers )
              pool_copy.rand.should_not == pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end

          it "removes a current 'all' modifier" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_all( modifier ).rand.should_not == pool.rand
              pool_copy.rand.should_not == pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end

          it "removes both 'all' and 'next' modifiers in one go" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_next( *(0..5).map { SecureRandom.hex } )
              pool_copy.modify_all( modifier ).rand.should_not == pool.rand
              pool_copy.rand.should_not == pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end
        end

        describe "#add_to_pool" do

          it "alters all future output values" do
            pool_copy = pool.clone
            pool_copy.add_to_pool( 'Some user data!' )
            100.times do
              pool_copy.rand.should_not == pool.rand
            end
          end

          it "alters all future output values consistently" do
            pool_copy = pool.clone

            10.times do
              user_data = SecureRandom.hex
              pool_copy.add_to_pool( user_data )
              pool.add_to_pool( user_data )

              10.times do
                pool_copy.rand.should == pool.rand
              end
            end
          end

        end

      end
    end
  end
end
