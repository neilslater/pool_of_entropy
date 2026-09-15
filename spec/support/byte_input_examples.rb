# frozen_string_literal: true

def input_error_class
  yield
  nil
rescue TypeError, ArgumentError => e
  e.class
end

shared_examples 'byte-preserving input' do |operation|
  {
    'ASCII' => 'a' * 64,
    'UTF-8 text' => "#{'café' * 12}abcd",
    'UTF-16LE text' => ('é' * 32).encode('UTF-16LE'),
    'UTF-32BE text' => ('😀' * 16).encode('UTF-32BE'),
    'binary data' => ([0, 255, 128, 65].pack('C*') * 16),
    'NUL bytes' => "\0" * 64,
    'invalid UTF-8' => "\xff\0" * 32
  }.each do |label, sample|
    [false, true].each do |frozen_input|
      context "with #{frozen_input ? 'frozen' : 'mutable'} #{label}" do
        let(:input) { frozen_input ? sample.dup.freeze : sample.dup }

        it 'produces the same output as the identical binary bytes' do
          result = instance_exec(input, &operation)
          expect(result).to eql instance_exec(input.b, &operation)
        end

        it 'preserves the caller string contents, encoding and frozen status' do
          instance_exec(input, &operation)
          expect([input.bytes == sample.bytes, input.encoding, input.frozen?]).to eql(
            [true, sample.encoding, frozen_input]
          )
        end
      end
    end
  end
end
