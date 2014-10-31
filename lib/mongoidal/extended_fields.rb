module Mongoidal
  module ExtendedFields
    extend ActiveSupport::Concern

    included do
      include SlugField
      include EnumField
      include TagField
    end
  end
end