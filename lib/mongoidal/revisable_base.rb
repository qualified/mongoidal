module Mongoidal
  module RevisableBase
    extend ActiveSupport::Concern

    included do
      field :last_revision_number, type: Integer

      scope :revised_by, ->(user) { where(:"revisions.user" => user) }

      def revised_by?(user)
        revisions.revised_by(user).any?
      end
    end

    # returns the time of the most recent revision
    def last_revised_at
      if revisions.count > 1
        revisions.last.created_at
      else
        nil
      end
    end

    def revisable_fields
      self.class.revisable_fields
    end

    def revisable_embeds
      self.class.revisable_embeds
    end

    def has_revised_changes?
      return false if new_record?

      return true if changes.any? do |k, v|
        revisable_fields.include?(k)
      end

      each_revisable_collection do |collection, fields, relation|
        collection.each do |item|
          return true if embedded_item_has_revised_changes?(item, fields)
        end
      end

      return false
    end

    def embedded_item_has_revised_changes?(item, fields)
      fields = revisable_embeds[fields] if fields.is_a? Symbol
      item.changes.any? do |field|
        fields.include?(field.first)
      end
    end

    def revised_changes
      return [] if new_record?

      changes.select do |k, v|
        revisable_fields.include?(k)
      end
    end

    def revised_changes?
      revised_changes.any?
    end

    # returns true if the field was revised.
    def field_revised?(name)
      new_record? ? false : revised_changes.has_key?(name.to_s)
    end

    def field_revision(name, changes = revised_changes)
      new_record? ? nil : changes[name.to_s]
    end

    # returns a hash of modified embed records.
    # the key = the relation name
    # the value = a hash in which the
    # key = record id
    # value = 2 item array, first value is field name, 2nd value is field value
    def revised_embed_changes
      new_record? ? {} : collect_embed_revision_models do |item, results, fields|
        item.changes.each do |k, v|
          if fields.include?(k)
            results[k] = v.last
          end
        end
      end
    end

    def field_revision_history(field)
      field = field.to_s
      history = []
      revisions.each do |revision|
        if revision.revised_attributes.has_key?(field)
          history << Revision::RevisedFieldInfo.new(revision, self, field)
        end
      end
      history
    end

    def embedded_field_revision_history(collection, id, field)
      # TODO:
      #if collection.is_a?(Mongoid::Document) ?
      #
      #end
      id = id.to_s
      field = field.to_s
      history = []
      revisions.each do |revision|
        if revision.revised_embeds.has_key?(collection)
          if revision.revised_embeds[collection][id]
            history << Revision::RevisedFieldInfo.new(revision, nil, field, collection, id)
          end
        end
      end
      history
    end

    def revise(message: nil, tag: nil, created_at: Time.now, method: nil, type: :change, event_data: nil)
      method ||= respond_to?(:store) ? :store : :save
      !!_revise(message, tag, created_at, method, type, event_data)
    end

    def revise!(message: nil, tag: nil, created_at: Time.now, method: nil, type: :change, event_data: nil)
      method ||= respond_to?(:store!) ? :store! : :save!
      _revise(message, tag, created_at, method, type, event_data)
    end

    def _revise(message, tag, created_at, method, type, event_data)
      case type
      when :change, :event
      else
        raise ArgumentError.new("type #{type} is invalid")
      end

      revision = prepare_revision(message, tag, type: type, created_at: created_at, event_data: event_data)
      send(method)
      revision_prepared_for_revise(revision)
      revision
    end

    def ensure_base_revision!
      if last_revision_number.nil?
        if revisions.any?
          self.set(last_revision_number: max_revision_number)
        else
          build_base_revision.save!
          self.set(last_revision_number: 0)
        end
      end
    end

    def prepare_revision(message, tag, type: :change, created_at: Time.now, event_data: nil)
      if has_revised_changes? || type != :change
        ensure_base_revision!
        revision = build_next_revision(type != :change)

        if revision
          revision.type = type
          revision.created_at = created_at
          revision.message = message
          revision.event_data = event_data
          revision.tag = tag

          self.last_revision_number = revision.number
        end

        @revision = revision
      end
    end

    protected

    def revision_prepared_for_revise(revision)
      # placeholder to handle additional post prepared logic
    end

    # loops through each revisable embedded model and passes the item,
    # results array and fields array so that they can be processed further
    def collect_embed_revision_models
      models = {}

      each_revisable_collection do |collection, fields, relation|
        models[relation] = {}
        collection.each do |item|
          embed_changes = {}

          yield item, embed_changes, fields

          models[relation][item.id.to_s] = embed_changes if embed_changes.any?
        end
      end

      models
    end

    def max_revision_number
      revisions.max(:number)
    end

    def build_next_revision(force = false)
      changes = revised_changes
      if has_revised_changes? || force
        revision = revisions.build
        revision.number = max_revision_number + 1
        revision.created_at = Time.now.utc

        changes.each do |k, v|
          revision.revised_attributes[k] = v.last
        end

        revision.revised_embeds = revised_embed_changes
        revision.set_compressed
        revision
      end
    end

    def build_base_revision
      raise RuntimeError, 'base revision already exists' if revisions.any?

      revision = revisions.build(number: 0)
      revision.created_at = self.created_at

      changes = revised_changes
      revisable_fields.each do |name|
        field_revision = field_revision(name, changes)
        value = field_revision ? field_revision.first : __send__(name)
        revision.revised_attributes[name] = value
      end

      # collect the initial field values for all of the revisable embedded models
      revision.revised_embeds = collect_embed_revision_models do |item, results, fields|
        fields.each do |k|
          results[k] = item.__send__(k)
        end
      end

      revision
    end

    def each_revisable_collection
      revisable_embeds.each do |relation, fields|
        collection = __send__(relation)
        yield collection, fields, relation
      end
    end

    module ClassMethods
      def ancestor_revisable_fields
        @ancestor_revisable_fields ||= Set.new.tap do |fields|
          self.ancestors.each do |ancestor|
            if ancestor != self and ancestor.respond_to? :revisable_fields
              fields.merge(ancestor.revisable_fields)
            end
          end
        end
      end

      def revisable_fields
        @revisable_fields ||= Set.new(ancestor_revisable_fields)
      end

      def revisable_embeds
        @revisable_embeds ||= {}
      end

      def field_is_revisable?(field, relation = nil)
        if relation
          revisable_embeds[relation].try(:include?, field.to_s)
        else
          revisable_fields.include?(field.to_s)
        end
      end

      protected

      def revisable(*field_names)
        @revisable_fields = revisable_fields + field_names.map(&:to_s)
      end

      def embedded_revisable(relation, *field_names)
        revisable_embeds[relation] ||= Set.new
        revisable_embeds[relation] += field_names.map(&:to_s)
      end
    end
  end
end