module Mongoidal
  module EmbeddedDocument
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
    end

    # extracts the created_at time from the id
    def created_at
      id.generation_time
    end

    # returns the parent model for this class. Useful for when the parent needs to be
    # accessed in a dynamic way and the actual name of the parent field isn't known.
    def parent_model
      name = parent_relationship.try(:name)
      send(name) if name
    end

    # the root model that this model is embedded in (no matter how many levels deep)
    def root_model
      parent_models.last
    end

    # touches self and all parents
    def touch_all
      touch
      parent_models.each(&:touch)
    end

    def parent_models
      @parent_models ||= begin
        parents = Array.new
        parents << (parent = parent_model)
        parents << (parent = parent.parent_model) while parent and parent.respond_to?(:parent_model)
        parents
      end
    end

    def parent_relationship
      self.class.parent_relationship
    end

    module ClassMethods
      # Returns the parent "embedded_in" relationship for this document
      # @return [Mongoid::Relations::Metadata]
      def parent_relationship
        @parent_relationship ||= relations.values.find do |relation|
          relation.macro == :embedded_in
        end
      end
    end
  end

end