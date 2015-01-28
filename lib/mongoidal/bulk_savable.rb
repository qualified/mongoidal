module Mongoidal
  module BulkSavable
    # useful method for allowing embedded documents to be saved without
    # fully replacing them. This method will extract the embed attributes
    # and insert/update/delete them one by one based off of the existing data,
    # instead of just replacing the entire array like a normal save would do.
    # A special "deleted" attribute is used to determine if an existing model should be destroyed.
    def bulk_save!(attributes, *embeds)
      root_attrs = attributes.except(*embeds)
      embed_attrs = attributes.slice(*embeds)

      assign_attributes(root_attrs)
      embeds.each do |embed|
        if embed_attrs[embed]
          embed_attrs[embed].each do |attrs|
            collection = self.send(embed)
            existing = collection.where(id: attrs[:id]).first
            if existing
              if attrs[:deleted]
                existing.destroy
              else
                existing.assign_attributes(attrs)
              end
            else
              collection.build(attrs)
            end
          end
        end
      end
      save!
    end
  end

end
