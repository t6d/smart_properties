require 'spec_helper'

RSpec.describe SmartProperties::Plugin do
  subject(:plugin) { SmartProperties::Plugin }
  let(:target_class) { Class.new }

  it "create a module" do
    expect(plugin.new(:include)).to be_kind_of(Module)
  end

  it "can be instantiated and included into a class through #attach" do
    plugin
      .new(:include) { def hello; end }
      .attach(target_class)

    expect(target_class.new).to respond_to(:hello)
  end

  it "can be instantiated and extend a class through #attach" do
    plugin
      .new(:extend) { def hello; end }
      .attach(target_class)

    expect(target_class).to respond_to(:hello)
  end

  it "raises if an invalid type is passed to .new" do
    expect { plugin.new(:unknown) }.to raise_error(ArgumentError)
  end
end
