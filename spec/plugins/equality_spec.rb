require 'spec_helper'

RSpec.describe "Equality plugin" do
  SmartPropertiesWithEqualityPlugin = SmartProperties(
    SmartProperties::Plugins::Initializer,
    SmartProperties::Plugins::Equality
  )
  it "supports comparing objects of the same type that don't have any properties" do
    test_class = Class.new do
      include SmartPropertiesWithEqualityPlugin
    end

    expect(test_class.new).to eq(test_class.new)
  end

  it "considers objects of different type with a common ancestor not equal" do
    test_class = Class.new do
      include SmartPropertiesWithEqualityPlugin
    end
    test_sub_class = Class.new(test_class) {}

    expect(test_class.new).to_not eq(test_sub_class.new)
  end

  it "determines equality by comparing each property" do
    test_class = Class.new do
      include SmartPropertiesWithEqualityPlugin
      property :name
    end

    value = Class.new(BasicObject) do
      def ==(_)
        true
      end
    end

    expect(test_class.new(name: value.new))
      .to eq(test_class.new(name: "irrelevant for this test"))
  end
end
