module Mongoidal
  module EmbeddedErrors
    def embedded_errors
      errors = self.errors.dup
      self.errors.each do |key, value|
        relation = self.class.embedded_relations[key.to_s]
        if relation
          invalid = self.send(key).select {|r| r.invalid?}.first
          errors["#{key}_errors"] = invalid.errors
        end
      end

      errors
    end
  end
end
