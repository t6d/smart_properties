require 'spec_helper'

HashPlugin = SmartProperties::Plugin.new(:include) do
  def self.without_optionals
    original_plugin_implementation = self

    SmartProperties::Plugin.new(:include) do
      include original_plugin_implementation
      def to_hash
        super.compact
      end
    end
  end

  def self.with_optionals
    self
  end

  def to_h
    to_hash
  end

  def to_hash
    self.class.properties.each.reduce({}) do |data, (_, property)|
      data.merge(property.name => self.send(property.reader).yield_self do |value|
        value.respond_to?(:to_hash) ? value.to_hash : value
      end)
    end
  end
end

RSpec.describe "Hash plugin" do
  SmartPropertiesWithHashPlugin = SmartProperties(
    SmartProperties::Plugins::Initializer,
    HashPlugin,
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
        HashPlugin.without_optionals
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
end
