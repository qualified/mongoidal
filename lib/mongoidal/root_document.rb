module Mongoidal
  module RootDocument
    extend ActiveSupport::Concern

    include Mongoidal::Helpers

    included do
      include Mongoid::Document
      include Mongoid::Timestamps

      Mongoidal::RootDocument.classes << self
    end

    def touch_all
      touch
    end

    def self.classes
      @classes ||= []
    end
  end
end