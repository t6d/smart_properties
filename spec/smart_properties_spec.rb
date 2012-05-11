require 'spec_helper'

describe SmartProperties do
  
  context "when extending an other class" do
    
    subject do
      Class.new.extend(described_class)
    end
    
    it "should add a .property method" do
      subject.should respond_to(:property)
    end
    
  end
  
end