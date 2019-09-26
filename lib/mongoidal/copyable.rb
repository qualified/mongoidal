module Mongoidal
  module Copyable
    extend ActiveSupport::Concern

    def copy_changes_to(target, *fields)
      changes = fields.any? ? self.changes.slice(*fields.map(&:to_s)) : self.changes
      if changes.any?
        changes.each do |k, v|
          if fields.any? or target.respond_to?(k)
            target[k] = v.last
          end
        end
      end
    end

    def copy_to(target)
      target.attributes = reset_ids(copyable_attributes)
    end

    def copy
      self.class.new(reset_ids(copyable_attributes))
    end

    def copyable_attributes
      attributes.slice(*(self.class.fields.keys + self.class.relations.keys))
    end

    # copies the fields from the instance to the target. Will reset any _id attributes that it
    # finds along the way. Two flags are available:
    # overwrite_nil_only - set to true if only nil target values should be overwritten
    # ignore_nil_source - set to false if the target should be overwritten with nil values from the source
    def copy_fields_to(target, *fields, overwrite_nil_only: false, ignore_nil_source: true)
      fields.each do |field|
        if not overwrite_nil_only or target[field].nil?
          val = self[field]
          unless val.nil? and ignore_nil_source
            target[field] = if val.is_a?(Hash) or val.is_a?(Array)
              reset_ids(val)
            else
              val
            end
          end
        end
      end
    end

    protected

    def reset_ids(attributes)
      if attributes.is_a?(Array)
        attributes.map do |v|
          v.is_a?(Hash) ? reset_ids(v.dup) : v
        end
      else
        attributes.each do |key, value|
          if key == '_id' and value.is_a?(BSON::ObjectId)
            attributes[key] = BSON::ObjectId.new
          elsif value.is_a?(Hash) or value.is_a?(Array)
            attributes[key] = reset_ids(value.dup)
          end
        end
      end
    end
  end
end