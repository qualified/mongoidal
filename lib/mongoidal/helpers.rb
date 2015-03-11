module Mongoidal
  module Helpers
    extend ActiveSupport::Concern

    @@models = []

    # keep track of all of the models that extend from this one
    def self.included base
      @@models << base unless base.name.include? 'Document'
    end

    def self.models
      @@models
    end

    # determines if a value is present - useful for bypassing a lazy attribute from automatically loading an object from storage
    def value_loaded?(name)
      !self.instance_variable_get("@#{name}").nil?
    end

    # dynamically determine if a field has changed. Maps to #{field_name}_changed?.
    def field_changed?(field_name)
      send "#{field_name}_changed?"
    end

    # provides array like slice capabilities. Useful because it calls the methods directly, instead
    # of just proxying to attributes.slice
    def slice(*syms, &block)
      result = {}
      syms.each do |sym|
        result[sym] = self.__send__ sym
      end

      # allow a block to be passed in so that it can be sliced using additional logic
      if block_given?
        result.merge!(block.call(self))
      end
      result
    end

    # reverts changed fields back to their saved value. If no field names are provided all changed
    # fields will be reverted
    def revert_fields(*names)
      names = changed if names.empty?
      reverted = []
      names.each do |name|
        if self.respond_to? "#{name}_change"
          values = self.__send__ "#{name}_change"
          if values
            self.__send__ "#{name}=", values.first
            reverted << name
          end
        end
      end

      reverted
    end
  end
end