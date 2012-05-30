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

  context "when used to build a class that has a property called :title on a class" do
    
    subject do
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

    its(:properties) { should have(1).property }
    its(:properties) { should have_key(:title) }

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
      
      it "should not influence other instances that have been initialized with different attributes" do
        other = klass.new :title => double(:to_title => 'Lorem ipsum')
        
        subject.title.should be == 'chunky'
        other.title.should   be == 'Lorem ipsum'
      end

    end

    context "when subclassed" do

      superklass = subject.call

      subject do
        Class.new(superklass)
      end

      its(:properties) { should have(1).property }
      its(:properties) { should have_key(:title) }

      context "instances of this subclass" do

        klass = subject.call

        subject do
          klass.new
        end

        it { should respond_to(:title) }
        it { should respond_to(:title=) }

      end

      context "instances of this subclass that have been intialized from a set of attributes" do
        
        klass = subject.call
        
        subject do
          klass.new :title => stub(:to_title => 'Message')
        end
        
        it "should have the correct title" do
          subject.title.should be == 'Message'
        end
        
      end
      
    end

    context "when subclassed and extended with a property called text" do
      
      superklass = subject.call
      
      subject do
        Class.new(superklass).tap do |c|
          c.instance_eval do
            property :text
          end
        end
      end

      its(:properties) { should have(2).property }
      its(:properties) { should have_key(:title) }
      its(:properties) { should have_key(:text) }

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
        
        it "should have the correct title" do
          subject.title.should be == 'Message'
        end
        
        it "should have the correct text" do
          subject.text.should be == 'Hello'
        end
        
      end
      
    end
    
    context "when extended with a :type property at runtime" do
      
      klass = subject.call
      
      subject do
        klass.tap do |c|
          c.instance_eval do
            property :type, :converts => :to_sym
          end
        end
      end

      its(:properties) { should have(2).property }
      its(:properties) { should have_key(:title) }
      its(:properties) { should have_key(:type) }

      context "instances of this class" do
        
        klass = subject.call
        
        subject do
          klass.new :title => double(:to_title => 'Lorem ipsum')
        end
        
        it { should respond_to(:type)  }
        it { should respond_to(:type=) }
        
      end
      
      context "when subclassing this class" do
        
        superklass = subject.call
        
        subject do
          Class.new(superklass)
        end
        
        context "instances of this class" do
          
          klass = subject.call
          
          subject do
            klass.new :title => double(:to_title => 'Lorem ipsum')
          end
          
          it { should respond_to :title }
          it { should respond_to :title= }
          
          it { should respond_to :type }
          it { should respond_to :type= }
          
        end
        
      end
      
    end
    
  end
  
  context "when used to build a class that has a property called :title which a lambda statement for conversion" do
    
    subject do
      Class.new.tap do |c|
        c.send(:include, described_class)
        c.instance_eval do
          property :title, :converts => lambda { |t| "<title>#{t.to_s}</title>"}
        end
      end
    end
    
    context "instances of this class" do
      
      klass = subject.call
      
      subject do
        klass.new
      end
      
      it "should convert the property title as specified the lambda statement" do
        subject.title = "Lorem ipsum"
        subject.title.should be == "<title>Lorem ipsum</title>"
      end
      
    end
    
  end
  
  context "when used to build a class that has a property called :visible which uses an array of valid values for acceptance checking" do
    
    subject do
      Class.new.tap do |c|
        def c.name; "TestDummy"; end
        
        c.send(:include, described_class)
        
        c.instance_eval do
          property :visible, :accepts => [true, false]
        end
      end
    end
    
    context "instances of this class" do
      
      klass = subject.call

      subject do
        klass.new
      end
      
      it "should allow to set true as value for visible" do
        expect { subject.visible = true }.to_not raise_error
      end
      
      it "should allow to set false as value for visible" do
        expect { subject.visible = false }.to_not raise_error
      end
      
      it "should not allow to set :maybe as value for visible" do
        expect { subject.visible = :maybe }.to raise_error(ArgumentError, "TestDummy does not accept :maybe as value for the property visible")
      end
      
    end
    
  end
  
  context 'when used to build a class that has a property called :license_plate which uses a lambda statement for accpetance checking' do
    
    subject do
      Class.new.tap do |c|
        def c.name; 'TestDummy'; end
        
        c.send(:include, described_class)
        
        c.instance_eval do
          property :license_plate, :accepts => lambda { |v| /\w{1,2} \w{1,2} \d{1,4}/.match(v) }
        end
      end
    end
    
    context 'instances of this class' do
      
      klass = subject.call
      
      subject do
        klass.new
      end
      
      it 'should not a accept "invalid" as value for license_plate' do
        expect { subject.license_plate = "invalid" }.to raise_error(ArgumentError, 'TestDummy does not accept "invalid" as value for the property license_plate')
      end
      
      it 'should accept "NE RD 1337" as license plate' do
        expect { subject.license_plate = "NE RD 1337" }.to_not raise_error
      end
      
    end
    
  end
  
  context 'when used to build a class that has a property called :text whose getter is overriden' do
    
    subject do
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
      
      klass = subject.call
      
      subject do
        klass.new
      end
      
      it "should return the accepted value for the property called :text" do
        subject.text.should be == '<em>Hello</em>'
      end
      
    end
    
  end
  
end
