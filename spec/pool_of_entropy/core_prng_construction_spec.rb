# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/byte_input_examples'

describe PoolOfEntropy::CorePRNG do
  describe '.new' do
    before do
      allow(SecureRandom).to receive(:random_bytes) { |length| "\0" * length }
    end

    [1, 256, '1', '256', 1.0, 1.5, 256.9].each do |size|
      context "with size #{size.inspect}" do
        let(:normalized_size) { Integer(size) }

        it 'allocates default entropy using the normalized block count' do
          described_class.new(size)
          expect(SecureRandom).to have_received(:random_bytes).with(normalized_size * 64).once
        end

        it 'preserves the byte length through a full cycle of block updates' do
          prng = described_class.new(size, "\0" * normalized_size * 64, normalized_size - 1)
          lengths = [prng.state.bytesize] + state_lengths_after(prng, [nil] * (normalized_size + 1))
          expect([prng.size, prng.mix_block_id, lengths.uniq]).to eql [normalized_size, 0, [normalized_size * 64]]
        end
      end
    end

    { 0 => ArgumentError, -1 => ArgumentError, 257 => ArgumentError, '257' => ArgumentError,
      nil => TypeError, false => TypeError, 'bad' => ArgumentError }.each do |size, error|
      it "rejects size #{size.inspect} before requesting entropy" do
        allow(SecureRandom).to receive(:random_bytes).and_raise('Unexpected entropy allocation')
        expect { described_class.new(size) }.to raise_error(error)
      end
    end

    it 'converts a coercible size only once' do
      size = instance_double(Integer, to_int: 2)
      described_class.new(size)
      expect(size).to have_received(:to_int).once
    end

    it 'rejects state length based on the normalized size' do
      allow(SecureRandom).to receive(:random_bytes).and_raise('Unexpected entropy allocation')
      expect { described_class.new(1.5, "\0" * 96) }.to raise_error(ArgumentError, /expected 64 bytes, got 96 bytes/)
    end

    [nil, :state, [], Object.new].each do |state|
      it 'rejects non-String explicit state without inspecting it or requesting entropy' do
        allow(SecureRandom).to receive(:random_bytes).and_raise('Unexpected entropy allocation')
        unless state.nil? || state.is_a?(Symbol)
          allow(state).to receive(:inspect).and_raise('State must not be inspected')
        end
        expect { described_class.new(1, state) }.to raise_error(TypeError, 'Expected a String')
      end
    end

    { -1 => 2, 4 => 1, '5' => 2, 1.9 => 1 }.each do |index, expected|
      it "normalizes block index #{index.inspect} by integer conversion and modulo" do
        prng = described_class.new(3, "\0" * 192, index)
        expect(prng.mix_block_id).to eq expected
      end
    end

    it 'accepts a coercible block index' do
      index = instance_double(Integer, to_int: -2)
      prng = described_class.new(3, "\0" * 192, index)
      expect(prng.mix_block_id).to eq 1
    end

    { nil => TypeError, 'bad' => ArgumentError, false => TypeError }.each do |index, error|
      it "rejects invalid block index #{index.inspect} without requesting entropy" do
        allow(SecureRandom).to receive(:random_bytes).and_raise('Unexpected entropy allocation')
        expect { described_class.new(1, "\0" * 64, index) }.to raise_error(error)
      end
    end

    it 'does not request entropy for explicit state' do
      described_class.new(1, "\0" * 64)
      expect(SecureRandom).not_to have_received(:random_bytes)
    end

    it 'owns a mutable binary copy of explicit state' do
      input = 'a' * 64
      prng = described_class.new(1, input)
      copy = prng.clone
      input.replace('b' * 64)
      expect([prng.state.encoding, prng.state.frozen?, prng.read_hex]).to eql [Encoding::BINARY, false, copy.read_hex]
    end

    it_behaves_like 'byte-preserving input', lambda { |input|
      prng = described_class.new(1, input)
      Array.new(3) { prng.read_hex }
    }
  end
end
