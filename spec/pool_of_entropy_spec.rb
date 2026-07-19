# frozen_string_literal: true

require 'spec_helper'

describe PoolOfEntropy do
  describe '.new' do
    it 'instantiates a default object' do
      pool = described_class.new
      expect(pool).to be_a described_class
    end

    it 'allows setting number of blocks in pool' do
      [1, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233].each do |size|
        pool = described_class.new(size: size)
        expect(pool.rand).to be_a_float_in(0.0...1.0)
      end
    end

    [[:size, 12], '', :size].each do |parameter|
      it "rejects non-hash parameter #{parameter.inspect}" do
        expect { described_class.new(parameter) }.to raise_error TypeError
      end
    end

    { -12 => ArgumentError, -1 => ArgumentError, 0 => ArgumentError,
      257 => ArgumentError, 1000 => ArgumentError, '' => ArgumentError,
      { foo: 'bar' } => TypeError }.each do |size, error|
      it "rejects size #{size.inspect}" do
        expect { described_class.new(size: size) }.to raise_error error
      end
    end

    it 'defaults to unpredicatble internal state' do
      pool = described_class.new
      expect((10..20).map { |x| pool.rand(x) }).not_to eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
    end

    it 'accepts { :blank => false } as explicit statement of default' do
      pool = described_class.new(blank: false)
      expect((10..20).map { |x| pool.rand(x) }).not_to eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
    end

    it 'allows an initial blank internal state' do
      pool = described_class.new(blank: true)
      expect((10..20).map { |x| pool.rand(x) }).to eql [8, 3, 0, 12, 11, 2, 4, 8, 1, 11, 18]
    end

    it 'accepts a single-element :seeds array' do
      pool = described_class.new(blank: true, seeds: ['foo'])
      expect((10..20).map { |x| pool.rand(x) }).to eql [9, 1, 3, 7, 8, 12, 14, 5, 11, 5, 6]
    end

    it 'accepts a multiple-element :seeds array' do
      pool = described_class.new(blank: true, seeds: %w[foo bar])
      expect((10..20).map { |x| pool.rand(x) }).to eql [8, 1, 5, 8, 2, 7, 11, 8, 8, 13, 14]
    end

    [-12, { seeds: [2] }, 'more_seeds'].each do |seeds|
      it "rejects non-array seeds #{seeds.inspect}" do
        expect { described_class.new(seeds: seeds) }.to raise_error TypeError
      end
    end
  end

  pool_types = [
    [
      'default instance',
      described_class.new
    ],
    [
      'instance with 2KB pool size',
      described_class.new(size: 32)
    ],
    [
      'instance with 1KB pool size, blank start',
      described_class.new(size: 16, blank: true)
    ],
    [
      'instance with default size, seeded',
      described_class.new(blank: true, seeds: ['of change'])
    ],
    [
      'instance cloned from another instance',
      described_class.new(size: 3).clone
    ],
    [
      'instance with maximum size, 16KB pool',
      described_class.new(size: 256, blank: true, seeds: %w[dgeq dsfsf dsafsaf])
    ]
  ]

  # NB "probability" and "randomness" tests in the following block are very light, just
  # intended to capture high-level failures in logic. See DIEHARDER_TEST.md for thorough
  # checks on statistical randomness of PoolOfEntropy::CorePRNG
  pool_types.each do |pool_name, pool|
    context "with #{pool_name}" do
      subject(:pool_copy) { pool.clone }

      before do
        pool.clear_all_modifiers
      end

      describe '#clone' do
        it 'returns a deep copy with same state and modifiers' do
          pool.modify_next(*(0..4).map { |i| "foo#{i}" })
          pool.modify_all('bar')
          expect(outputs_match?(pool_copy, pool, count: 100)).to be true
        end
      end

      describe '#rand' do
        it 'calls CorePRNG#read_bytes when no argument is given' do
          core_prng = pool.instance_variable_get(:@core_prng)
          allow(core_prng).to receive(:read_bytes).and_return("\x1e\xfe" * 8)
          20.times { expect(pool.rand).to be 0.12106507972838931 }
        end

        it 'returns a Float between 0.0 and 1.0 when no argument is given' do
          100.times do
            expect(pool.rand).to be_a_float_in(0.0...1.0)
          end
        end

        it 'returns a different Float each time with no argument (with high probability)' do
          expect(Set[*(1..100).map { pool.rand }].size).to be 100
        end

        it 'calls CorePRNG#read_bytes with an Integer argument' do
          core_prng = pool.instance_variable_get(:@core_prng)
          allow(core_prng).to receive(:read_bytes).and_return("\x1e\xfe" * 8)
          20.times { expect(pool.rand(20)).to be 2 }
        end

        it 'returns an Integer between 0 and x (excluding x)' do
          [1, 2, 3, 5, 8, 13, 21, 34, 55, 89].each do |x|
            100.times do
              expect(pool.rand(x)).to be_an_integer_in(0...x)
            end
          end
        end

        # This is a very weak test of randomness, see DIEHARDER_TEST.md
        it 'selects Integer values without obvious bias' do
          expect(Set[*(1..500).map { pool.rand(20) }].size).to be 20
        end

        it 'returns a different Integer each time (with high probability for large x)' do
          expect(Set[*(1..100).map { pool.rand(2**64) }].size).to be 100
        end

        it 'calls CorePRNG#read_bytes with a Range argument' do
          core_prng = pool.instance_variable_get(:@core_prng)
          allow(core_prng).to receive(:read_bytes).and_return("\x1e\xfe" * 8)
          20.times { expect(pool.rand(7..28)).to be 9 }
        end

        it 'returns an Integer that is a member of the Range argument' do
          [1..2, 2..5, 3..8, 5..13, 21..34, 55..89].each do |r|
            100.times do
              expect(pool.rand(r)).to be_an_integer_in(r)
            end
          end
        end

        it 'returns a different Integer each time (with high probability for a large Range)' do
          expect(Set[*(1..100).map { pool.rand(100_000_000_000..200_000_000_000) }].size).to be 100
        end
      end

      describe '#modify_next' do
        let(:bulk_queue_results) do
          repeat_results do
            modifiers = (0..5).map { SecureRandom.hex }
            pool_copy.modify_next(*modifiers)
            modifiers.map { pool_copy.rand == pool.modify_next(_1).rand } << outputs_match?(pool_copy, pool, count: 1)
          end
        end

        let(:incremental_queue_results) do
          repeat_results do
            modifiers = (0..5).map { SecureRandom.hex }
            matches = modifiers.map do |modifier|
              pool_copy.modify_next(modifier)
              pool_copy.rand == pool.modify_next(modifier).rand
            end
            matches << outputs_match?(pool_copy, pool, count: 1)
          end
        end

        let(:nil_modifier_results) do
          repeat_results do
            pool_copy.modify_next('hello', nil, 'goodbye')
            [pool_copy.rand != pool.rand, pool_copy.rand == pool.rand, pool_copy.rand != pool.rand,
             pool_copy.rand == pool.rand, pool_copy.rand == pool.rand]
          end
        end

        it 'changes output value from next call to #rand' do
          pool_copy = pool.clone
          100.times do
            modifier = SecureRandom.hex
            expect(pool_copy.modify_next(modifier).rand).not_to eql pool.rand
          end
        end

        it 'changes output value consistently' do
          pool_copy = pool.clone
          100.times do
            modifier = SecureRandom.hex
            expect(pool_copy.modify_next(modifier).rand).to eql pool.modify_next(modifier).rand
          end
        end

        it 'changes next output value but not future ones' do
          results = repeat_results(100) do
            modifier = SecureRandom.hex
            [pool_copy.modify_next(modifier).rand != pool.rand, pool_copy.rand == pool.rand]
          end
          expect(results).to all be true
        end

        it 'consumes modifiers queued in bulk' do
          expect(bulk_queue_results).to all be true
        end

        it 'consumes modifiers queued incrementally' do
          expect(incremental_queue_results).to all be true
        end

        it "treats a nil modifier as 'do not modify'" do
          expect(nil_modifier_results).to all be true
        end
      end

      describe '#modify_all' do
        let(:reset_modifier_results) do
          repeat_results do
            modifier = SecureRandom.hex
            changed = [pool_copy.modify_all(modifier).rand != pool.rand, pool_copy.rand != pool.rand]
            pool_copy.modify_all(nil)
            changed << outputs_match?(pool_copy, pool)
          end
        end

        it 'changes output value from future calls to #rand' do
          results = repeat_results do
            modifier = SecureRandom.hex
            [pool_copy.modify_all(modifier).rand != pool.rand, outputs_differ?(pool_copy, pool)]
          end
          expect(results).to all be true
        end

        it 'changes output value consistently' do
          results = repeat_results do
            modifier = SecureRandom.hex
            [pool_copy.modify_all(modifier).rand == pool.modify_all(modifier).rand, outputs_match?(pool_copy, pool)]
          end
          expect(results).to all be true
        end

        it 'changes output value consistently with #modify_next' do
          pool_copy = pool.clone
          100.times do
            modifier = SecureRandom.hex
            expect(pool_copy.modify_all(modifier).rand).to eql pool.modify_next(modifier).rand
          end
        end

        it 'can be reset wih nil modifier' do
          expect(reset_modifier_results).to all be true
        end
      end

      describe '#clear_all_modifiers' do
        let(:clear_next_results) do
          repeat_results do
            pool_copy.modify_next(*(0..5).map { SecureRandom.hex })
            changed = pool_copy.rand != pool.rand
            pool_copy.clear_all_modifiers
            [changed, outputs_match?(pool_copy, pool)]
          end
        end

        let(:clear_all_results) do
          repeat_results do
            modifier = SecureRandom.hex
            changed = [pool_copy.modify_all(modifier).rand != pool.rand, pool_copy.rand != pool.rand]
            pool_copy.clear_all_modifiers
            changed << outputs_match?(pool_copy, pool)
          end
        end

        let(:clear_combined_results) do
          repeat_results do
            modifier = SecureRandom.hex
            pool_copy.modify_next(*(0..5).map { SecureRandom.hex })
            changed = [pool_copy.modify_all(modifier).rand != pool.rand, pool_copy.rand != pool.rand]
            pool_copy.clear_all_modifiers
            changed << outputs_match?(pool_copy, pool)
          end
        end

        it "removes a queue of 'next' modifiers" do
          expect(clear_next_results).to all be true
        end

        it "removes a current 'all' modifier" do
          expect(clear_all_results).to all be true
        end

        it "removes both 'all' and 'next' modifiers in one go" do
          expect(clear_combined_results).to all be true
        end
      end

      describe '#add_to_pool' do
        let(:add_to_pool_results) do
          repeat_results do
            user_data = SecureRandom.hex
            pool_copy.add_to_pool(user_data)
            pool.add_to_pool(user_data)
            outputs_match?(pool_copy, pool)
          end
        end

        it 'alters all future output values' do
          pool_copy = pool.clone
          pool_copy.add_to_pool('Some user data!')
          100.times do
            expect(pool_copy.rand).not_to eql pool.rand
          end
        end

        it 'alters all future output values consistently' do
          expect(add_to_pool_results).to all be true
        end
      end
    end
  end
end
