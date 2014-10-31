require 'mongoid_slug'
module Mongoidal
  module SlugField
    extend ActiveSupport::Concern

    module ClassMethods
      protected

      def slug_field(field_name, options = {})
        options[:type] = String

        include Mongoid::Slug

        field field_name, options.slice(:type, :default)
        slug field_name, options.slice(:history, :scope, :reserve, :permanent, :as, :index)
        validates_presence_of field_name unless options[:allow_nil]

        # should just use to_param instead
        #define_method "slug" do
        #  _slugs ? _slugs.first : nil
        #end

        scope :any_slug, lambda {|slugs| where(:_slugs.in => slugs.is_a?(Array) ? slugs : [slugs])}

        if options[:scope]
          #TODO: make this support relationships - currently only supports fields
          scope :scoped_slug, lambda {|scoped_value, slug| where(options[:scope] => scoped_value, :_slugs.in => slug)}
        end
      end
    end
  end
end