module Mongoidal
  module EnumField
    extend ActiveSupport::Concern

    module ClassMethods

      def enum_fields
        @enum_fields ||= {}
      end

      protected

      def enum_field(field_name, options = {})
        raise "values option is required" unless options.has_key? :values

        options[:type] ||= Symbol

        field_options = options.slice(:type, :default, :index)

        field(field_name, field_options).tap do
          values = options[:values]
          actual_values = values.dup

          # keep track of enum fields so that they can be iterated later
          enum_fields[field_name] = options


          # mongoid 3.1.0 now validates against the pre-serialized value meaning that
          # if a string is ever used to set a value then it's symbol version will not be tested against.
          # To fix this we make sure both symbol and string representations are supported.
          inclusion_values = actual_values.clone
          actual_values.each do |v|
            inclusion_values << v.to_s if v.is_a?(Symbol)
          end

          if options[:type] == Array
            validate do
              value = self.send(field_name)
              if value
                if value.is_a?(Array)
                  extras = value - inclusion_values
                  errors.add(field_name, "values #{extras} are not allowed") if extras.any?
                else
                  errors.add(field_name, 'must be an array')
                end
              end
            end
          else
            validates_inclusion_of field_name,
                                   in: inclusion_values,
                                   message: options.has_key?(:message) ? options[:message] : 'invalid value',
                                   allow_nil: options[:allow_nil]
          end

          ## helper methods:

          define_singleton_method "#{field_name}_values" do
            values
          end

          # define the is_? shortcut methods
          unless options[:omit_shortcuts]
            default_suffix = "_#{field_name}"
            default_suffix = default_suffix.singularize if options[:type] == Array
            suffix = options[:suffix] == false ? '' : options[:suffix] || default_suffix
            prefix = options[:prefix] == false ? '' : options[:prefix] || 'is_'
            values.each do |key|
              unless key.blank?
                define_method "#{prefix}#{key}#{suffix}?" do
                  val = self.__send__ field_name
                  options[:type] == Array ? (val & [key.to_sym, key.to_s]).any? : (val == key.to_sym || val == key.to_s)
                end
              end
            end
          end

          unless actual_values.include? ''
            # treat empty values as nil values
            before_validation do |doc|
              if doc.__send__(field_name).blank?
                doc.__send__("#{field_name}=", nil)
              end
            end
          end

          # provide a changes method which show what was added and removed
          define_method "#{field_name}_changes" do
            changes = self.__send__("#{field_name}_change").dup
            changes[0] ||= []
            changes[1] ||= []
            {
              added: changes[1] - changes[0],
              removed: changes[0] - changes[1]
            }
          end

          # allows easy access to translations
          define_method "#{field_name}_translate" do |val = nil|
            val ||= self.__send__ field_name
            val = val.first if val.is_a?(Array)
            self.class.__send__ "#{field_name}_value_translate", val
          end

          #alias translate method to short form
          define_method "#{field_name}_t" do |val = nil|
            self.__send__ "#{field_name}_translate", val
          end

          define_singleton_method "#{field_name}_value_translate" do |val|
            if options[:i18n]
              I18n.t("#{options[:i18n]}.#{val}")
            elsif respond_to?(:translate)
              self.translate("#{field_name}.#{val}")
            else
              val.to_s.humanize
            end
          end

          define_singleton_method "#{field_name}_value_t" do |val|
            self.send("#{field_name}_value_translate", val)
          end
        end
      end
    end
  end
end