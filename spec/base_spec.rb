require 'spec_helper'

RSpec.describe SmartProperties do
  it 'should add a protected class method called .property when included' do
    klass = Class.new { include SmartProperties }
    expect(klass.respond_to?(:property, true)).to eq(true)
    expect { klass.property }.to raise_error(NoMethodError)
  end

  context "when used to build a class with a property that uses none of the features provided by SmartProperties" do
    subject(:klass) { DummyClass.new { property :title } }

    context "an instance of this class" do
      it 'should accept an instance of BasicObject, which does not respond to nil?, as value for title' do
        instance = klass.new
        expect { instance.title = BasicObject.new }.to_not raise_error
        expect { instance[:title] = BasicObject.new }.to_not raise_error

        expect { instance = klass.new(title: BasicObject) }.to_not raise_error
      end
    end
  end

  context "when used to build a class that has a property called title that utilizes the full feature set of SmartProperties" do
    subject(:klass) do
      default_title = double(to_title: 'chunky')

      DummyClass.new do
        property :title, converts: :to_title, accepts: String, required: true, default: default_title
      end
    end

    it { is_expected.to have_smart_property(:title) }

    context "an instance of this class when initialized with no arguments" do
      subject(:instance) { klass.new }

      it "should have the default title" do
        expect(instance.title).to eq('chunky')
        expect(instance[:title]).to eq('chunky')
      end

      it "should convert all values that are assigned to title into strings when using the #title= method" do
        instance.title = double(to_title: 'bacon')
        expect(instance.title).to eq('bacon')

        instance[:title] = double(to_title: 'yummy')
        expect(instance.title).to eq('yummy')
      end

      it "should not allow to assign an object as title that do not respond to #to_title" do
        exception = NoMethodError
        message = /undefined method `to_title'/

        expect { instance.title = Object.new }.to raise_error(exception, message)
        expect { instance[:title] = Object.new }.to raise_error(exception, message)
      end

      it "should not allow to assign nil as the title" do
        exception = SmartProperties::MissingValueError
        message = "Dummy requires the property title to be set"
        further_expectations = lambda do |error|
          expect(error.to_hash[:title]).to eq('must be set')
        end

        expect { instance.title = nil }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = nil }.to raise_error(exception, message, &further_expectations)

        expect { instance.title = double(to_title: nil) }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = double(to_title: nil) }.to raise_error(exception, message, &further_expectations)
      end

      it "should not influence other instances that have been initialized with different attributes" do
        other_instance = klass.new title: double(to_title: 'Lorem ipsum')

        expect(instance.title).to eq('chunky')
        expect(other_instance.title).to eq('Lorem ipsum')
      end
    end

    context 'an instance of this class when initialized with a null object' do
      let(:null_object) do
        Class.new(BasicObject) do
          def nil?
            true
          end
        end
      end

      it 'should raise an error during initialization' do
        exception = SmartProperties::MissingValueError
        message = "Dummy requires the property title to be set"
        further_expectations = lambda do |error|
          expect(error.to_hash[:title]).to eq('must be set')
        end

        instance = klass.new
        expect { instance.title = null_object.new }.to raise_error(exception, message, &further_expectations)
        expect { instance[:title] = null_object.new }.to raise_error(exception, message, &further_expectations)

        expect { klass.new(title: null_object.new) }.to raise_error(exception, message, &further_expectations)
      end
    end

    context 'an instance of this class when initialized with a subclass of BasicObject that responds to #to_title but by design not to #nil?' do
      let(:title) do
        Class.new(BasicObject) do
          def to_title
            "Chunky bacon"
          end
        end
      end

      it 'should have the correct title' do
        instance = klass.new(title: title.new)
        expect(instance.title).to eq("Chunky bacon")
      end
    end

    context 'an instance of this class when initialized with a title argument' do
      it "should have the title specified by the corresponding keyword argument" do
        instance = klass.new(title: double(to_title: 'bacon'))
        expect(instance.title).to eq('bacon')
        expect(instance[:title]).to eq('bacon')
      end

      it "should have the title specified in the corresponding attributes hash that uses strings as keys" do
        attributes = {"title" => double(to_title: 'bacon')}
        instance = klass.new(attributes)
        expect(instance.title).to eq('bacon')
        expect(instance[:title]).to eq('bacon')
      end
    end

    context "an instance of this class when initialized with a block" do
      it "should have the title specified in the block" do
        instance = klass.new do |c|
          c.title = double(to_title: 'bacon')
        end
        expect(instance.title).to eq('bacon')
        expect(instance[:title]).to eq('bacon')
      end
    end
  end
end
