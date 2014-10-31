module Mongoidal
  module RootDocument
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      include Mongoid::Timestamps
    end

    def touch_all
      touch
    end
  end
end