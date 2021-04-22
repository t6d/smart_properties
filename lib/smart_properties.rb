define_method(:SmartProperties, &Class.new(Module) do
  def self.to_proc
    method(:new).to_proc
  end

  def initialize(*plugins, &block)
    @plugins = plugins
    super(&block)
  end

  def included(base)
    default_plugins = [SmartProperties::DSL]
    default_plugins << SmartProperties::Bootstrap unless base.is_a?(Class)
    [*default_plugins, *plugins].each { |plugin| plugin.attach(base) }
  end

  def inspect
    to_s
  end

  def to_s
    "SmartProperties(%s)" % plugins.join(", ")
  end

  def plugins
    @plugins.map do |plugin|
      case plugin
      when Proc
        plugin.call
      else
        plugin
      end
    end
  end
end)

SmartProperties = SmartProperties(-> { SmartProperties::Initializer }, -> { SmartProperties::GenericAccessors })

##
# {SmartProperties} can be used to easily build more full-fledged accessors
# for standard Ruby classes. In contrast to regular accessors,
# {SmartProperties} support validation and conversion of input data, as well
# as, the specification of default values. Additionally, individual
# {SmartProperties} can be marked as required. This causes the runtime to
# throw an +ArgumentError+ whenever a required property has not been
# specified.
#
# In order to use {SmartProperties}, simply include the {SmartProperties}
# module and use the {ClassMethods#property} method to define properties.
#
# @see ClassMethods#property
#   More information on how to configure properties
#
# @example Definition of a property that makes use of all {SmartProperties} features.
#
#  property :language_code, :accepts => [:de, :en],
#                           :converts => :to_sym,
#                           :default  => :de,
#                           :required => true
#
module SmartProperties; end

require_relative 'smart_properties/plugin'
require_relative 'smart_properties/dsl'
require_relative 'smart_properties/bootstrap'
require_relative 'smart_properties/generic_accessors'
require_relative 'smart_properties/initializer'
require_relative 'smart_properties/property_collection'
require_relative 'smart_properties/property'
require_relative 'smart_properties/errors'
require_relative 'smart_properties/version'
require_relative 'smart_properties/validations'
