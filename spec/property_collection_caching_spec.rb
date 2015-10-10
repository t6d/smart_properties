require 'spec_helper'

describe SmartProperties, "property collection caching:" do
  specify "SmartProperty enabled objects should be extendable at runtime" do
    base_class = DummyClass.new { property :title }
    subclass = DummyClass.new(base_class) { property :body }
    subsubclass = DummyClass.new(subclass) { property :attachment }

    expect(base_class.new).to have_smart_property(:title)
    expect(subclass.new).to have_smart_property(:title)
    expect(subclass.new).to have_smart_property(:body)

    base_class.class_eval { property :severity }
    expect(base_class.new).to have_smart_property(:severity)
    expect(subclass.new).to have_smart_property(:severity)
    expect(subsubclass.new).to have_smart_property(:severity)

    expected_names = [:title, :body, :attachment, :severity]

    names = subsubclass.properties.map(&:first) # Using enumerable
    expect(names - expected_names).to be_empty

    names = subsubclass.properties.each.map(&:first) # Using enumerator
    expect(names - expected_names).to be_empty

    expect(subsubclass.properties.keys - expected_names).to be_empty
    expect(subsubclass.properties.to_hash.keys - expected_names).to be_empty
  end
end
