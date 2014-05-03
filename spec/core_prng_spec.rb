require 'pool_of_entropy'

describe PoolOfEntropy::CorePRNG do
  describe "class methods" do

    describe "#new" do
      it "should instantiate a default object" do
        PoolOfEntropy::CorePRNG.new.should be_a PoolOfEntropy::CorePRNG
      end
    end
  end

end
