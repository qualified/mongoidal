module Mongoidal
  module TagField
    extend ActiveSupport::Concern

    module ClassMethods
      protected

      def tag_field(field_name, options = {})
        ## set default options
        options[:separator] = ',' unless options[:separator]

        cleanse_tags = lambda do |tags|
          unless tags.nil?
            tags = tags.downcase if tags.is_a?(String) and options[:downcase]
            tags = [tags.to_s] if tags.is_a? Symbol
            tags = tags.split(options[:separator]) if tags.is_a? String
            tags = tags.compact.map {|tag| tag.to_s.strip}.reject(&:blank?).uniq
            tags = tags.map {|tag| tag.to_sym} if options[:type] == Symbol
          end
          tags
        end

        ## create field
        field_options = options.slice(:default, :localize, :as)
        field_options[:type] = options[:type] == Symbol ? Mongoidal::SymArray : Array

        field(field_name, field_options).tap do
          ## create index if option is set
          index({field_name => 1}, {background: true}) if options[:index] == true

          ## create scope
          scope "any_#{field_name}", lambda {|tags| where(field_name.in => cleanse_tags.call(tags)) }
          scope "all_#{field_name}", lambda {|tags| where(field_name.all => cleanse_tags.call(tags)) }

          ## define smart setter method that converts strings to arrays and trims whitespace
          define_method "#{field_name}=" do |tags|
            self[field_name] = cleanse_tags.call(tags)
          end

          # this is just an alias to the normal setter
          define_method "#{field_name}_text=" do |tags|
            self[field_name] = cleanse_tags.call(tags)
          end

          define_method "#{field_name}_text" do
            tags = self.__send__(field_name) || []
            tags.join(options[:separator] == ',' ? ', ' : options[:separator])
          end

          define_method "add_#{field_name}" do |tags|
            if tags
              existing = self[field_name] || []
              self[field_name] = existing | cleanse_tags.call(tags)
            end
          end

          define_method "remove_#{field_name}" do |tags|
            if tags
              existing = self[field_name] || []
              existing -= Array.wrap(tags)
            end
          end

          ## define cleanse helper
          define_method "cleanse_for_#{field_name}" do |tags|
            cleanse_tags.call tags
          end

          ## define tags_added method to be able to determine which tags were newly added
          define_method "#{field_name}_added" do
            tags = self.__send__ "#{field_name}"
            tags_was = self.__send__("#{field_name}_was") || []
            tags ? tags - tags_was : nil
          end

          define_method "#{field_name}_removed" do
            tags = self.__send__ "#{field_name}"
            tags_was = self.__send__("#{field_name}_was") || []
            tags ? tags_was - tags : nil
          end
        end
      end
    end
  end
end