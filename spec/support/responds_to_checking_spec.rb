require 'spec_helper'

RSpec.describe SmartProperties, 'responds to checking' do
  context "when used to build a class that has a property called :title which uses an array of valid method names" do
    subject(:klass) { DummyClass.new { property :actor, responds_to: [:method_1, :method_2] } }

    context "an instance of this class" do
      subject(:instance) { klass.new }

      it "should not allow an object missing method_1 or method_2 from being set as value for actor" do
        expect { instance.actor = 0 }.to raise_error
      end

      it "should allow an object with method_1 and method_2 to be set as value for actor" do
        expect { instance.actor = Actor }.to_not raise_error
      end

      class Actor
        def self.method_1
        end
        def self.method_2
        end
      end
    end
  end
end
