module Mongoidal
  module Nesting

    # allows updating of an entire document structure without having to replace existing embedded
    # documents. It is assumed that the entire embeds_many collection is being replaced.
    # deleted models are not actually destroyed, but instead returned within a flat array which
    # can later be destroyed.
    # If a specific set of embed relations are not provided then all embeds_many relations will be used
    def nested_assign(attributes, position: nil)
      attributes = HashWithIndifferentAccess.new(attributes)
      embeds = self.class.relations.select {|k, v| v.is_a?(Mongoid::Association::Embedded::EmbedsMany)}

      root_attrs = attributes.except(*embeds.keys)
      embed_attrs = attributes.slice(*embeds.keys)

      to_delete = []

      assign_attributes(root_attrs)

      # modifying collections is immediate (called before save!, so we want to make sure everything is valid first)
      if valid?
        embeds.each do |k, relation|
          if embed_attrs[relation.name]
            matched = []
            collection = self.send(relation.name)

            pos = 0
            embed_attrs[relation.name].each do |attrs|
              existing = find_existing_embedded(relation, collection, attrs)

              if existing
                existing.assign_attributes(attrs)
                matched << existing
              else
                matched << collection.build(attrs)
              end

              # special attribute for setting sort order
              if position and matched.last.respond_to?(position)
                matched.last.send("#{position}=", pos += 1)
              end
            end

            collection.each do |nested|
              to_delete << nested unless matched.include? nested
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
    # Any items not present within the new array will be destroyed
    def nested_save!(attributes, *embeds, &block)
      to_delete = nested_assign(attributes, *embeds)
      if valid?
        block.call(to_delete) if block_given?
        to_delete.each(&:destroy)
      end
      save!
    end

    protected

    # tries to match to an existing embedded document using the id within the attributes provided.
    # if the match is unable to be made, it will try to use the find_within_collection class method
    # on the relation class if available.
    def find_existing_embedded(relation, collection, attrs)
      existing = collection.where(id: attrs[:id]).first if attrs[:id]
      unless existing
        klass = relation.class_name.to_const
        if klass.respond_to? :find_within_collection
          existing = klass.find_within_collection(collection, attrs)
        end
      end
      existing
    end
  end
end
