require 'spec_helper'

describe SmartProperties do

  context "when extending an other class" do

    subject do
      Class.new.tap do |c|
        c.send(:include, described_class)
      end
    end

    it "should add a .property method" do
      subject.should respond_to(:property)
    end

  end

  context "when used to define a smart property called :title on a class" do
    
    subject do
      title = Object.new.tap do |o|
        def o.to_title; 'chunky'; end
      end
      
      klass = Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          def name; "TestDummy"; end
        end
      end
      
      klass.property :title, :accepts => String,
                             :converts => :to_title,
                             :required => true,
                             :default => title
      
      klass
    end

    context "instances of this class" do
      
      klass = subject.call
      
      subject do
        klass.new
      end
      
      it { should respond_to(:title) }
      it { should respond_to(:title=) }
      
      it "should have 'chucky' as default value for title" do
        subject.title.should be == 'chunky'
      end
      
      it "should convert all values that are assigned to title into strings" do
        subject.title = double(:to_title => 'bacon')
        subject.title.should be == 'bacon'
      end
      
      it "should not allow to set nil as title" do
        expect { subject.title = nil }.to raise_error(ArgumentError, "TestDummy requires the property title to be set")
      end
      
      it "should not allow to set objects as title that do not respond to #to_title" do
        expect { subject.title = Object.new }.to raise_error(ArgumentError, "Object does not respond to #to_title")
      end
      
      it "should allow to set a title using the #write_property method" do
        subject.write_property(:title, double(:to_title => 'bacon'))
        subject.title.should be == 'bacon'
      end
      
      it "should allow to get the title using the #read_property method" do
        subject.read_property(:title).should be == 'chunky'
      end
      
      it "should not influence other instances that have been initialized with different attributes" do
        other = klass.new :title => double(:to_title => 'Lorem ipsum')
        
        subject.title.should be == 'chunky'
        other.title.should   be == 'Lorem ipsum'
      end

    end
    
    context "when subclassed and extended with a property called text" do
      
      superklass = subject.call
      
      subject do
        klass = Class.new(superklass)
        klass.property :text
        klass
      end
      
      context "instances of this subclass" do
        
        klass = subject.call
        
        subject do
          klass.new
        end
        
        it { should respond_to(:title) }
        it { should respond_to(:title=) }
        it { should respond_to(:text) }
        it { should respond_to(:text=) }
        
      end
      
      context "instances of the super class" do
        
        subject do
          superklass.new
        end
        
        it { should_not respond_to(:text) }
        it { should_not respond_to(:text=) }
        
      end
      
      context "instances of this subclass that have been intialized from a set of attributes" do
        
        klass = subject.call
        
        subject do
          klass.new :title => stub(:to_title => 'Message'), :text => "Hello"
        end
        
        its(:title) { should be == 'Message' }
        its(:text)  { should be == 'Hello' }
        
      end
      
    end

  end

end
