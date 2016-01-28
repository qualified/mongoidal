module Mongoidal
  # provides utility methods for easily marking fields as not being permittable. By calling permit_fields! after
  # defining all of the fields/relations in the class, a permitted_fields class method will be defined which can be
  # used with strong params to have a default set of fields.
  # Best practice is to unpermit any field that may have cases where it should not be permittable, and instead allow
  # the controller to add that field as permited as needed.
  module Permittable
    extend ActiveSupport::Concern

    module ClassMethods
      def permitted_fields
        @permitted_fields ||= [].tap do |permitted|
          self.ancestors.each do |ancestor|
            if ancestor != self and ancestor.respond_to? :permitted_fields
              permitted.concat(ancestor.permitted_fields)
            end
          end
        end
      end

      def permitted(*fields)
        fields.each do |name|
          if name.respond_to? :name
            name = name.name.to_sym
          end

          relation = self.relations[name.to_s]

          if relation
            if relation.macro == :belongs_to
              permitted_fields << "#{name}_id".to_sym
            elsif relation.macro == :embeds_one or relation.macro == :embeds_many
              klass = relation.class_name.to_const 
              if klass.respond_to?(:permitted_fields)
                permitted_fields << name
                permitted_fields << {name => klass.permitted_fields}
              end
            end
          else
            field = self.fields[name.to_s]
            if field
              if field.options[:type] == Array or field.options[:type].nil?
                permitted_fields << name
                permitted_fields << {name => []}
              else
                permitted_fields << name
              end
            else
              permitted_fields << name
            end
          end
        end
      end

      def permit_fields!(id: nil, embeds: true)
      end
    end
  end
end