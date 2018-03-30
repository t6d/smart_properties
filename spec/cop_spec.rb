require 'spec_helper'
require 'rubocop-smart_properties'

RSpec.describe RuboCop::Cop::SmartProperties::DefaultsPerInstance do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'SmartProperties/DefaultsPerInstance' => RuboCop::ConfigLoader
        .default_configuration['SmartProperties/DefaultsPerInstance']
    )
  end


    shared_examples 'that is mutable' do
      let(:code) do
        <<-RUBY.strip_indent
          property :my_prop, accepts: String, default: #{default}
                                              ^^^^^^^^^#{'^'*default.size} Use proc when defaults are mutable objects
        RUBY
      end

      it 'is an offence' do
        expect_offense(code)
      end

      context 'with read_only set' do
        let(:code) do
          <<-RUBY.strip_indent
            property :my_prop, read_only: true, default: #{default}
        RUBY
      end

      it 'is not an offence' do
        expect_no_offenses(code)
      end
    end
  end

  shared_examples 'that is immutable' do
    let(:code) do
      <<-RUBY.strip_indent
          property :my_prop, accepts: String, default: #{default}
      RUBY
    end

    it 'is not an offence' do
      expect_no_offenses(code)
    end
  end

  ['1', '3', '3.1', 'true', 'false', ':symbol', '"a string".freeze', '[].freeze', '{b: 1}.freeze', 'CONSTANT', 'NESTED::CONSTANT'].each do |value|
    context "immutalbe #{value}" do
      let(:default) { value }
      it_behaves_like 'that is immutable'
    end
  end

  ['-> { something }', 'lambda { something }', 'Proc.new { something }'].each do |value|
    context "callable #{value}" do
      let(:default) { value }
      it_behaves_like 'that is immutable'
    end
  end


  ['Object.new', '"a string"', '[]', '{}'].each do |value|
    context "mutalbe #{value}" do
      let(:default) { value }
      it_behaves_like 'that is mutable'
    end
  end

  context 'propety without a default' do
    let(:code) do
      <<-RUBY.strip_indent
        property :my_prop, read_only: true
      RUBY
    end

    it 'is not an offence' do
      expect_no_offenses(code)
    end
  end
end
