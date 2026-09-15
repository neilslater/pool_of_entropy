# frozen_string_literal: true

require 'spec_helper'
require_relative 'support/byte_input_examples'

describe PoolOfEntropy do
  let(:pool) { described_class.new(blank: true).modify_all('fixed').modify_next('queued', nil, 'last') }

  describe '.new' do
    before do
      allow(SecureRandom).to receive(:random_bytes) { |length| "\0" * length }
    end

    [1, 256, '1', '256', 1.0, 1.5, 256.9].each do |size|
      it "uses normalized size #{size.inspect} for default entropy" do
        described_class.new(size: size)
        expect(SecureRandom).to have_received(:random_bytes).with(Integer(size) * 64).once
      end

      it "uses normalized size #{size.inspect} for blank state" do
        actual = described_class.new(size: size, blank: true)
        expected = described_class.new(size: Integer(size), blank: true)
        expect(outputs_match?(actual, expected)).to be true
      end
    end

    [0, -1, 257, '257'].each do |size|
      it "rejects size #{size.inspect} before requesting entropy" do
        allow(SecureRandom).to receive(:random_bytes).and_raise('Unexpected entropy allocation')
        expect { described_class.new(size: size) }.to raise_error(ArgumentError)
      end
    end

    it 'converts a coercible size only once' do
      size = instance_double(Integer, to_int: 2)
      described_class.new(size: size)
      expect(size).to have_received(:to_int).once
    end

    [nil, false].each do |size|
      it "retains the default size for #{size.inspect}" do
        described_class.new(size: size)
        expect(SecureRandom).to have_received(:random_bytes).with(64).once
      end
    end

    it_behaves_like 'byte-preserving input', lambda { |input|
      prng = described_class.new(blank: true, seeds: ['first', input])
      Array.new(3) { prng.rand }
    }
  end

  %i[add_to_pool modify_all modify_next].each do |method|
    describe "##{method}" do
      it_behaves_like 'byte-preserving input', lambda { |input|
        prng = described_class.new(blank: true)
        prng.rand
        prng.public_send(method, input)
        Array.new(3) { prng.rand }
      }

      it 'retains string conversion convenience' do
        copy = pool.clone
        pool.public_send(method, instance_double(Object, to_s: 'café'))
        copy.public_send(method, 'café'.b)
        expect(outputs_match?(pool, copy)).to be true
      end

      it 'retains state and existing modifiers when conversion raises' do
        copy = pool.clone
        input = instance_double(Object)
        allow(input).to receive(:to_s).and_raise(TypeError, 'Cannot convert')
        error = input_error_class { pool.public_send(method, input) }
        expect([error, outputs_match?(pool, copy)]).to eql [TypeError, true]
      end

      it 'retains state and existing modifiers when conversion returns a non-String' do
        copy = pool.clone
        error = input_error_class { pool.public_send(method, instance_double(Object, to_s: 123)) }
        expect([error, outputs_match?(pool, copy)]).to eql [TypeError, true]
      end

      it 'returns self for chaining' do
        expect(pool.public_send(method, 'input')).to equal pool
      end
    end
  end

  describe '#modify_next' do
    it 'retains the whole queue when a later conversion fails' do
      copy = pool.clone
      input = instance_double(Object)
      allow(input).to receive(:to_s).and_raise(TypeError, 'Cannot convert')
      error = input_error_class { pool.modify_next('valid', nil, input) }
      expect([error, outputs_match?(pool, copy)]).to eql [TypeError, true]
    end

    it 'retains the whole queue when a later conversion returns a non-String' do
      copy = pool.clone
      error = input_error_class { pool.modify_next('valid', nil, instance_double(Object, to_s: 123)) }
      expect([error, outputs_match?(pool, copy)]).to eql [TypeError, true]
    end

    it 'leaves the queue unchanged for an empty batch' do
      copy = pool.clone
      pool.modify_next
      expect(outputs_match?(pool, copy)).to be true
    end
  end
end
