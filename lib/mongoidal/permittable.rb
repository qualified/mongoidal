module Mongoidal
  # provides utility methods for easily marking fields as not being permittable. By calling permit_fields! after
  # defining all of the fields/relations in the class, a permitted_fields class method will be defined which can be
  # used with strong params to have a default set of fields.
  # Best practice is to unpermit any field that may have cases where it should not be permittable, and instead allow
  # the controller to add that field as permited as needed.
  module Permittable
    extend ActiveSupport::Concern

    def self.unpermitted_fields
      @unpermitted_fields ||= [:_id, :_type, :created_at, :updated_at]
    end

    module ClassMethods
      def unpermitted
        @unpermitted ||= Set.new.tap do |unpermitted|
          unpermitted.merge(Permittable.unpermitted_fields)
          self.ancestors.each do |ancestor|
            if ancestor != self and ancestor.respond_to? :unpermitted
              unpermitted.merge(ancestor.unpermitted)
            end
          end
        end
      end

      def unpermit(*fields)
        fields.each do |field|
          if field.respond_to? :name
            field = field.name.to_sym
          end

          relation = self.relations[field.to_s]

          if relation and relation.macro == :belongs_to
            unpermitted << "#{field}_id".to_sym
          else
            unpermitted << field
          end

        end
      end

      def permit_fields!(id: nil, embeds: true)
        permitted = []
        nested = {}
        fields = self.fields.keys.map(&:to_sym) - unpermitted.to_a
        fields.each do |field|
          type = self.fields[field.to_s].options[:type]
          if type == Array
            nested[field] = []
          else
            permitted << field
          end
        end

        # support embedded
        if embeds
          # if embeds is true
          if embeds == true
            # only select the embeds relations that have a permitted_fields method on their class
            embeds = self.relations.each do |k, v|
              # if id is nil, then we will auto-include it if this is an embedded document.
              if v.macro == :embedded_in
                id = true if id.nil?
              else
                unless unpermitted.include?(k.to_sym)
                  if v.macro == :embeds_one or v.macro == :embeds_many
                    if v.class_name.to_const.respond_to?(:permitted_fields)
                      permitted << k.to_sym
                      eclass = self.relations[k].class_name.to_const
                      if eclass.respond_to? :permitted_fields
                        nested[k.to_sym] = eclass.permitted_fields
                      end
                    end
                  end
                end
              end
            end
          end
        end

        permitted << :id if id
        permitted << nested if nested.present?

        self.define_singleton_method :permitted_fields do
          permitted
        end
      end
    end
  end
end