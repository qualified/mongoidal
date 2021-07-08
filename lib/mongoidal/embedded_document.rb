module Mongoidal
  module EmbeddedDocument
    extend ActiveSupport::Concern
    include Mongoidal::Helpers

    included do
      include Mongoid::Document
    end

    # extracts the created_at time from the id
    def created_at
      id.generation_time
    end

    # touches self and all parents
    def touch_all
      touch
      _parents.each(&:touch)
    end

    def _parents
      parents = []
      object = self
      while (object._parent) do parents << object = object._parent; end
      parents
    end

    def parent_relationship
      self.class.parent_relationship
    end

    module ClassMethods
      # Returns the parent "embedded_in" relationship for this document
      # @return [Mongoid::Relations::Metadata]
      def parent_relationship
        @parent_relationship ||= relations.values.find do |relation|
          relation.is_a?(Mongoid::Association::Referenced::EmbeddedIn)
        end
      end
    end
  end

end