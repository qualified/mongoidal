module Mongoidal
  module Copyable
    extend ActiveSupport::Concern

    def copy_changes_to(target, *fields)
      changes = fields.any? ? self.changes.slice(*fields.map(&:to_s)) : self.changes
      if changes.any?
        changes.each do |k, v|
          target[k] = v.last
        end
      end
    end

    def copy_to(target)
      target.attributes = reset_ids(attributes.dup)
    end

    def copy
      self.class.new(reset_ids(attributes.dup))
    end

    protected

    def reset_ids(attributes)
      attributes.each do |key, value|
        if key == '_id' and value.is_a?(BSON::ObjectId)
          attributes[key] = BSON::ObjectId.new
        elsif value.is_a?(Hash)
          attributes[key] = reset_ids(value.dup)
        elsif value.is_a?(Array)
          attributes[key] = value.map do |v|
            v.is_a?(Hash) ? reset_ids(v.dup) : v
          end
        end
      end
    end
  end
end