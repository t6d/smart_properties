require 'spec_helper'

RSpec.describe "Hash plugin" do
  SmartPropertiesWithHashPlugin = SmartProperties(
    SmartProperties::Plugins::Initializer,
    SmartProperties::Plugins::HashSerialization,
  )

  SmartPropertiesWithHashPluginWithoutOptionals = SmartProperties(
    SmartProperties::Plugins::Initializer,
    SmartProperties::Plugins::HashSerialization.without_optionals,
  )
  it "adds a to_h method" do
    test_class = Class.new do
      include SmartPropertiesWithHashPlugin
    end

    expect(test_class.new).to respond_to(:to_h)
  end

  it "serializes all properties by default" do
    test_class = Class.new do
      include SmartPropertiesWithHashPlugin
      property :firstname
      property :lastname
    end

    test = test_class.new(firstname: "John", lastname: "Doe")
    expect(test.to_h).to eq({
      firstname: "John",
      lastname: "Doe"
    })
  end

  it "can be configured to exclude optional properties that are nil" do
    test_class = Class.new do
      include SmartProperties(
        SmartProperties::Plugins::Initializer,
        SmartProperties::Plugins::HashSerialization.without_optionals
      )
      property :firstname
      property :lastname
    end

    test = test_class.new(firstname: "John")
    expect(test.to_h).to eq({ firstname: "John" })
  end

  it "supports nested data structures" do
    employer_class = Class.new do
      include SmartPropertiesWithHashPlugin
      property :name
    end

    person_class = Class.new do
      include SmartPropertiesWithHashPlugin
      property :name
      property :employer
    end

    employer = employer_class.new(name: "Shopify")
    person = person_class.new(name: "John Doe", employer: employer)

    expect(person.to_h).to eq({
      name: "John Doe",
      employer: {
        name: "Shopify"
      }
    })

    expect(person_class.new(person.to_h).to_h).to eq(person.to_h)
  end

  it "supports deserializing nested data structures" do
    employer_class = Class.new do
      include SmartPropertiesWithHashPluginWithoutOptionals
      property :name
    end

    person_class = Class.new do
      include SmartPropertiesWithHashPluginWithoutOptionals
      property :name
      property :employer, converts: employer_class
      property :friends, converts: self
    end

    properties = {
      name: "John Doe",
      employer: {
        name: "Shopify"
      },
      friends: [{
        name: "Jane Doe"
      }]
    }

    expect(person_class.new(properties).to_h).to eq(properties)
  end
end
