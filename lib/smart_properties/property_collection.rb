require 'forwardable'

module SmartProperties
  class PropertyCollection
    include Enumerable
    extend Forwardable

    attr_reader :parent

    def self.for(scope)
      parent = scope.ancestors[1..-1].find do |ancestor|
        ancestor.ancestors.include?(SmartProperties) &&
          ancestor != scope &&
          ancestor != SmartProperties
      end

      if parent.nil?
        new
      else
        parent.properties.register(collection = new)
        collection
      end
    end

    def initialize
      @collection = {}
      @collection_with_parent_collection = {}
      @children = []
    end

    def []=(name, value)
      name = name.to_s
      collection[name] = value
      collection_with_parent_collection[name] = value
      notify_children
      value
    end

    def [](name)
      collection_with_parent_collection[name.to_s]
    end

    def key?(name)
      collection_with_parent_collection.key?(name.to_s)
    end

    def keys
      collection_with_parent_collection.keys.map(&:to_sym)
    end

    def each(&block)
      return to_enum(:each) if block.nil?
      collection_with_parent_collection.each { |name, value| block.call([name.to_sym, value]) }
    end

    def to_h
      each.to_h
    end

    def to_hash
      to_h
    end

    def register(child)
      children.push(child)
      child.refresh(collection_with_parent_collection)
      nil
    end

    def_delegators :collection_with_parent_collection, :count, :size, :length, :values

    protected

    attr_accessor :children
    attr_accessor :collection
    attr_accessor :collection_with_parent_collection

    def notify_children
      @children.each { |child| child.refresh(collection_with_parent_collection) }
    end

    def refresh(parent_collection)
      @collection_with_parent_collection = parent_collection.merge(collection)
      notify_children
      nil
    end
  end
end
