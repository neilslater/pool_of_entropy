# frozen_string_literal: true

require 'spec_helper'

describe PoolOfEntropy::CorePRNG do
  shared_examples 'an adjustable reader' do |prng, read|
    let(:original) { prng.clone }
    let(:copy) { original.clone }

    it 'returns the same output for the same adjustment' do
      copy
      10.times do
        expect(read.call(original, 'Hello!')).to eql read.call(copy, 'Hello!')
      end
    end

    { 'different adjustments' => [%w[Hello!], %w[Goodbye!]],
      'an adjustment on only the original' => [%w[Hello!], []],
      'an adjustment on only the copy' => [[], %w[Goodbye!]],
      'multiple adjustments on only the original' => [%w[Hello Goodbye], []] }.each do |description, arguments|
      it "returns different output for #{description}" do
        copy
        10.times do
          expect(read.call(original, *arguments.first)).not_to eql read.call(copy, *arguments.last)
        end
      end
    end

    context 'when adjusted reads use mismatched arguments' do
      before do
        copy
        [[%w[Hello!], %w[Goodbye!]], [[], %w[Goodbye!]], [%w[Hello!], []], [%w[Hello Goodbye], []]].each do |args|
          read.call(original, *args.first)
          read.call(copy, *args.last)
        end
      end

      it 'does not include adjustments in state changes' do
        expect(original.state).to eql copy.state
      end

      it 'returns to matching output' do
        expect(read.call(original)).to eql read.call(copy)
      end
    end
  end

  describe '.new' do
    it 'instantiates a default object' do
      prng = described_class.new
      expect(prng).to be_a(described_class).and have_attributes(size: 1)
    end

    it 'allows setting number of blocks in pool' do
      prng = described_class.new(10)
      expect(prng).to be_a(described_class).and have_attributes(size: 10)
    end

    { -43 => ArgumentError, -1 => ArgumentError, 0 => ArgumentError,
      257 => ArgumentError, 1000 => ArgumentError, nil => TypeError,
      '' => ArgumentError, { foo: 2 } => TypeError }.each do |size, error|
      it "rejects block count #{size.inspect}" do
        expect { described_class.new(size) }.to raise_error error
      end
    end

    it 'allows setting internal state' do
      prng = described_class.new(1, "\x0" * 64)
      expect(prng).to be_a(described_class).and have_attributes(size: 1, state: "\x0" * 64)
    end

    { [1, :boo] => TypeError, [1, []] => TypeError, [1, ''.dup] => ArgumentError,
      [1, "\x0" * 63] => ArgumentError, [1, "\x0" * 200] => ArgumentError,
      [2, "\x0" * 64] => ArgumentError }.each do |arguments, error|
      it "rejects state data #{arguments.last.inspect}" do
        expect { described_class.new(*arguments) }.to raise_error error
      end
    end

    it 'allows setting mix_block_id' do
      prng = described_class.new(3, "\x12" * 192, 1)
      expect(prng).to be_a(described_class).and have_attributes(
        size: 3, state: "\x12" * 192, mix_block_id: 1
      )
    end
  end

  describe '#clone' do
    it 'copies all attributes' do
      prng_orig = described_class.new
      prng_copy = prng_orig.clone

      expect(prng_copy).to have_attributes(
        size: prng_orig.size, state: prng_orig.state, mix_block_id: prng_orig.mix_block_id
      )
    end

    it 'deeps clone the internal state string' do
      prng_orig = described_class.new
      prng_copy = prng_orig.clone
      expect(prng_copy.state).not_to be prng_orig.state
    end
  end

  describe '#update' do
    it 'changes the internal state' do
      prng = described_class.new
      init_state = prng.state.clone
      prng.update('boo')
      expect(prng.state).not_to eql init_state
    end

    { 1 => %w[boo boowgkjwrhqgioueqrhgiue2hguirhqwiughreuioghreuifhqwoifhr3iufghfwrgrwgetdfwd],
      5 => ['boo', 'getdfwd' * 1000, 'boefewfweo', 'geefewftdfwd' * 1000] }.each do |size, updates|
      it "preserves the state length for a #{size}-block pool" do
        prng = described_class.new(size)
        lengths = state_lengths_after(prng, updates)
        expect(lengths).to all be(size * 64)
      end
    end

    ['boo', 'getdfwd' * 1000, 'boefewfweo', 'geefewftdfwd' * 1000].each_with_index do |data, index|
      it "changes only state block #{index}" do
        prng = described_class.new(5)
        index.times { |prior| prng.update(['boo', 'getdfwd' * 1000, 'boefewfweo'][prior]) }
        before = prng.state.clone
        expect { prng.update(data) }.to change { [before, prng.state] }.to(change_only_block(index))
      end
    end
  end

  instance01 = described_class.new
  instance01.update('QWertyuiopp')
  instance01.update('Asdfghjkjl')
  instance01.update('Zxcvbnm')

  pool_types = [
    [
      'default instance',
      described_class.new
    ],
    [
      'instance with 2KB pool size',
      described_class.new(32)
    ],
    [
      'instance with initial state all 0',
      described_class.new(1, "\x0" * 64)
    ],
    [
      'instance with fixed initial state',
      described_class.new(5, 'fiver' * 64, 3)
    ],
    [
      'instance cloned from 2KB instance',
      described_class.new(32).clone
    ],
    [
      'instance that has been updated with user data',
      instance01
    ]
  ]

  # NB "probability" and "randomness" tests in the following block are very light, just
  # intended to capture high-level failures in logic. See DIEHARDER_TEST.md for thorough
  # checks on statistical randomness of PoolOfEntropy::CorePRNG
  pool_types.each do |prng_name, prng|
    context "with #{prng_name}" do
      describe '#read_bytes' do
        it 'always returns a 16 byte string' do
          100.times { expect(prng.read_bytes.length).to be 16 }
        end

        it 'has a high probability of returning a different string each time' do
          expect(Set[*(1..100).map { prng.read_bytes }].size).to be 100
        end

        it 'always returns a 16 byte string with adjustments' do
          100.times { expect(prng.read_bytes('654321').length).to be 16 }
        end

        it 'has a high probability of returning a different adjusted string each time' do
          expect(Set[*(1..100).map { prng.read_bytes('654321') }].size).to be 100
        end

        it_behaves_like 'an adjustable reader', prng, ->(reader, *args) { reader.read_bytes(*args) }
      end

      describe '#read_hex' do
        it 'always returns a 32 digit hex string' do
          100.times do
            expect(prng.read_hex).to match(/\A[0-9a-f]{32}\z/)
          end
        end

        it 'has a high probability of returning a different string each time' do
          expect(Set[*(1..100).map { prng.read_hex }].size).to be 100
        end

        it 'always returns a 32 digit hex string with adjustments' do
          100.times do
            expect(prng.read_hex('QWertyeu')).to match(/\A[0-9a-f]{32}\z/)
          end
        end

        it 'has a high probability of returning a different adjusted string each time' do
          expect(Set[*(1..100).map { prng.read_hex('654321') }].size).to be 100
        end

        it_behaves_like 'an adjustable reader', prng, ->(reader, *args) { reader.read_hex(*args) }
      end

      describe '#read_bignum' do
        it 'always returns a 128-bit unsigned integer' do
          100.times do
            expect(prng.read_bignum).to be_an_integer_in(0...(2**128))
          end
        end

        it 'has a high probability of returning a different number each time' do
          expect(Set[*(1..100).map { prng.read_bignum }].size).to be 100
        end

        it 'always returns an adjusted 128-bit unsigned integer' do
          100.times do
            expect(prng.read_bignum('Biggest')).to be_an_integer_in(0...(2**128))
          end
        end

        it 'has a high probability of returning a different adjusted number each time' do
          expect(Set[*(1..100).map { prng.read_bignum('654321') }].size).to be 100
        end

        it_behaves_like 'an adjustable reader', prng, ->(reader, *args) { reader.read_bignum(*args) }
      end

      describe '#read_float' do
        it 'always returns a Float between 0.0 (inclusive) and 1.0 (exclusive)' do
          100.times do
            expect(prng.read_float).to be_a_float_in(0.0...1.0)
          end
        end

        it 'has a high probability of returning a different Float each time' do
          expect(Set[*(1..100).map { prng.read_float }].size).to be 100
        end

        it 'always returns an adjusted Float between 0.0 (inclusive) and 1.0 (exclusive)' do
          100.times do
            expect(prng.read_float('Boom')).to be_a_float_in(0.0...1.0)
          end
        end

        it 'has a high probability of returning a different adjusted Float each time' do
          expect(Set[*(1..100).map { prng.read_float('654321') }].size).to be 100
        end

        it_behaves_like 'an adjustable reader', prng, ->(reader, *args) { reader.read_float(*args) }
      end

      describe '#generate_integer' do
        it 'always returns an integer between 0 (inclusive) and supplied top (exclusive)' do
          [10, 100, 1000, 647_218_456].each do |maximum|
            100.times do
              expect(prng.generate_integer(maximum)).to be_an_integer_in(0...maximum)
            end
          end
        end

        it 'generates integers within a range larger than 2**128' do
          results = (0..100).map do
            prng.generate_integer(2**1024)
          end
          expect(results).to all be_an_integer_in(0...(2**1024))
        end

        it 'can generate integers larger than 2**1020' do
          results = (0..100).map { prng.generate_integer(2**1024) }
          expect(results.select { |n| n > 2**1020 }.count).to be > 50
        end

        it 'returns different integers without adjustments when the upper bound is large' do
          expect(Set[*(1..100).map { prng.generate_integer((2**75) - 7) }].size).to be 100
        end

        it 'covers a distribution 0...top' do
          expect(Set[*(1..100).map { prng.generate_integer(10) }].size).to be 10
        end

        [[10, %w[jkffwe]], [100, %w[jkffweefewg]], [1000, %w[jkffweefewg efhwjkfgw]],
         [647_218_456, %w[j*****g efhwjkfgw]]].each do |maximum, adjustments|
          it "returns integers below #{maximum}" do
            100.times do
              expect(prng.generate_integer(maximum, *adjustments)).to be_an_integer_in(0...maximum)
            end
          end
        end

        it 'returns different integers with adjustments when the upper bound is large' do
          expect(Set[*(1..100).map { prng.generate_integer((2**80) - 5, '654321') }].size).to be 100
        end

        it_behaves_like 'an adjustable reader', prng,
                        ->(reader, *args) { reader.generate_integer((2**64) - 3, *args) }
      end

      describe 'all read methods' do
        it 'generate higher and lower values in sync' do
          orders = reader_orders(prng)
          expect(orders).to match(
            int: orders[:hex], hex: orders[:hex], float: orders[:hex],
            num: orders[:bytes], bytes: orders[:bytes]
          )
        end
      end
    end
  end

  describe 'using predictable sequences' do
    let(:prng) { described_class.new(1, "\x0" * 64) }

    let(:zeroed_sequence) do
      %w[da0cd77eb1c84458ddcc91e36b9dcb35
         498ec24d1126440047eed396d836b5e1 0b90df55c5e7c1513b072367eae4a4ce
         f12b5b54b5594e785bbb9a4ac50ccec8 d506bd4e201a00dc30499bd8e59a30d8
         2557893cf995fe43bd00721fce6ab16a 41ee50244cdd02334bafc3e9d8f564d9
         8156c7c7bcfd856cb9d1012243cfc662 1116f840e2aee924bd2c7d722c602635
         96cf31967465b83f5ef3476c60afe20a f041f6df72aa2eab7394f08e83d52a0c
         5ccbb30077f2433bd765ddc86840a880 6a4339fd5d445024048ea8f91a3e02fd
         707e9499b9f0e9e906a0c0ddd0530803 553704d95703284df323f0aa4244cf81
         cb1522ce0bdf2504fdd62df7416be73e 05c4932cb9d3a7c0675b0228826e661a
         59606f23e34e726a7912dacfde533d97 188cf17dde6947264ce05f8274874ffa
         24c184b56453891657953f557635b742 a5f969e50228b2ee0f38cc37c5033541
         f1de0e5d149cc5a7f0e38c0ee501d7bc 5ca3a6beb0b810568be83ab2179eb550
         756fb9c58277eb8c6092142224caecf4 0ed9505eadb3def60ec42051f0bf15ef]
    end

    let(:alternating_sequence) do
      %w[
        da0cd77eb1c84458ddcc91e36b9dcb35 de4b20a0560263090c6fe11ebba6256e
        0b90df55c5e7c1513b072367eae4a4ce 0c92d534160cb268cb3282a9dd3f1efe
        d506bd4e201a00dc30499bd8e59a30d8 089f799236a9cf64f22f1deafbe28214
        41ee50244cdd02334bafc3e9d8f564d9 84477b9a3d51bb72868ccb85bea71cad
        1116f840e2aee924bd2c7d722c602635 469e4bb2f38719c7f85d79c8900a8fa8
        f041f6df72aa2eab7394f08e83d52a0c e21bf2508b8e1755ae70c74c0d36ec2e
        6a4339fd5d445024048ea8f91a3e02fd a94a80c80c9edd95808a67775c2b42d4
        553704d95703284df323f0aa4244cf81 edd6aea5bda7b2d9c494067c5cdbe410
        05c4932cb9d3a7c0675b0228826e661a cf81635ca2fa910fd11cf45508dc658b
        188cf17dde6947264ce05f8274874ffa bb4aaeb98e13400c1216c674a872ba93
        a5f969e50228b2ee0f38cc37c5033541 1a795355f979575247b3fa9c92d97917
        5ca3a6beb0b810568be83ab2179eb550 1a98419cca1dd1b370ce8a4a2ab721b7
        0ed9505eadb3def60ec42051f0bf15ef
      ]
    end
    let(:adjusted_sequence) do
      %w[
        fed9de9a612f4157ebb49582ca557a50 a7adc2374a4df2ed67846ac09a3b6645
        cbdf8bbbe6145751fe14004719915160 8cd84be95376f72918c305bdea43e36d
        9e08e80ff40c942f0cf4d479b5378fa0 54d80c5330873f9733a0adef0197220f
        2abe07bd85d2066a624dd3630e59730a 88b6a697fe74aeb8ec83845e103b7b63
        9c6c9d613855f6535adb419cc564fd10 23f9b778b254035a0e4219423a52da77
        4cd50c14ee17fa29c8b1f209432a36b3 2b5646b164d863de716f67adef653859
        fd81d0bbbd2828ecdfcba0b486ef786c 08e6594fc277ff7fafbf37475ecadbf6
        5e2333ecc800eb9a06e347924ed42e94 8a14e48013028b2c9f174a07ddd5ef49
        e9a5c331f54b155f570c2cf2bcd37209 1ce84279195a5b23ffeb3063edbfab21
        7422e19e58f2fcf20805f601266bf676 8df0226465b74d830360ea8609d181bf
        3e5d5e8cf8ad032fb4005826bdf7bb94 65e3f9ab28c26bead6647c21bcc6245e
        8ed5d8892d464ebeaa8dcbcef0968936 2f000bc1ab14d914196cc1d5055db189
        8e9c4b8152f14e47ac31f25a80765ebf
      ]
    end

    it 'generates expected hex strings from simple zeroed pool' do
      expect((0..24).map { prng.read_hex }).to eql zeroed_sequence
    end

    it 'generates expected hex strings from simple zeroed pool and an adjustment' do
      expect((0..24).map { prng.read_hex('bananas') }).to eql adjusted_sequence
    end

    it 'generates expected hex strings from simple zeroed pool and alternating adjustments' do
      results = (0..24).map { |index| index.odd? ? prng.read_hex('bananas', index.to_s) : prng.read_hex }
      expect(results).to eql alternating_sequence
    end
  end
end
