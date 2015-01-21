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
      target.attributes = reset_ids(attributes.dup)
    end

    def copy
      self.class.new(reset_ids(attributes.dup))
    end

    def copy_fields_to(target, *fields, overwrite_nil_only: false)
      fields.each do |field|
        if not overwrite_nil_only or target[field].nil?
          val = self[field]

          target[field] = if val.is_a?(Hash) or val.is_a?(Array)
            reset_ids(val)
          else
            val
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