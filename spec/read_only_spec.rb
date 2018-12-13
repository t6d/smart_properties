# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SmartProperties, 'read only properties' do
  context 'when a property is defined as read_only there should be no accessor for the property' do
    subject(:klass) { DummyClass.new { property :id, read_only: true } }

    it "should throw a no method error when trying to set the property" do
      new_class_instance = klass.new(id: 42)

      expect(new_class_instance.id).to eq(42)
      expect { new_class_instance.id = 50 }.to raise_error(NoMethodError)
      expect(new_class_instance.id).to eq(42)
    end
  end

  context 'when a property is defined as not read_only there should be an accessor available' do
    subject(:klass) { DummyClass.new { property :id, read_only: false } }

    it "should allow changing of the property" do
      new_class_instance = klass.new(id: 42)

      new_class_instance.id = 50
      expect(new_class_instance.id).to eq(50)
    end
  end

  context 'when read_only is not defined on the property it should default to being writable' do
    subject(:klass) { DummyClass.new { property :id } }

    it "should allow changing of the property" do
      new_class_instance = klass.new(id: 42)

      new_class_instance.id = 50
      expect(new_class_instance.id).to eq(50)
    end
  end
end
