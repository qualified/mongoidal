module Mongoidal
  module EmbeddedErrors
    def embedded_errors
      # to_hash and keys exist on Rails 6.1 and 7.x; Errors#to_h and two-arg each do not on 7.0
      errors = self.errors.to_hash
      errors.keys.each do |key|
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
