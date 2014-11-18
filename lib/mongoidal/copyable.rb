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
      attributes.each do |key, value|
        if key != '_id'
          target[key] = value
        end
      end
    end
  end
end