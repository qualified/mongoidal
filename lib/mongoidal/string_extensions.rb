class String
  unless respond_to?(:to_slug)
    def to_slug(sep = '-')
      self.gsub("'", '').parameterize(sep)
    end
  end

  alias :slugify :to_slug

  unless respond_to?(:to_const)
    # gets the class/type matching the string (i.e. "Model::RootDocument".to_class)
    def to_const(suffix = nil)
      to_const_name(suffix).constantize
    end

    def to_const_name(suffix = nil)
      name = self.gsub("__", "::_").camelize
      suffix = suffix.to_s.camelize if suffix.is_a? Symbol
      name += suffix unless !suffix or name.ends_with? suffix
      name
    end

    def const_defined?(suffix = nil)
      not to_const_name(suffix).split('::').inject(Object) do |mod, class_name|
        mod and mod.const_defined?(class_name) ? mod.const_get(class_name) : nil
      end.nil?
    end
  end
end