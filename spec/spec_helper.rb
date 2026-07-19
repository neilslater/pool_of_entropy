# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
end

require 'pool_of_entropy'

RSpec::Matchers.define :be_a_float_in do |range|
  match { |actual| actual.is_a?(Float) && range.cover?(actual) }
end

RSpec::Matchers.define :be_an_integer_in do |range|
  match { |actual| actual.is_a?(Integer) && range.cover?(actual) }
end

RSpec::Matchers.define :change_only_block do |block_index|
  match do |states|
    before, after = states
    blocks = before.bytes.each_slice(64).to_a.zip(after.bytes.each_slice(64).to_a)
    blocks.each_with_index.all? { |pair, index| (pair.first != pair.last) == (index == block_index) }
  end
end

def outputs_match?(first, second, count: 10)
  count.times.all? { first.rand == second.rand }
end

def outputs_differ?(first, second, count: 10)
  count.times.all? { first.rand != second.rand }
end

def repeat_results(count = 10)
  Array.new(count) { Array(yield) }.flatten
end

def reader_orders(prng)
  readers = (0..4).map { prng.clone }
  results = (1..20).map do
    { bytes: readers[0].read_bytes, hex: readers[1].read_hex, float: readers[2].read_float,
      num: readers[3].read_bignum, int: readers[4].generate_integer(1_000_000_000) }
  end
  %i[int hex float num bytes].to_h { |key| [key, results.sort_by { |result| result[key] }] }
end

def state_lengths_after(prng, updates)
  updates.map do |data|
    prng.update(data)
    prng.state.length
  end
end
