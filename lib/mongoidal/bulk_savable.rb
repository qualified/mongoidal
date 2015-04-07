module Mongoidal
  module BulkSavable

    # allows updating of an entire document structure without having to replace existing embedded
    # documents. a special 'deleted' attribute is used to determine if a model should be deleted.
    # deleted models are not actually destroyed, but instead returned within a flat array which
    # can later be destroyed.
    # If a specific set of embed relations are not provided then all embeds_many relations will be used
    def bulk_assign(attributes, *embeds)
      if embeds.blank?
        embeds = self.class.relations.select {|k, v| v.macro == :embeds_many }.keys
      end

      root_attrs = attributes.except(*embeds)
      embed_attrs = attributes.slice(*embeds)

      to_delete = []

      assign_attributes(root_attrs)
      embeds.each do |embed|
        if embed_attrs[embed]
          embed_attrs[embed].each do |attrs|
            collection = self.send(embed)
            existing = collection.where(id: attrs[:id] || attrs['id']).first

            if !existing and attrs['slug']
              existing = collection.where(slug: attrs['slug']).first
            end

            deleted = attrs[:deleted] || attrs['deleted']

            if existing
              if deleted
                to_delete << existing
              else
                existing.assign_attributes(attrs)
              end
            elsif !deleted
              collection.build(attrs)
            end
          end
        end
      end

      to_delete
    end

    # useful method for allowing embedded documents to be saved without
    # fully replacing them. This method will extract the embed attributes
    # and insert/update/delete them one by one based off of the existing data,
    # instead of just replacing the entire array like a normal save would do.
    # A special "deleted" attribute is used to determine if an existing model should be destroyed.
    def bulk_save!(attributes, *embeds, &block)
      to_delete = bulk_assign(attributes, *embeds)
      block.call(to_delete) if block_given?
      to_delete.each(&:destroy)
      save!
    end
  end
end
