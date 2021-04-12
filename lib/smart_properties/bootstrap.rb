module SmartProperties
  module Bootstrap
    def included(target)
      super
      target.include(SmartProperties)
    end
  end
end
