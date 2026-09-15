# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/byte_input_examples'

describe PoolOfEntropy::CorePRNG do
  let(:prng) { described_class.new(2, "\0" * 128, 1) }

  describe '#update' do
    it_behaves_like 'byte-preserving input', lambda { |input|
      prng = described_class.new(1, "\0" * 64)
      prng.read_bytes
      prng.update(input)
      Array.new(3) { prng.read_hex }
    }

    it 'converts objects to strings' do
      copy = prng.clone
      prng.update(instance_double(Object, to_s: 'café'))
      copy.update('café'.b)
      expect(prng.read_hex).to eql copy.read_hex
    end

    it 'treats nil as an empty string and advances the block index' do
      copy = prng.clone
      prng.update(nil)
      copy.update('')
      expect([prng.mix_block_id, prng.read_hex]).to eql [0, copy.read_hex]
    end

    it 'preserves state when conversion raises' do
      copy = prng.clone
      input = instance_double(Object)
      allow(input).to receive(:to_s).and_raise(TypeError, 'Cannot convert')
      error = input_error_class { prng.update(input) }
      expect([error, prng.mix_block_id, prng.read_hex]).to eql [TypeError, copy.mix_block_id, copy.read_hex]
    end

    it 'preserves state when conversion returns a non-String' do
      copy = prng.clone
      error = input_error_class { prng.update(instance_double(Object, to_s: 123)) }
      expect([error, prng.mix_block_id, prng.read_hex]).to eql [TypeError, copy.mix_block_id, copy.read_hex]
    end
  end

  { read_bytes: [], read_hex: [], read_bignum: [], read_float: [],
    generate_integer: [(2**160) - 7] }.each do |method, args|
    describe "##{method}" do
      it_behaves_like 'byte-preserving input', lambda { |input|
        prng = described_class.new(1, "\0" * 64)
        Array.new(3) { prng.public_send(method, *args, 'first', nil, input) }
      }

      it 'ignores nil adjustments' do
        copy = prng.clone
        expect(prng.public_send(method, *args, nil, 'value', nil)).to eql copy.public_send(method, *args, 'value')
      end

      it 'rejects a later non-String adjustment without advancing state' do
        copy = prng.clone
        error = input_error_class { prng.public_send(method, *args, 'valid', Object.new) }
        expect([error, prng.mix_block_id, prng.read_hex]).to eql [TypeError, copy.mix_block_id, copy.read_hex]
      end

      it 'rejects objects with string conversion methods as direct adjustments' do
        input = instance_double(String, to_str: 'text', to_s: 'text')
        expect { prng.public_send(method, *args, input) }.to raise_error(TypeError)
      end
    end
  end
end
