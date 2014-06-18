require 'spec_helper'

describe PoolOfEntropy do
  describe "class methods" do

    describe "#new" do
      it "should instantiate a default object" do
        pool = PoolOfEntropy.new
        expect( pool ).to be_a PoolOfEntropy
      end

      it "should allow setting number of blocks in pool" do
        [1,3,5,8,13,21,34,55,89,144,233].each do |s|
          pool = PoolOfEntropy.new( :size => 12 )
          expect( pool ).to be_a PoolOfEntropy
          num = pool.rand()
          expect( num ).to be_a Float
          expect( num ).to be >= 0.0
          expect( num ).to be < 1.0
        end
      end

      it "should fail when param is not a hash" do
        expect { PoolOfEntropy.new( [:size,12] ) }.to raise_error TypeError
        expect { PoolOfEntropy.new( '' ) }.to raise_error TypeError
        expect { PoolOfEntropy.new( :size ) }.to raise_error TypeError
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
        expect( pool ).to be_a PoolOfEntropy
        expect( (10..20).map { |x| pool.rand(x) } ).to_not eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should accept { :blank => false } as explicit statement of default" do
        pool = PoolOfEntropy.new( :blank => false )
        expect( pool ).to be_a PoolOfEntropy
        expect( (10..20).map { |x| pool.rand(x) } ).to_not eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should allow an initial blank internal state" do
        pool = PoolOfEntropy.new( :blank => true )
        expect( pool ).to be_a PoolOfEntropy
        expect( (10..20).map { |x| pool.rand(x) } ).to eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
      end

      it "should accept and use :seeds array" do
        pool = PoolOfEntropy.new( :blank => true, :seeds => ['foo'] )
        expect( pool ).to be_a PoolOfEntropy
        expect( (10..20).map { |x| pool.rand(x) } ).to eql [9, 1, 3, 7, 8, 12, 14, 5, 11, 5, 6]

        pool = PoolOfEntropy.new( :blank => true, :seeds => ['foo', 'bar'] )
        expect( pool ).to be_a PoolOfEntropy
        expect( (10..20).map { |x| pool.rand(x) } ).to eql [8, 1, 5, 8, 2, 7, 11, 8, 8, 13, 14]
      end

      it "should fail if :seeds param is not an array" do
        expect { PoolOfEntropy.new( :seeds => -12 ) }.to raise_error TypeError
        expect { PoolOfEntropy.new( :seeds => { :seeds => [2] } ) }.to raise_error TypeError
        expect { PoolOfEntropy.new( :seeds => 'more_seeds' ) }.to raise_error TypeError
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
              expect( pool_copy.rand() ).to eql pool.rand()
            end
          end
        end

        describe "#rand" do

          context "with no param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { expect( pool.rand ).to eql 0.12106507972838931 }
            end

            it "should return a Float between 0.0 and 1.0" do
              100.times do
                num = pool.rand
                expect( num ).to be_a Float
                expect( num ).to be >= 0.0
                expect( num ).to be < 1.0
              end
            end

            it "should return a different Float each time (with high probability) " do
              expect( Set[ *(1..100).map{ pool.rand } ].size ).to eql 100
            end
          end

          context "with an Integer param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { expect( pool.rand(20) ).to eql 2 }
            end

            it "should return an Integer between 0 and x (excluding x)" do
              [ 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 ].each do |x|
                100.times do
                  num = pool.rand( x )
                  expect( num ).to be_a Fixnum
                  expect( num ).to be >= 0
                  expect( num ).to be < x
                end
              end
            end

            # This is a very weak test of randomness, see DIEHARDER_TEST.md
            it "should select values without obvious bias" do
              expect( Set[ *(1..200).map{ pool.rand( 20 ) } ].size ).to eql 20
            end

            it "should return a different Integer each time (with high probability for large x) " do
              expect( Set[ *(1..100).map{ pool.rand( 2**64 ) } ].size ).to eql 100
            end
          end

          context "with a Range param" do
            it "should call PoolOfEntropy::CorePRNG::read_bytes internally" do
              allow_any_instance_of( PoolOfEntropy::CorePRNG).
                  to receive( :read_bytes ).and_return( "\x1e\xfe" * 8 )
              20.times { expect( pool.rand( 7..28 ) ).to eql 9 }
            end

            it "should return an Integer that is a member of the range" do
              [ 1..2, 2..5, 3..8, 5..13, 21..34, 55..89 ].each do |r|
                100.times do
                  num = pool.rand( r )
                  expect( num ).to be_a Fixnum
                  expect( num ).to be >= r.min
                  expect( num ).to be <= r.max
                end
              end
            end

            it "should return a different Integer each time (with high probability for large range) " do
              expect( Set[ *(1..100).map{ pool.rand( 100000000000..200000000000 ) } ].size ).to eql 100
            end

          end

        end


        describe "#modify_next" do
          it "changes output value from next call to #rand" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_next( modifier ).rand ).to_not eql pool.rand
            end
          end

          it "changes output value consistently" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_next( modifier ).rand ).to eql pool.modify_next( modifier ).rand
            end
          end

          it "changes next output value but not future ones" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_next( modifier ).rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to eql pool.rand
            end
          end

          it "can create a 'queue' of modifiers, used in turn" do
            pool_copy = pool.clone
            10.times do
              modifiers = (0..5).map { SecureRandom.hex }

              # Syntax for all-at-once
              pool_copy.modify_next( *modifiers )
              modifiers.each do |modifier|
                expect( pool_copy.rand ).to eql pool.modify_next( modifier ).rand
              end
              # Assert we're back in sync without modifiers
              expect( pool_copy.rand ).to eql pool.rand

              # Adding to queue one-at-a-time
              modifiers.each do |modifier|
                pool_copy.modify_next( modifier )
              end
              modifiers.each do |modifier|
                expect( pool_copy.rand ).to eql pool.modify_next( modifier ).rand
              end
              # Assert we're back in sync without modifiers
              expect( pool_copy.rand ).to eql pool.rand
            end
          end

          it "treats a nil modifier as 'do not modify'" do
            pool_copy = pool.clone
            10.times do
              pool_copy.modify_next( 'hello', nil, 'goodbye' )
              expect( pool_copy.rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to eql pool.rand
              expect( pool_copy.rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to eql pool.rand
              expect( pool_copy.rand ).to eql pool.rand
            end
          end
        end # modify_next

        describe "#modify_all" do
          it "changes output value from future calls to #rand" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_all( modifier ).rand ).to_not eql pool.rand
              10.times do
                expect( pool_copy.rand ).to_not eql pool.rand
              end
            end
          end

          it "changes output value consistently" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_all( modifier ).rand ).to eql pool.modify_all( modifier ).rand
              10.times do
                expect( pool_copy.rand ).to eql pool.rand
              end
            end
          end

          it "changes output value consistently with #modify_next" do
            pool_copy = pool.clone
            100.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_all( modifier ).rand ).to eql pool.modify_next( modifier ).rand
            end
          end

          it "can be reset wih nil modifier" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_all( modifier ).rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to_not eql pool.rand
              pool_copy.modify_all( nil )
              10.times do
                expect( pool_copy.rand ).to eql pool.rand
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
              expect( pool_copy.rand ).to_not eql pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                expect( pool_copy.rand ).to eql pool.rand
              end
            end
          end

          it "removes a current 'all' modifier" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              expect( pool_copy.modify_all( modifier ).rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to_not eql pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                expect( pool_copy.rand ).to eql pool.rand
              end
            end
          end

          it "removes both 'all' and 'next' modifiers in one go" do
            pool_copy = pool.clone
            10.times do
              modifier = SecureRandom.hex
              pool_copy.modify_next( *(0..5).map { SecureRandom.hex } )
              expect( pool_copy.modify_all( modifier ).rand ).to_not eql pool.rand
              expect( pool_copy.rand ).to_not eql pool.rand
              pool_copy.clear_all_modifiers
              10.times do
                expect( pool_copy.rand ).to eql pool.rand
              end
            end
          end
        end

        describe "#add_to_pool" do

          it "alters all future output values" do
            pool_copy = pool.clone
            pool_copy.add_to_pool( 'Some user data!' )
            100.times do
              expect( pool_copy.rand ).to_not eql pool.rand
            end
          end

          it "alters all future output values consistently" do
            pool_copy = pool.clone

            10.times do
              user_data = SecureRandom.hex
              pool_copy.add_to_pool( user_data )
              pool.add_to_pool( user_data )

              10.times do
                expect( pool_copy.rand ).to eql pool.rand
              end
            end
          end

        end

      end
    end
  end
end
