require 'spec_helper'

describe SmartProperties do

  context "when extending an other class" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
      end
    end

    it "should add a .property method" do
      expect(klass.respond_to?(:property, true)).to be_truthy
    end

    context "and defining a property with invalid configuration options" do
      it "should raise an error reporting one invalid option when one invalid option was given" do
        expect {
          klass.tap do |c|
            c.instance_eval do
              property :title, :invalid_option => 'boom'
            end
          end
        }.to raise_error(ArgumentError, "SmartProperties do not support the following configuration options: invalid_option.")
      end

      it "should raise an error reporting three invalid options when three invalid options were given" do
        expect {
          klass.tap do |c|
            c.instance_eval do
              property :title, :invalid_option_1 => 'boom', :invalid_option_2 => 'boom', :invalid_option_3 => 'boom'
            end
          end
        }.to raise_error(ArgumentError, "SmartProperties do not support the following configuration options: invalid_option_1, invalid_option_2, invalid_option_3.")
      end
    end
  end

  context "when used to build a class that has a property called :title" do
    subject(:klass) do
      title = Object.new.tap do |o|
        def o.to_title; 'chunky'; end
      end

      klass = Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          def name; "TestDummy"; end

          property :title, :accepts => String,
                                 :converts => :to_title,
                                 :required => true,
                                 :default => title
        end
      end

      klass
    end

    let(:superklass) { klass }

    it { is_expected.to have_smart_property(:title) }

    context "instances of this class" do
      subject(:instance) { klass.new }

      it { is_expected.to respond_to(:title) }
      it { is_expected.to respond_to(:title=) }

      it "should have 'chunky' as default value for title when accessed using the #title method" do
        expect(instance.title).to eq('chunky')
      end

      it "should have 'chunky' as default value for title when accessed using the #[] method" do
        expect(instance[:title]).to eq('chunky')
      end

      it "should convert all values that are assigned to title into strings when using the #title= method" do
        instance.title = double(:to_title => 'bacon')
        expect(instance.title).to eq('bacon')
      end

      it "should convert all values that are assigned to title into strings when using the #[]= method" do
        instance[:title] = double(:to_title => 'bacon')
        expect(instance.title).to eq('bacon')
      end

      it "should not allow to set nil as title" do
        expect { instance.title = nil }.to raise_error(ArgumentError, "TestDummy requires the property title to be set")
      end

      it "should not allow to set objects as title that do not respond to #to_title" do
        expect { instance.title = Object.new }.to raise_error(NoMethodError, /undefined method `to_title'/)
      end

      it "should not influence other instances that have been initialized with different attributes" do
        other_instance = klass.new :title => double(:to_title => 'Lorem ipsum')

        expect(instance.title).to eq('chunky')
        expect(other_instance.title).to eq('Lorem ipsum')
      end

      context "when initialized with a block" do
        subject(:instance) do
          klass.new do |c|
            c.title = double(:to_title => 'bacon')
          end
        end

        it "should have the title specified in the block" do
          expect(instance.title).to eq('bacon')
        end
      end
    end

    context "when subclassed" do
      subject(:subklass) { Class.new(superklass) }

      it { is_expected.to have_smart_property(:title) }

      context "instances of this subclass" do
        subject(:instance) { subklass.new }

        it { is_expected.to respond_to(:title) }
        it { is_expected.to respond_to(:title=) }
      end

      context "instances of this subclass that have been intialized from a set of attributes" do
        subject(:instance) { subklass.new :title => double(:to_title => 'Message') }

        it "should have the correct title" do
          expect(instance.title).to eq('Message')
        end
      end
    end

    context "when subclassed and extended with a property called text" do
      subject(:subklass) do
        Class.new(superklass).tap do |c|
          c.instance_eval do
            property :text
          end
        end
      end

      it { is_expected.to have_smart_property(:title) }
      it { is_expected.to have_smart_property(:text) }

      context "instances of this subclass" do
        subject(:instance) { subklass.new }

        it { is_expected.to respond_to(:title) }
        it { is_expected.to respond_to(:title=) }
        it { is_expected.to respond_to(:text) }
        it { is_expected.to respond_to(:text=) }
      end

      context "instances of the super class" do
        subject(:instance) { superklass.new }

        it { is_expected.not_to respond_to(:text) }
        it { is_expected.not_to respond_to(:text=) }
      end

      context "instances of this subclass" do
        context "when initialized with a set of attributes" do
          subject(:instance) { subklass.new :title => double(:to_title => 'Message'), :text => "Hello" }

          context "when properties are accessed using the dedicated instance methods" do
            it("should have the correct title") { expect(instance.title).to eq('Message') }
            it("should have the correct text") { expect(instance.text).to eq('Hello') }
          end

          context "when properties are accessed using the index methods" do
            it("should have the correct title") { expect(instance[:title]).to eq('Message') }
            it("should have the correct text") { expect(instance[:text]).to eq('Hello') }
          end
        end

        context "when initialized with a block" do
          subject(:instance) do
            subklass.new do |c|
              c.title = double(:to_title => 'Message')
              c.text = "Hello"
            end
          end

          it("should have the correct title") { expect(instance.title).to eq('Message') }
          it("should have the correct text") { expect(instance.text).to eq('Hello') }
        end
      end
    end

    context "when extended with a :type property at runtime" do
      before do
        superklass.tap do |c|
          c.instance_eval do
            property :type, :converts => :to_sym
          end
        end
      end

      it { is_expected.to have_smart_property(:title) }
      it { is_expected.to have_smart_property(:type) }

      context "instances of this class" do
        subject(:instance) { superklass.new :title => double(:to_title => 'Lorem ipsum') }

        it { is_expected.to respond_to(:type)  }
        it { is_expected.to respond_to(:type=) }
      end

      context "when subclassing this class" do
        subject(:subclass) { Class.new(superklass) }

        context "instances of this class" do
          subject(:instance) { subclass.new :title => double(:to_title => 'Lorem ipsum') }

          it { is_expected.to respond_to :title }
          it { is_expected.to respond_to :title= }
          it { is_expected.to respond_to :type }
          it { is_expected.to respond_to :type= }
        end
      end
    end
  end

  context "when used to build a class that has a property called :title that uses a lambda statement for conversion" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          property :title, :converts => lambda { |t| "<title>#{t.to_s}</title>"}
        end
      end
    end

    context "instances of this class" do
      subject(:instance) { klass.new }

      it "should convert the property title as specified the lambda statement" do
        instance.title = "Lorem ipsum"
        expect(instance.title).to eq("<title>Lorem ipsum</title>")
      end
    end
  end

  context "when used to build a class that has a property called :title that uses an object that responds to #to_proc for conversion" do
    subject(:klass) do
      converter = Object.new.tap do |o|
        def o.to_proc
          lambda { |t| "<title>#{t.to_s}</title>"}
        end
      end

      Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          property :title, :converts => converter
        end
      end
    end

    context "instances of this class" do
      subject(:instance) { klass.new }

      it "should convert the property title as specified the lambda statement" do
        instance.title = "Lorem ipsum"
        expect(instance.title).to eq("<title>Lorem ipsum</title>")
      end
    end
  end

  context "when used to build a class that has a property called :visible which uses an array of valid values for acceptance checking" do
    subject(:klass) do
      Class.new.tap do |c|
        def c.name; "TestDummy"; end

        c.send(:include, described_class)

        c.instance_eval do
          property :visible, :accepts => [true, false]
        end
      end
    end

    context "instances of this class" do
      subject(:instance) { klass.new }

      context "when properties are accessed using the dedicated instance methods" do
        it "should allow to set true as value for visible" do
          expect { instance.visible = true }.to_not raise_error
        end

        it "should allow to set false as value for visible" do
          expect { instance.visible = false }.to_not raise_error
        end

        it "should not allow to set :maybe as value for visible" do
          expect { instance.visible = :maybe }.to raise_error(ArgumentError, "TestDummy does not accept :maybe as value for the property visible")
        end
      end

      context "when properties are accessed using the index methods" do
        it "should allow to set true as value for visible" do
          expect { instance[:visible] = true }.to_not raise_error
        end

        it "should allow to set false as value for visible" do
          expect { instance[:visible] = false }.to_not raise_error
        end

        it "should not allow to set :maybe as value for visible" do
          expect { instance[:visible] = :maybe }.to raise_error(ArgumentError, "TestDummy does not accept :maybe as value for the property visible")
        end
      end
    end
  end

  context "when used to build a class that has a property called :title that can either be a String or a Symbol" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          property :title, accepts: [String, Symbol]
        end
      end
    end

    context "intance of this class" do
      subject(:instance) { klass.new }

      context "when properties are accessed using the dedicated instance methods" do
        it "should accept a String as title" do
          expect { subject.title = "Test" }.to_not raise_error
        end

        it "should accept a Symbol as title" do
          expect { subject.title = :test }.to_not raise_error
        end
      end

      context "when properties are accessed using the index methods" do
        it "should accept a String as title" do
          expect { subject[:title] = "Test" }.to_not raise_error
        end

        it "should accept a Symbol as title" do
          expect { subject[:title] = :test }.to_not raise_error
        end
      end
    end
  end

  context 'when used to build a class that has a property called :license_plate which uses a lambda statement for accpetance checking' do
    subject(:klass) do
      Class.new.tap do |c|
        def c.name; 'TestDummy'; end

        c.send(:include, described_class)

        c.instance_eval do
          property :license_plate, :accepts => lambda { |v| /\w{1,2} \w{1,2} \d{1,4}/.match(v) }
        end
      end
    end

    context 'instances of this class' do
      subject(:instance) { klass.new }

      context "when properties are accessed using the dedicated instance methods" do
        it 'should not a accept "invalid" as value for license_plate' do
          expect { instance.license_plate = "invalid" }.to raise_error(ArgumentError, 'TestDummy does not accept "invalid" as value for the property license_plate')
        end

        it 'should accept "NE RD 1337" as license plate' do
          expect { instance.license_plate = "NE RD 1337" }.to_not raise_error
        end
      end

      context "when properties are accessed using the index methods" do
        it 'should not a accept "invalid" as value for license_plate' do
          expect { instance[:license_plate] = "invalid" }.to raise_error(ArgumentError, 'TestDummy does not accept "invalid" as value for the property license_plate')
        end

        it 'should accept "NE RD 1337" as license plate' do
          expect { instance[:license_plate] = "NE RD 1337" }.to_not raise_error
        end
      end
    end
  end

  context 'when used to build a class that has a property called :text whose getter is overriden' do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)

        c.instance_eval do
          property :text, :default => 'Hello'
        end

        c.class_eval do
          def text
            "<em>#{super}</em>"
          end
        end
      end
    end

    context "instances of this class" do
      subject(:instance) { klass.new }

      context "when properties are accessed using the dedicated instance methods" do
        it "should return the accepted value for the property called :text" do
          expect(instance.text).to eq('<em>Hello</em>')
        end
      end

      context "when properties are accessed using the index methods" do
        it "should return the accepted value for the property called :text" do
          expect(instance[:text]).to eq('<em>Hello</em>')
        end
      end
    end
  end

  context 'when used to build a class that has a property called :id whose default value is a lambda statement' do
    subject(:klass) do
      counter = Class.new.tap do |c|

        c.class_eval do
          def next
            @counter ||= 0
            @counter += 1
          end
        end

      end.new

      Class.new.tap do |c|
        c.send(:include, described_class)

        c.instance_eval do
          property :id, :default => lambda { counter.next }
        end
      end
    end

    context "instances of this class" do
      it "should have auto-incrementing ids" do
        first_instance = klass.new
        second_instance = klass.new

        expect(second_instance.id - first_instance.id).to eq(1)
      end
    end
  end

  context 'when used to build a class that is then subclassed and later extended at runtime' do
    let!(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title)
      end
    end

    let!(:subklass) do
      Class.new(klass).tap do |c|
        c.send(:property, :body)
      end
    end

    before do
      klass.tap do |c|
        c.send(:property, :priority)
      end
    end

    context "the class" do
      subject { klass }

      it { is_expected.to have_smart_property(:title) }
      it { is_expected.to have_smart_property(:priority) }
    end

    context 'the subclass' do
      subject { subklass }

      it { is_expected.to have_smart_property(:title) }
      it { is_expected.to have_smart_property(:body) }
      it { is_expected.to have_smart_property(:priority) }

      it "should be initializable using a block" do
        configuration_instructions = lambda do |s|
          s.title = "Lorem Ipsum"
          s.priority = :low
          s.body = "Lorem ipsum dolor sit amet."
        end

        expect { subklass.new(&configuration_instructions) }.to_not raise_error
      end

      it "should be initializable using a hash of attributes" do
        attributes = {
          :title => "Lorem Ipsum",
          :priority => :low,
          :body => "Lorem ipsum dolor sit amet."
        }

        expect { subklass.new(attributes) }.to_not raise_error
      end
    end
  end

  context "when building a class that has a property which is not required and has a default" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title, :default => 'Lorem Ipsum')
      end
    end

    context 'instances of that class' do
      context 'when created with a set of attributes that explicitly contains nil for the title' do
        subject(:instance) { klass.new :title => nil }

        it "should have no title" do
          expect(instance.title).to be_nil
        end
      end

      context 'when created without any arguments' do
        subject(:instance) { klass.new }

        context "when properties are accessed using the index methods" do
          it "should have the default title" do
            expect(instance.title).to eq('Lorem Ipsum')
          end
        end

        context "when properties are accessed using the index methods" do
          it "should have the default title" do
            expect(instance[:title]).to eq('Lorem Ipsum')
          end
        end
      end

      context 'when created with an empty block' do
        subject(:instance) { klass.new {} }

        context "when properties are accessed using the index methods" do
          it "should have the default title" do
            expect(instance.title).to eq('Lorem Ipsum')
          end
        end

        context "when properties are accessed using the index methods" do
          it "should have the default title" do
            expect(instance[:title]).to eq('Lorem Ipsum')
          end
        end
      end
    end
  end

  context "when building a class that has a property which is required and has no default" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :title, :required => true)

        def c.name; "Dummy"; end
      end
    end

    context 'instances of that class' do
      context 'when created with a set of attributes that contains a title' do
        subject(:instance) { klass.new :title => 'Lorem Ipsum' }

        it "should have the correct title" do
          expect(instance.title).to eq('Lorem Ipsum')
        end
      end

      context 'when created with an block specifying that property' do
        subject(:instance) { klass.new { |i| i.title = 'Lorem Ipsum' } }

        it "should have the default title" do
          expect(instance.title).to eq('Lorem Ipsum')
        end
      end

      context "when created with no arguments" do
        it "should raise an error stating that required properties are missing" do
          expect { klass.new }.to raise_error(ArgumentError, "Dummy requires the following properties to be set: title")
        end
      end
    end
  end

  context "when building a class that has a property which is required depending on the value of another property" do
    subject(:klass) do
      described_class = self.described_class

      Class.new do
        include described_class
        property :name, :required => lambda { not anonymous }
        property :anonymous, accepts: [true, false], default: true
        def self.name; "Dummy"; end
      end
    end

    context "when created with no arguments" do
      it "should not raise an error" do
        expect { klass.new }.to_not raise_error
      end
    end

    context "when created with no name and anonymous being set to false" do
      it "should raise an error indicating that a required property was not specified" do
        expect { klass.new anonymous: false }.to raise_error(ArgumentError, "Dummy requires the following properties to be set: name")
      end
    end

    context "when created with a name and anonymous being set to false" do
      it "should not raise an error" do
        expect { klass.new name: "John Doe", anonymous: false }.to_not raise_error
      end
    end
  end

  context "when building a class that has a property which is required and has false as default" do
    subject(:klass) do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.send(:property, :flag, :required => true, :default => false)

        def c.name; "Dummy"; end
      end
    end

    context 'instances of that class' do
      context 'when created with a set of attributes that explicitly contains nil for the title' do
        subject(:instance) { klass.new :flag => true }

        it "should have no title" do
          expect(instance.flag).to be_truthy
        end
      end

      context 'when created with an block specifying that property' do
        subject(:instance) { klass.new { |i| i.flag = true } }

        context "when properties are accessed using the dedicated instance methods" do
          it "should have the default title" do
            expect(instance.flag).to be(true)
          end
        end

        context "when properties are accessed using the index methods" do
          it "should have the default title" do
            expect(instance[:flag]).to be(true)
          end
        end
      end

      context "when created with no arguments" do
        subject(:instance) { klass.new }

        context "when properties are accessed using the dedicated instance methods" do
          it "should have false as default flag" do
            expect(instance.flag).to be(false)
          end
        end

        context "when properties are accessed using the index methods" do
          it "should have false as default flag" do
            expect(instance[:flag]).to be(false)
          end
        end
      end
    end
  end
end
