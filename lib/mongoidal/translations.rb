module Mongoidal
  module Translations
    extend ActiveSupport::Concern
    # translation helper
    def translate(key, options = {})
      self.class.translate(key, options)
    end

    module ClassMethods
      def translate(key, options = {})
        t = I18n.t("models.#{self.name.underscore}.#{key}", options)
        # special logic to process a _ value as the text value when specifying a hash on a field name.
        # this is useful for both defining the label for a field name and also providing translations
        # for its values. This feature is typically needed for enums
        (t.is_a?(Hash) and t.has_key?(:_)) ? t[:_] : t
      end
    end
  end
end